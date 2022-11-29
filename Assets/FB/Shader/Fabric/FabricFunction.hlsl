#ifndef FABRIC_FUNCTION_INCLUDE
#define FABRIC_FUNCTION_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

#define TRANSMISSION_WRAP_ANGLE (PI/12)
#define TRANSMISSION_WRAP_LIGHT cos(PI/2 - TRANSMISSION_WRAP_ANGLE)
#define FGDTEXTURE_RESOLUTION (64)
#define LTC_LUT_SIZE   64
#define LTC_LUT_SCALE  ((LTC_LUT_SIZE - 1) * rcp(LTC_LUT_SIZE))
#define LTC_LUT_OFFSET (0.5 * rcp(LTC_LUT_SIZE))

//apply for silk
void GetPreIntegratedFGDGGXAndDisneyDiffuse(UnityTexture2D FGD, half NdotV, half perceptualRoughness, half3 fresnel0, out half3 specularFGD, out half diffuseFGD, out half reflectivity)
{
    // We want the LUT to contain the entire [0, 1] range, without losing half a texel at each side.
    half2 coordLUT = Remap01ToHalfTexelCoord(half2(sqrt(NdotV), perceptualRoughness), FGDTEXTURE_RESOLUTION);
    
    half3 preFGD = FGD.SampleLevel(FGD.samplerstate, coordLUT, 0).xyz;

    // Pre-integrate GGX FGD
    // Integral{BSDF * <N,L> dw} =
    // Integral{(F0 + (1 - F0) * (1 - <V,H>)^5) * (BSDF / F) * <N,L> dw} =
    // (1 - F0) * Integral{(1 - <V,H>)^5 * (BSDF / F) * <N,L> dw} + F0 * Integral{(BSDF / F) * <N,L> dw}=
    // (1 - F0) * x + F0 * y = lerp(x, y, F0)
    specularFGD = lerp(preFGD.xxx, preFGD.yyy, fresnel0);
    
    // Pre integrate DisneyDiffuse FGD:
    // z = DisneyDiffuse
    // Remap from the [0, 1] to the [0.5, 1.5] range.
    diffuseFGD = preFGD.z + 0.5;

    reflectivity = preFGD.y;
}

void GetPreIntegratedFGDCharlieAndFabricLambert(UnityTexture2D FGD, float NdotV, float perceptualRoughness, float3 fresnel0, out float3 specularFGD, out float diffuseFGD, out float reflectivity)
{
    // Read the texture
    float3 preFGD = FGD.SampleLevel(FGD.samplerstate, float2(NdotV, perceptualRoughness), 0).xyz;
    
    //need to adjust lighting percent it is too strong
    specularFGD = lerp(preFGD.xxx, preFGD.yyy, fresnel0) * 2.0f * PI;

    // z = FabricLambert
    diffuseFGD = preFGD.z;

    reflectivity = preFGD.y;
}

// half3 LightingUnityFabric_Unity(SurfaceData_SGame fabricSurfaceData, BSDFData_Fabric bsdfData, InputData_SGame inputData, PreLightData_Fabric preLightData)
// {
//     #if !defined (LIGHTMAP_ON)
//         half4 shadowMask = unity_ProbesOcclusion;
//     #else
//         half4 shadowMask = half4(1, 1, 1, 1);
//     #endif

//     LightingData lightingData = (LightingData)0;

//     // Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
//     Light mainLight = GetMainLight_SGame(inputData.positionWS,inputData.shadowCoord,shadowMask);
    
//     // AmbientOcclusionFactor aoFactor;
     
//     // #if defined(_SCREEN_SPACE_OCCLUSION)
//     //     aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
//     //     mainLight.color *= aoFactor.directAmbientOcclusion;
//     //     fabricSurfaceData.ambientOcclusion = min(fabricSurfaceData.ambientOcclusion, aoFactor.indirectAmbientOcclusion);
//     // #endif
//     fabricSurfaceData.ambientOcclusion = fabricSurfaceData.ambientOcclusion;

//     // #if UNITY_VERSION > 202210
//     //     uint meshRenderingLayers = GetMeshRenderingLayer();
//     // #else
//         uint meshRenderingLayers = GetMeshRenderingLightLayer();
//     // #endif
    
//     MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

//     half3 diffuse = 0, specular = 0;
//     half3 indirectDiffuse = 0, indirectSpecular = 0;

//     EvaluateBSDF_Env(fabricSurfaceData, bsdfData, inputData, preLightData, indirectDiffuse, indirectSpecular);

//     //MainLight
//     if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
//     {
//         EvaluateBSDF_Directional_SGame(bsdfData, inputData, mainLight, preLightData, diffuse, specular);
//     }
    
//     lightingData.mainLightColor = bsdfData.diffuseColor * diffuse + specular;

//     //Addtional Light
//     #if defined(_ADDITIONAL_LIGHTS)
//     uint pixelLightCount = GetAdditionalLightsCount();

//     LIGHT_LOOP_BEGIN(pixelLightCount)
//         Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask /* , aoFactor*/);

//     if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
//     {
//         half3 addDiffuse = 0, addSpecular = 0 ;
//         EvaluateBSDF_Directional_SGame(bsdfData, inputData, light, preLightData, addDiffuse, addSpecular);
//         lightingData.additionalLightsColor += (addDiffuse + addSpecular );
//     }
//     LIGHT_LOOP_END
//     #endif

//     lightingData.giColor = indirectDiffuse + indirectSpecular;
//     lightingData.emissionColor = fabricSurfaceData.emission;
    
//     //use lightingData version
//     half3 color = CalculateLightingColor(lightingData, 1);//specular don't multiply albedo

//     return color;
// }

#endif  // FABRIC_FUNCTION_INCLUDE