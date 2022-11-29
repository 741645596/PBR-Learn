//指示器材质
Shader "FB/Particle/AdditiveIndicator"
{
Properties
	{
		[MainTexture]_MainTex ("Particle Texture", 2D) = "white" {}
		_AlphaTex ("千万不要填，系统用的", 2D) = "white" {}
		_CutOff ("Cut off", float) = 0.5
		_FadeFactor("Fade Factor", float) = 1
		_ZTestMode("ZTestMode", float) = 4
		
		_IndicatorAttenuation("IndicatorAttenuation(遮挡半透衰减)", float) = 0.3

		[Toggle(_TINTCOLOR_ON)] _TINTCOLORON("Tint Color", Float) = 0
		_TintColor("Tint Color", Color) = (0.5,0.5,0.5,1)
	}
		
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Cull Off 
		Lighting Off 
		ZWrite Off 
		//ZTest [_ZTestMode]
		Fog { Mode Off }
		
		LOD 100
		
		Pass
		{
			//Tags {"LightMode" = "SrpDefaultUnlit"}
			Tags {"LightMode"="UniversalForward"}
			ZTest LEqual
			Blend SrcAlpha One

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _DUMMY _TINTCOLOR_ON
			#pragma multi_compile _DUMMY _CUTOFF_ON
			#pragma multi_compile _DUMMY _SEPERATE_ALPHA_TEX_ON
			//#pragma fragmentoption ARB_precision_hint_fastest	
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups)

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half _CutOff;
				half4 _TintColor;
				half _FadeFactor;
				float4 _MainTex_ST;

				#ifdef _SEPERATE_ALPHA_TEX_ON
					TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
				#endif

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color;
				#ifdef _TINTCOLOR_ON
					o.color *= _TintColor * 2;
				#endif
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				#ifdef _SEPERATE_ALPHA_TEX_ON
					half4 color = half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy).rgb,SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex,i.uv.xy).r);
				#else
					half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
				#endif

				#ifdef _CUTOFF_ON
					if (color.a < _CutOff)
						discard;
				#endif
				color *= i.color;
				color.a *= _FadeFactor;
				return color;
			}

			ENDHLSL
		}
		Pass
		{
			Tags {"LightMode" = "SrpDefaultUnlit"}

			Stencil
			{
				Ref 1
				Comp Greater
				Pass replace
				Fail keep
				ZFail keep
			}

			ZTest Greater
			Blend SrcAlpha One
			//Tags {"LightMode"="UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _DUMMY _TINTCOLOR_ON
			#pragma multi_compile _DUMMY _CUTOFF_ON
			#pragma multi_compile _DUMMY _SEPERATE_ALPHA_TEX_ON
				//#pragma fragmentoption ARB_precision_hint_fastest	
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

				CBUFFER_START(HeroURPGroups)

					TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
					half _CutOff;
					half4 _TintColor;
					half _FadeFactor;
					float4 _MainTex_ST;

					#ifdef _SEPERATE_ALPHA_TEX_ON
						TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
					#endif
					half _IndicatorAttenuation;

				CBUFFER_END

				struct appdata_full {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					half4 color : COLOR0;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					half4 color : TEXCOORD1;
				};

				v2f vert(appdata_full v)
				{
					v2f o;
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.pos = TransformObjectToHClip(v.vertex.xyz);
					o.color = v.color;
					#ifdef _TINTCOLOR_ON
						o.color *= _TintColor * 2;
					#endif
					return o;
				}

				half4 frag(v2f i) : SV_Target
				{
					#ifdef _SEPERATE_ALPHA_TEX_ON
						half4 color = half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy).rgb,SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex,i.uv.xy).r);
					#else
						half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
					#endif

					#ifdef _CUTOFF_ON
						if (color.a < _CutOff)
							discard;
					#endif
					color *= i.color;
					color.a *= _FadeFactor;
					color.a *= _IndicatorAttenuation;
					//color.rgb = float3(1,0,0);
					return color;
				}

				ENDHLSL
			}
	}
	FallBack Off

}

