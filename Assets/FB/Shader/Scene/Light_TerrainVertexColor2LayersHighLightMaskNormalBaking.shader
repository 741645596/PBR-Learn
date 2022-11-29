
Shader "FB/Scene/Light/TerrainVertexColor2LayersHighLightMaskNormalBaking" {
	Properties {
		_Splat0 ("Layer 1", 2D) = "white" {}
		_Splat1 ("Layer 2", 2D) = "black" {}
		_AlphaTex("Alpha(Layer1R, Layer2G)", 2D) = "white" {}
		_LightTex("Light Text (RGB)", 2D) = "white" {}
		_Light("LightScale", float) = 2
		_Normal0("Normal 1", 2D) = "white" {}
		_GlobalLightDirection("Global Light Direction", Vector) = (-0.3, 1, -0.3, 1)
		_HightColor("HighLight Color", Color) = (1, 1, 1, 1)
		_Sun("Sun", float) = 1
		_HightLightIntensity("High Light Intensity", float) = 5
		_MaskSpeedX("Mask Speed X", float) = 1
		_MaskSpeedY("Mask Speed Y", float) = 1
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess("Shininess", Range(0.03, 1)) = 0.078125
	}
	SubShader {
		Tags { "RenderPipeline" = "UniversalPipeline" }
		Pass {
			Tags { "RenderType" = "Opaque" "Queue" = "Geometry+3" "LightMode"="UniversalForward"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_Splat0); SAMPLER(sampler_Splat0);
				TEXTURE2D_X(_Splat1); SAMPLER(sampler_Splat1);
				TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
				TEXTURE2D_X(_AlphaTex1); SAMPLER(sampler_AlphaTex1);
				TEXTURE2D_X(_LightTex); SAMPLER(sampler_LightTex);
				TEXTURE2D_X(_Normal0); SAMPLER(sampler_Normal0);
				float4 _Splat0_ST, _Splat1_ST;
				half _Light;
				half4 _HightColor;
				half _Sun;
				half _Shininess;
				half _HightLightIntensity;
				half _MaskSpeedX;
				half _MaskSpeedY;
				half4 _SpecColor;
				half4 _GlobalLightDirection;
				half _Global_SceneBrightness = 1;

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				half4 color : COLOR0;
				float4 tangent:TANGENT;
				float3 normal:NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0_Splat0 : TEXCOORD0;
				float2 uv1_Splat1 : TEXCOORD1;
				float2 uv1 : TEXCOORD3;
				half4 color : TEXCOORD4;
				float4 worldPos : TEXCOORD5;
				half3 tsViewDir : TEXCOORD6;
				half3 tsLightDir : TEXCOORD7;
			};

			float3 ObjSpaceViewDir(in float4 v)
			{
				float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
				return objSpaceCameraPos - v.xyz;
			}

			#define TANGENT_SPACE_ROTATION \
			float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w; \
			float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal )

			v2f vert(appdata_full v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv0_Splat0 = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.uv1_Splat1 = TRANSFORM_TEX(v.texcoord1, _Splat1);
				o.uv1 = v.texcoord1;
				o.color = v.color;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				TANGENT_SPACE_ROTATION;
				o.tsLightDir = mul(rotation, mul(unity_WorldToObject, _GlobalLightDirection).xyz);
				o.tsViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				return o;
			}

			half4 frag(v2f i) : SV_Target{
				half4 color;
				half4 lay1 = half4(SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, i.uv0_Splat0).rgb, SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, i.uv0_Splat0).r);
				half4 lay2 = half4(SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, i.uv1_Splat1).rgb, SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, i.uv1_Splat1).g);
				half3 normal1TS = UnpackNormal(SAMPLE_TEXTURE2D(_Normal0, sampler_Normal0, i.uv0_Splat0));
				half3 normal2TS = half3(0, 0, 1);

				half viwDir_CamDirDot = abs(dot(normalize(i.worldPos - _WorldSpaceCameraPos), normalize(UNITY_MATRIX_V[2].xyz)));
				lay2.rgb = lay2.rgb + pow(viwDir_CamDirDot, _Sun) * _HightColor.rgb * lay2.a * _HightLightIntensity;

				color.rgb = lerp(lay1, lay2.rgb, i.color.a);
				color.rgb *= i.color.rgb * 2;
				half3 normalTS = lerp(normal1TS, normal2TS, i.color.a);
				half gloss = lerp(lay1.a, lay2.a, i.color.a);
				half3 lm = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv1).rgb *_Light;

				//高光部分
				half3 h = normalize(normalize(i.tsViewDir) + normalize(i.tsLightDir));
				float nh = max(0, dot(normalTS, h));
				float spec = pow(nh, _Shininess * 128.0);
				half3 specColor = _SpecColor * gloss * spec;
				color.rgb += specColor;
				color.rgb *= lm.rgb;
				color.rgb *= _Global_SceneBrightness;
				color.a = 1;
				return color;
			}

			ENDHLSL
		}
	}
}


