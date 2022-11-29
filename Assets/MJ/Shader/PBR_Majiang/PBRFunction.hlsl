#ifndef PBR_FUNCTION_INCLUDE
#define PBR_FUNCTION_INCLUDE

#include "SGamePBRInput.hlsl"

///////// Energy Compensation //////////
float3 AverageFresnel(float3 r, float3 g) {
    return float3(0.087237.xxx) + 0.0230685 * g - 0.0864902 * g * g + 0.0774594 * g * g * g
           + 0.782654 * r - 0.136432 * r * r + 0.278708 * r * r * r
           + 0.19744  * g * r + 0.0360605 * g * g * r - 0.2586 * g * r * r;
}

float3 MultiScatterBRDF(half3 albedo,half roughness, half3 N,half3 V,half3 L) {

    half NdotL = saturate(dot(N,L));
    half NdotV = saturate(dot(N,V));

    half E_avg = SAMPLE_TEXTURE2D(_EnergyLUT , sampler_LinearClamp, float2(0, roughness)).x;
    half E_o   = SAMPLE_TEXTURE2D(_EnergyLUT , sampler_LinearClamp, float2(NdotL, roughness)).y;
    half E_i   = SAMPLE_TEXTURE2D(_EnergyLUT , sampler_LinearClamp, float2(NdotV, roughness)).y;

    
    // copper
    float3 edgetint = float3(0.827, 0.792, 0.678);
    float3 F_avg = AverageFresnel(albedo, edgetint);
    
    float3 fms = (float3(1.0.xxx) - E_o) * (float3(1.0.xxx) - E_i) / (PI * (float3(1.0.xxx) - E_avg));
    float3 F_add = F_avg * E_avg / (float3(1.0.xxx) - F_avg * (float3(1.0.xxx) - E_avg));

    // return fms;
    return F_add * fms;
}



#endif //PBR_FUNCTION_INCLUDE