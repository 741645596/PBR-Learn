#ifndef SKINMUTIPAR_INPUT_INCLUDE
#define SKINMUTIPAR_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

CBUFFER_START(URPGroups)

	half _Bloom_Suppress;
	half _Bloom_SuppressMin;
	//half4 _BaseColor;
	half _ShadeMin;
	half _SpecularTwoLobesA;
	half _SpecularTwoLobesB;
	
	

CBUFFER_END

#endif