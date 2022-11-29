
Shader "FB/Particle/ObjectDouble"
{
	Properties
	{
		[MainTexture] _MainTex("Diffuse (RGB)", 2D) = "grey" {}
		_LightTex("LightTex (RGB)", 2D) = "white" {}
		_LightScale("LightScale", float) = 1
	}
		
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest+1" "IgnoreProjector" = "True""RenderPipeline" = "UniversalPipeline" }
		LOD 200
		Cull Off
		Fog{ Mode Off }
		
		Pass
		{
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile _DUMMY _LIGHT_TEX_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(HeroURPGroups)

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_LightTex); SAMPLER(sampler_LightTex);
				float4 _MainTex_ST;
				half _LightScale;

			CBUFFER_END

			struct appdata_base {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0; 
				#ifdef _LIGHT_TEX_ON
					half3 normalVS: TEXCOORD1;
				#endif
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				#ifdef _LIGHT_TEX_ON
					o.normalVS = mul(UNITY_MATRIX_MV, float4(v.normal, 0)).xyz;
				#endif
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
				#ifdef _LIGHT_TEX_ON
					half2 uv = normalize(i.normalVS).xy * 0.5 + 0.5;
					half4 light = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, uv);
					color.rgb *= light.rgb * _LightScale;
				#endif
				return color;
			}
			
			ENDHLSL
		}
	}

}

