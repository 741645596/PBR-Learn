Shader "FB/PostProcessing/LitePostProcess"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        
        Pass //0
        {
            Tags { "LightMode" = "BloomPreFilter Pass" }
            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex BloomPreFilterVertex
            #pragma fragment BloomPreFilterFrag

            #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"
            
            sampler2D _MainTex;
            half _BloomThreshold;
            #define _BloomClampMax 128

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings BloomPreFilterVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                // UV
                o.uv = i.uv;
                
                return o;
            }

            half4 BloomPreFilterFrag (Varyings i) : SV_Target
            {
                half3 color = tex2D(_MainTex, i.uv).rgb;

                // sample the texture
                //half3 color = tex2D(_MainTex, i.uv).rgb;
                color = min(_BloomClampMax, color);

                // half totalLuminance = LuminanceUE(color);
                // half bloomLuminance = totalLuminance - _BloomThreshold;
                // half bloomAmount = saturate(bloomLuminance * 0.5f);

                half brightness = Max3(color.r, color.g, color.b);
                half ThresholdKnee = _BloomThreshold * 0.5;
                half softness = clamp(brightness - _BloomThreshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
                softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
                half multiplier = max(brightness - _BloomThreshold, softness) / max(brightness, 1e-4);
                color *= multiplier;

                return EncodeHDR(color);
            }
            ENDHLSL
        }

        Pass //1
        {
            Tags { "LightMode" = "Bloom DownSample Pass" }
            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex BloomDownSampleVertex
            #pragma fragment BloomDownSampleFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 uv01         : TEXCOORD0;
                float4 uv23         : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            Varyings BloomDownSampleVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                float f = 0.5;
                // UV
                float4 offset = _MainTex_TexelSize.xyxy * float2(-f, f).xxyy;
                o.uv01.xy = i.uv + offset.xy;
                o.uv01.zw = i.uv + offset.zy;
                o.uv23.xy = i.uv + offset.xw;
                o.uv23.zw = i.uv + offset.zw;

                return o;
            }

            half4 BloomDownSampleFrag (Varyings i) : SV_Target
            {
                half3 s = 0;
                s += tex2D(_MainTex, i.uv01.xy).rgb;
                s += tex2D(_MainTex, i.uv01.zw).rgb;
                s += tex2D(_MainTex, i.uv23.xy).rgb;
                s += tex2D(_MainTex, i.uv23.zw).rgb;
                //
                return half4(s * 0.25f, 1);
            }
            ENDHLSL
        }

        Pass //2
        {
            Tags { "LightMode" = "Bloom UpSample Pass" }
            ZTest Always 
            ZWrite Off
            BlendOp Add
            Blend One One
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex BloomUpSampleVertex
            #pragma fragment BloomUpSampleFrag

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

            Varyings BloomUpSampleVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                // UV
                o.uv = i.uv;

                return o;
            }

            half4 BloomUpSampleFrag (Varyings i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDHLSL
        }

        Pass //3
        {
            Tags { "LightMode" = "Bloom Final Pass" }
            ZTest Always 
            ZWrite Off
            //ColorMask RGB

            HLSLPROGRAM
            #pragma vertex BloomFinalVertex
            #pragma fragment BloomFinalFrag

            //#pragma multi_compile _ ENABLE_LITSCREEN_WRAP ENABLE_LITSCREEN_WRAP_CHROMATIC ENABLE_LITSCREEN_CHROMATIC
            #pragma multi_compile _ ENABLE_BLOOM_HIGHT ENABLE_BLOOM_HIGHT_DIRT
            #pragma shader_feature_local_fragment _ ENABLE_CAP
            #pragma multi_compile _ ENABLE_UNITYEDITOR
            #pragma multi_compile _ NEED_LUT
            #pragma multi_compile _ ENABLE_FINISHCOLOR_LERP ENABLE_FINISHCOLOR_BLENDMUT
            #pragma multi_compile _ ENABLE_SCREEN_VIGNETTE//暗角

            #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"
            

            // Textures
            sampler2D _MainTex;

            #if defined(ENABLE_UNITYEDITOR)
                sampler2D _MainTexEditor;
                float4 _MainTexEditor_TexelSize;
            #endif

            sampler2D _CameraColorTextureST;
            float4 _CameraColorTextureST_TexelSize;
            
            TEXTURE2D(_ColorLut);               SAMPLER(sampler_ColorLut);
            TEXTURE2D(_ColorLutNotACES);               SAMPLER(sampler_ColorLutNotACES);

            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            sampler2D _DistortionTexture;//扭曲

            // Color grading
            float4 _LutParams; 

            // Bloom
            half3 _BloomTintColor;
            half _BloomIntensity;
            half _BloomIterations;

            // Bloom unity
            float4 _Bloom_Params;
            float _Bloom_RGBM;
            float4 _LensDirt_Params;
            float _LensDirt_Intensity;
            TEXTURE2D(_LensDirt_Texture);    

            #define BloomIntensity          _Bloom_Params.x
            #define BloomTint               _Bloom_Params.yzw
            #define BloomRGBM               _Bloom_RGBM.x
            #define LensDirtScale           _LensDirt_Params.xy
            #define LensDirtOffset          _LensDirt_Params.zw
            #define LensDirtIntensity       _LensDirt_Intensity.x

            // Definitions
            #define LutParams           _LutParams.xyz
            #define PostExposure        _LutParams.w

            // Vignette
            half _VignetteIntensity;
            half _VignetteRoughness;
            half _VignetteSmothness;

            // ChromaticAberration
            half _ChromaticAberration;

            half4 _LitPostFinishColor;

            half _LitPostFinishColorLerp;

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 projection : TEXCOORD1;
            };

            half Vignette(float2 uvPar)
            {
                float2 uv=(uvPar - half2(0.5,0.5))*_VignetteIntensity;
                float2 d =float2(abs(uv.x),abs(uv.y));
                d.x=pow(d.x,_VignetteRoughness);
                d.y=pow(d.y,_VignetteRoughness);
                float dist = length(d);
                return pow(saturate(1 - dist * dist), _VignetteSmothness);
            }

            half ChromaticAberrationGChannel(Varyings i)
            {
                half2 coords = 2.0 * i.uv - 1.0;
                half coordDot = dot(coords,coords);
                #if defined(ENABLE_UNITYEDITOR)
                    half2 uvG = i.uv - _MainTexEditor_TexelSize.xy * _ChromaticAberration * coords * coordDot;
                    return tex2D(_MainTexEditor,uvG).g;
                #else
                    half2 uvG = i.uv - _CameraColorTextureST_TexelSize.xy * _ChromaticAberration * coords * coordDot;
                    return tex2D(_CameraColorTextureST,uvG).g;
                #endif
            }

            Varyings BloomFinalVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                // UV
                o.uv = UnityStereoTransformScreenSpaceTex(i.uv);

                o.projection = ComputeScreenPos(o.positionCS);
                return o;
            }

            float3 ACESToneMapping(float3 color) {
                color = color * 0.8;
                float3 A = 2.51;
                float3 B = 0.03;
                float3 C = 2.43;
                float3 D = 0.59;
                float3 E = 0.14;

                return (color*(A*color+B)) / (color*(C*color+D)+E);
            }

            float3 ACESToneMapping(float3 color, float adapted_lum)
            {
                const float A = 2.51f;
                const float B = 0.03f;
                const float C = 2.43f;
                const float D = 0.59f;
                const float E = 0.14f;

                color *= adapted_lum;
                return (color * (A * color + B)) / (color * (C * color + D) + E);
            }

            half2 WrapUv(half2 uv,half2 distortion){
                distortion = clamp(distortion,0, 1);
                half2 m = smoothstep(0,0.3,distortion)*smoothstep(1,0.7,distortion)*0.5;
                distortion=(distortion*2-1)*m;
                uv += distortion.xy;
                uv = clamp(uv, 0, 1);
                return uv;
            }

            half4 BloomFinalFrag (Varyings i) : SV_Target
            {
                float2 uvPra=i.uv.xy;
                #if defined(ENABLE_CAP)//编辑器截图
                    //深度区分模型与背景
                    float2 screenUV = i.projection.xy / i.projection.w;
                    screenUV.y=-_ProjectionParams.x*screenUV.y+clamp(_ProjectionParams.x,0,1);
                    float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                    rawDepth=smoothstep(0.01,0.02,rawDepth);
                #endif
                half4 cameraColorTexture=half4(0,0,0,0);

                //#if defined(ENABLE_LITSCREEN_WRAP) || defined(ENABLE_LITSCREEN_WRAP_CHROMATIC) || defined(ENABLE_LITSCREEN_CHROMATIC)
                //    half4 wrapTex=tex2D(_DistortionTexture, i.uv);
                //    half2 distortion = wrapTex.rg;
                //    i.uv=WrapUv(i.uv,distortion);
                //    #if defined(ENABLE_LITSCREEN_WRAP_CHROMATIC) || defined(ENABLE_LITSCREEN_CHROMATIC)
                //        float2 chromaticOffset = wrapTex.ba*0.3;
                //        #if defined(ENABLE_UNITYEDITOR)
                //            half2 colorR = tex2D(_MainTexEditor, i.uv).ra;
                //            half colorG = tex2D(_MainTexEditor, i.uv+chromaticOffset).g;
                //            half colorB = tex2D(_MainTexEditor, i.uv-chromaticOffset).b;
                //        #else
                //            half2 colorR = tex2D(_CameraColorTextureST, i.uv).ra;
                //            half colorG = tex2D(_CameraColorTextureST, i.uv+chromaticOffset).g;
                //            half colorB = tex2D(_CameraColorTextureST, i.uv-chromaticOffset).b;
                //        #endif
                //        cameraColorTexture = half4(colorR.r,colorG,colorB,colorR.g);
                //    #else
                //        #if defined(ENABLE_UNITYEDITOR)
                //            cameraColorTexture = tex2D(_MainTexEditor, i.uv);
                //        #else
                //            cameraColorTexture = tex2D(_CameraColorTextureST, i.uv);
                //        #endif
                //    #endif
                //#else
                //    #if defined(ENABLE_UNITYEDITOR)
                //        cameraColorTexture = tex2D(_MainTexEditor, i.uv);
                //    #else
                //        cameraColorTexture = tex2D(_CameraColorTextureST, i.uv);
                //    #endif
                //#endif

                #if defined(ENABLE_UNITYEDITOR)
                    cameraColorTexture = tex2D(_MainTexEditor, i.uv);
                #else
                    cameraColorTexture = tex2D(_CameraColorTextureST, i.uv);
                #endif

                half3 color = cameraColorTexture.rgb;

                // Chromatic Aberration
                color.g = ChromaticAberrationGChannel(i);

                #if defined(ENABLE_BLOOM_HIGHT)
                    half4 bloom = tex2D(_MainTex, i.uv);

                    #if UNITY_COLORSPACE_GAMMA
                        bloom.xyz *= bloom.xyz; // γ to linear
                    #endif
                    UNITY_BRANCH
                    if (BloomRGBM > 0)
                    {
                        bloom.xyz = DecodeRGBM(bloom);
                    }
                    bloom.xyz *=BloomIntensity* BloomTint;
                    #if defined(ENABLE_BLOOM_HIGHT_DIRT)
                        {
                            // UVs for the dirt texture should be DistortUV(uv * DirtScale + DirtOffset) but
                            // considering we use a cover-style scale on the dirt texture the difference
                            // isn't massive so we chose to save a few ALUs here instead in case lens
                            // distortion is active.
                            half3 dirt = SAMPLE_TEXTURE2D(_LensDirt_Texture, sampler_LinearClamp, i.uv * LensDirtScale + LensDirtOffset).xyz;
                            dirt *= LensDirtIntensity;
                            bloom.xyz += dirt * bloom.xyz;
                        }
                    #endif

                #else
                    half3 bloom = tex2D(_MainTex, i.uv).rgb / _BloomIterations;
                #endif

                #if !defined(ENABLE_CAP)
                    #if defined(ENABLE_BLOOM_HIGHT)
                        color += bloom.rgb;
                    #else
                        // Bloom
                        color += bloom * _BloomTintColor * _BloomIntensity;
                    #endif
                #endif

                #if NEED_LUT
                    #if UNITY_COLORSPACE_GAMMA
                        {
                            color = SRGBToLinear(color);
                            bloom = SRGBToLinear(bloom);
                        }
                    #endif

                    color *= PostExposure;
                    
                    float3 inputLutSpace = saturate(LinearToLogC(color)); // LUT space is in LogC
                    color=ApplyLut2D(TEXTURE2D_ARGS(_ColorLut, sampler_ColorLut), inputLutSpace, LutParams);
                    
                    // Back to sRGB
                    #if UNITY_COLORSPACE_GAMMA || _LINEAR_TO_SRGB_CONVERSION
                        {
                            color = LinearToSRGB(color);
                        }
                    #endif
                #endif

                // Vignette
                #if defined(ENABLE_SCREEN_VIGNETTE)//暗角
                    color *= Vignette(uvPra);
                #endif

                #if defined(ENABLE_CAP) //截屏
                    half4 res = half4(color, cameraColorTexture.a);
                    rawDepth=clamp(rawDepth+dot(res.rgb,float3(1,1,1)),0,1);
                    res = LinearToSRGB(res);
                    res.rgb=lerp(0,res.rgb,rawDepth);
                    res.a=rawDepth;
                    return res;
                #else
                    #if defined(ENABLE_FINISHCOLOR_LERP)
                        return half4(lerp(color,_LitPostFinishColor.rgb,_LitPostFinishColorLerp), 0);
                    #elif defined(ENABLE_FINISHCOLOR_BLENDMUT)
                        return half4(color*_LitPostFinishColor.rgb, 0);
                    #else
                        return half4(color, 0);
                    #endif
                #endif

            }
            ENDHLSL
        }

        Pass //4
        {
            Tags { "LightMode" = "Bloom Prefilter" }
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma multi_compile_local _ _BLOOM_HQ
            #pragma exclude_renderers gles
            #pragma multi_compile_local _ _USE_RGBM
            #pragma multi_compile _ _USE_DRAW_PROCEDURAL

            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

            TEXTURE2D_X(_MainTex);
            float4 _MainTex_TexelSize;
            TEXTURE2D_X(_SourceTexLowMip);
            float4 _SourceTexLowMip_TexelSize;

            float4 _Params; // x: scatter, y: clamp, z: threshold (linear), w: threshold knee

            #define Scatter             _Params.x
            #define ClampMax            _Params.y
            #define Threshold           _Params.z
            #define ThresholdKnee       _Params.w

            struct BloomAttritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BloomVaryings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            BloomVaryings SceneEffectVertex (BloomAttritubes i)
            {
                BloomVaryings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 EncodeHDR(half3 color)
            {
                #if _USE_RGBM
                    half4 outColor = EncodeRGBM(color);
                #else
                    half4 outColor = half4(color, 1.0);
                #endif

                #if UNITY_COLORSPACE_GAMMA
                    return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
                #else
                    return outColor;
                #endif
            }

            half3 DecodeHDR(half4 color)
            {
                #if UNITY_COLORSPACE_GAMMA
                    color.xyz *= color.xyz; // γ to linear
                #endif

                #if _USE_RGBM
                    return DecodeRGBM(color);
                #else
                    return color.xyz;
                #endif
            }

            half4 SceneEffectFrag (BloomVaryings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);

                //#if _BLOOM_HQ
                //    float texelSize = _MainTex_TexelSize.x;
                //    half4 A = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, -1.0));
                //    half4 B = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.0, -1.0));
                //    half4 C = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, -1.0));
                //    half4 D = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-0.5, -0.5));
                //    half4 E = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.5, -0.5));
                //    half4 F = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, 0.0));
                //    half4 G = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv);
                //    half4 H = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, 0.0));
                //    half4 I = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-0.5, 0.5));
                //    half4 J = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.5, 0.5));
                //    half4 K = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(-1.0, 1.0));
                //    half4 L = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(0.0, 1.0));
                //    half4 M = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + texelSize * float2(1.0, 1.0));

                //    half2 div = (1.0 / 4.0) * half2(0.5, 0.125);

                //    half4 o = (D + E + I + J) * div.x;
                //    o += (A + B + G + F) * div.y;
                //    o += (B + C + H + G) * div.y;
                //    o += (F + G + L + K) * div.y;
                //    o += (G + H + M + L) * div.y;

                //    half3 color = o.xyz;
                //#else
                //half3 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv).xyz;
                //#endif

                half3 color = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv).xyz;

                // User controlled clamp to limit crazy high broken spec
                color = min(ClampMax, color);

                // Thresholding
                half brightness = Max3(color.r, color.g, color.b);
                half softness = clamp(brightness - Threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
                softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
                half multiplier = max(brightness - Threshold, softness) / max(brightness, 1e-4);
                color *= multiplier;

                // Clamp colors to positive once in prefilter. Encode can have a sqrt, and sqrt(-x) == NaN. Up/Downsample passes would then spread the NaN.
                color = max(color, 0);

                return EncodeHDR(color);
            }
            ENDHLSL
        }

        Pass //5
        {
            Tags { "LightMode" = "Bloom Blur Horizontal" }
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma multi_compile_local _ _BLOOM_HQ
            #pragma exclude_renderers gles
            #pragma multi_compile_local _ _USE_RGBM
            #pragma multi_compile _ _USE_DRAW_PROCEDURAL

            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

            TEXTURE2D_X(_MainTex);
            float4 _MainTex_TexelSize;
            TEXTURE2D_X(_SourceTexLowMip);
            float4 _SourceTexLowMip_TexelSize;

            float4 _Params; // x: scatter, y: clamp, z: threshold (linear), w: threshold knee

            #define Scatter             _Params.x
            #define ClampMax            _Params.y
            #define Threshold           _Params.z
            #define ThresholdKnee       _Params.w

            struct BloomAttritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BloomVaryings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            BloomVaryings SceneEffectVertex (BloomAttritubes i)
            {
                BloomVaryings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 EncodeHDR(half3 color)
            {
                #if _USE_RGBM
                    half4 outColor = EncodeRGBM(color);
                #else
                    half4 outColor = half4(color, 1.0);
                #endif

                #if UNITY_COLORSPACE_GAMMA
                    return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
                #else
                    return outColor;
                #endif
            }

            half3 DecodeHDR(half4 color)
            {
                #if UNITY_COLORSPACE_GAMMA
                    color.xyz *= color.xyz; // γ to linear
                #endif

                #if _USE_RGBM
                    return DecodeRGBM(color);
                #else
                    return color.xyz;
                #endif
            }

            half4 SceneEffectFrag (BloomVaryings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float texelSize = _MainTex_TexelSize.x * 2.0;
                float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);

                // 9-tap gaussian blur on the downsampled source
                half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(texelSize * 4.0, 0.0)));
                half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(texelSize * 3.0, 0.0)));
                half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(texelSize * 2.0, 0.0)));
                half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(texelSize * 1.0, 0.0)));
                half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv                               ));
                half3 c5 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(texelSize * 1.0, 0.0)));
                half3 c6 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(texelSize * 2.0, 0.0)));
                half3 c7 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(texelSize * 3.0, 0.0)));
                half3 c8 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(texelSize * 4.0, 0.0)));

                half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
                + c4 * 0.22702703
                + c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

                return EncodeHDR(color);
            }
            ENDHLSL
        }

        Pass //6
        {
            Tags { "LightMode" = "Bloom Blur Vertical" }
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma multi_compile_local _ _BLOOM_HQ
            #pragma exclude_renderers gles
            #pragma multi_compile_local _ _USE_RGBM
            #pragma multi_compile _ _USE_DRAW_PROCEDURAL

            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

            TEXTURE2D_X(_MainTex);
            float4 _MainTex_TexelSize;
            TEXTURE2D_X(_SourceTexLowMip);
            float4 _SourceTexLowMip_TexelSize;

            float4 _Params; // x: scatter, y: clamp, z: threshold (linear), w: threshold knee

            #define Scatter             _Params.x
            #define ClampMax            _Params.y
            #define Threshold           _Params.z
            #define ThresholdKnee       _Params.w

            struct BloomAttritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BloomVaryings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            BloomVaryings SceneEffectVertex (BloomAttritubes i)
            {
                BloomVaryings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 EncodeHDR(half3 color)
            {
                #if _USE_RGBM
                    half4 outColor = EncodeRGBM(color);
                #else
                    half4 outColor = half4(color, 1.0);
                #endif

                #if UNITY_COLORSPACE_GAMMA
                    return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
                #else
                    return outColor;
                #endif
            }

            half3 DecodeHDR(half4 color)
            {
                #if UNITY_COLORSPACE_GAMMA
                    color.xyz *= color.xyz; // γ to linear
                #endif

                #if _USE_RGBM
                    return DecodeRGBM(color);
                #else
                    return color.xyz;
                #endif
            }

            half4 SceneEffectFrag (BloomVaryings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float texelSize = _MainTex_TexelSize.y;
                float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);

                // Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
                half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(0.0, texelSize * 3.23076923)));
                half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv - float2(0.0, texelSize * 1.38461538)));
                half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv                                      ));
                half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(0.0, texelSize * 1.38461538)));
                half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv + float2(0.0, texelSize * 3.23076923)));

                half3 color = c0 * 0.07027027 + c1 * 0.31621622
                + c2 * 0.22702703
                + c3 * 0.31621622 + c4 * 0.07027027;

                return EncodeHDR(color);
            }
            ENDHLSL
        }

        Pass //7
        {
            Tags { "LightMode" = "Bloom Upsample" }
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma multi_compile_local _ _BLOOM_HQ
            #pragma exclude_renderers gles
            #pragma multi_compile_local _ _USE_RGBM
            #pragma multi_compile _ _USE_DRAW_PROCEDURAL

            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

            TEXTURE2D_X(_MainTex);
            float4 _MainTex_TexelSize;
            TEXTURE2D_X(_SourceTexLowMip);
            float4 _SourceTexLowMip_TexelSize;

            float4 _Params; // x: scatter, y: clamp, z: threshold (linear), w: threshold knee

            #define Scatter             _Params.x
            #define ClampMax            _Params.y
            #define Threshold           _Params.z
            #define ThresholdKnee       _Params.w

            struct BloomAttritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BloomVaryings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            BloomVaryings SceneEffectVertex (BloomAttritubes i)
            {
                BloomVaryings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 EncodeHDR(half3 color)
            {
                #if _USE_RGBM
                    half4 outColor = EncodeRGBM(color);
                #else
                    half4 outColor = half4(color, 1.0);
                #endif

                #if UNITY_COLORSPACE_GAMMA
                    return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
                #else
                    return outColor;
                #endif
            }

            half3 DecodeHDR(half4 color)
            {
                #if UNITY_COLORSPACE_GAMMA
                    color.xyz *= color.xyz; // γ to linear
                #endif

                #if _USE_RGBM
                    return DecodeRGBM(color);
                #else
                    return color.xyz;
                #endif
            }

            half3 Upsample(float2 uv)
            {
                half3 highMip = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, uv));

                #if _BLOOM_HQ && !defined(SHADER_API_GLES)
                    half3 lowMip = DecodeHDR(SampleTexture2DBicubic(TEXTURE2D_X_ARGS(_SourceTexLowMip, sampler_LinearClamp), uv, _SourceTexLowMip_TexelSize.zwxy, (1.0).xx, unity_StereoEyeIndex));
                #else
                    half3 lowMip = DecodeHDR(SAMPLE_TEXTURE2D_X(_SourceTexLowMip, sampler_LinearClamp, uv));
                #endif

                return lerp(highMip, lowMip, Scatter);
            }

            half4 SceneEffectFrag (BloomVaryings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half3 color = Upsample(UnityStereoTransformScreenSpaceTex(input.uv));
                return EncodeHDR(color);
            }
            ENDHLSL
        }

        Pass //8
        {
            Tags { "LightMode" = "Gaussion Blur Pass" }
            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex BloomDownSampleVertex
            #pragma fragment BloomDownSampleFrag
            #pragma multi_compile _ GAUSSION_LITPOSTFINAL_LERP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float _PixOffsetSize;

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;

                #if defined(GAUSSION_LITPOSTFINAL_LERP)
                    float2 uv         : TEXCOORD0;
                #else
                    float4 uv01         : TEXCOORD0;
                    float4 uv23         : TEXCOORD1;
                    float4 uv45         : TEXCOORD2;
                    float4 uv67         : TEXCOORD3;
                    float2 uv8         : TEXCOORD4;
                #endif

            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _TurnBlurTex;
            half _BlurLerp;

            Varyings BloomDownSampleVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                #if defined(GAUSSION_LITPOSTFINAL_LERP)
                    o.uv = i.uv;
                #else
                    float f = _PixOffsetSize;
                    // UV
                    float2 offset = _MainTex_TexelSize.xy * f;
                    o.uv01.xy = i.uv +float2(-offset.x,offset.y);
                    o.uv01.zw = i.uv +float2(0,offset.y);
                    o.uv23.xy = i.uv +float2(offset.x,offset.y);
                    o.uv23.zw = i.uv +float2(-offset.x,0);
                    o.uv45.xy = i.uv;
                    o.uv45.zw = i.uv +float2(offset.x,0);
                    o.uv67.xy = i.uv +float2(-offset.x,-offset.y);
                    o.uv67.zw = i.uv +float2(0,-offset.y);
                    o.uv8  = i.uv +float2(offset.x,-offset.y);
                #endif

                return o;
            }

            half4 BloomDownSampleFrag (Varyings i) : SV_Target
            {
                #if defined(GAUSSION_LITPOSTFINAL_LERP)
                    half4 mainColor = half4(tex2D(_MainTex, i.uv));
                    half4 blurColor = half4(tex2D(_TurnBlurTex, i.uv));
                    half4 res = lerp(mainColor,blurColor,_BlurLerp);
                    return res;
                #else
                    half3 s = 0;
                    s += tex2D(_MainTex, i.uv01.xy).rgb;
                    s += tex2D(_MainTex, i.uv01.zw).rgb*2;
                    s += tex2D(_MainTex, i.uv23.xy).rgb;
                    s += tex2D(_MainTex, i.uv23.zw).rgb*2;

                    s += tex2D(_MainTex, i.uv45.xy).rgb*4;
                    s += tex2D(_MainTex, i.uv45.zw).rgb*2;

                    s += tex2D(_MainTex, i.uv67.xy).rgb;
                    s += tex2D(_MainTex, i.uv67.zw).rgb*2;

                    s += tex2D(_MainTex, i.uv8.xy).rgb;
                    //
                    return half4(s/16, 1);
                #endif

            }
            ENDHLSL
        }

        Pass //9
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
            int _ScreenDirectionTurnBlurMaxCount;

            half _BlurRange; //模糊距离
            half _BlurPower; //模糊占比
            half _Step; //模糊偏移单位
            half2 _Center; //模糊中心

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                float2 dir = i.uv.xy - _Center;
                float2 m_Dir = normalize(dir) * _BlurRange;
                float dis = length(dir);
                float lerpValue = saturate(_BlurPower*dis);
                half4 color = half4(0,0,0,0);
                for(int j =0;j<_ScreenDirectionTurnBlurMaxCount;j++){
                    half2 offset = j*_Step*m_Dir*lerpValue;
                    half2 uv1 = i.uv - offset;
                    half2 uv2=i.uv + offset;
                    color += tex2D(_MainTex, uv1);
                    color += tex2D(_MainTex, uv2);
                }
                color = color/(_ScreenDirectionTurnBlurMaxCount*2);
                return color;
            }
            ENDHLSL
        }

        Pass //10 finish color
        {
            Tags { "LightMode" = "Finish Color Pass" }
            ZTest Always 
            ZWrite Off
            BlendOp Add
            Blend One Zero
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile _ ENABLE_FINISHCOLOR_LERP ENABLE_FINISHCOLOR_BLENDMUT

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
            half4 _LitPostFinishColor;
            half _LitPostFinishColorLerp;

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                half4 color = tex2D(_MainTex, i.uv);
                #if defined(ENABLE_FINISHCOLOR_LERP)
                    color.rgb = lerp(color,_LitPostFinishColor.rgb,_LitPostFinishColorLerp);
                    return color;
                #elif defined(ENABLE_FINISHCOLOR_BLENDMUT)
                    color.rgb = color.rgb*_LitPostFinishColor.rgb;
                    return color;
                #else
                    return color;
                #endif
            }
            ENDHLSL
        }
    }
}
