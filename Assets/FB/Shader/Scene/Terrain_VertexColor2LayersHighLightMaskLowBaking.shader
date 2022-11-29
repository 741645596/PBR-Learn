// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FB/Scene/Terrain/VertexColor2LayersHighLightMaskLowBaking" {
	Properties{
		_Splat0("Layer 1", 2D) = "white" {}
		_Splat1("Layer 2", 2D) = "black" {}
		_LightTex("Light Text (RGB)", 2D) = "white" {}
		_Light("LightScale", float) = 2
	}
	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry+3" "RenderPipeline" = "UniversalPipeline"}
		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_Splat0); SAMPLER(sampler_Splat0);
				TEXTURE2D_X(_Splat1); SAMPLER(sampler_Splat1);
				TEXTURE2D_X(_LightTex); SAMPLER(sampler_LightTex);
				float4 _Splat0_ST, _Splat1_ST;
				half _Light;
				half _Global_SceneBrightness;

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0_Splat0 : TEXCOORD0;
				float2 uv1_Splat1 : TEXCOORD1;
				float2 uv1 : TEXCOORD2;
				half4 color : TEXCOORD3;
			};

			v2f vert(appdata_full v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv0_Splat0 = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.uv1_Splat1 = TRANSFORM_TEX(v.texcoord1, _Splat1);
				o.uv1 = v.texcoord1.xy;
				o.color = v.color;
				return o;
			}

			half4 frag(v2f i) : SV_Target{
				half4 color;
				half3 lay1 = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, i.uv0_Splat0).rgb;
				half3 lay2 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, i.uv1_Splat1).rgb;
				color.rgb = lerp(lay1, lay2, i.color.a);
				color.rgb *= i.color.rgb * 2;
				half3 lm = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv1).rgb *_Light;
				color.rgb *= lm.rgb;
				color.rgb *= _Global_SceneBrightness;
				color.a = 1;

				return color;
			}

			ENDHLSL
		}
	}
}








