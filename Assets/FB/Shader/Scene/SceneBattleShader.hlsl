#ifndef SCENEBATTLE_SHADER
#define SCENEBATTLE_SHADER

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
#include "SceneBattleShaderInput.hlsl" 

half4 frag(v2f i) : SV_Target
{
	#if defined(_MATTYPE_RIVER)
		half4 waveMaskTex = SAMPLE_TEXTURE2D(_WaveMaskTex, sampler_WaveMaskTex, i.uv.zw);
		half4 waveNoiseTexA = SAMPLE_TEXTURE2D(_WaveNoiseTex, sampler_WaveNoiseTex, i.waveUV.xy);
		half4 waveNoiseTexB = SAMPLE_TEXTURE2D(_WaveNoiseTex, sampler_WaveNoiseTex, i.waveUV.zw);
		half2 uv1 = waveNoiseTexA.b * waveMaskTex.r;
		i.uv.xy=i.uv.xy+uv1*_WaveStrength.x;
		//映射
        float waveLerp=waveMaskTex.g*waveMaskTex.r;
        float waveLerpA=GetRange(waveLerp,0.05,0.7,0,UNITY_PI);
		waveLerpA=sin(waveLerpA);
		float waveLerpB=GetRange(waveLerp,0,1,0,UNITY_FOUR_PI*2);
		waveLerp = frac(sin(waveLerpB+_Time.x*30)*waveLerpA)*_WaveStrength.z;
	#endif

	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON) 
		half4 color = SAMPLE_TEXTURE2D(_BaseMapMatCap,sampler_BaseMapMatCap,i.uv.xy);
	#elif defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		half4 color = SAMPLE_TEXTURE2D(_BaseMapMatCapPBR,sampler_BaseMapMatCapPBR,i.uv.xy);
	#else
		half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv.xy);
	#endif
	#if defined(_MATTYPE_RIVER)
		color.rgb=lerp(color.rgb,waveNoiseTexB.rgb,waveMaskTex.r*_WaveStrength.y);
		color.rgb=color.rgb+waveLerp;
	#endif
	color = EffectFrag(color,i)*_BaseColor + SAMPLE_TEXTURE2D(_EmissionMap,sampler_EmissionMap,i.uv.xy).r * _EmissionColor;
	return color;
}

#endif



