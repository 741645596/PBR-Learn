
Shader "FB/Particle/MAlphaBlend" {
	Properties {
		_TintColor ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_AlphaTex ("Aplha (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", float) = 2.0
	}
	SubShader {

		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent""RenderPipeline" = "UniversalPipeline" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		LOD 100
		
		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
				half4 _MainTex_ST;
				half4 _TintColor;
				half _Brightness;
			CBUFFER_END
			
			struct appdata {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half4 color : COLOR;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color * _TintColor;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 texcol;
				texcol.rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * i.color.rgb * _Brightness;
				texcol.a = SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, i.uv).r * i.color.a * _Brightness;
				return texcol;
			}
			
			ENDHLSL
		}
	} 
	FallBack Off
}

