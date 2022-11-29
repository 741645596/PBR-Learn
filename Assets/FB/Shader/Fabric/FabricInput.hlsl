#ifndef FABRIC_INPUT_INCLUDE
#define FABRIC_INPUT_INCLUDE

#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
#include "Assets/Common/ShaderLibrary/Surface/ShadingModel.hlsl"

CBUFFER_START(UnityPerMaterial)

// transparent
float _Cutoff;

float _Anisotropy;

float4 _BaseMap_ST;
float4 _BaseColor;
float4 _SpecColor;
half _SpecTintStrength;
float4 _Transmission_Tint;

float _Metallic;
float _SmoothnessMax;
float _OcclusionStrength;

float _NormalScale;

float _ThreadAOStrength;
float _ThreadNormalStrength;
float _ThreadSmoothnessScale;
float _ThreadTilling;

float _FuzzMapUVScale;
float _FuzzStrength;

float4 _preIntegratedFGD_TexelSize;

// shadow
//阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
float4 _ShadowColor;
//阴影平面的高度 目前由外部脚本设定 UpdateShadowPlane.cs
float _ShadowHeight;
//XZ平面的偏移
float _ShadowOffsetX;
float _ShadowOffsetZ;

//模型高度 由外部脚本设定 UpdateShadowPlane.cs
float _MeshHight;
//模型位置 由外部脚本设定 UpdateShadowPlane.cs
float4 _WorldPos;
//影子透明度
float _AlphaVal;

float3 _ProGameOutDir;
float _ShadowStr=1;

CBUFFER_END

TEXTURE2D(_preIntegratedFGD);
SAMPLER(sampler_preIntegratedFGD);

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_MaskMap);
SAMPLER(sampler_MaskMap);

TEXTURE2D(_ThreadMap);
SAMPLER(sampler_ThreadMap);

TEXTURE2D(_FuzzMap);
SAMPLER(sampler_FuzzMap);

#endif // FABRIC_INPUT_INCLUDE