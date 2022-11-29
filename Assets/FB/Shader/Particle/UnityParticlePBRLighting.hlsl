#ifndef SKINMUTIPAR_LIGHTING_INCLUDE
#define SKINMUTIPAR_LIGHTING_INCLUDE

#define m_kDielectricSpec half4(0.028, 0.028, 0.028, 1.0 - 0.028)
#define M_HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define M_HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

struct BRDFDataSSS
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

void InitInitializeBRDFDataSSS(SurfaceDataSSS surfaceData,out BRDFDataSSS brdfData) {

    brdfData = (BRDFDataSSS)0;

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
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = brdfData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    brdfData.shadowMask = shadowMask;
}

half3 GI(BRDFDataSSS brdfData, InputDataSSS inputData, SurfaceDataSSS surfaceData)
{
    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    half fresnelTerm = pow4(1.0 - NoV);
    fresnelTerm=fresnelTerm*smoothstep(1,0.8,fresnelTerm);

    half3 indirectDiffuse = inputData.bakedGI * surfaceData.occlusion;

    half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

    #if defined(UNITY_USE_NATIVE_HDR)
        half3 irradiance = encodedIrradiance.rgb;
    #else
        half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    #endif

    half3 indirectSpecular = irradiance * surfaceData.occlusion;
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += indirectSpecular * half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm));
    return c;
}

half BRDFSpecular(BRDFDataSSS brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
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

//SecondLobeRoughnessDerivation 0-1 �ײ�ֲڶ�
//SpecularLobeInterpolation 0-1 ����߹����
half BRDFSpecularWithTwoLobes(BRDFDataSSS brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS,
    half SecondLobeRoughnessDerivation,half SpecularLobeInterpolation)
{
    float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.

    float secondRoughness = brdfData.roughness * (1 + SecondLobeRoughnessDerivation);
    float secondRoughness2MinusOne = secondRoughness * secondRoughness - 1;

    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    float d2 = NoH * NoH * secondRoughness2MinusOne + 1.00001f;

    half normalizationTerm2 = secondRoughness * 4.0 + 2.0;

    half LoH2 = LoH * LoH;
    half specularTerm1 = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    half specularTerm2 = (secondRoughness * secondRoughness) / ((d2 * d2) * max(0.1h, LoH2) * normalizationTerm2);

    //half specularTerm = lerp(specularTerm1, specularTerm2, SpecularLobeInterpolation);
    half specularTerm = specularTerm2+ specularTerm1* SpecularLobeInterpolation;

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        specularTerm = specularTerm - HALF_MIN;
        specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
    #endif

    specularTerm = clamp(specularTerm, 0, 8);

    return specularTerm;
}

//����=SSS��������

half3 SSSRangeLightingPhysicallyBased(SurfaceDataSSS surfaceData,BRDFDataSSS brdfData, Light light, InputDataSSS inputData, half gi)
{
    half shadowAttenuation = light.shadowAttenuation;
    shadowAttenuation = lerp(1, shadowAttenuation,surfaceData.shadowStrenght);


    float NdotL = saturate(dot(inputData.normalWS, light.direction));
    float sNdotL = _ShadeMin + NdotL * (1 - _ShadeMin);
    float3 radiance = light.color * (light.distanceAttenuation * shadowAttenuation * sNdotL);

    //half3 brdf = brdfData.diffuse+brdfData.specular * BRDFSpecular(brdfData, inputData.normalWS, light.direction, inputData.viewDirectionWS);
    half3 brdf = brdfData.diffuse + brdfData.specular * BRDFSpecularWithTwoLobes(brdfData, inputData.normalWS, light.direction, inputData.viewDirectionWS, _SpecularTwoLobesA, _SpecularTwoLobesB);

    return brdf * radiance;
}

half4 SSSRangePBR(InputDataSSS inputData, SurfaceDataSSS surfaceData)
{

    BRDFDataSSS brdfData;
    InitInitializeBRDFDataSSS(surfaceData, brdfData);

    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
        #if defined(ENABLE_HQ_SHADOW)
            Light mainLight = GetMainLight(float4(0,0,0,0), inputData.positionWS, brdfData.shadowMask);
            #if defined(_RECEIVE_SHADOWS_OFF)
               mainLight.shadowAttenuation=1;
            #else
               mainLight.shadowAttenuation = inputData.shadowCoord.x;
            #endif
        #elif defined(ENABLE_HQ_AND_UNITY_SHADOW)
            Light mainLight = GetMainLight(inputData.shadowCoord);
            #if defined(_RECEIVE_SHADOWS_OFF)
                mainLight.shadowAttenuation=1;
            #else
                mainLight.shadowAttenuation = inputData.shadowCoord.x*mainLight.shadowAttenuation;
            #endif
        #else
            Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, brdfData.shadowMask);
        #endif
    #else
        Light mainLight = GetMainLight();
    #endif

    //Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, brdfData.shadowMask);


    #if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
        inputData.bakedGI = SubtractDirectMainLightFromLightmap(mainLight, inputData.normalWS, inputData.bakedGI);
    #endif
    half gi = dot(inputData.bakedGI.rgb, half3(1, 1, 1)) * surfaceData.occlusion;

    // Indirect
    half3 color = GI(brdfData, inputData, surfaceData);

    // Direct
    color += SSSRangeLightingPhysicallyBased(surfaceData,brdfData,
        mainLight, inputData, gi);

    // Additional 
    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, brdfData.shadowMask);
            color += SSSRangeLightingPhysicallyBased(surfaceData,brdfData,
                light, inputData, gi);
        }
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif
    color += surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

half3 MixFogColorPBR(real3 fragColor, real3 fogColor, real fogFactor)
{
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        real fogIntensity = ComputeFogIntensity(fogFactor);
        fragColor = lerp(fogColor, fragColor, fogIntensity);
    #endif
    return fragColor;
}

half4 SSSRangeFragment(VaryingsSSS input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceDataSSS surfaceData;

    InitSurfaceDataSSSRange(input, surfaceData);

    InputDataSSS inputData;
    InitInputDataSSS(input, surfaceData.normalTS, inputData);

    half4 color = SSSRangePBR(inputData, surfaceData);
    color.rgb = MixFogColorPBR(color.rgb,  unity_FogColor.rgb, inputData.fogCoord);

    color = PBRDissolve(color,input.uv.xy);
    return color;
}

#endif