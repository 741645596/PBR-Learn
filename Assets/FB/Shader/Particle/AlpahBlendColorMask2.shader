
Shader "FB/Particle/AlpahBlendColorMask2" {
	Properties {
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_ColorMaskTex ("Color Mask Texture", 2D) = "white" {}
		_Level("Brightness", Float) = 1
	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off Lighting Off ZWrite Off Fog { Mode Off }

		Pass {

			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _DUMMY _SEPERATE_ALPHA_TEX_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_ColorMaskTex); SAMPLER(sampler_ColorMaskTex);
				uniform half4 _MainTex_ST;
				uniform half4 _ColorMaskTex_ST;
				half4 _TintColor;
				half _Level;
			CBUFFER_END

			struct appdata {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2	uv : TEXCOORD0;
				half2	uv2 : TEXCOORD1;
				half4	color : COLOR;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.texcoord, _ColorMaskTex);
				o.color = v.color * _TintColor;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
				half4 texcol = color * SAMPLE_TEXTURE2D(_ColorMaskTex, sampler_ColorMaskTex, i.uv2) * i.color * _Level;
				return texcol;
			}
			ENDHLSL
		}
	}
	Fallback Off
}