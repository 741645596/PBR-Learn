
Shader "FB/Scene/Terrain/VertexColor2LayersHighLightMaskBaking" {
	Properties {
		_Splat0("Layer 1", 2D) = "white" {}
		_Splat1("Layer 2", 2D) = "black" {}
		_AlphaTex1("Alpha 2", 2D) = "white" {}
		_LightTex("Light Text (RGB)", 2D) = "white" {}
		_Light("LightScale", float) = 2
		_HightColor("HighLight Color", Color) = (1, 1, 1, 1)
		_Shininess("Shininess", float) = 1
		_HightLightIntensity("High Light Intensity", float) = 5
		_MaskTex("MaskTex(RGB)", 2D) = "white" {}
		_MaskSpeedX("Mask Speed X", float) = 1
		_MaskSpeedY("Mask Speed Y", float) = 1
	}
	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry+3" "RenderPipeline" = "UniversalPipeline"}
		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"                 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_Splat0); SAMPLER(sampler_Splat0);
				TEXTURE2D_X(_Splat1); SAMPLER(sampler_Splat1);
				TEXTURE2D_X(_LightTex); SAMPLER(sampler_LightTex);
				TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
				TEXTURE2D_X(_AlphaTex1); SAMPLER(sampler_AlphaTex1);
				float4 _Splat0_ST, _Splat1_ST;
				half _Light;
				half4 _HightColor;
				half _Shininess, _HightLightIntensity;
				half _MaskSpeedX, _MaskSpeedY;
				float4 _AlphaTex1_ST;
				half _Global_SceneBrightness;

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				half4 color : COLOR0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv0_Splat0 : TEXCOORD0;
				float2 uv1_Splat1 : TEXCOORD1;
				float2 uv1 : TEXCOORD3;
				half4 color : TEXCOORD4;
				float4 worldPos : TEXCOORD5;
				float2 uv_alphatex : TEXCOORD6;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv0_Splat0 = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.uv1_Splat1 = TRANSFORM_TEX(v.texcoord1, _Splat1);
				o.uv1 = v.texcoord1;
				o.color = v.color;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv_alphatex = TRANSFORM_TEX(v.texcoord1, _AlphaTex1);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 color;
				half3 lay1 = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, i.uv0_Splat0);
				half4 lay2 = half4(SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, i.uv1_Splat1).rgb, SAMPLE_TEXTURE2D(_AlphaTex1, sampler_AlphaTex1, i.uv_alphatex).r);

				half viwDir_CamDirDot = abs(dot(normalize(i.worldPos - _WorldSpaceCameraPos), normalize(UNITY_MATRIX_V[2].xyz)));
				half2 maskUV = frac(i.worldPos.xz / 15 + half2(_MaskSpeedX, _MaskSpeedY) * _Time.x);
				half3 maskColor = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskUV);
				lay2.rgb = lay2.rgb + pow(viwDir_CamDirDot, _Shininess) * _HightColor.rgb * lay2.a * maskColor * _HightLightIntensity;
				color.rgb = lerp(lay1, lay2.rgb, i.color.a);
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




