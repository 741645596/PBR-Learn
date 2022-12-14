#ifndef HEROBATTLE_SHADER
#define HEROBATTLE_SHADER

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
#include "HeroBattleShaderInput.hlsl" 

half4 frag(v2f i) : SV_Target
{
	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON) 
		half4 color = SAMPLE_TEXTURE2D(_BaseMapMatCap,sampler_BaseMapMatCap,i.uv.xy);
	#elif defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		half4 color = SAMPLE_TEXTURE2D(_BaseMapMatCapPBR,sampler_BaseMapMatCapPBR,i.uv.xy);
	#else
		half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv.xy);
	#endif
	color = EffectFrag(color,i)*GET_PROP(_BaseColor);
	return color;
}

#endif



