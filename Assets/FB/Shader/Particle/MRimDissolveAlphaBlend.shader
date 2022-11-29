
Shader "FB/Particle/MRimDissolveAlphaBlend" {
	Properties {
		_EdgeColor ("Edge Color", Color) = (1,1,1,1)
		_EdgeIn ("Edge In Range", Range (0, 2)) = 0.5
		_EdgeOut ("Edge Out Range", Range (0, 2)) = 1.5
		_TintColor ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_AlphaTex ("Aplha (RGB)", 2D) = "white" {}
		_FXTex ("Dissolve Map (RGB)", 2D) = "white" {}
		_FXScale ("Dissolve Edge Scale", Float) = 10.0
		_Shining ("Dissolve Factor [0, 1]", Range(0,1)) = 1
	}

	SubShader {
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent""RenderPipeline" = "UniversalPipeline" }
		Fog { Mode Off }
		LOD 100
		
		Pass {
			Tags {"LightMode"="UniversalForward"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
		
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl" 
			
			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
				TEXTURE2D_X(_FXTex); SAMPLER(sampler_FXTex);
				half _FXScale;
				half _Shining;
				float4 _MainTex_ST;
				float4 _FXTex_ST;
				half4 _EdgeColor;
				half _EdgeIn;
				half _EdgeOut;
				half4 _TintColor;

			CBUFFER_END
			
			struct appdata {
				half4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half3 normal : NORMAL;
				half4 color : COLOR;
			};
			
			struct v2f {
				half4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
				half4 color : COLOR0;
				half3 rim : COLOR1;
			};

			float3 ObjSpaceViewDir(in float4 v)
			{
				float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
				return objSpaceCameraPos - v.xyz;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _FXTex);
				half3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
				half dotProduct = max(0, dot(v.normal, viewDir));
				o.rim = smoothstep(_EdgeIn,  _EdgeOut, 1 - dotProduct) * _EdgeColor.rgb;
				o.color = v.color * _TintColor;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half test = _Shining + 0.1;
				half4 texcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * i.color;
				half fx = SAMPLE_TEXTURE2D(_FXTex, sampler_FXTex, i.uv.zw).r;
				half alpha = saturate((test - fx) * _FXScale);
				texcol.a *= SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, i.uv.xy).r * alpha;
				texcol.rgb += i.rim;
				return texcol;
			}

			ENDHLSL
		}
	} 
	FallBack Off
}
