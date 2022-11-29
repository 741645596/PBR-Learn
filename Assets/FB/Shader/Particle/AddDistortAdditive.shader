
Shader "FB/Particle/AddDistortAdditive" {
	Properties {
		[Header(Blend)]
		[Space(5)]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("��ϲ� 1 ��one one ��ADD",int) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("��ϲ� 2 ��SrcAlpha    OneMinusSrcAlpha ��alphaBlend",int) = 1
		[Space(5)]

		//������
		[MainTexture]_MainTex("Alpha (A)", 2D) = "white" {}
		[HideInInspector]_MainTexClamp("MainTexClamp(����WrapMode)",float) = 1  //0:Clamp 1:RepeatUV
		[HideInInspector]_MainTexRepeatU("MainTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
		[HideInInspector]_MainTexRepeatV("MainTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

		_TintColor("Tint Color", Color) = (0.5,0.5,0.5,0.5)

		//��������
		_NoiseTex ("Distort Texture (RG)", 2D) = "white" {}

		[HideInInspector]_NoiseTexClamp("NoiseTexClamp(����WrapMode)",float) = 1  //0:Clamp 1:RepeatUV
		[HideInInspector]_NoiseTexRepeatU("NoiseTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
		[HideInInspector]_NoiseTexRepeatV("NoiseTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

		_HeatTime  ("Heat Time", range (-1,1)) = 0
		_ForceX  ("Strength X", range (0,1)) = 0.1
		_ForceY  ("Strength Y", range (0,1)) = 0.1
		[HideInInspector]_Opacity ("Opacity", float) = 1
	}

	Category {

		Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		//Blend SrcAlpha One
		Blend[_SrcBlend][_DestBlend]
		Cull Off 
		Lighting Off 
		ZWrite Off

		SubShader {
			Pass {

				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile_particles
				#include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"

				CBUFFER_START(HeroURPGroups) 

					TEXTURE2D_X(_NoiseTex); SAMPLER(sampler_NoiseTex);
					TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
					half4 _TintColor;
					half _ForceX;
					half _ForceY;
					half _HeatTime;
					half4 _MainTex_ST;
					half4 _NoiseTex_ST;
					half _Opacity;
					float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
					float _NoiseTexClamp, _NoiseTexRepeatU, _NoiseTexRepeatV;

				CBUFFER_END

				struct appdata_t {
					half4 vertex : POSITION;
					half4 color : COLOR;
					half2 texcoord: TEXCOORD0;
				};

				struct v2f {
					half4 vertex : POSITION;
					half4 color : COLOR;
					half2 uvmain : TEXCOORD1;
				};

				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.color = v.color;
					o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
					return o;
				}

				half4 frag(v2f i) : SV_Target
				{
					//noise effect
					float2 offsetColor1Uv = i.uvmain + _Time.xz * _HeatTime;
					offsetColor1Uv = GetUV(offsetColor1Uv, _NoiseTexClamp, _NoiseTexRepeatU, _NoiseTexRepeatV, _NoiseTex_ST);
					half4 offsetColor1 = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex, offsetColor1Uv);
					//offsetColor1 = GetTextColor(offsetColor1, offsetColor1Uv, _NoiseTexRepeatU, _NoiseTexRepeatV);

					float2 offsetColor2Uv = i.uvmain + _Time.yx * _HeatTime;

					offsetColor2Uv = GetUV(offsetColor2Uv, _NoiseTexClamp, _NoiseTexRepeatU, _NoiseTexRepeatV, _NoiseTex_ST);
					half4 offsetColor2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, offsetColor2Uv);
					//offsetColor2 = GetTextColor(offsetColor2, offsetColor2Uv, _NoiseTexRepeatU, _NoiseTexRepeatV);


					half c = (offsetColor1.r + offsetColor2.r) - 1;
					i.uvmain.x += c * _ForceX;
					i.uvmain.y += c * _ForceY;

					float2 uvMain= GetUV(i.uvmain.xy, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
					half4 mainColor= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
					//mainColor = GetTextColor(mainColor, uvMain, _MainTexRepeatU, _MainTexRepeatV);

					half4 res=2.0f * i.color * _TintColor * mainColor;
					res.a=res.a*_Opacity;
					return res;
				}
				ENDHLSL
			}
		}
	}
}
