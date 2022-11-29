Shader "FB/Scene/Light/TerrainVertexColor2Layers" {
	Properties {
		_Splat0 ("Layer 1", 2D) = "white" {}
		_Splat1 ("Layer 2", 2D) = "black" {}
	}
                
	SubShader {
		Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

		pass{
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_Splat0); SAMPLER(sampler_Splat0);
				TEXTURE2D_X(_Splat1); SAMPLER(sampler_Splat1);
				float4 _Splat0_ST, _Splat1_ST;

			CBUFFER_END

			struct appdata {
				float4 vert : POSITION0;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv_Splat0 : TEXCOORD0;
				half2 uv_Splat1 : TEXCOORD1;
				half4 color : COLOR0;

			};

			v2f vert(appdata i) {
				v2f o;
				o.pos = TransformObjectToHClip(i.vert.xyz);
				o.uv_Splat0 = TRANSFORM_TEX(i.texcoord, _Splat0);
				o.uv_Splat1 = TRANSFORM_TEX(i.texcoord, _Splat1);
				o.color = i.color;
				return o;
			}
		
			half4 frag (v2f IN) : SV_Target{
				float4 lay1 = SAMPLE_TEXTURE2D(_Splat0,sampler_Splat0,IN.uv_Splat0);
				float4 lay2 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, IN.uv_Splat1);
				half4 color = half4(lerp(lay1.rgb, lay2.rgb, IN.color.a) * IN.color.rgb*2, 1);
				return color;
			}

			ENDHLSL
		}
	}
}

