#ifndef SGAME_PBRINPUT_INCLUDE
#define SGAME_PBRINPUT_INCLUDE

#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

CBUFFER_START(UnityPerMaterial)
	int	_Col;
	int _Row;
	// transparent
	half _Cutoff;

	// PBR
	half4 _BaseColor;
	float4 _BaseMap_ST;

	half _Smoothness;
    half _Metallic;
    half _OcclusionStrength;
	half _SpecularOcclusionStrength;

	half4 _EmissionColor;
	half4 _TransmitColor;
	half _TransmitInt;

	// clear Cloat
	half _ClearCoatMask;
    half _ClearCoatSmoothness;
	half _ClearCoatDownSmoothness;
	float4 _ClearCoatCubeMap_HDR;
	half _ClearCoat_Detail_Factor;

	// detail
	float _DetailMap_Tilling_1;
	half _DetailAlbedoScale_1;
	half3 _DetailAlbedoColor_1;
	half _DetailNormalScale_1;
	half _DetailSmoothnessScale_1;

	float _DetailMap_Tilling_2;
	half _DetailAlbedoScale_2;
	half3 _DetailAlbedoColor_2;
	half _DetailNormalScale_2;
	half _DetailSmoothnessScale_2;

	float _DetailMap_Tilling_3;
	half _DetailAlbedoScale_3;
	half3 _DetailAlbedoColor_3;
	half _DetailNormalScale_3;
	half _DetailSmoothnessScale_3;

	float _DetailMap_Tilling_4;
	half _DetailAlbedoScale_4;
	half3 _DetailAlbedoColor_4;
	half _DetailNormalScale_4;
	half _DetailSmoothnessScale_4;

	// iridescence
	half _Iridescence;
    half _IridescenceThickness;

	// shadow
	//阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
	half4 _ShadowColor;
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
	half _AlphaVal;

	half3 _ProGameOutDir;
	half _ShadowStr=1;

CBUFFER_END

TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);

TEXTURE2D(_NormalMap);		SAMPLER(sampler_NormalMap);
TEXTURE2D(_BentNormalMap);SAMPLER(sampler_BentNormalMap);

TEXTURE2D(_MetallicGlossMap);SAMPLER(sampler_MetallicGlossMap);

TEXTURE2D_HALF(_EmissionMap);SAMPLER(sampler_EmissionMap);

TEXTURE2D_HALF(_ClearCoatMap);SAMPLER(sampler_ClearCoatMap);
TEXTURECUBE(_ClearCoatCubeMap);SAMPLER(sampler_ClearCoatCubeMap);

TEXTURE2D_HALF(_IridescenceMask);SAMPLER(sampler_IridescenceMask);

TEXTURE2D(_EnergyLUT);SAMPLER(sampler_EnergyLUT);
TEXTURE2D(_DiffuseRamp);SAMPLER(sampler_DiffuseRamp);

TEXTURE2D(_CurveMap);	SAMPLER(sampler_CurveMap);

//detail
TEXTURE2D_HALF(_Detail_ID);SAMPLER(sampler_Detail_ID);
TEXTURE2D(_DetailMap_1);SAMPLER(sampler_DetailMap_1);
TEXTURE2D(_DetailMap_2);SAMPLER(sampler_DetailMap_2);
TEXTURE2D(_DetailMap_3);SAMPLER(sampler_DetailMap_3);
TEXTURE2D(_DetailMap_4);SAMPLER(sampler_DetailMap_4);

#endif	//SGAME_PBRINPUT_INCLUDE
