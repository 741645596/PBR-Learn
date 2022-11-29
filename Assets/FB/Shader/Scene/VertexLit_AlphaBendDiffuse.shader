
Shader "FB/Scene/VertexLit/AlphaBendDiffuse" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		[MainTexture]_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_AlphaTex ("千万不要填，系统用的", 2D) = "white" {}
		[Toggle(_THISLIGHTMAP_ON)] _THISLIGHTMAPON("LightMap", Float) = 1
	}

	SubShader {
		//Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Tags {"Queue" = "Geometry+2" "IgnoreProjector" = "True" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 200
	
		Pass{
			Tags { LightMode = UniversalForward }

			HLSLPROGRAM

			#ifdef _THISLIGHTMAP_ON
				#define LIGHTMAP_ON
			#endif

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _THISLIGHTMAP_ON
			//#pragma multi_compile _SEPERATE_ALPHA_TEX_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Scene.hlsl" 

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				float4 _MainTex_ST;
				half4 _Color;
				#ifdef _SEPERATE_ALPHA_TEX_ON
					TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex)
				#endif
			CBUFFER_END

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				#ifdef _THISLIGHTMAP_ON
					DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
				#endif	
				};
			
			struct appdata_lightmap {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0; 
				#ifdef _THISLIGHTMAP_ON
					float2 lightmapUV : TEXCOORD1;
				#endif	
			};

			v2f vert(appdata_lightmap i) {
				v2f o;
				o.pos = TransformObjectToHClip(i.vertex.xyz);
				o.uv0 = TRANSFORM_TEX(i.texcoord, _MainTex);
				#ifdef _THISLIGHTMAP_ON
					OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
				#endif	
				return o;
			}

			half4 frag(v2f i) : SV_Target{

				#ifdef _SEPERATE_ALPHA_TEX_ON
					half4 color = half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv0).rgb,SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex, i.uv0).r) * _Color;
				#else
					half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * _Color;
				#endif
				#ifdef _THISLIGHTMAP_ON
					half3 lightMapValue = SampleLightmap(i.lightmapUV);
					lightMapValue=(lightMapValue+half3(1.5,1.5,1.5))*0.5;
					color.rgb *= lightMapValue;
				#endif	
				
				return color;
			}

			ENDHLSL
		}
	}
}
