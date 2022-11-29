
Shader "FB/Particle/MDissolveAdditive" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_FXTex ("Dissolve Map (RGB)", 2D) = "white" {}
		_FXColor ("Dissolve Edge Color", Color) = (1,1,1,1)
		_ColorRange ("Dissolve Edge Color Scale", float) = 10
		_Dissolve("Dissolve Offset [0, 1]", float) = 1
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Fog { Mode Off }
		LOD 100
		
		Pass {
			Tags {"LightMode"="UniversalForward"}
			Name "BASE"
			ZWrite Off
			Cull Off
			Blend SrcAlpha One
		
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_FXTex); SAMPLER(sampler_FXTex);
				float4 _MainTex_ST;
				float4 _FXTex_ST;
				half _Dissolve;
				half4 _FXColor;
				half _ColorRange;
				half4 _Color;

			CBUFFER_END

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				half4 color : COLOR0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _FXTex);
				o.color = v.color;
				o.color.rgb *= _Color.rgb;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half test = _Dissolve;
				half4 texcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * half4(i.color.rgb, _Color.a);
				half fx = SAMPLE_TEXTURE2D(_FXTex, sampler_FXTex, i.uv.zw).r;
				half alpha = ceil(test * i.color.a - fx) * texcol.a;
				half col = saturate((test-fx)*_ColorRange);
				half4 ret = half4(_FXColor.rgb*(1.0-col)*2.0+texcol.rgb, alpha);
				return ret;
			}

			ENDHLSL
		}
	} 
	FallBack Off
}
