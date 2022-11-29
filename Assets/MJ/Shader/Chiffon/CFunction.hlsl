#ifndef C_FUNCTION_INCLUDE
#define C_FUNCTION_INCLUDE

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
        half3 radiance = light.color * shadow * saturate(NoL);
        return radiance;
    }

    //Sparkle
    float4 checkBoardFunction(float3 vec)
    {
        float2 checkBoardAdd = vec.yy + vec.xz;
        float2 checkBoardMul = vec.yy * vec.xz;

        float4 checkBoardCombine;
        checkBoardCombine.yw = checkBoardAdd * checkBoardMul;
        checkBoardCombine.xz = checkBoardMul * 0.4 + checkBoardAdd * 0.6;
        checkBoardCombine = checkBoardCombine * 2611.14087 + 5.381;
        checkBoardCombine = frac(checkBoardCombine);
        checkBoardCombine = checkBoardCombine * 63.7809982;
        checkBoardCombine = frac(checkBoardCombine);

        return checkBoardCombine;
    }
    // SparkleGGX
    // 通过sparkleGGXVec 修正ndotH的ggx算法
    // 只是返回一个强度
    half4 SparkleGGX(half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half roughness, half4 sparkleGGXVec)
    {
        float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));
        float NdotH = dot(normalWS, halfDir);
        // 
        float4 NdotHVec = sparkleGGXVec + NdotH;
        NdotHVec = frac(NdotHVec);// 取小数
        NdotHVec = NdotHVec - 0.5;
        NdotHVec = abs(NdotHVec) + abs(NdotHVec);

        float a2 = roughness * roughness;
        a2 = max(a2, 0.1);
        float a4 = a2 * a2;
        float4 d = NdotHVec * (a4 - 1.0) * NdotHVec + 1.0;
        d = d * d;
        half4 D = a4 / (d * PI);
        D = min(D, 100.0);

        return D;
    }
    

#endif //PBRC_FUNCTION_INCLUDE