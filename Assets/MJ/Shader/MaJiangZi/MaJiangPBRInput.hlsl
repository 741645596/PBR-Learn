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

		half  _SSSRange;
		float  _lobe0Smoothness;
		float _lobe1Smoothness;
		float _LobeMix;
		half  _Occlusion;
		half _EnvDiffInt;
		half _PBRToDiffuse;
		half _DiffusePower;
		half _BlushInt;
		half4 _BlushColor;
		half3 _BackLightColor;

		half  _BackLightIntensity;
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

	TEXTURE2D(_SkinMap);SAMPLER(sampler_SkinMap);
	TEXTURE2D(_BlushArea);
	TEXTURE2D_HALF(_SSSLUT);SAMPLER(sampler_SSSLUT);
	TEXTURE2D_HALF(_ThickMap);SAMPLER(sampler_ThickMap);

#endif	//SGAME_PBRINPUT_INCLUDE
