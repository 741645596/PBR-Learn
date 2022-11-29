
Shader "FB/Indicator/Additive"
{
	Properties
	{
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
		_FadeFactor("Fade Factor", range(0,1)) = 1
		_BeCoveredAlpha("Fade Factor", range(0,1)) = 0.3
		[HDR]_TintColor("Tint Color", Color) = (0.5,0.5,0.5,1)
	}
		
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Blend SrcAlpha One
		Cull Off 
		Lighting Off 
		ZWrite Off 
		Fog { Mode Off }
		
		LOD 100
		
		Pass
		{
			Tags {"LightMode"="UniversalForward"}
			ZTest LEqual

			Stencil
			{
				Ref 0
				Comp equal
				Pass keep
				Fail keep
				ZFail keep
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _CUTOFF_ON
			#include "Indicator.hlsl" 
		

			ENDHLSL
		}

		Pass
		{
			Tags {"LightMode"="SrpDefaultUnlit"}
			ZTest GEqual

			Stencil
			{
				Ref 0
				Comp equal
				Pass keep
				Fail keep
				ZFail keep
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _CUTOFF_ON
			#define _BE_COVERED
			#include "Indicator.hlsl" 
		

			ENDHLSL
		}
	}
	FallBack Off

}

