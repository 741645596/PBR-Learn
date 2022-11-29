
Shader "FB/Other/UnlitTexture2" {
	Properties {
		[MainTexture] _MainTex ("Base (RGB)", 2D) = "white" {}
	}

	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
		LOD 100
	
		Pass {  
			Tags {"LightMode"="UniversalForward"}
			ColorMask RGB
	
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				float4 _MainTex_ST;
			CBUFFER_END

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);
				return col;
			}

			ENDHLSL
		}
	}

}
