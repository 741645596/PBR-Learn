#ifndef MATCAP_INPUT_INCLUDE
#define MATCAP_INPUT_INCLUDE

#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	half4 _BaseColor;
	half _NormalScale;
	half _MatcapScale;
	half4 _NormalAnim;
	half _UVScale;
CBUFFER_END

TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
TEXTURE2D(_MatcapMap);  SAMPLER(sampler_MatcapMap);
TEXTURE2D(_NormalMap);  SAMPLER(sampler_NormalMap);

#endif // MATCAP_INPUT_INCLUDE