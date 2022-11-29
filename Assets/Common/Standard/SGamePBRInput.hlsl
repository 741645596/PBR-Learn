#ifndef SGAME_PBRINPUT_INCLUDE
	#define SGAME_PBRINPUT_INCLUDE

	#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
	#include "Assets/Common/ShaderLibrary/Surface/ShadingModel.hlsl"
	#include "Assets/Common/ShaderLibrary/Common/GlobalIllumination.hlsl"

	CBUFFER_START(UnityPerMaterial)

		// transparent
		half _Cutoff;

		// PBR
		half4 _BaseColor;
		float4 _BaseMap_ST;

		half _Smoothness;
		half _Metallic;
		half _OcclusionStrength;
		half _SpecularOcclusionStrength;

		half _Reflectance;

		half4 _EmissionColor;

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

		// laser
		half  _LaserIOR;
		half  _LaserThickness;
		half  _LaserBrdfIntensity;
		half  _LaserAnisotropy;
		half3 _LaserColor;
		half  _LaserSmoothstepValue_1;
		half  _LaserSmoothstepValue_2;
		half  _LaserUniversal;
		half  _LaserAreaCubemapInt;

		// Subsurface
		half3 _SubsurfaceColor;

		// Anisotropy
		half _Anisotropy;

		// shadow
		half4  _ShadowColor;		//阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
		
		float  _ShadowHeight;		//阴影平面的高度 目前由外部脚本设定 UpdateShadowPlane.cs
		
		float  _ShadowOffsetX;		//XZ平面的偏移
		float  _ShadowOffsetZ;

		float  _MeshHight;			//模型高度 由外部脚本设定 UpdateShadowPlane.cs
		float4 _WorldPos;			//模型位置 由外部脚本设定 UpdateShadowPlane.cs
		
		half  _AlphaVal;			//影子透明度

		half3 _ProGameOutDir;

		half _ReceiveShadows;
	CBUFFER_END

	TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);

	TEXTURE2D(_NormalMap);
	TEXTURE2D(_BentNormalMap);

	TEXTURE2D(_MetallicGlossMap);

	TEXTURE2D_HALF(_EmissionMap);

	TEXTURE2D_HALF(_ClearCoatMap);
	TEXTURECUBE(_ClearCoatCubeMap);

	TEXTURE2D_HALF(_IridescenceMask);

	TEXTURE2D_HALF(_LaserMap);

	TEXTURE2D_HALF(_ThickMap);

	//detail
	TEXTURE2D_HALF(_Detail_ID);
	TEXTURE2D(_DetailMap_1);
	TEXTURE2D(_DetailMap_2);
	TEXTURE2D(_DetailMap_3);
	TEXTURE2D(_DetailMap_4);

#endif	//SGAME_PBRINPUT_NEW_INCLUDE
