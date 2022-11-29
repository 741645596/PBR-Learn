
Shader "Text Effects/Fancy Text Fallback"
{
	Properties
	{
		_Color ("Main Color", color) = (1, 1, 1, 1)
		[MainTexture]_MainTex ("Font Texture", 2D) = "white" {}
		[HideInInspector] _OverlayTex("Overlay Texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"RenderPipeline" = "UniversalPipeline"
		}
		Lighting Off 
		Cull Off 
		ZTest Always 
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		Pass
		{
			HLSLPROGRAM

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USEOVERLAYTEXTURE_ON
			#pragma multi_compile __ _USEBEVEL_ON
			#pragma multi_compile __ _USEOUTLINE_ON

			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_OverlayTex); SAMPLER(sampler_OverlayTex);
				half4 _Color;
				int _OverlayTextureColorMode;
				half4 _HighlightColor;
				int _HighlightColorMode;
				half4 _ShadowColor;
				int _ShadowColorMode;
				half2 _HighlightOffset;
				half4 _OutlineColor;
				half _OutlineThickness;
				int _OutlineColorMode;
				float4 _MainTex_ST;
				float4 _MainTex_TexelSize;
				float4 _OverlayTex_ST;
			CBUFFER_END
			
			struct appdata_t {
				float4 vertex : POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;

				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 texcoordOverlay : TEXCOORD1;

				float4 tangent : TEXCOORD2;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color * _Color;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.texcoordOverlay = v.texcoord1;
				o.tangent = v.tangent;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				float factor = min(i.texcoordOverlay.x, 1);

				half4 col = i.color;
				col.a *= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).a;

				#ifdef _USEOVERLAYTEXTURE_ON
					half3 colOverlay = SAMPLE_TEXTURE2D(_OverlayTex, sampler_OverlayTex, i.texcoordOverlay - float2(1, 1)).rgb;
					if (_OverlayTextureColorMode == 0)
					{
						col.rgb = lerp(col.rgb, colOverlay, factor);
					}
					else if (_OverlayTextureColorMode == 1)
					{
						col.rgb = col.rgb + colOverlay * factor;
					}
					else
					{
						col.rgb = lerp(col.rgb, col.rgb * colOverlay, factor);
					}
				#endif

				#ifdef _USEBEVEL_ON
					half2 highlightOffset = _HighlightOffset.x * half2(i.tangent.xy) - _HighlightOffset.y * half2(i.tangent.zw);

					col.rgb = lerp(col.rgb, _ShadowColor.rgb, (1 - SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + highlightOffset).a) * _ShadowColor.a * factor);

					col.rgb = lerp(col.rgb, _HighlightColor.rgb, (1 - SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - highlightOffset).a) * _HighlightColor.a * factor);
				#endif

				#ifdef _USEOUTLINE_ON
					float alpha = 8;

					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0, _OutlineThickness)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0, -_OutlineThickness)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(_OutlineThickness, 0)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-_OutlineThickness, 0)).a;

					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.707 * _OutlineThickness, 0.707 * _OutlineThickness)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-0.707 * _OutlineThickness, 0.707 * _OutlineThickness)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.707 * _OutlineThickness, -0.707 * _OutlineThickness)).a;
					alpha -= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-0.707 * _OutlineThickness, -0.707 * _OutlineThickness)).a;

					alpha = clamp(alpha, 0, 1) * _OutlineColor.a * factor;

					if (_OutlineColorMode == 0)
					{
						col.rgb = lerp(col.rgb, _OutlineColor.rgb, alpha);
					}
					else if (_OutlineColorMode == 1)
					{
						col.rgb = col.rgb + _OutlineColor.rgb * alpha;
					}
					else
					{
						col.rgb = lerp(col.rgb, col.rgb * _OutlineColor.rgb, alpha);
					}
				#endif
				
				return col;
			}
			
			ENDHLSL
		}
	}
	
	Fallback "Unlit/Texture"
}
