#ifndef PBR_INPUT_INCLUDE
#define PBR_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#include "../ShaderLibrary/CommonInput.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half _Cutoff;
    // PBR
    half _Smothness;
    half _Metallic;
    half _Occlusion;
    half4 _EmissionColor;
    half4 _CustomLightDir;
    half3 _CustomLightColor;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_MixMap);
TEXTURE2D(_BumpMap);
TEXTURE2D(_EmissionMap);

half3 GetRMO(float2 uv)
{
    #if ENABLE_MIXMAP
        half4 mixMapTex = SAMPLE_TEXTURE2D(_MixMap, sampler_BaseMap, uv); 
        return half3(1- mixMapTex.a, mixMapTex.r, mixMapTex.g);
    #else
        return half3(1-_Smothness, _Metallic, _Occlusion);
    #endif
}

// half3 GetprefilteredDFG(half NoV, half perceptualRoughness)
// {
//     // We want the LUT to contain the entire [0, 1] range, without losing half a texel at each side.
//     float2 coordLUT = Remap01ToHalfTexelCoord(float2(NoV, perceptualRoughness), FGDTEXTURE_RESOLUTION);

//     return SAMPLE_TEXTURE2D_LOD(_DFG, s_linear_clamp_sampler, coordLUT, 0).xyz;
// }


half4 GetEmission(float2 uv)
{
    #if ENABLE_EMISSION
        return SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, uv) * _EmissionColor;
    #else
        return _EmissionColor;
    #endif
}

#include "PBRLighting.hlsl"
#endif
