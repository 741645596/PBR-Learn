
Shader "FB/PostProcessing/ClearAlpha" 
{
	Properties 
	{
		[MainTexture] _MainTex ("Base (RGB)", 2D) = "" {}
	}

	Subshader 
	{
		Tags {"RenderPipeline" = "UniversalPipeline"}
		Pass
		{
			Tags {"LightMode"="UniversalForward"}
			ZTest Always 
			Cull Off 
			ZWrite Off
			ColorMask A
			Fog { Mode off }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			struct appdata_img {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f 
			{
				float4 pos : POSITION;
				half2 uv  : TEXCOORD0;
			};

			v2f vert( appdata_img v ) 
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv =  v.texcoord.xy;
				return o;
			}
				
			half4 frag(v2f i) : SV_Target
			{
				return float4(0,0,0,1);
			}

			ENDHLSL
		}
	}

	Fallback off
}
