
Shader "FB/Particle/AdditiveRim"
{
	Properties
	{
		_EdgeColor ("Edge Color", Color) = (1,1,1,1)
		_EdgePower ("Edge Power", float) = 1.0
		_EdgeScale ("Edge Scale", float) = 1.0
		_Brightness ("Brightness", float) = 1.0
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,1)
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_AlphaTex ("千万不要填，系统用的", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
		_FadeFactor("Fade Factor", float) = 1
		_ZTestMode("ZTestMode", float) = 4
	}
		
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Blend SrcAlpha One
		//Cull Off 
		Lighting Off 
		ZWrite Off 
		ZTest [_ZTestMode]
		Fog { Mode Off }
		
		LOD 100
		
		Pass
		{
			Tags {"LightMode"="UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _TINTCOLOR_OFF _TINTCOLOR_ON
			#pragma multi_compile _CUTOFF_OFF _CUTOFF_ON
			#pragma multi_compile _SEPERATE_ALPHA_TEX_OFF _SEPERATE_ALPHA_TEX_ON

			#include "SGameParticlesRim.hlsl"
			ENDHLSL
		}
	}
	FallBack Off
}

