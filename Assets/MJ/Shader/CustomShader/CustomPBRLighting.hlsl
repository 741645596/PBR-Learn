#ifndef SCENEBATTLE_PBRLIGHTING
#define SCENEBATTLE_PBRLIGHTING

#include "CustomPBRForward.hlsl"

#define m_kDielectricSpec half4(0.028, 0.028, 0.028, 1.0 - 0.028)
#define M_HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define M_HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

struct BRDFDataPBR
{
    half3 albedo;
    half3 diffuse;
    half3 specular;
    half reflectivity;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;
    half4 shadowMask;
    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
};

void InitInitializeBRDFDataPBR(SurfaceDataPBR surfaceData,out BRDFDataPBR brdfData) {

    brdfData = (BRDFDataPBR)0;

    half oneMinusDielectricSpec = m_kDielectricSpec.a;
    half oneMinusReflectivity = oneMinusDielectricSpec - surfaceData.metallic * oneMinusDielectricSpec;
    half reflectivity = 1.0 - oneMinusReflectivity;
    half3 brdfDiffuse = surfaceData.albedo * oneMinusReflectivity;
    half3 brdfSpecular = lerp(m_kDielectricSpec.rgb, surfaceData.albedo, surfaceData.metallic);

    brdfData.diffuse = brdfDiffuse;
    brdfData.specular = brdfSpecular;
    brdfData.reflectivity = reflectivity;
    brdfData.perceptualRoughness = 1 - surfaceData.smoothness;
    brdfData.roughness = max(brdfData.perceptualRoughness* brdfData.perceptualRoughness, M_HALF_MIN_SQRT);
    brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, M_HALF_MIN);
    brdfData.grazingTerm = saturate(surfaceData.smoothness + reflectivity);
    brdfData.normalizationTerm = brdfData.roughness * 4.0h + 2.0h;
    brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    half4 shadowMask = half4(1, 1, 1, 1);

    brdfData.shadowMask = shadowMask;
}
real3 PBRDecodeHDREnvironment(real4 encodedIrradiance, real4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    real alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);

    // If Linear mode is not supported we can skip exponent part
    return (decodeInstructions.x * PositivePow(alpha, decodeInstructions.y)) * encodedIrradiance.rgb;
}

half3 GI(BRDFDataPBR brdfData, InputDataPBR inputData, SurfaceDataPBR surfaceData)
{
    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    float f =1.0 - NoV;
    f=f*f;
    f=f*f;
    half fresnelTerm = f;

    half3 indirectDiffuse = inputData.bakedGI * surfaceData.occlusion;

    half mip = brdfData.perceptualRoughness * (1.7 - 0.7 * brdfData.perceptualRoughness);
    mip = mip * 6;

    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

    #if defined(UNITY_USE_NATIVE_HDR)
        half3 irradiance = encodedIrradiance.rgb;
    #else
        half3 irradiance = PBRDecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    #endif

    half3 indirectSpecular = irradiance * 1;
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += indirectSpecular * half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm));
    return c;
}

half BRDFSpecular(BRDFDataPBR brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));
    float NoH = saturate(dot(float3(normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    half d2 = half(d * d);

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / (d2 * max(half(0.1), LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        specularTerm = specularTerm - M_HALF_MIN;
        specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
    #endif

    specularTerm = clamp(specularTerm, 0, 8);

    return specularTerm;
}

half3 RangeLightingPhysicallyBasedPBR(SurfaceDataPBR surfaceData,BRDFDataPBR brdfData, Light light, InputDataPBR inputData, half gi)
{
    half shadowAttenuation = light.shadowAttenuation;
    //shadowAttenuation = lerp(1, shadowAttenuation,surfaceData.shadowStrenght);

    float NdotL = dot(inputData.normalWS, light.direction);
    float sNdotL = 0.3 + saturate(NdotL) * (1 - 0.3);
    float3 radiance = light.color * (light.distanceAttenuation * shadowAttenuation * sNdotL);

    half3 brdf = brdfData.diffuse+brdfData.specular * BRDFSpecular(brdfData, inputData.normalWS, light.direction, inputData.viewDirectionWS);

    return brdf * radiance;
}

Light GetMainLight_SGame(float3 positionWS,float4 shadowCoord,float4 shadowMask)
{
	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		#if defined(ENABLE_HQ_SHADOW)
			Light light = GetMainLight(float4(0,0,0,0), positionWS, shadowMask);

			#if defined(_RECEIVE_SHADOWS_OFF)
				light.shadowAttenuation = 1;
			#else
				light.shadowAttenuation = shadowCoord.x;
			#endif
			// Shadow
			return light;

		#elif defined(ENABLE_HQ_AND_UNITY_SHADOW)

			Light light = GetMainLight(shadowCoord.x);
			#if defined(_RECEIVE_SHADOWS_OFF)
				light.shadowAttenuation=1;
			#else
				light.shadowAttenuation = shadowCoord.x * light.shadowAttenuation;
			#endif
			// And_Unity_Shadow
			return light;
		#else
			// Off
			return GetMainLight(shadowCoord, positionWS,shadowMask);
        
		#endif
	#else
		return GetMainLight();
	#endif
}

half4 PBR(InputDataPBR inputData, SurfaceDataPBR surfaceData)
{

    BRDFDataPBR brdfData;
    InitInitializeBRDFDataPBR(surfaceData, brdfData);

    Light mainLight = GetMainLight_SGame(inputData.positionWS,inputData.shadowCoord,half4(1,1,1,1));

    half gi = dot(inputData.bakedGI.rgb, half3(1, 1, 1)) * surfaceData.occlusion;
    
    // Indirect
    half3 color = GI(brdfData, inputData, surfaceData);

    // Direct
    color += RangeLightingPhysicallyBasedPBR(surfaceData,brdfData,
        mainLight, inputData, gi);

    // Additional 
    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, brdfData.shadowMask);
            color += RangeLightingPhysicallyBasedPBR(surfaceData,brdfData,
                light, inputData, gi);
        }
    #endif

    color += surfaceData.emission;
    return half4(color, surfaceData.alpha);
}

half4 FragmentRES(VaryingsPBR input){
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceDataPBR surfaceData;

    InitSurfaceDataPBR(input, surfaceData);

    InputDataPBR inputData;
    InitInputData(input, surfaceData.normalTS, inputData);

    half4 color = PBR(inputData, surfaceData);

    #if defined(_TRANSLUCENT) 
		color.a = color.a*_AlphaVal*_AlphaSet;
        clip(color.a-0.5);
	#else
		color.a = 1;
	#endif

    return color;
}

half4 Fragment(VaryingsPBR input) : SV_Target
{
    return FragmentRES(input);
}

#endif
