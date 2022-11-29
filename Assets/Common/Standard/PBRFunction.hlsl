#ifndef PBR_FUNCTION_INCLUDE
    #define PBR_FUNCTION_INCLUDE

    #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
    #include "Assets/Common/ShaderLibrary/Surface/ShadingModel.hlsl"

    ///////// Roughness ////////////////////
    void UnityRoughness(half smoothness,inout half perceptualRoughness,inout half roughness,inout half roughness2)
    {
        perceptualRoughness = 1 - smoothness;
        roughness = max(perceptualRoughness * perceptualRoughness, M_HALF_MIN_SQRT);
        roughness2 = max(roughness * roughness, M_HALF_MIN);
    }

    void FilamentRoughness(half smoothness,inout half perceptualRoughness,inout half roughness,inout half roughness2)
    {
        perceptualRoughness = clamp(1 - smoothness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
        roughness = perceptualRoughness * perceptualRoughness;
        roughness2 = roughness * roughness;
    }

    //////////// Specular Occlusion ////////////////
    void SpecularOcclusionData(half3 R,half3 BN,half perceptualRoughness,half occlusion,half specularOcclusionStrength,inout half3 albedo,inout half metallic)
    {
        // Base signal depends on occlusion and dot product between reflection and bent normal vector
        half occlusionAmount = max(0, dot(R, BN));
        half reflOcclusion = occlusion - (1 - occlusionAmount);
        // Scale with roughness. This is what "sharpens" glossy reflections
        reflOcclusion = saturate(reflOcclusion / perceptualRoughness);
        // Fade between roughness-modulated occlusion and "regular" occlusion based on surface roughness
        // This is done because the roughness-modulated signal doesn't represent rough surfaces very well
        reflOcclusion = lerp(reflOcclusion, lerp(occlusionAmount, 1, occlusion), perceptualRoughness);
        // Scale by color and return
        half so_factor = max(lerp(1, reflOcclusion, specularOcclusionStrength),0);

        albedo = lerp(1,pow(so_factor,(1 - perceptualRoughness) * 2),metallic * metallic) * albedo;
        metallic = pow(so_factor,0.5) * metallic;
    }
    
    /////////// F0 ///////////////////
    float ComputeDielectricF0(float reflectance) {
        return 0.16 * reflectance * reflectance;
    }

    float3 ComputeF0(float3 baseColor, float metallic, float reflectance) {
        return baseColor.rgb * metallic + (reflectance * (1.0 - metallic));
    }

    void DetailLayer(float2 uv,inout half3 albedo,inout half3 normalTS,inout half smoothness)
    {
        half4 detail_id = SAMPLE_TEXTURE2D(_Detail_ID, sampler_LinearRepeat, uv);
        
        half3 detail_scale = half3(_DetailAlbedoScale_1,_DetailNormalScale_1,_DetailSmoothnessScale_1) * detail_id.r
        + half3(_DetailAlbedoScale_2,_DetailNormalScale_2,_DetailSmoothnessScale_2) * detail_id.g
        + half3(_DetailAlbedoScale_3,_DetailNormalScale_3,_DetailSmoothnessScale_3) * detail_id.b
        + half3(_DetailAlbedoScale_4,_DetailNormalScale_4,_DetailSmoothnessScale_4) * detail_id.a;

        half3 detail_color = _DetailAlbedoColor_1.rgb * detail_id.r
        + _DetailAlbedoColor_2.rgb * detail_id.g
        + _DetailAlbedoColor_3.rgb * detail_id.b
        + _DetailAlbedoColor_4.rgb * detail_id.a;

        half4 detail_map1 = SAMPLE_TEXTURE2D(_DetailMap_1, sampler_LinearRepeat, uv * _DetailMap_Tilling_1.xx);
        half4 detail_map2 = SAMPLE_TEXTURE2D(_DetailMap_2, sampler_LinearRepeat, uv * _DetailMap_Tilling_2.xx);
        half4 detail_map3 = SAMPLE_TEXTURE2D(_DetailMap_3, sampler_LinearRepeat, uv * _DetailMap_Tilling_3.xx);
        half4 detail_map4 = SAMPLE_TEXTURE2D(_DetailMap_4, sampler_LinearRepeat, uv * _DetailMap_Tilling_4.xx);

        half4 final_detail = lerp( lerp( lerp( detail_map1 , detail_map2 , detail_id.g) , detail_map3 , detail_id.b) , detail_map4 , detail_id.a);

        half3 detail_normal = normalize(UnpackNormal(half4(final_detail.w, final_detail.y, 1, 1.0)));

        half3 normal_adjust = NormalStrength(detail_normal, detail_scale.y);

        half detail_smoothness = final_detail.z * 2 - 1;

        albedo = Remap((final_detail.x * 2 - 1) * detail_scale.x, half2 (-1, 1), half2 (0, 1)) * albedo * 2  + detail_color;
        albedo = clamp(albedo, 0.05, 0.95);
        // albedo = lerp(_Albedo, (final_detail.x - 0.5)>0?1:-1, _Detail_Scale.x * abs(final_detail.x *2 - 1));

        normalTS = normalize(NormalBlend(normalTS, normal_adjust));
        smoothness = clamp(smoothness + detail_smoothness * detail_scale.z, 0, 0.95);
    }


    ////////////// Init Start ////////////////////////
    inline void InitSurfaceData(float2 uv,out SurfaceData_SGame outSurfaceData)
    {
        outSurfaceData = (SurfaceData_SGame)0;

        // base map
        half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_LinearRepeat, uv);

        //alpha
        outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;

        #if defined(_ALPHATEST_ON)
            clip(outSurfaceData.alpha - _Cutoff);
        #endif

        outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
        outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

        //specGloss
        half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_LinearRepeat, uv);
        outSurfaceData.metallic = specGloss.r * _Metallic;
        outSurfaceData.smoothness = specGloss.b * _Smoothness * 0.95;

        outSurfaceData.reflectance = _Reflectance;

        //ao
        outSurfaceData.occlusion = LerpWhiteTo(specGloss.g, _OcclusionStrength);

        //emission
        #if defined(_EMISSION_ON)
            outSurfaceData.emission = _EmissionColor.rgb * SAMPLE_TEXTURE2D(_EmissionMap, sampler_LinearRepeat, uv).r * outSurfaceData.albedo;
        #endif

        #if defined(_ANISOTROPY_ON) 
            outSurfaceData.anisotropy = _Anisotropy;
        #endif

        //clearcloat
        #if defined(_CLEARCOAT_ON)
            half clearCoatMap = SAMPLE_TEXTURE2D(_ClearCoatMap,sampler_LinearRepeat,uv).r;
            outSurfaceData.clearCoatMask = _ClearCoatMask * clearCoatMap;
            outSurfaceData.clearCoatSmoothness = _ClearCoatSmoothness;
        #endif

        #if defined(_IRIDENSCENE_ON)
            outSurfaceData.iridescence = _Iridescence * SAMPLE_TEXTURE2D(_IridescenceMask, sampler_LinearRepeat, uv).r;
        #endif

        #if defined(_LASER_ON)
            outSurfaceData.laser = SAMPLE_TEXTURE2D(_LaserMap, sampler_LinearRepeat, uv).r;
        #endif
    }

    void InitInputData(Varyings_SGame input,inout SurfaceData_SGame surfaceData, out InputData_SGame inputData)
    {
        inputData = (InputData_SGame)0;
        inputData.positionWS = input.positionWS;
        inputData.positionCS = input.positionCS;

        // Normal, View
        inputData.viewDirWS = normalize(UnPackViewDir(input.tangentWS,input.bitangentWS,input.normalWS));
        inputData.TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);

        half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_LinearRepeat, input.uv));

        #if defined(_CLEARCOAT_ON)	
            inputData.clearCoatNormalWS = normalize(mul(normalTS, inputData.TBN));
        #endif
        
        // Detail
        #if defined(_DETAILMAP_ON)
            DetailLayer(input.uv,surfaceData.albedo,normalTS,surfaceData.smoothness);
        #endif

        inputData.normalWS = normalize(mul(normalTS,inputData.TBN));
        
        // Specular Occlusion
        #if defined(_SPECULAROCCLUSION_ON)
            half3 bent_normal_data = UnpackNormal(SAMPLE_TEXTURE2D(_BentNormalMap,sampler_LinearRepeat,input.uv));
            inputData.bentNormalWS = normalize(mul(bent_normal_data,inputData.TBN));
        #endif

        // Normal Filter
        #if defined(MODULATE_SMOOTHNESS)
            ModulateSmoothnessByNormal(surfaceData.smoothness, inputData.normalWS);
        #endif
        
        // Clear Coat
        #if defined(_CLEARCOAT_ON)	
            surfaceData.smoothness = clamp(lerp(surfaceData.smoothness,surfaceData.smoothness * _ClearCoatDownSmoothness,surfaceData.clearCoatMask),0,0.95);
            inputData.clearCoatNormalWS = lerp(inputData.clearCoatNormalWS,inputData.normalWS,_ClearCoat_Detail_Factor);
        #endif

        // Irradiance
        #if defined(LIGHTMAP_ON)
            float4 encodedIrradiance = SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap,input.uv.zw);
            inputData.Irradiance = DecodeLightmap(encodedIrradiance, float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h));
            //#if defined(DIRLIGHTMAP_COMBINED)
            float4 direction = SAMPLE_TEXTURE2D(unity_LightmapInd,samplerunity_Lightmap,input.uv.zw);
            half3 LightDir = direction.xyz * 2.0f - 1.0f;
            half halfLambert = dot(inputData.normalWS,LightDir) * 0.5 + 0.5;
            inputData.Irradiance = inputData.Irradiance * halfLambert / max(1e-4,direction.w);

            // half BlinnPhong = pow(saturate(dot(inputData.normalWS,normalize(LightDir + inputData.viewDirWS))),30);
            // inputData.Irradiance += inputData.Irradiance * BlinnPhong;

            //#endif
        #else
            inputData.Irradiance = SampleSH(inputData.normalWS);
            // inputData.Irradiance = input.vertexSH;   // Low
        #endif
    }

    void InitBRDFData(InputData_SGame inputData,inout SurfaceData_SGame surfaceData,out BRDFData_PBR brdfData) {

        brdfData = (BRDFData_PBR)0;

        // Unity Handle
        UnityRoughness(surfaceData.smoothness,brdfData.perceptualRoughness,brdfData.roughness,brdfData.roughness2);

        // Filament Handle
        // FilamentRoughness(surfaceData.smoothness,brdfData.perceptualRoughness,brdfData.roughness,brdfData.roughness2);

        brdfData.normalizationTerm = brdfData.roughness * 4.0h + 2.0h;
        brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;

        // Specular Occlusion
        #if defined(_SPECULAROCCLUSION_ON)
            half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
            SpecularOcclusionData(reflectVector,inputData.bentNormalWS,brdfData.perceptualRoughness,surfaceData.occlusion,_SpecularOcclusionStrength,surfaceData.albedo,surfaceData.metallic);
        #endif

        half oneMinusDielectricSpec = kDieletricSpec.a;
        half oneMinusReflectivity = oneMinusDielectricSpec - surfaceData.metallic * oneMinusDielectricSpec;

        brdfData.diffuse = surfaceData.albedo * oneMinusReflectivity;

        // brdfData.specular = lerp(kDieletricSpec.rgb, max(0, surfaceData.albedo), surfaceData.metallic);
        float reflectance = ComputeDielectricF0(surfaceData.reflectance);
        brdfData.specular = ComputeF0( surfaceData.albedo, surfaceData.metallic, reflectance);

        brdfData.grazingTerm = saturate(surfaceData.smoothness + 1 - oneMinusReflectivity);

        brdfData.envBRDF = EnvBRDFApproxLazarov(brdfData.perceptualRoughness,saturate(dot(inputData.normalWS,inputData.viewDirWS)));

        // Iridescence
        #if defined(_IRIDENSCENE_ON)
            half NoV = saturate(dot(inputData.normalWS, inputData.viewDirWS));
            half topIor = lerp(1.0f, 1.5f, surfaceData.clearCoatMask);
            half viewAngle = lerp(NoV,sqrt(1.0 + Sq(1.0 / topIor) * (Sq(dot(inputData.normalWS, inputData.viewDirWS)) - 1.0)),surfaceData.clearCoatMask);
            
            half3 Iridescence = F_Iridescence(topIor, viewAngle, _IridescenceThickness, brdfData.specular);
            brdfData.specular = lerp(brdfData.specular,Iridescence,surfaceData.iridescence);
        #endif

        #if defined(_CLEARCOAT_ON)
            UnityRoughness(surfaceData.clearCoatSmoothness,brdfData.clearCoatPerceptualRoughness,brdfData.clearCoatRoughness,brdfData.clearCoatRoughness2);
            brdfData.clearCoatNormalizationTerm = brdfData.clearCoatRoughness * 4.0h + 2.0h;  
            brdfData.clearCoatRoughness2MinusOne = brdfData.clearCoatRoughness2 - 1.0h;
        #endif
    }

    void PrepareData(Varyings_SGame input,out InputData_SGame inputData,out SurfaceData_SGame surfaceData,out BRDFData_PBR brdfData,out Light light)
    {
        InitSurfaceData(input.uv, surfaceData);
        InitInputData(input, surfaceData, inputData);
        InitBRDFData(inputData,surfaceData, brdfData);
        light = GetMainLight_SGame(inputData.positionWS,input.shadowCoord);
    }
    /////////////// Init End ////////////////////////////

    void ApplyOtherColor(SurfaceData_SGame surfaceData,InputData_SGame inputData,BRDFData_PBR brdfData,inout half3 color)
    {
        #if defined(_EMISSION_ON)
            color += surfaceData.emission;
        #endif

        #if defined(_ADDITIONAL_LIGHTS_VERTEX)
            color += inputData.vertexLighting * brdfData.diffuse;
        #endif

        // color = MixFog(color, inputData.fogCoord);
    }

    half3 Radiance(Light light,half3 N)
    {
        half NoL = dot(light.direction , N);
        half shadow = light.distanceAttenuation * light.shadowAttenuation;

        #if defined(_SUBSURFACE_ON)
            half3 radiance = light.color * shadow * SubsurfaceScatter_kShading(NoL,_SubsurfaceColor);
        #else
            half3 radiance = light.color * shadow * saturate(NoL);
        #endif

        return radiance;
    }


    

#endif //PBR_FUNCTION_INCLUDE