
Shader "FB/Scene/VertexLit/Diffuse" {
	Properties{
		[MainTexture] _MainTex("Base (RGB)", 2D) = "white" {}
		[Toggle(_THISLIGHTMAP_ON)] _THISLIGHTMAPON("LightMap", Float) = 1
	}
	SubShader{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		LOD 200

		Pass{
			Tags { LightMode = UniversalForward }

			HLSLPROGRAM

			#ifdef _THISLIGHTMAP_ON
				#define LIGHTMAP_ON
			#endif

			#define LIGHTMAP_ON
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _THISLIGHTMAP_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Scene.hlsl" 

			CBUFFER_START(HeroURPGroups)

				TEXTURE2D_X(_MainTex);
				SAMPLER(sampler_MainTex);
				float4 _MainTex_ST;

				#ifdef _FOG_OF_WAR_ON
					TEXTURE2D_X(_FogOfWar);
					SAMPLER(sampler_FogOfWar);
					float _SceneSize;
				#endif

			CBUFFER_END

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;

				#ifdef _THISLIGHTMAP_ON
					DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
				#endif	

				#ifdef _FOG_OF_WAR_ON
					float4 worldPos : TEXCOORD2;
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

				#ifdef _FOG_OF_WAR_ON
							o.worldPos = mul(unity_ObjectToWorld, i.vertex);
				#endif

				#ifdef _THISLIGHTMAP_ON
					OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
				#endif

				return o;
			}

			half4 frag(v2f i) : SV_Target{
				half4 color = half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv0).rgb, 1);
				color.rgb = LinearToGammaSpace(color.rgb);

				#ifdef _FOG_OF_WAR_ON
					half fog = SAMPLE_TEXTURE2D(_FogOfWar, sampler_FogOfWar, float2(i.worldPos.x / _SceneSize + 0.5, i.worldPos.z / _SceneSize + 0.5)).a;
					fog = max(0.3, fog);
					color.rgb *= fog;
				#endif

				#ifdef _THISLIGHTMAP_ON
					half3 lightMapValue = SampleLightmap(i.lightmapUV);
					lightMapValue=(lightMapValue+half3(1.5,1.5,1.5))*0.5;
					color.rgb *= lightMapValue;
				#endif

				color.rgb = GammaToLinearSpace(color.rgb);
				return color;

			}

			ENDHLSL

		}
	}
}


//Shader "S_Game_Scene/Light_VertexLit/Diffuse" {
//	Properties {
//		[MainTexture] _MainTex ("Base (RGB)", 2D) = "white" {}
//	}
//	SubShader {
//		Tags { "RenderType"="Opaque" }
//		LOD 200
//		
//		Pass{
//		Tags { LightMode = UniversalForward }
//		CGPROGRAM
//		#pragma vertex vert
//		#pragma fragment frag
//
//		#include "UnityCG.cginc"
//		
//		sampler2D _MainTex;
//		float4 _MainTex_ST;
//		
//#if _FOG_OF_WAR_ON
//		sampler2D _FogOfWar;
//		float _SceneSize;
//#endif
//
//		struct v2f {
//			float4 pos : SV_POSITION;
//			float2 uv0 : TEXCOORD0;
//			float2 uvLM : TEXCOORD1;
//#if _FOG_OF_WAR_ON
//			float4 worldPos : TEXCOORD2;
//#endif
//		};
//	  
//		struct appdata_lightmap {
//			float4 vertex : POSITION;
//			float2 texcoord : TEXCOORD0;
//			float2 texcoord1 : TEXCOORD1;
//		};
//
//		v2f vert(appdata_lightmap i) {
//			v2f o;
//			o.pos = UnityObjectToClipPos(i.vertex);
//			o.uv0 = TRANSFORM_TEX(i.texcoord, _MainTex);
//			o.uvLM = i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
//#if _FOG_OF_WAR_ON
//			o.worldPos = mul(unity_ObjectToWorld, i.vertex);
//#endif
//			return o;
//		}
//		
//		
//		half4 frag(v2f i) : COLOR {
//			half4 color = half4(tex2D (_MainTex, i.uv0).rgb, 1);
//			color.rgb = LinearToGammaSpace(color.rgb);
//
//#if _FOG_OF_WAR_ON
//			half fog = tex2D (_FogOfWar, float2(i.worldPos.x/_SceneSize + 0.5, i.worldPos.z/_SceneSize + 0.5)).a;
//            fog = max(0.3, fog);
//			color.rgb *= fog;
//#endif
//			color.rgb*=DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM));
//			color.rgb = GammaToLinearSpace(color.rgb);
//
//			return color;
//
//		}
//		ENDCG
//		
//		}
//	} 
//}
