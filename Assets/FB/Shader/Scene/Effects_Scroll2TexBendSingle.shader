
Shader "FB/Scene/Effects/Scroll2TexBendSingle" {
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
		_SrcBlend("SrcBlend", float)=5
		_DestBlend("DestBlend", float)=10
	}

	SubShader {
		Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
	
		Blend [_SrcBlend] [_DestBlend]
		Lighting Off 
		ZWrite Off
		ColorMask RGB
		Fog { Mode Off }
		LOD 500
	
		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest		
			#pragma multi_compile _DUMMY _FOG_OF_WAR_ON _FOG_OF_WAR_ON_LOW
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "FogOfWar.hlsl"                           
		
			CBUFFER_START(HeroURPGroups) CBUFFER_END
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MainTex2); SAMPLER(sampler_MainTex2);
				float4 _MainTex_ST;
				float4 _MainTex2_ST;
				float _ScrollX;
				float _ScrollY;
				float _Scroll2X;
				float _Scroll2Y;
				float _MMultiplier;
				float4 _UVXX;
				float4 _Color;
			CBUFFER_START(HeroURPGroups) CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
				#if defined(_FOG_OF_WAR_ON) || defined(_FOG_OF_WAR_ON_LOW)
					float3 worldPos : TEXCOORD2;
				#endif
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time.x);
				o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_MainTex2) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);
				o.color = _MMultiplier * _Color * v.color;
				#if defined(_FOG_OF_WAR_ON) || defined(_FOG_OF_WAR_ON_LOW)
					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				#endif
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half4 o;
				half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
				half2 uv=tex.r * _UVXX.x;
				half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv.zw + uv);
				o = tex * tex2 * i.color;
				#if defined(_FOG_OF_WAR_ON) || defined(_FOG_OF_WAR_ON_LOW)
					o.xyz = ComputeFow(o.xyz, i.worldPos);
				#endif
				return o;
			}

			ENDHLSL
		}
	}
}