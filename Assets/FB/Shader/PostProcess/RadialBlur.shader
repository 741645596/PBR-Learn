
Shader "FB/PostProcessing/RadialBlur" 
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
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _DUMMY _HIGHQUALITY_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			struct v2f 
			{
					float4 pos : POSITION;
					half4 uv  : TEXCOORD0;
					half2 blurSize : TEXCOORD1;
			};

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half2 _ScreenCenter;
				half _FalloffExp;
				half _BlurScale;
			CBUFFER_END

			struct appdata_img {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
				
			v2f vert( appdata_img v ) 
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = v.texcoord.xy;
				o.uv.zw = v.texcoord.xy * float2(2,2) + float2(-1,-1);
				o.blurSize = _BlurScale * 0.2 / _ScreenParams.xy;
				return o;
			}
				
			half4 frag(v2f i) : SV_Target
			{
				half2 screenUV = i.uv.xy;
				half2 screenPos = i.uv.zw;
				half2 blurSize = i.blurSize;
				half2 posToCenter = screenPos - _ScreenCenter;
				half len = length(posToCenter);
				half2 dir = posToCenter / len;
				dir *= pow(len, _FalloffExp) * blurSize;
				half4 c = 0;
				c.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV + dir * 0).rgb;
				c.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV + dir * 1).rgb;
				c.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV + dir * 2).rgb;
				c.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV + dir * 3).rgb;
				c.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV + dir * 4).rgb;
				c.rgb *= 0.2;
				return c;
			}
			ENDHLSL
		}
	}

	Fallback off
}
