Shader "FB/Scene/Effects/Scroll2TexBendLightMap" {
	Properties {
		[MainTexture] _MainTex ("Tex1(RGB)", 2D) = "white" {}
		_MainTex2 ("Tex2(RGB)", 2D) = "white" {}
		_ScrollX ("Tex1 speed X", Float) = 1.0
		_ScrollY ("Tex1 speed Y", Float) = 0.0
		_Scroll2X ("Tex2 speed X", Float) = 1.0
		_Scroll2Y ("Tex2 speed Y", Float) = 0.0
		_Color("Color", Color) = (1,1,1,1)
		_UVXX("UVXX", vector)=(0.3,1,1,1)	
		_MMultiplier ("Layer Multiplier", Float) = 2.0
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
		LOD 200
		Cull Back

		pass{
			Tags { LightMode = UniversalForward }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MainTex2); SAMPLER(sampler_MainTex2);
				float4 _MainTex_ST;
				float4 _MainTex2_ST;
				float _ScrollX;
				float _ScrollY;
				float _Scroll2X;
				float _Scroll2Y;
				half4 _Color;
				float4 _UVXX;
				float _MMultiplier;
			CBUFFER_END

			struct appdata {
				float4 vert : POSITION0;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				half4 color: TEXCOORD2;
				float2  offsetXY:TEXCOORD3;
				float2  offsetZW:TEXCOORD4;
			};

			v2f vert(appdata i){
				v2f o;
				o.pos = TransformObjectToHClip(i.vert.xyz);
				o.uv1 = TRANSFORM_TEX(i.texcoord, _MainTex);
				o.uv2 = TRANSFORM_TEX(i.texcoord, _MainTex2);
				o.color = _MMultiplier * _Color;
				o.offsetXY = frac(float2(_ScrollX, _ScrollY) * _Time.x);
				o.offsetZW = frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);
				return o;
			}

			half4 frag(v2f i) : SV_Target{
				half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv1 + i.offsetXY);
				half2 uv = tex.r * _UVXX.x;
				half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv2 + i.offsetZW + uv);
				half4 c = tex + tex2;
				c.rgb *= i.color.rgb;
				c.a=1;
				return c;
			}
				
			ENDHLSL
		}
	} 
}
