
Shader "FB/Scene/Effects/Scroll2TexBend0Clip" {
	Properties {
		[MainTexture] _MainTex ("Tex1(RGB)", 2D) = "white" {}
		_MainTex2 ("Tex2(RGB)", 2D) = "white" {}
		_AlphaTex1("千万不要填，系统用的", 2D) = "white" {}
		_AlphaTex2("千万不要填，系统用的", 2D) = "white" {}
		_ScrollX ("Tex1 speed X", Float) = 1.0
		_ScrollY ("Tex1 speed Y", Float) = 0.0
		_Scroll2X ("Tex2 speed X", Float) = 1.0
		_Scroll2Y ("Tex2 speed Y", Float) = 0.0
		_Color("Color", Color) = (1,1,1,1)
		_UVXX("UVXX", vector)=(0.3,1,1,1)	
		_MMultiplier ("Layer Multiplier", Float) = 2.0
	
		_SrcBlend("SrcBlend", float)=5
		_DestBlend("DestBlend", float)=10
		_ClipRange("Clip Range", vector) = (-1.0, 1.0, -1.0, 1.0)
	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent""RenderPipeline" = "UniversalPipeline" }
	
		Blend [_SrcBlend] [_DestBlend]
		Cull Off 
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
			#pragma multi_compile _DUMMY _SEPERATE_ALPHA_TEX_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MainTex2); SAMPLER(sampler_MainTex2);
				TEXTURE2D_X(_AlphaTex1); SAMPLER(sampler_AlphaTex1);
				TEXTURE2D_X(_AlphaTex2); SAMPLER(sampler_AlphaTex2);
				float4 _MainTex_ST;
				float4 _MainTex2_ST;
				float _ScrollX;
				float _ScrollY;
				float _Scroll2X;
				float _Scroll2Y;
				float _MMultiplier;
				float4 _UVXX;
				float4 _Color;
				float4 _ClipRange;
			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
				float2 screenpos : TEXCOORD2;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time.x);
				o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_MainTex2) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);
				o.screenpos = o.pos.xy;
				o.color = _MMultiplier * _Color * v.color;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half4 o;
				#ifdef _SEPERATE_ALPHA_TEX_ON
					half4 tex = half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb, SAMPLE_TEXTURE2D(_AlphaTex1, sampler_AlphaTex1, i.uv.xy).r);
				#else
					half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
				#endif
				half2 uv=tex.r * _UVXX.x;
				#ifdef _SEPERATE_ALPHA_TEX_ON
					half4 tex2 = half4(SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv.zw + uv).rgb, SAMPLE_TEXTURE2D(_AlphaTex2, sampler_AlphaTex2, i.uv.zw + uv).r);
				#else
					half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv.zw + uv);
				#endif
				o = tex * tex2 * i.color;
				//o.a = 	dot(o.rgb, float3(0.3,0.59,0.11));
				float factor1 = step(_ClipRange.x, i.screenpos.x);
				float factor2 = step(i.screenpos.x, _ClipRange.y);
				float factor3 = step(_ClipRange.z, i.screenpos.y);
				float factor4 = step(i.screenpos.y, _ClipRange.w);
				o.a = o.a * factor1 * factor2 * factor3 * factor4;
				return o;
			}
			ENDHLSL
		}
	}
	FallBack Off
}
