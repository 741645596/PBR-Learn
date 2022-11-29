
Shader "FB/Particle/MAdditiveMaskTint" {
	Properties {
		_TintColor ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "black" {}
		_Brightness ("Brightness", float) = 2.0
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent""RenderPipeline" = "UniversalPipeline" }
		Blend One One
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
				TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
				half4 _MainTex_ST;
				half4 _MaskTex_ST;
				half4 _TintColor;
				half _Brightness;

			CBUFFER_END
			
			struct appdata {
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 uv1 : TEXCOORD1;
				half4 color : COLOR;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.texcoord, _MaskTex);
				o.color = v.color;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _TintColor * _Brightness;
				half4 ret = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv1) * tex;
				ret *= i.color.a;
				return ret;
			}
			
			ENDHLSL
		}
	} 
	FallBack Off
}
