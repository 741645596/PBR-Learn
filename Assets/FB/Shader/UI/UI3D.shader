
Shader "FB/UI/UI3D" {
	Properties {
		[MainTexture] _MainTex ("Base Texture", 2D) = "white" {}
		_AlphaTex("Alpha Texture", 2D) = "white" {}
        _FontTex("Font Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
	}

	SubShader {

		Tags 
		{
			"Queue"="Transparent+1500"     //为了跟TextMesh一致
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
			"RenderPipeline" = "UniversalPipeline"
		}

		Lighting Off 
		ZTest Off
		ZWrite Off 
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass 
		{
			Tags {"LightMode"="UniversalForward"}
			//Tags {"LightMode"="Default UI RP"}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 

			TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
			TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
			TEXTURE2D_X(_FontTex); SAMPLER(sampler_FontTex);

			CBUFFER_START(UnityPerMaterial) 
				float4 _MainTex_ST;
				float4 _FontTex_ST;
				half4 _Color;
			CBUFFER_END

			struct appdata_t {
				float4 vertex : POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color*_Color;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                // 以1.5为区分界限，避免误差
				#ifdef UNITY_HALF_TEXEL_OFFSET
					o.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
				#endif
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
                if (i.texcoord.x < 1.5)
                {
					half4 alpha = SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, i.texcoord);
					half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * i.color;
					//color.rgb = LinearToSRGB(color.rgb);
					color.a = color.a * alpha.r;
					return color;
                }
                else
                {
					half4 col_ui = i.color;
					//col_ui.rgb = LinearToSRGB(col_ui.rgb);
                    col_ui.a = SAMPLE_TEXTURE2D(_FontTex, sampler_FontTex, i.texcoord - float2(2, 2)).a;
                    return col_ui;
                }
			}

			ENDHLSL
		}
	}
}

