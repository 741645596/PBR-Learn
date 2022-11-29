
Shader "FB/Particle/MAdditiveMasUVOffset1"
{
	Properties 
	{
		_TintColor ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex("Main_Texture", 2D) = "white" {}
		_MaskTex("Mask_Texture", 2D) = "white" {}
		_Speed("Main_Texture_Speed", float) = 0.0
		_Brightness ("Brightness", float) = 2.0
	}
	
	SubShader 
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		Blend One OneMinusSrcAlpha
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		LOD 100

		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl" 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
				half4 _MainTex_ST;
				half4 _MaskTex_ST;
				float _Speed;
				half4 _TintColor;
				half _Brightness;

			CBUFFER_END

			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
			};

			v2f vert (appdata_t v) {
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				float2 offset = float2(0.0, _Time.x * _Speed);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + offset + _MainTex_ST.zw;
				o.uv2 = TRANSFORM_TEX(v.texcoord, _MaskTex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _TintColor * _Brightness;
				col.rgb *= SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv2).rgb;
				col.a = 0.0;
				return col;
			}
			ENDHLSL
		}
	}
	Fallback "M-Game/Particles/Additive Mask UV Offset"
}