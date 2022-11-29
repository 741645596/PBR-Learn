
Shader "FB/UI/UIAdditive"
{
	Properties
	{
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,1)
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_AlphaTex ("千万不要填，系统用的", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
		_FadeFactor("Fade Factor", float) = 1
		_ZTestMode("ZTestMode", float) = 4
         _Color ("Tint", Color) = (1,1,1,1)
         // required for UI.Mask
         _StencilComp ("Stencil Comparison", Float) = 8
         _Stencil ("Stencil ID", Float) = 0
         _StencilOp ("Stencil Operation", Float) = 0
         _StencilWriteMask ("Stencil Write Mask", Float) = 255
         _StencilReadMask ("Stencil Read Mask", Float) = 255
         _ColorMask ("Color Mask", Float) = 15
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
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
    
        ColorMask [_ColorMask]
            
        LOD 100
		
		Pass
		{
			//Tags {"LightMode"="UniversalForward"}
			Tags {"LightMode"="Default UI RP"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _TINTCOLOR_OFF _TINTCOLOR_ON
			#pragma multi_compile _CUTOFF_OFF _CUTOFF_ON
			#pragma multi_compile _SEPERATE_ALPHA_TEX_OFF _SEPERATE_ALPHA_TEX_ON

			#include "SGameUIParticles.hlsl"

			ENDHLSL
		}
	}
	FallBack Off
}

