#ifndef SGAME_PBRLIGHTING_INCLUDE
    #define SGAME_PBRLIGHTING_INCLUDE

    #include "SGamePBRInput.hlsl"
    #include "PBRFunction.hlsl"

    void SGamePhysicallyBased(SurfaceData_SGame surfaceData,BRDFData_PBR brdfData, Light light, InputData_SGame inputData,half3 energyCompensation,inout half3 DirectDiffuse,inout half3 DirectSpecular)
    {
        half NoV = saturate(dot(inputData.normalWS,inputData.viewDirWS));
        half NoL = dot(inputData.normalWS,light.direction);

        half3 Distort_L = light.direction;

        #if defined(_CLEARCOAT_ON)
            Distort_L = normalize(light.direction + (light.direction - inputData.viewDirWS) * surfaceData.clearCoatMask);
        #endif

        #if !defined(_ANISOTROPY_ON)
            half3 SpecularTerm = UnitySpecular(inputData.normalWS, Distort_L, inputData.viewDirWS,brdfData.roughness2MinusOne,brdfData.roughness2,brdfData.normalizationTerm) 
            * energyCompensation;
        #else
            half3 SpecularTerm = UE4_Aniso(brdfData.perceptualRoughness,brdfData.roughness,surfaceData.anisotropy, inputData.normalWS,inputData.viewDirWS, Distort_L,inputData.TBN[0],inputData.TBN[1],brdfData.specular) * PI;
        #endif

        DirectDiffuse = brdfData.diffuse;
        DirectSpecular = brdfData.specular * SpecularTerm;
    }

    void DirectLighting(SurfaceData_SGame surfaceData,BRDFData_PBR brdfData, Light mainLight, InputData_SGame inputData,out half3 DirectDiffuse,out half3 DirectSpecular)
    {
        // Energy Compensation
        half multiscatterDFGX = brdfData.envBRDF.x + brdfData.envBRDF.y;
        half3 EnergyCompensation = 1.0 + brdfData.specular * (rcp(multiscatterDFGX) - 1.0);

        uint meshRenderingLayers = GetMeshRenderingLightLayer();
        if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
        {
            SGamePhysicallyBased(surfaceData,brdfData,mainLight, inputData,EnergyCompensation,DirectDiffuse,DirectSpecular);
        }
        
        // clearCoat
        #if defined(_CLEARCOAT_ON)
            half NoV_ClearCoat = saturate(dot(inputData.clearCoatNormalWS, inputData.viewDirWS));
            half3 clearCoatLighting = kDieletricSpec.r * UnitySpecular(inputData.clearCoatNormalWS,mainLight.direction, inputData.viewDirWS,brdfData.clearCoatRoughness2MinusOne,brdfData.clearCoatRoughness2,brdfData.clearCoatNormalizationTerm);
            half coatFresnel = kDieletricSpec.x + kDieletricSpec.a * Pow4(1.0 - NoV_ClearCoat);
            DirectSpecular = DirectSpecular * (1.0 - surfaceData.clearCoatMask * coatFresnel) + clearCoatLighting * surfaceData.clearCoatMask;
        #endif

        // Radiance
        half3 MainRadiance = Radiance(mainLight,inputData.normalWS);

        DirectDiffuse *= MainRadiance;
        DirectSpecular *= MainRadiance;

        #if defined(_ADDITIONAL_LIGHTS)
            uint pixelLightCount = GetAdditionalLightsCount();
            half3 AdditionalDiffuse,AdditionalSpecular;
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS, unity_ProbesOcclusion /*float4(1, 1, 1, 1) */);
                half3 AdditionalRadiance = Radiance(light,inputData.normalWS);
                SGamePhysicallyBased(surfaceData,brdfData,light, inputData,EnergyCompensation,AdditionalDiffuse,AdditionalSpecular);
                DirectDiffuse += AdditionalDiffuse * AdditionalRadiance;
                DirectSpecular += AdditionalSpecular * AdditionalRadiance;
            }
        #endif

        #if defined(_LASER_ON)
            half3 LaserColor = HightLightLaser(inputData.viewDirWS, inputData.normalWS,inputData.TBN[0],inputData.TBN[1],_LaserAnisotropy,_LaserUniversal,_LaserThickness,_LaserSmoothstepValue_1,_LaserSmoothstepValue_2,_LaserBrdfIntensity,_LaserIOR,DirectDiffuse,DirectSpecular,MainRadiance,_LaserColor,mainLight);
            LaserColor = lerp(1,LaserColor,surfaceData.laser);
            DirectDiffuse *= LaserColor;
            DirectSpecular *= LaserColor;
        #endif
    }

    void IndirectLighting(BRDFData_PBR brdfData, InputData_SGame inputData, SurfaceData_SGame surfaceData,Light mainLight,out half3 indirectDiffuse,out half3 IndirectSpecular)
    {
        half3 Irradiance = inputData.Irradiance;
        // #if defined(LIGHTMAP_ON)
        //     Irradiance = SubtractDirectMainLightFromLightmap(mainLight, inputData.normalWS, Irradiance);
        // #endif
        indirectDiffuse = Irradiance * brdfData.diffuse;

        half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
        half NoV = saturate(dot(inputData.normalWS, inputData.viewDirWS));

        #if !defined(_ANISOTROPY_ON)
            IndirectSpecular = UEIBL(reflectVector,inputData.positionWS, brdfData.perceptualRoughness,brdfData.specular,NoV,surfaceData.occlusion,brdfData.envBRDF);
            // IndirectSpecular = UnityIBL(brdfData.specular,brdfData.grazingTerm,brdfData.perceptualRoughness,brdfData.roughness2,inputData.positionWS,NoV,reflectVector,surfaceData.occlusion);
        #else
            IndirectSpecular = AnisotropyIBL(inputData.positionWS,_Anisotropy,inputData.normalWS,inputData.viewDirWS,inputData.TBN[0],inputData.TBN[1],brdfData.perceptualRoughness,brdfData.specular,surfaceData.occlusion,NoV);
        #endif

        // clearCoat
        #if defined(_CLEARCOAT_ON)
            half NoV_ClearCoat = saturate(dot(inputData.clearCoatNormalWS, inputData.viewDirWS));
            half3 reflectVector_ClearCoat = reflect(-inputData.viewDirWS, inputData.clearCoatNormalWS);

            // Custom Indirect Clear Coat Cube Map
            ClearCloatIllumination(_ClearCoatCubeMap,_ClearCoatCubeMap_HDR,brdfData.clearCoatPerceptualRoughness,surfaceData.clearCoatMask,inputData.positionWS,NoV_ClearCoat,reflectVector_ClearCoat,
            surfaceData.specular,surfaceData.occlusion,IndirectSpecular);
        #endif
        
        indirectDiffuse *= surfaceData.occlusion;
        IndirectSpecular *= surfaceData.occlusion;
    }

    ////////// Core Function Start //////////////
    half4 PBRFragment(Varyings_SGame input) : SV_Target
    {
        SurfaceData_SGame surfaceData;
        InputData_SGame inputData;
        BRDFData_PBR brdfData;
        Light MainLight;

        PrepareData(input,inputData,surfaceData,brdfData,MainLight);

        // Direct Color / Additional Color
        half3 DirectDiffuse,DirectSpecular;
        DirectLighting(surfaceData,brdfData,MainLight,inputData,DirectDiffuse,DirectSpecular);

        // Indirect Color
        half3 IndirectDiffuse,IndirectSpecular;
        IndirectLighting(brdfData, inputData,surfaceData,MainLight,IndirectDiffuse,IndirectSpecular);
        
        // Combine
        half3 color = DirectDiffuse + DirectSpecular + IndirectDiffuse + IndirectSpecular;
        
        // Emission / Fog Color / Additional Vertex Color
        ApplyOtherColor(surfaceData,inputData,brdfData,color);

        return half4(color,surfaceData.alpha);
    }
    ////////// Core Function End //////////////

#endif  //SGAME_PBRLIGHTING_NEW_INCLUDE
