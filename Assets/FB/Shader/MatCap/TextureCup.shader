
Shader "FB/Matcap/TextureCup" {
	Properties {
		[MainTexture] _MainTex ("Base (RGB)", 2D) = "black" {}
		_MaskTex ("Mask (R,G,B)", 2D) = "white" {}
		_CupTex ("Cup Texture", 2D) = "white" {}
		_CupLV	("Cup 强度", Float) = 1.0
	}

	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry+3" "RenderPipeline" = "UniversalPipeline"}
		LOD 100
	
		Pass {
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
		    TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
			TEXTURE2D_X(_CupTex); SAMPLER(sampler_CupTex);

			CBUFFER_START(UnityPerMaterial) 

				half4 _MainTex_ST;
				half4 _CupTex_ST;
				half _CupLV;
			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2	uv : TEXCOORD0;
				half2	uv2 : TEXCOORD1;
			};

			float3 reflect(float3 I,float3 N)
			{
				return I - 2.0 * N * dot(N,I);
			}

			float2 R_To_UV(float3 r)
			{
				float interim = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1.0) * (r.z + 1.0));
				return float2(r.x / interim + 0.5,r.y / interim + 0.5);
			}

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				float3 posEyeSpace = mul(UNITY_MATRIX_MV,v.vertex).xyz;
				float3 I = posEyeSpace - float3(0,0,0);
				float3 N = mul((float3x3)UNITY_MATRIX_MV,v.normal);
				N = normalize(N);
				float3 R = reflect(I,N);
				o.uv2 = R_To_UV(R);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
				half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.xy);
				half4 cuptex = SAMPLE_TEXTURE2D(_CupTex, sampler_CupTex, i.uv2);
				half4 color = lerp(col,col + cuptex * _CupLV,mask.r);
				color.a = 1;

				return color;
			}
	
			ENDHLSL
		}
	}
	Fallback Off
}