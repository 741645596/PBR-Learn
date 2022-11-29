#ifndef SGAME_PBRLIGHTING_INCLUDE
    #define SGAME_PBRLIGHTING_INCLUDE

    #include "./FeiYunTouziPBRForward.hlsl"
    #include "Assets/Common/ShaderLibrary/Common/GlobalIllumination.hlsl"


    void InitInitializeBRDFData(InputData_PBR inputData,inout SurfaceData_PBR surfaceData,out BRDFData_PBR brdfData) {

        brdfData = (BRDFData_PBR)0;

        // Unity Handle
        brdfData.perceptualRoughness = 1 - surfaceData.smoothness;
        brdfData.roughness = max(brdfData.perceptualRoughness* brdfData.perceptualRoughness, M_HALF_MIN_SQRT);
        brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, M_HALF_MIN);

        // Filament Handle
        //brdfData.perceptualRoughness = clamp(1 - surfaceData.smoothness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
        //brdfData.roughness = brdfData.perceptualRoughness * brdfData.perceptualRoughness;
        //brdfData.roughness2 = brdfData.roughness * brdfData.roughness;

        brdfData.normalizationTerm = brdfData.roughness * 4.0h + 2.0h;
        brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;

        // Specular Occlusion
        #if defined(_SPECULAROCCLUSION_ON)
            half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
            // Base signal depends on occlusion and dot product between reflection and bent normal vector
            half occlusionAmount = max(0, dot(reflectVector, inputData.bentNormalWS));
            half reflOcclusion = surfaceData.occlusion - (1 - occlusionAmount);
            // Scale with roughness. This is what "sharpens" glossy reflections
            reflOcclusion = saturate(reflOcclusion / brdfData.perceptualRoughness);
            // Fade between roughness-modulated occlusion and "regular" occlusion based on surface roughness
            // This is done because the roughness-modulated signal doesn't represent rough surfaces very well
            reflOcclusion = lerp(reflOcclusion, lerp(occlusionAmount, 1, surfaceData.occlusion), brdfData.perceptualRoughness);
            // Scale by color and return
            half so_factor = max(lerp(1, reflOcclusion, _SpecularOcclusionStrength),0);

            surfaceData.albedo = lerp(1,pow(so_factor,_Smoothness * 2),surfaceData.metallic * surfaceData.metallic) * surfaceData.albedo;
            surfaceData.metallic = pow(so_factor,0.5) * surfaceData.metallic;
        #endif

        half oneMinusDielectricSpec = kDieletricSpec.a;
        half oneMinusReflectivity = oneMinusDielectricSpec - surfaceData.metallic * oneMinusDielectricSpec;

        brdfData.diffuse = surfaceData.albedo * oneMinusReflectivity;
        brdfData.specular = lerp(kDieletricSpec.rgb, max(0, surfaceData.albedo), surfaceData.metallic);

        // Iridescence
        // #if defined(_IRIDESCENCE_ON)
        //     half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirWS));
        //     half topIor = lerp(1.0f, 1.5f, surfaceData.clearCoatMask);
        //     half viewAngle = lerp(NdotV,sqrt(1.0 + Sq(1.0 / topIor) * (Sq(dot(inputData.normalWS, inputData.viewDirWS)) - 1.0)),surfaceData.clearCoatMask);
        
        //     half3 Iridescence = F_Iridescence(topIor, viewAngle, surfaceData.iridescence.y, brdfData.specular);
        //     brdfData.specular = lerp(brdfData.specular,Iridescence,surfaceData.iridescence.x);
        // #endif


        #if defined(_CLEARCOAT_ON)
            // Unity Handle
            brdfData.clearCoatPerceptualRoughness = 1 - surfaceData.clearCoatSmoothness;
            brdfData.clearCoatRoughness = max(brdfData.clearCoatPerceptualRoughness * brdfData.clearCoatPerceptualRoughness, HALF_MIN_SQRT);
            brdfData.clearCoatRoughness2 = max(brdfData.clearCoatRoughness * brdfData.clearCoatRoughness, HALF_MIN);
            
            // Filament Handle
            // brdfData.clearCoatPerceptualRoughness = clamp(1 - surfaceData.clearCoatSmoothness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
            // brdfData.clearCoatRoughness = brdfData.clearCoatPerceptualRoughness * brdfData.clearCoatPerceptualRoughness;
            // brdfData.clearCoatRoughness2 = brdfData.clearCoatRoughness * brdfData.clearCoatRoughness;
            
            brdfData.clearCoatNormalizationTerm = brdfData.clearCoatRoughness * 4.0h + 2.0h;  
            brdfData.clearCoatRoughness2MinusOne = brdfData.clearCoatRoughness2 - 1.0h;
        #endif

    }


    half3 GI(BRDFData_PBR brdfData, InputData_PBR inputData, SurfaceData_PBR surfaceData)
    {
        half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
        half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirWS));

        half3 c = (inputData.bakedGI * brdfData.diffuse + UEIBL(reflectVector,inputData.positionWS, brdfData.roughness,brdfData.specular,NdotV,1));

        // clearCoat
        #if defined(_CLEARCOAT_ON)

            half NoV_ClearCoat = saturate(abs(dot(inputData.clearCoatNormalWS, inputData.viewDirWS)) + 1e-5);
            half3 reflectVector_ClearCoat = reflect(-inputData.viewDirWS, inputData.clearCoatNormalWS);

            // Custom Indirect Clear Coat Cube Map
            ClearCloatIllumination(_ClearCoatCubeMap,brdfData.clearCoatRoughness,surfaceData.clearCoatMask,inputData.positionWS,NoV_ClearCoat,reflectVector_ClearCoat,
            surfaceData.specular,surfaceData.occlusion,c);
        #endif
        return c * surfaceData.occlusion;
    }


    half3 SGamePhysicallyBased(SurfaceData_PBR surfaceData,BRDFData_PBR brdfData, Light light, InputData_PBR inputData)
    {
        half shadowAttenuation = light.shadowAttenuation;
        shadowAttenuation = lerp(1, shadowAttenuation,surfaceData.shadowStrenght);

        half NdotV = saturate(dot(inputData.normalWS,inputData.viewDirWS));

        half NdotL = saturate(dot(inputData.normalWS,light.direction));

        half3 radiance = light.color * (light.distanceAttenuation * shadowAttenuation * NdotL);

        // EnergyCompensation
        

        half3 Distort_L = light.direction;
        #if defined(_CLEARCOAT_ON)
            Distort_L = normalize(light.direction + (light.direction - inputData.viewDirWS) * surfaceData.clearCoatMask);
        #endif

        half3 brdf = brdfData.diffuse 
        + brdfData.specular
        * (UnitySpecular(inputData.normalWS, Distort_L, inputData.viewDirWS,brdfData.roughness2MinusOne,brdfData.roughness2,brdfData.normalizationTerm));

        // clearCoat
        #if defined(_CLEARCOAT_ON)
            // half NoV_ClearCoat = saturate(abs(dot(inputData.clearCoatNormalWS, inputData.viewDirWS)) + 1e-5);
            half3 clearCoatLighting = kDieletricSpec.r * BRDFSpecular(inputData.clearCoatNormalWS,light.direction, inputData.viewDirWS,brdfData.clearCoatRoughness2MinusOne,brdfData.clearCoatRoughness2,brdfData.clearCoatNormalizationTerm);
            half coatFresnel = kDieletricSpec.x + kDieletricSpec.a * Pow4(1.0 - NdotV);
            brdf = brdf * (1.0 - surfaceData.clearCoatMask * coatFresnel) + clearCoatLighting * surfaceData.clearCoatMask;
        #endif


        #if defined(_IRIDESCENCE_ON)

            half half_NoL = (dot(inputData.normalWS,light.direction) * 0.5 + 0.5);
            float BdotV = asin(dot(inputData.TBN[1],inputData.viewDirWS));
            float TdotV = asin(dot(-inputData.TBN[0], inputData.viewDirWS));
            
            half BoV_lerp_ToV = lerp((lerp(BdotV,TdotV,_Anisotropy)),abs(BdotV + TdotV + (NdotV)),_UniversalLaser);
            // half BoV_lerp_ToV = abs(lerp(BdotV,TdotV,_Anisotropy));
            // BoV_lerp_ToV = abs(BdotV) + abs(-TdotV);
            // BoV_lerp_ToV = abs(BdotV + TdotV + NdotV);
            half filmThickness = BoV_lerp_ToV * _FilmThickness - _FilmIOR;
            float3 film_color = cos(filmThickness * float3(24.849998, 30.450001, 35.0));
            film_color = film_color * -0.5 + float3(0.5, 0.5, 0.5);
            film_color = pow(film_color, 2);
            // film_color = lerp(film_color,0.5,filmThickness);
            // film_color = pow(film_color, 2);
            film_color = lerp( film_color, smoothstep(LaserSmoothstepValue_1, LaserSmoothstepValue_2, film_color), 1-pow(NdotV,6));
            // film_color = min(max(film_color, 0), 100);
            film_color = saturate(film_color )* light.color * half_NoL;
            // film_color = pow(saturate(film_color),2);

            film_color += brdf * radiance * _FilmBrdfIntensity;
            
            return film_color * _LaserColor * brdf;
        #endif

        return brdf * radiance ;
    }

    half4 SGameFragmentPBR(InputData_PBR inputData, SurfaceData_PBR surfaceData,Varyings_PBR input)
    {
        BRDFData_PBR brdfData;
        InitInitializeBRDFData(inputData,surfaceData, brdfData);

        Light mainLight = GetMainLight_SGame(inputData.positionWS,inputData.shadowCoord);

        #if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
            inputData.bakedGI = SubtractDirectMainLightFromLightmap(mainLight, inputData.normalWS, inputData.bakedGI);
        #endif

        // Indirect Color
        half3 color = GI(brdfData, inputData,surfaceData);
        #if defined(_IRIDESCENCE_ON)
            // color *= 1;//_FilmBrdfIntensity;
        #endif

        // Direct Color
        color += SGamePhysicallyBased(surfaceData,brdfData,mainLight,inputData);

        // Additional Color
        #ifdef _ADDITIONAL_LIGHTS
            uint pixelLightCount = GetAdditionalLightsCount();
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS, float4(1,1,1,1));
                color += SGamePhysicallyBased(surfaceData,brdfData,light,inputData);
            }
        #endif

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
            color += inputData.vertexLighting * brdfData.diffuse;
        #endif

        #if defined(_EMISSION_ON)
            color += surfaceData.emission;
        #endif

        return half4(color, surfaceData.alpha);
    }

    half4 PBRFragment(Varyings_PBR input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);

        SurfaceData_PBR surfaceData;

        InitSurfaceData(input.uv, surfaceData);
        
        InputData_PBR inputData;
        InitInputData(input, surfaceData, inputData);

        half4 color = SGameFragmentPBR(inputData,surfaceData,input);
        
        color.rgb = MixFogColorPBR(color.rgb,  unity_FogColor.rgb, inputData.fogCoord);

        // return clamp(color,0,8);
        return color;
    }

#endif  //SGAME_PBRLIGHTING_INCLUDE
