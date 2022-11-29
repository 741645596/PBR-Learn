Shader "FB/PostProcessing/WrapAndBlur"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	_AlphaTempTex("Texture1", 2D) = "white" {}
	_AAA("AAA",vector) = (0,0,0,0)
	}
		SubShader
	{
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

		Pass //0
		{
			//简化版 效果略差 扭曲，高斯模糊，径向扭曲会在一个Pass执行 适合中配设备
			Tags { "LightMode" = "WrapAndBlur Pass A" }
			ZTest Always
			ZWrite Off
			BlendOp Add
			Blend One Zero
			ColorMask RGBA

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Frag
			#pragma multi_compile _ ENABLE_SCREEN_WRAP //扭曲
			#pragma multi_compile _ ENABLE_SCREEN_CHROMATIC //色散
			#pragma multi_compile _ ENABLE_SCREEN_SCREENDIRECTIONBLUR //径向模糊
			#pragma multi_compile _ ENABLE_SCREEN_GAUSSIANBLUR_SAMP5 ENABLE_SCREEN_GAUSSIANBLUR_SAMP9 //高斯模糊
			#pragma multi_compile _ ENABLE_SCREEN_VIGNETTE//暗角

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attritubes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _DistortionTexture;//扭曲
			sampler2D _ScreenDirectionBlurTexture;//径向模糊
			sampler2D _GaussionBlurTexture;//高斯模糊
			int _ScreenDirectionBlurForCount;

			// Vignette
			half _VignetteIntensity;
			half _VignetteRoughness;
			half _VignetteSmothness;

			half Vignette(float2 uvPar)
			{
				float2 uv = (uvPar - half2(0.5,0.5)) * _VignetteIntensity;
				float2 d = float2(abs(uv.x),abs(uv.y));
				d.x = pow(d.x,_VignetteRoughness);
				d.y = pow(d.y,_VignetteRoughness);
				float dist = length(d);
				return pow(saturate(1 - dist * dist), _VignetteSmothness);
			}

			half2 WrapUv(half2 uv,half2 distortion) {
				distortion = clamp(distortion,0, 1);
				half2 m = smoothstep(0,0.3,distortion) * smoothstep(1,0.7,distortion) * 0.5;
				distortion = (distortion * 2 - 1) * m;
				uv += distortion.xy;
				uv = clamp(uv, 0, 1);
				return uv;
			}

			Varyings Vertex(Attritubes i)
			{
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			half4 GetMainColor(float2 uv,float2 chromaticOffset) {
				#if defined(ENABLE_SCREEN_CHROMATIC)
					half2 colorR = tex2D(_MainTex, uv).ra;
					half colorG = tex2D(_MainTex, uv + chromaticOffset).g;
					half colorB = tex2D(_MainTex, uv - chromaticOffset).b;
					return half4(colorR.r,colorG,colorB,colorR.g);
				#else
					return tex2D(_MainTex,uv);
				#endif
			}

			half4 Frag(Varyings i) : SV_Target
			{
				float2 uv = i.uv;
				float2 uvPra = uv;
				//色散
				float2 chromaticOffset = float2(0,0);
				//径向模糊
				float4 screenDirectionTex;
				//高斯模糊 简化 没有循环 只有像素范围
				float4 gaussionTex;
				float2 gaussionSize;
				float gaussionLerp;
				float blurP = 0;

				#if defined(ENABLE_SCREEN_SCREENDIRECTIONBLUR)
					screenDirectionTex = tex2D(_ScreenDirectionBlurTexture, uv);
					blurP = blurP + screenDirectionTex.b;
				#endif
				#if defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP5) || defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP9)
					gaussionTex = tex2D(_GaussionBlurTexture, uv);
					gaussionLerp = gaussionTex.r;
					gaussionLerp = saturate(gaussionLerp);
					float p = gaussionTex.g * 200 * gaussionLerp;
					p = clamp(p,0,6);
					gaussionSize = _MainTex_TexelSize.xy * p;
					blurP = saturate(blurP + gaussionLerp);
				#endif

				#if defined(ENABLE_SCREEN_WRAP)
					half4 wrapTex = tex2D(_DistortionTexture, uv);
					wrapTex = lerp(wrapTex,wrapTex * 0.3,blurP);
					half2 distortion = wrapTex.rg;
					uv = WrapUv(uv,distortion);
					#if defined(ENABLE_SCREEN_CHROMATIC)
						chromaticOffset = wrapTex.ba * 0.3;
					#endif
				#endif
				half4 resColor = half4(0,0,0,0);
				#if defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP5) || defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP9)
					half4 mainTex = GetMainColor(uv,chromaticOffset);
					half4 color = half4(0,0,0,0);
					half4 colorGaussion = half4(0,0,0,0);
					float count = 0;
					#if defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP5)
						float2 gaussionUV2 = uv + float2(0,gaussionSize.y);
						float2 gaussionUV4 = uv + float2(-gaussionSize.x,0);
						float2 gaussionUV5 = uv;
						float2 gaussionUV6 = uv + float2(gaussionSize.x,0);
						float2 gaussionUV8 = uv + float2(0,-gaussionSize.y);
						//
						colorGaussion += GetMainColor(gaussionUV2,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV4,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV5,chromaticOffset) * 4;
						colorGaussion += GetMainColor(gaussionUV6,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV8,chromaticOffset) * 2;
						//
						int m = clamp(ceil(p),0.000001,1);
						count = m;
						colorGaussion = (colorGaussion / 12) * m;
					#else
						float2 gaussionUV1 = uv + float2(-gaussionSize.x,gaussionSize.y);
						float2 gaussionUV2 = uv + float2(0,gaussionSize.y);
						float2 gaussionUV3 = uv + float2(gaussionSize.x,gaussionSize.y);
						float2 gaussionUV4 = uv + float2(-gaussionSize.x,0);
						float2 gaussionUV5 = uv;
						float2 gaussionUV6 = uv + float2(gaussionSize.x,0);
						float2 gaussionUV7 = uv + float2(-gaussionSize.x,-gaussionSize.y);
						float2 gaussionUV8 = uv + float2(0,-gaussionSize.y);
						float2 gaussionUV9 = uv + float2(gaussionSize.x,-gaussionSize.y);
						//
						colorGaussion += GetMainColor(gaussionUV1,chromaticOffset);
						colorGaussion += GetMainColor(gaussionUV2,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV3,chromaticOffset);
						colorGaussion += GetMainColor(gaussionUV4,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV5,chromaticOffset) * 4;
						colorGaussion += GetMainColor(gaussionUV6,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV7,chromaticOffset);
						colorGaussion += GetMainColor(gaussionUV8,chromaticOffset) * 2;
						colorGaussion += GetMainColor(gaussionUV9,chromaticOffset);
						//
						int m = clamp(ceil(p),0.000001,1);
						count = m;
						colorGaussion = (colorGaussion / 16) * m;
					#endif

					half4 colorScreenDirection = half4(0,0,0,0);
					#if defined(ENABLE_SCREEN_SCREENDIRECTIONBLUR)
						float2 m_Dir = screenDirectionTex.xy;
						m_Dir = 2 * m_Dir - 1;
						float lerpValue = screenDirectionTex.z;
						lerpValue = saturate(lerpValue);
						float _Step = screenDirectionTex.w / 10;
						for (int j = 0; j < _ScreenDirectionBlurForCount; j++) {
							half2 offset = j * _Step * m_Dir * lerpValue;
							half2 uv1 = uv - offset;
							half2 uv2 = uv + offset;
							colorScreenDirection += GetMainColor(uv1,chromaticOffset);
							colorScreenDirection += GetMainColor(uv2,chromaticOffset);
						}
						int m2 = clamp(ceil(_Step),0.000001,1);
						count = count + m2;
						colorScreenDirection = (colorScreenDirection / (_ScreenDirectionBlurForCount * 2)) * m2;
					#endif
					colorGaussion = lerp(colorGaussion,(colorScreenDirection + colorScreenDirection + colorGaussion) / 3,clamp(count - 1,0.000001,1));
					count = clamp(count,0.000001,2);
					color = (colorScreenDirection + colorGaussion) / count;
					count = clamp(count,0.000001,1);
					resColor = lerp(mainTex,color,count);
				#elif defined(ENABLE_SCREEN_SCREENDIRECTIONBLUR)
					float2 m_Dir = screenDirectionTex.xy;
					m_Dir = 2 * m_Dir - 1;
					float lerpValue = screenDirectionTex.z;
					lerpValue = saturate(lerpValue);
					float _Step = screenDirectionTex.w / 10;
					half4 color = half4(0,0,0,0);
					for (int j = 0; j < _ScreenDirectionBlurForCount; j++) {
						half2 offset = j * _Step * m_Dir * lerpValue;
						half2 uv1 = uv - offset;
						half2 uv2 = uv + offset;
						color += GetMainColor(uv1,chromaticOffset);
						color += GetMainColor(uv2,chromaticOffset);
					}
					color = color / (_ScreenDirectionBlurForCount * 2);
					resColor = color;
				#else
					float4 mainTex = GetMainColor(uv,chromaticOffset);
					resColor = mainTex;
				#endif
				#if defined(ENABLE_SCREEN_VIGNETTE)
					resColor *= Vignette(uvPra);
				#endif

				return resColor;
			}
			ENDHLSL
		}

		Pass //1
		{
			Tags { "LightMode" = "PostProcessing Wrap Pass" }
			ZTest Always
			ZWrite Off
			BlendOp Add
			Blend One Zero
			ColorMask RGBA

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Frag
			#pragma multi_compile _ ENABLE_SCREEN_WRAP //扭曲
			#pragma multi_compile _ ENABLE_SCREEN_CHROMATIC //色散

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attritubes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
			};

			sampler2D _MainTex;
			sampler2D _DistortionTexture;

			half2 WrapUv(half2 uv,half2 distortion) {
				distortion = clamp(distortion,0, 1);
				half2 m = smoothstep(0,0.3,distortion) * smoothstep(1,0.7,distortion) * 0.5;
				distortion = (distortion * 2 - 1) * m;
				uv += distortion.xy;
				uv = clamp(uv, 0, 1);
				return uv;
			}

			Varyings Vertex(Attritubes i)
			{
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			half4 Frag(Varyings i) : SV_Target
			{
				half4 resColor = half4(0,0,0,0);
				#if defined(ENABLE_SCREEN_CHROMATIC)
					#if defined(ENABLE_SCREEN_WRAP)
						half4 wrapTex = tex2D(_DistortionTexture, i.uv);
						half2 distortion = wrapTex.rg;
						i.uv = WrapUv(i.uv,distortion);
						//色散
						half2 co = wrapTex.ba * 0.3;
						half2 cameraColorTextureR = tex2D(_MainTex, i.uv).ra;
						half cameraColorTextureG = tex2D(_MainTex, i.uv + co).g;
						half cameraColorTextureB = tex2D(_MainTex, i.uv - co).b;
						half4 cameraColorTexture = half4(cameraColorTextureR.x,cameraColorTextureG,cameraColorTextureB,cameraColorTextureR.y);
						resColor = cameraColorTexture;
					#else
						half2 wrapTex = tex2D(_DistortionTexture, i.uv).ba;
						//色散
						half2 co = wrapTex.rg * 0.3;
						half2 cameraColorTextureR = tex2D(_MainTex, i.uv).ra;
						half cameraColorTextureG = tex2D(_MainTex, i.uv + co).g;
						half cameraColorTextureB = tex2D(_MainTex, i.uv - co).b;
						half4 cameraColorTexture = half4(cameraColorTextureR.x,cameraColorTextureG,cameraColorTextureB,cameraColorTextureR.y);
						resColor = cameraColorTexture;
					#endif
				#else
					#if defined(ENABLE_SCREEN_WRAP)
						half2 wrapTex = tex2D(_DistortionTexture, i.uv).rg;
						half2 distortion = wrapTex.rg;
						i.uv = WrapUv(i.uv,distortion);
						half4 cameraColorTexture = tex2D(_MainTex, i.uv);
						resColor = cameraColorTexture;
					#else
						half4 cameraColorTexture = tex2D(_MainTex, i.uv);
						resColor = cameraColorTexture;
					#endif

				#endif
				return resColor;
			}
			ENDHLSL
		}

		Pass //2
		{
			Tags { "LightMode" = "Gaussion Blur Pass" }
			ZTest Always
			ZWrite Off
			ColorMask RGBA

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Frag
			#pragma multi_compile _ ENABLE_SCREEN_GAUSSIANBLUR_SAMP5 ENABLE_SCREEN_GAUSSIANBLUR_SAMP9 //高斯模糊

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attritubes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _GaussionBlurTexture;//高斯模糊

			Varyings Vertex(Attritubes i)
			{
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			half4 Frag(Varyings i) : SV_Target
			{
				half4 resColor = half4(0,0,0,0);
				float4 gaussionTex = tex2D(_GaussionBlurTexture, i.uv);
				float gaussionLerp = saturate(gaussionTex.r);
				float p = gaussionTex.g * 200 * gaussionLerp;
				p = clamp(p,0,6);
				float2 offset = _MainTex_TexelSize.xy * p;
				half4 mainTex = tex2D(_MainTex, i.uv);
				half4 s = 0;
				//
				#if defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP5)
					float2 uv01;
					uv01.xy = i.uv + float2(0,offset.y);
					float2 uv23;
					uv23.xy = i.uv + float2(-offset.x,0);
					float4 uv45;
					uv45.xy = i.uv;
					uv45.zw = i.uv + float2(offset.x,0);
					float2 uv67;
					uv67.xy = i.uv + float2(0,-offset.y);
				#else
					float4 uv01;
					uv01.xy = i.uv + float2(-offset.x,offset.y);
					uv01.zw = i.uv + float2(0,offset.y);
					float4 uv23;
					uv23.xy = i.uv + float2(offset.x,offset.y);
					uv23.zw = i.uv + float2(-offset.x,0);
					float4 uv45;
					uv45.xy = i.uv;
					uv45.zw = i.uv + float2(offset.x,0);
					float4 uv67;
					uv67.xy = i.uv + float2(-offset.x,-offset.y);
					uv67.zw = i.uv + float2(0,-offset.y);
					float2 uv8;
					uv8.xy = i.uv + float2(offset.x,-offset.y);
				#endif
					//
					#if defined(ENABLE_SCREEN_GAUSSIANBLUR_SAMP5)
						s += tex2D(_MainTex, uv01.xy) * 2;
						s += tex2D(_MainTex, uv23.xy) * 2;
						s += tex2D(_MainTex, uv45.xy) * 4;
						s += tex2D(_MainTex, uv45.zw) * 2;
						s += tex2D(_MainTex, uv67.xy) * 2;
						resColor = lerp(mainTex,s / 12,gaussionLerp);
					#else
						s += tex2D(_MainTex, uv01.xy);
						s += tex2D(_MainTex, uv01.zw) * 2;
						s += tex2D(_MainTex, uv23.xy);
						s += tex2D(_MainTex, uv23.zw) * 2;
						s += tex2D(_MainTex, uv45.xy) * 4;
						s += tex2D(_MainTex, uv45.zw) * 2;
						s += tex2D(_MainTex, uv67.xy);
						s += tex2D(_MainTex, uv67.zw) * 2;
						s += tex2D(_MainTex, uv8.xy);
						resColor = lerp(mainTex,s / 16,gaussionLerp);
					#endif
					return resColor;
				}
				ENDHLSL
			}

			Pass //3
			{
				Tags { "LightMode" = "Screen Direction Blur Pass" }
				ZTest Always
				ZWrite Off
				BlendOp Add
				Blend One Zero
				ColorMask RGBA

				HLSLPROGRAM
				#pragma vertex Vertex
				#pragma fragment Frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct Attritubes
				{
					float4 positionOS : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct Varyings
				{
					float4 positionCS   : SV_POSITION;
					float2 uv           : TEXCOORD0;
				};

				sampler2D _MainTex;
				sampler2D _ScreenDirectionBlurTexture;
				int _ScreenDirectionBlurForCount;

				Varyings Vertex(Attritubes i)
				{
					Varyings o;
					o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
					o.uv = i.uv;
					return o;
				}

				half4 Frag(Varyings i) : SV_Target
				{
					float4 screenDirectionTex = tex2D(_ScreenDirectionBlurTexture, i.uv);
					float2 m_Dir = screenDirectionTex.xy;
					m_Dir = 2 * m_Dir - 1;
					float lerpValue = screenDirectionTex.z;
					lerpValue = saturate(lerpValue);
					float _Step = screenDirectionTex.w / 10;
					half4 color = half4(0,0,0,0);
					for (int j = 0; j < _ScreenDirectionBlurForCount; j++) {
						half2 offset = j * _Step * m_Dir * lerpValue;
						half2 uv1 = i.uv - offset;
						half2 uv2 = i.uv + offset;
						color += tex2D(_MainTex, uv1);
						color += tex2D(_MainTex, uv2);
					}
					color = color / (_ScreenDirectionBlurForCount * 2);
					return color;

				}
				ENDHLSL
			}

			Pass //4
			{
				Tags { "LightMode" = "Copy Pass" }
				ZTest Always
				ZWrite Off
				BlendOp Add
				Blend One Zero
				ColorMask RGBA

				HLSLPROGRAM
				#pragma vertex Vertex
				#pragma fragment Frag
				#pragma multi_compile _ ENABLE_CLEAR_WRAP
				#pragma multi_compile _ ENABLE_CLEAR_GAUSSION
				#pragma multi_compile _ ENABLE_CLEAR_SCREENDIRECTION

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct Attritubes
				{
					float4 positionOS : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct Varyings
				{
					float4 positionCS   : SV_POSITION;
					float2 uv           : TEXCOORD0;
				};

				sampler2D _MainTex;

				Varyings Vertex(Attritubes i)
				{
					Varyings o;
					o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
					o.uv = i.uv;
					return o;
				}

				half4 Frag(Varyings i) : SV_Target
				{
					half4 resColor = tex2D(_MainTex, i.uv);

					#if defined(ENABLE_CLEAR_WRAP)
						resColor.rg = half2(0,0);
					#endif

					#if defined(ENABLE_CLEAR_GAUSSION)
						resColor.a = 0;
					#endif

					#if defined(ENABLE_CLEAR_SCREENDIRECTION)
						resColor.b = 0;
					#endif
					return resColor;
				}
				ENDHLSL
			}

			Pass //5
			{
				Tags { "LightMode" = "Output Channel" }
				ZTest Always
				ZWrite Off
				BlendOp Add
				Blend One Zero
				ColorMask RGBA

				HLSLPROGRAM
				#pragma vertex Vertex
				#pragma fragment Frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct Attritubes
				{
					float4 positionOS : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct Varyings
				{
					float4 positionCS   : SV_POSITION;
					float2 uv           : TEXCOORD0;
				};

				sampler2D _MainTex;
				sampler2D _AlphaTempTex;
				uniform half3 _AAA;

				Varyings Vertex(Attritubes i)
				{
					Varyings o;
					o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
					o.uv = i.uv;
					return o;
				}

				void Frag(Varyings i)
				{
					half3 resColor = tex2D(_AlphaTempTex, i.uv);
					_AAA.r = resColor.r;
					_AAA.g = resColor.g;
					_AAA.b = resColor.b;
				}
				ENDHLSL
			}

	}
}
