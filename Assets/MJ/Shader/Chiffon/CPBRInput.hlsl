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
		// Anisotropy
		half _Anisotropy;
		// ------- sparkle -----------------
		half4 _SparkleSize;
		half4 _SparkleColor;

		half _SparkleDependency;
		half _SparkleRoughness;
		half _SparkleScaleMin;
		half _SparkleDensity;
		// #endif
	CBUFFER_END

	TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
	TEXTURE2D(_NormalMap);
	TEXTURE2D(_BentNormalMap);
	TEXTURE2D(_MetallicGlossMap);
	TEXTURE2D_HALF(_EmissionMap);
	TEXTURE2D(_SparkleTex);    SAMPLER(sampler_SparkleTex);
	TEXTURE2D(_SparkleMaskTex);    SAMPLER(sampler_SparkleMaskTex);

#endif	//SGAME_PBRINPUT_NEW_INCLUDE
