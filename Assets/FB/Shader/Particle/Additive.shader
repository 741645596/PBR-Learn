
Shader "FB/Particle/Additive"
{
	Properties
	{
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_AlphaTex ("千万不要填，系统用的", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
		_FadeFactor("Fade Factor", float) = 1
		_ZTestMode("ZTestMode", float) = 4

		[Toggle(_TINTCOLOR_ON)] _TINTCOLORON("Tint Color", Float) = 0
		_TintColor("Tint Color", Color) = (0.5,0.5,0.5,1)
	}
		
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Blend SrcAlpha One
		Cull Off 
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
			#pragma multi_compile _DUMMY _TINTCOLOR_ON
			#pragma multi_compile _DUMMY _CUTOFF_ON
			#pragma multi_compile _DUMMY _SEPERATE_ALPHA_TEX_ON
			#include "SGameParticles.hlsl"

			ENDHLSL
		}
	}
	FallBack Off

}

