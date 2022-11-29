
Shader "FB/Scene/Effects/Scroll2TexBendWaterVCA"
{
	Properties {
		[MainTexture] _MainTex ("Tex1(RGB)", 2D) = "white" {}
		_MainTex2 ("Tex2(RGB)", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_Mask("Tex1Mask (RGB)", 2D) = "white" {}
		_ScrollX ("Tex1 speed X", Float) = 1.0
		_ScrollY ("Tex1 speed Y", Float) = 0.0
		_Scroll2X ("Normal speed X", Float) = 1.0
		_Scroll2Y ("Normal speed Y", Float) = 0.0
		_Color("Color", Color) = (1,1,1,1)
		_UVXX("UVXX", vector)=(0.3,1,1,1)	
		_MMultiplier ("Layer Multiplier", Float) = 2.0
	}
	
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		Lighting Off 
		ZWrite On
		Cull Off
		Fog { Mode Off }
		LOD 500	

		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MainTex2); SAMPLER(sampler_MainTex2);
				TEXTURE2D_X(_NormalTex); SAMPLER(sampler_NormalTex);
				TEXTURE2D_X(_Mask); SAMPLER(sampler_Mask);
				float4 _MainTex_ST;
				float4 _MainTex2_ST;
				float4 _NormalTex_ST;
				float _ScrollX;
				float _ScrollY;
				float _Scroll2X;
				float _Scroll2Y;
				float _MMultiplier;
				float4 _UVXX;
				float4 _Color;

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				half4 color : COLOR0;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				half3 normal: TEXCOORD3;
				half3 tangent : TEXCOORD4;
				half3 binormal : TEXCOORD5;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time.x);
				o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_NormalTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);
				o.uv2.xy = TRANSFORM_TEX(v.texcoord.xy,_MainTex2);
				o.color = _MMultiplier * _Color * v.color;
				o.normal = mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz;
				o.tangent = mul(UNITY_MATRIX_MV, float4(v.tangent.xyz, 0)).xyz;
				o.binormal = cross(o.normal, o.tangent) * v.tangent.w;
				o.color.a = v.color.a;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half3x3 basis = half3x3(i.tangent, i.binormal, i.normal);
				half3 normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.zw).rgb * 2 - 1;
				half3 normalVS = normalize(mul(normal, basis));
				half4 o;
				half2 uvr = normalVS.xy * 0.5 + 0.5;
				half2 uv=normal* _UVXX.x;
				half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv2.xy + uv);
				half4 Mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv2.xy + uv);
				half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy + uv * 0.2)*Mask;
				// o = tex  + tex2 * i.color.a;
				// o = tex * (1 - i.color.a) + tex2 * i.color.a;
				o = tex + tex2 * i.color;
				o.a = i.color.a;
				return o;
			}
			ENDHLSL
		}
	}
}
