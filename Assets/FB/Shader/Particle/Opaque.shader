Shader "FB/Particle/Opaque"
{
	Properties
	{
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,1)
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
	}
		
	SubShader
	{
		Tags { "IgnoreProjector"="True" "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
		Lighting Off 
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
			#include "SGameParticles.hlsl"
			ENDHLSL
		}
	}

	FallBack Off
}

