
Shader "FB/Particle/DissolveAlphaBlendNoEdge" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FXTex ("Dissolve Map (RGB)", 2D) = "white" {}
		_EdgeWidth ("Dissolve Edge Width", float) = 10
		_Shining("Dissolve Offset [0, 1]", float) = 1
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		LOD 100
		
		Pass {
			Tags {"LightMode"="UniversalForward"}
			Name "BASE"
			Cull Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl" 
				
			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_FXTex); SAMPLER(sampler_FXTex);
				uniform half _Shining;
				uniform half4 _MainTex_ST;
				uniform half4 _FXTex_ST;
				uniform half4 _Color;
				uniform half _EdgeWidth;
			CBUFFER_END
			
			struct appdata {
				half4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f {
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 uv2 : TEXCOORD1;
				half4 color : COLOR0;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.texcoord, _FXTex);
				o.color = v.color;
				o.color.a *= _Color.a;
				return o;
			}
			
			half4 frag (v2f i) : COLOR
			{				
				half test = _Shining;
				half4 tintColor = half4(_Color.rgb, i.color.a);
				half4 texcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * tintColor;
				half fx = SAMPLE_TEXTURE2D(_FXTex, sampler_FXTex, i.uv2).r;
				half alpha = 1 - saturate((test - fx) * _EdgeWidth);
				texcol.a *= alpha;
				return texcol;
			}

			ENDHLSL
		}
	} 
	FallBack Off
}
