#ifndef FABRIC_LIGHTING_INCLUDE
    #define FABRIC_LIGHTING_INCLUDE

    #include "FabricForward.hlsl"
    #include "FabricFunction.hlsl"
    #include "Assets/Common/ShaderLibrary/Common/GlobalIllumination.hlsl"

    struct BSDFData_Fabric
    {
        half3 diffuseColor;
        half3 fresnel0;
        half  perceptualRoughness;
        half3 transmittance;
        half  roughnessT;
        half  roughnessB;
        half  anisotropy;
    };

    struct PreLightData_Fabric
    {
        half3 specularFGD;              // Store preintegrated BSDF for both specular and diffuse
        half  diffuseFGD;
    };

    PreLightData_Fabric GetPreLightData_Fabric(InputData_SGame inputData, UnityTexture2D FGD, inout BSDFData_Fabric bsdfData)
    {
        PreLightData_Fabric preLightData = (PreLightData_Fabric)0;

        half3 V = inputData.viewDirWS;
        half3 N = inputData.normalWS;

        half clampNdotV = ClampNdotV(dot(N, V));

        half3 iblN;
        half reflectivity;

        // Reminder: This is a static if resolve at compile time
        #if defined(_SILK_ON) // Silk
            {
                GetPreIntegratedFGDGGXAndDisneyDiffuse(FGD, clampNdotV, bsdfData.perceptualRoughness, bsdfData.fresnel0, preLightData.specularFGD, preLightData.diffuseFGD, reflectivity);
                // perceptualRoughness is use as input and output here
                GetGGXAnisotropicModifiedNormalAndRoughness_SGame(inputData.TBN[1], inputData.TBN[0], N, V, bsdfData.anisotropy, bsdfData.perceptualRoughness, iblN, bsdfData.perceptualRoughness);

            }
        #else //Cotton Wool
            iblN = N;

            GetPreIntegratedFGDCharlieAndFabricLambert(FGD, clampNdotV, bsdfData.perceptualRoughness, bsdfData.fresnel0, preLightData.specularFGD, preLightData.diffuseFGD, reflectivity);
        #endif
        
        return preLightData;
    }

    // float3 diffR; // Diffuse  reflection   (T -> MS -> T, same sides)
    // float3 specR; // Specular reflection   (R, RR, TRT, etc)
    // float3 diffT; // Diffuse  transmission (rough T or TT, opposite sides)
    // float3 specT; // Specular transmission (T, TT, TRRT, etc)

    void SGame_FabricLighting(BSDFData_Fabric bsdfData , InputData_SGame inputData, Light light, PreLightData_Fabric preLightData, out half3 diffuse, out half3 specular)
    {
        half3 L = light.direction;
        half3 V = inputData.viewDirWS;
        half3 N = inputData.normalWS;

        half3 lightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        
        // -----------------------
        half NdotV = dot(N, V);
        half clampNdotV = ClampNdotV(NdotV);
        half NdotL = dot(N, L);
        half clampedNdotV = ClampNdotV(NdotV);
        half clampedNdotL = saturate(NdotL);
        half flippedNdotL = ComputeWrappedDiffuseLighting(-NdotL, TRANSMISSION_WRAP_LIGHT);

        half LdotV, NdotH, LdotH, invLenLV;
        GetBSDFAngle(V, L, NdotL, NdotV, LdotV, NdotH, LdotH, invLenLV);

        half  diffTerm;
        half3 specTerm;

        #if !defined(_SILK_ON)
            specTerm = Cloth_Specular(NdotL,clampedNdotV, NdotH,bsdfData.roughnessT,bsdfData.fresnel0);
            
            // diffTerm = Fd_Fabric(bsdfData.roughnessT) ; // FabricLambert Orginal HDRP code
            diffTerm = FabricLambertNoPI(bsdfData.roughnessT) ; //hack : No INV_PI for URP to match the HDRP result
            
        #else // MATERIALFEATUREFLAGS_FABRIC_SILK
            // For silk we just use a tinted anisotropy
            half3 H = (L + V) * invLenLV;

            // For anisotropy we must not saturate these values
            half TdotH = dot(inputData.TBN[0], H);
            half TdotL = dot(inputData.TBN[0], L);
            half BdotH = dot(inputData.TBN[1], H);
            half BdotL = dot(inputData.TBN[1], L);
            half TdotV = dot(inputData.TBN[0], V);
            half BdotV = dot(inputData.TBN[1], V);
            
            half partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, clampNdotV, bsdfData.roughnessT, bsdfData.roughnessB);
            specTerm = Silk_Specular(TdotH, TdotL, BdotH, BdotL, NdotL, LdotH, NdotH, clampedNdotV, bsdfData.fresnel0,bsdfData.roughnessT,bsdfData.roughnessB,partLambdaV);
            
            // Use abs NdotL to evaluate diffuse term also for transmission
            // TODO: See with Evgenii about the clampedNdotV here. This is what we use before the refactor
            // but now maybe we want to revisit it for transmission

            // diffTerm = DisneyDiffuse(clampedNdotV, abs(NdotL), LdotV, bsdfData.perceptualRoughness); // Orginal HDRP code

            // Burt:We don't need DisneyDiffuse,Lambert is already enough for phone
            // diffTerm = DisneyDiffuseNoPI(clampedNdotV, abs(NdotL), LdotV, bsdfData.perceptualRoughness); //hack : No INV_PI for URP to match the HDRP result
            diffTerm = Fd_Lambert() * PI;
            
        #endif
        
        // The compiler should optimize these. Can revisit later if necessary.
        float3 diffR = diffTerm * clampedNdotL;
        float3 diffT = diffTerm * flippedNdotL;

        // Probably worth branching here for perf reasons.
        // This branch will be optimized away if there's no transmission (as NdotL > 0 is tested in IsNonZeroBSDF())
        // And we hope the compile will move specTerm in the branch in case of transmission (TODO: verify as we fabric this may not be true as we already have branch above...)
        // specR = bsdfData.bitangentWS;
        float3 specR = 0;
        if (NdotL > 0)
        {
            specR = specTerm * clampedNdotL;
        }
        // -----------------------
        
        half3 transmittance = bsdfData.transmittance;

        // If transmittance or the CBSDF_SGame's transmission components are known to be 0,
        // the optimization pass of the compiler will remove all of the associated code.
        // However, this will take a lot more CPU time than doing the same thing using
        // the preprocessor.
        diffuse  = (diffR + diffT * transmittance) * lightColor * bsdfData.diffuseColor;
        specular = specR  * lightColor;
    }

    BSDFData_Fabric InitInitializeBSDFData_Fabric(SurfaceData_SGame surfaceData,InputData_SGame inputData, half3 transmittance)
    {
        BSDFData_Fabric bsdfData = (BSDFData_Fabric)0;

        // IMPORTANT: All enable flags are statically know at compile time, so the compiler can do compile time optimization
        bsdfData.diffuseColor = surfaceData.albedo;

        bsdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surfaceData.smoothness);
        
        #if defined(_SILK_ON)
            bsdfData.anisotropy = surfaceData.anisotropy;
        #endif

        bsdfData.transmittance = transmittance;

        // In forward everything is statically know and we could theorically cumulate all the material features. So the code reflect it.
        // However in practice we keep parity between deferred and forward, so we should constrain the various features.
        // The UI is in charge of setuping the constrain, not the code. So if users is forward only and want unleash power, it is easy to unleash by some UI change

        // After the fill material SSS data has operated, in the case of the fabric we force the value of the fresnel0 term
        bsdfData.fresnel0 = surfaceData.specular;

        // roughnessT and roughnessB are clamped, and are meant to be used with punctual and directional lights.
        // perceptualRoughness is not clamped, and is meant to be used for IBL.
        // perceptualRoughness can be modify by FillMaterialClearCoatData, so ConvertAnisotropyToClampRoughness must be call after
        ConvertAnisotropyToClampRoughness(bsdfData.perceptualRoughness, bsdfData.anisotropy, bsdfData.roughnessT, bsdfData.roughnessB);

        return bsdfData;
    }

    half3 IndirectClothColor(PreLightData_Fabric preLightData,SurfaceData_SGame fabricSurfaceData,InputData_SGame inputData,BSDFData_Fabric bsdfData)
    {
        half3 R = dot(-inputData.viewDirWS,inputData.normalWS);
        // Indirect Color
        half3 indirectDiffuse = inputData.Irradiance * fabricSurfaceData.occlusion * bsdfData.diffuseColor;
        half3 indirectSpecular = ClothIBL(preLightData.specularFGD,R,bsdfData.perceptualRoughness,fabricSurfaceData.occlusion);

        return indirectDiffuse + indirectSpecular;
    }

    half4 SGameFragmentFabric(SurfaceData_SGame fabricSurfaceData, InputData_SGame inputData,Varyings_SGame input)
    {
        BSDFData_Fabric bsdfData = InitInitializeBSDFData_Fabric(fabricSurfaceData, inputData, _Transmission_Tint);

        PreLightData_Fabric preLightData = GetPreLightData_Fabric(inputData, UnityBuildTexture2DStructNoScale(_preIntegratedFGD), bsdfData);

        Light mainLight = GetMainLight_SGame(inputData.positionWS,input.shadowCoord);
        
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.Irradiance);

        // Direct Color
        half3 diffuse = 0, specular = 0;
        SGame_FabricLighting(bsdfData, inputData, mainLight, preLightData, diffuse, specular);

        half3 directColor = bsdfData.diffuseColor * diffuse + specular;

        // Additional Color
        #ifdef _ADDITIONAL_LIGHTS
            uint pixelLightCount = GetAdditionalLightsCount();
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS, unity_ProbesOcclusion);
                half3 addDiffuse = 0, addSpecular = 0 ;
                SGame_FabricLighting(bsdfData, inputData, light, preLightData, addDiffuse, addSpecular);
                directColor += addDiffuse + addSpecular;
            }
        #endif


        half3 R = reflect(-inputData.viewDirWS, inputData.normalWS);
        // Indirect Color
        half3 indirectDiffuse = inputData.Irradiance * fabricSurfaceData.occlusion * bsdfData.diffuseColor;
        half3 indirectSpecular = ClothIBL(preLightData.specularFGD,R,bsdfData.perceptualRoughness,fabricSurfaceData.occlusion);
        half3 indirectColor = indirectDiffuse + indirectSpecular;
        // indirectColor = IndirectClothColor(preLightData,fabricSurfaceData,inputData,bsdfData);

        half3 color = directColor + indirectColor;

        return half4(color,fabricSurfaceData.alpha);
    }

    float4 FabricFragment(Varyings_SGame input, half facing : VFACE):SV_TARGET
    {
        SurfaceData_SGame fabricSurfaceData = InitializeSurfaceData_SGame(input.uv);

        InputData_SGame inputData = InitializeInputData_SGame(input,fabricSurfaceData, max(facing,0));

        half4 color = SGameFragmentFabric(fabricSurfaceData,inputData,input);

        return color;
    }

#endif // FABRIC_LIGHTING_INCLUDE