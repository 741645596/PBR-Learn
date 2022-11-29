
Shader "FB/UI/Effects_Scroll2TexBendAdd" {
	Properties {

		[MainTexture] _MainTex ("Tex1(RGB)", 2D) = "white" {}
		_MainTex2 ("Tex2(RGB)", 2D) = "white" {}
		_ScrollX ("Tex1 speed X", Float) = 1.0
		_ScrollY ("Tex1 speed Y", Float) = 0.0
		_Scroll2X ("Tex2 speed X", Float) = 1.0
		_Scroll2Y ("Tex2 speed Y", Float) = 0.0
		_Color("Color", Color) = (1,1,1,1)
		_UVXX("UVXX", vector)=(0.3,1,1,1)	
		_MMultiplier ("Layer Multiplier", Float) = 2.0

	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" }
	
		Blend SrcAlpha One
		Cull Off Lighting Off ZWrite Off
		ColorMask RGB
		Fog { Mode Off }
		LOD 100

		Pass {

			Tags {"LightMode"="Default UI RP"}

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 

			TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
			TEXTURE2D_X(_MainTex2); SAMPLER(sampler_MainTex2);

			CBUFFER_START(UnityPerMaterial) 
				float4 _MainTex_ST;
				float4 _MainTex2_ST;
				float _ScrollX;
				float _ScrollY;
				float _Scroll2X;
				float _Scroll2Y;
				float _MMultiplier;
				float4 _UVXX;
				float4 _Color;
			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				half4 color : TEXCOORD1;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time.x);
				o.uv.zw = TRANSFORM_TEX(v.texcoord.xy,_MainTex2) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);

				o.color = _MMultiplier * _Color * v.color;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half4 o;
				half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
				half2 uv=tex.r * _UVXX.x;
				half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv.zw + uv);
				o = tex * tex2 * i.color;

				o.rgb = LinearToSRGB(o.rgb);

				return o;
			}

			ENDHLSL
		}		
	}
}
