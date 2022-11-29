//工具 纹理色散
Shader "FB/PostProcessing/EditorTextureChromatic" 
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
			Fog { Mode off }

			HLSLPROGRAM

			#pragma multi_compile _ ENABLE_RG ENABLE_RB ENABLE_GB
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			
			float offsetX;
			
			float offsetY;

			TEXTURE2D_X(_MainTex);
            SAMPLER(point_repeat);

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

				#if defined(ENABLE_RG)

					float2 xUV=i.uv+float2(offsetX,0);
					float r=SAMPLE_TEXTURE2D(_MainTex, point_repeat, xUV).r;
					float2 yUV=i.uv+float2(0,offsetY);
					float g=SAMPLE_TEXTURE2D(_MainTex, point_repeat, yUV).g;
					float b=SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).b;
					return half4(r,g,b,SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).a);

				#elif defined(ENABLE_RB)

					float2 xUV=i.uv+float2(offsetX,0);
					float r=SAMPLE_TEXTURE2D(_MainTex, point_repeat, xUV).r;
					float g=SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).g;
					float2 yUV=i.uv+float2(0,offsetY);
					float b=SAMPLE_TEXTURE2D(_MainTex, point_repeat, yUV).b;
					return half4(r,g,b,SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).a);

				#else
				
					float r=SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).r;
					float2 xUV=i.uv+float2(offsetX,0);
					float g=SAMPLE_TEXTURE2D(_MainTex, point_repeat, xUV).g;
					float2 yUV=i.uv+float2(0,offsetY);
					float b=SAMPLE_TEXTURE2D(_MainTex, point_repeat, yUV).b;
					return half4(r,g,b,SAMPLE_TEXTURE2D(_MainTex, point_repeat, i.uv).a);

				#endif

				return float4(0,0,0,1);
			}

			ENDHLSL
		}
	}

	Fallback off
}
