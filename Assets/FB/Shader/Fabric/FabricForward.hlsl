#ifndef FABRIC_FORWARD_INCLUDE
    #define FABRIC_FORWARD_INCLUDE

    #include "FabricInput.hlsl"

    SurfaceData_SGame InitializeSurfaceData_SGame(half2 uv)
    {
        SurfaceData_SGame surfaceData = (SurfaceData_SGame)0;

        float4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv) * _BaseColor;

        half3 mask_map = SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,uv).rgb;
        half metallic = _Metallic * mask_map.r;
        half smoothness = Remap(mask_map.b,float2(0,1),float2(0,_SmoothnessMax));
        half occlusion = lerp(1,mask_map.g,_OcclusionStrength);

        #if defined(_FUZZMAP_ON)
            half fuzz_map = SAMPLE_TEXTURE2D(_FuzzMap,sampler_FuzzMap, uv * _FuzzMapUVScale).r;
            albedoAlpha.rgb = saturate(lerp(0,fuzz_map,_FuzzStrength).xxx + albedoAlpha.rgb) * occlusion;
        #endif

        // Origin
        // surfaceData.albedo = albedoAlpha.rgb;
        // surfaceData.specular = _SpecColor.rgb;
        // surfaceData.albedo *= (1.0 - Max3(surfaceData.specular.r, surfaceData.specular.g, surfaceData.specular.b));
        
        // Change To Metallic
        surfaceData.metallic = metallic;
        surfaceData.specular = lerp(kDieletricSpec.rrr,  albedoAlpha, surfaceData.metallic);
        surfaceData.specular = lerp(surfaceData.specular,  _SpecColor.rgb, _SpecTintStrength);
        surfaceData.albedo = lerp(albedoAlpha,  kDieletricSpec, surfaceData.metallic);
        
        surfaceData.alpha = albedoAlpha.a;

        #if _ALPHATEST_ON
            clip(surfaceData.alpha - _Cutoff);
        #endif

        surfaceData.smoothness = smoothness;
        surfaceData.occlusion = occlusion;

        #if defined(_SILK_ON)
            surfaceData.anisotropy = _Anisotropy;
        #endif

        #if !defined(_SILK_ON)
            surfaceData.smoothness =  lerp(0.0, 0.6, smoothness);
        #endif
        
        #if defined(_ENABLE_GEOMETRIC_SPECULAR_AA)
            surfaceData.smoothness = GeometricNormalFiltering(surfaceData.smoothness, fragInputs.TBN[2], surfaceDescription.SpecularAAScreenSpaceVariance, surfaceDescription.SpecularAAThreshold);
        #endif

        return surfaceData;
    }

    void SG_ThreadMapDetail(float2 thread_uv, float threadAOStrength, float threadNormalStrength, float threadSmoothnessStrength, 
    inout float3 normal, inout float smoothness, inout float ao)
    {
        float4 threadMap = SAMPLE_TEXTURE2D(_ThreadMap, sampler_ThreadMap, thread_uv);

        float3 threadNormal = normalize(UnpackNormal(float4(threadMap.a, threadMap.g, 1, 1)));
        threadNormal = float3(threadNormal.rg * threadNormalStrength, lerp(1, threadNormal.b, saturate(threadNormalStrength)));

        float smoothness_adjus = Remap(threadMap.b, float2 (0, 1), float2 (-1, 1));
        smoothness_adjus = lerp(0,smoothness_adjus,threadSmoothnessStrength);
        
        normal = normalize(NormalBlend(threadNormal, normal));
        smoothness = saturate(smoothness + smoothness_adjus);
        // ao = min(ao, lerp(1, threadMap.r, threadAOStrength));
        ao = Remap((threadMap.x * 2 - 1) * threadAOStrength, float2 (-1, 1), float2 (0, 1)) * ao * 2 ;
    }

    InputData_SGame InitializeInputData_SGame(Varyings_SGame input,SurfaceData_SGame surfaceData,half FaceSign)
    {
        InputData_SGame inputData = (InputData_SGame)0;
        inputData.positionWS = input.positionWS;

        inputData.TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);

        float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,input.uv);
        float3 normalTS = UnpackNormal(normal_map);
        normalTS.xy *= _NormalScale;
        normalTS = normalize(normalTS);

        #if defined(_THREADMAP_ON)
            SG_ThreadMapDetail(input.uv * _ThreadTilling,_ThreadAOStrength * 2,_ThreadNormalStrength,_ThreadSmoothnessScale,normalTS ,surfaceData.smoothness,surfaceData.occlusion);
        #endif

        inputData.normalWS = TransformTangentToWorld(normalTS, inputData.TBN); // default Tangent Space
        
        if(FaceSign == 0)
        inputData.normalWS = -inputData.normalWS;

        inputData.normalWS = normalize(inputData.normalWS);
        inputData.viewDirWS = normalize(UnPackViewDir(input.tangentWS,input.bitangentWS,input.normalWS));

        inputData.Irradiance = SampleSH(inputData.normalWS);

        return inputData;
    }

#endif // FABRIC_FORWARD_INCLUDE