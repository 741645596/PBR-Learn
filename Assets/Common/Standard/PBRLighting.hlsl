#ifndef PBR_LIGHTING_INCLUDE
#define PBR_LIGHTING_INCLUDE

struct PixelData
{
    half3   diffuseColor;
    half    alpha;

    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
        float4  shadowCoord;
    #endif

    float3  positionWS;
    half3   normalWS;
    half3   viewDirWS;
    half    NoV;
    half    perceptualRoughness;
    half    roughness;
    half    roughness2;
    half    occlusion;
    half3   f0;
    half    grazingTerm;
    half4   emission;
    half3   bakedGI;



     #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF) && (defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW))
         half hqShasow;
     #endif
};

half SpecularLobe(const PixelData pixel, float3 H, half NoL, float NoH, half LoH)
{
    half DVF = GGX_Unity(NoH, LoH * LoH, pixel.roughness2, pixel.roughness2 - 1.0h, pixel.roughness * 4.0h + 2.0h);
    DVF = clamp(DVF, 0, 5);
    return DVF;
}

half3 DiffuseLobe(const PixelData pixel) {
    return pixel.diffuseColor;// * Fd_Lambert();
}

void CalculateIBL(PixelData pixel, inout half3 color)
{
    half3 reflectVector = reflect(-pixel.viewDirWS, pixel.normalWS);
    half fresnelTerm = Pow4(1.0 - pixel.NoV);

    half3 indirectDiffuse = pixel.bakedGI * pixel.occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, pixel.perceptualRoughness, pixel.occlusion);

    half3 c = indirectDiffuse * pixel.diffuseColor;
    float surfaceReduction = 1.0 / (pixel.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(pixel.f0, pixel.grazingTerm, fresnelTerm);
    
    color += c;
}

void CalculateDirectionalLight(PixelData pixel, inout half3 color)
{
    // Calculate lighting
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
         #if defined(ENABLE_HQ_SHADOW)
            Light light = GetMainLight();
            #if defined(_RECEIVE_SHADOWS_OFF)
                light.shadowAttenuation=1;
            #else
                light.shadowAttenuation = pixel.hqShasow;
            #endif
         #elif defined(ENABLE_HQ_AND_UNITY_SHADOW)
            Light light = GetMainLight(pixel.shadowCoord);
            #if defined(_RECEIVE_SHADOWS_OFF)
                light.shadowAttenuation=1;
            #else
                light.shadowAttenuation = pixel.hqShasow*light.shadowAttenuation;
            #endif
         #else
            Light light = GetMainLight(pixel.shadowCoord);
         #endif
    #else
        Light light = GetMainLight();
    #endif

    //#if _CUSTOM_LIGHT_COLOR
    //    light.color = pixel.customLightColor;
    //#endif
    //#if _CUSTOM_LIGHT_DIR
    //    light.direction = pixel.customLightDir;    
    //#endif
    light.shadowAttenuation= lerp(1,light.shadowAttenuation,pixel.emission.a);
    // Skip direct lighting at back & shadow
    half NoL = saturate(dot(pixel.normalWS, light.direction));
    if (NoL <= 0.0 || light.shadowAttenuation == 0.0) return;

    // Calculate BRDF vectors
    float3 lightDirWSFloat3 = float3(light.direction);
    float3 H = normalize(float3(pixel.viewDirWS) + lightDirWSFloat3);
    float NoH = saturate(dot(float3(pixel.normalWS), H));
    float LoH = saturate(dot(lightDirWSFloat3, H));
    half Fr = SpecularLobe(pixel, H, NoL, NoH, LoH);
    half3 Fd = DiffuseLobe(pixel);
    half3 lo = Fd + Fr * pixel.f0;
    lo = lo * light.color * light.distanceAttenuation * light.shadowAttenuation * NoL;

    color += lo;
}

#if defined(_ADDITIONAL_LIGHTS)
void CalculateAdditionalLight(PixelData pixel, inout half3 color)
{
    uint pixelLightCount = GetAdditionalLightsCount();
    for (int lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex) 
    { 
        Light light = GetAdditionalLight(lightIndex, pixel.positionWS);
        half NoL = saturate(dot(pixel.normalWS, light.direction));

        // Calculate BRDF vectors
        float3 lightDirWSFloat3 = float3(light.direction);
        float3 H = normalize(float3(pixel.viewDirWS) + lightDirWSFloat3);
        float NoH = saturate(dot(float3(pixel.normalWS), H));
        float LoH = saturate(dot(lightDirWSFloat3, H));

        half3 Fd = DiffuseLobe(pixel);
        half Fr = SpecularLobe(pixel, H, NoL, NoH, LoH);

        half3 lo = Fd + Fr * pixel.f0;
        lo = lo * light.color * light.distanceAttenuation * NoL;
        color += lo;
    }
}
#endif

void AddEmissive(PixelData pixel, inout half3 color)
{
    color += pixel.emission.rgb;
}

#endif //PBR_LIGHTING_INCLUDE