
Shader "FB/Particle/MAdditive" {
	Properties {
		_TintColor ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_Brightness ("Brightness", float) = 2.0
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half4 _MainTex_ST;
				half4 _TintColor;
				half _Brightness;

			CBUFFER_END
			
			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
			};
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.color.rgb = v.color.a * v.color.rgb * _TintColor.rgb;
				o.color.a = v.color.a * _TintColor.a;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				return _Brightness * i.color * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
			}
			
			ENDHLSL
		}
	} 
	FallBack Off
}
