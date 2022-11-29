Shader "FB/Scene/Light/TerrainVertexColor2Layers01" {
	Properties {
		_Splat0 ("Layer 1", 2D) = "white" {}
		_Splat1 ("Layer 2", 2D) = "black" {}
	}
                
	SubShader {
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		LOD 200
		
		Pass {
			Tags { LightMode = UniversalForward }
			
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma require interpolators15
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_Splat0); SAMPLER(sampler_Splat0);
				TEXTURE2D_X(_Splat1); SAMPLER(sampler_Splat1);
				float4  _Splat0_ST;
				float4  _Splat1_ST;
				#ifdef _FOG_OF_WAR_ON
					TEXTURE2D_X(_FogOfWar); SAMPLER(sampler_FogOfWar);
					float _SceneSize;
				#endif

			CBUFFER_END



			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color:COLOR;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float4 worldPos:TEXCOORD2;
				half4 color:TEXCOORD3;
			};
		
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv0 = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.uv1 = TRANSFORM_TEX(v.texcoord, _Splat1);
				o.worldPos =mul(unity_ObjectToWorld,v.vertex);
				o.color=v.color;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float4 lay1 = SAMPLE_TEXTURE2D(_Splat0,sampler_Splat0,i.uv0);
				float4 lay2 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, i.uv1);
				half4 c=half4(lerp(lay1.rgb, lay2.rgb, i.color.a)*i.color.rgb * 2,1);

				#ifdef _FOG_OF_WAR_ON
					half fog = SAMPLE_TEXTURE2D(_FogOfWar, sampler_FogOfWar, float2(i.worldPos.x / _SceneSize + 0.5, i.worldPos.z / _SceneSize + 0.5)).a;
					fog = max(0.3, fog);
					c.rgb *= fog;
				#endif

				return c;
			}

			ENDHLSL
		}
	}
}

