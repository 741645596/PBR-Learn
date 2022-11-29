
Shader "FB/PostProcessing/TemproalAntiAliasing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            ZWrite Off
            ZTest Always
            Cull off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_YCOCG    
            #pragma shader_feature USE_MOTIONVECTOR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "PostProcess.hlsl"

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

            sampler2D _MainTex;
            sampler2D _PrevTex;
            #if USE_MOTIONVECTOR
                sampler2D _MotionVectorTexture;
            #endif

            float4 _MainTex_TexelSize;
            float4 _TAAParams;
            #define _FeedbackMin            _TAAParams.x
            #define _FeedbackMax            _TAAParams.y
            #define _JitterUV               _TAAParams.zw
            #define _SubpixelThreshold      0.5
            #define _GatherBase             0.5
            #define _GatherSubpixelMotion   0.1666

            Varyings vert (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformWorldToHClip(i.positionOS.xyz);

                // UV
                o.uv = i.uv;
                
                return o;
            }

            float3 sim_tonemapping(float3 c,float adapted_lum){
                return c*rcp(1.0f+adapted_lum);
            }

            float3 inversesim_tonemapping(float3 c,float adapted_lum){
                return c*rcp(max(1.0f-adapted_lum,0.001));
            }

            float3 sample_color(sampler2D tex, float2 uv)
            {
                #if USE_YCOCG
                    float3 c = tex2D(tex, uv).rgb;
                    float luma= Luminance(c);
                    c.rgb = sim_tonemapping(c.rgb,luma);
                    return RGBToYCoCg(c.rgb);
                #else
                    return tex2D(tex, uv).rgb;
                #endif
            }

            float3 resvolve_color(float3 c)
            {
                #if USE_YCOCG
                    c = YCoCgToRGB(c);
                    float luma= Luminance(c);
                    c=inversesim_tonemapping(c,luma);
                    return c;
                #else
                    return c;
                #endif
            }

            float3 clip_aabb(float3 aabb_min, float3 aabb_max, float3 history)
            {
                float3 center = 0.5 * (aabb_max + aabb_min);
                float3 extents = 0.5 * (aabb_max - aabb_min) + FLT_EPS;

                float3 offset = history - center;
                float3 v_unit = offset.xyz / extents;
                float3 a_unit = abs(v_unit);
                float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

                if (ma_unit > 1.0)
                    return center + offset / ma_unit;
                else
                    return history;
            }

            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

            float GetDepth(float2 uv){
                 float offset=3;
                 float2 uv_x_r = uv+float2(offset*_MainTex_TexelSize.x,0);
                 float2 uv_x_l = uv-float2(offset*_MainTex_TexelSize.x,0);
                 float2 uv_y_u = uv+float2(0,offset*_MainTex_TexelSize.y);
                 float2 uv_y_d = uv-float2(0,offset*_MainTex_TexelSize.y);

                 float rawDepth_x_r =  SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv_x_r).r;
                 float rawDepth_x_l =  SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv_x_l).r;
                 float maxX=abs(rawDepth_x_l-rawDepth_x_r);
                 float rawDepth_y_u =  SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv_y_u).r;
                 float rawDepth_y_d =  SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv_y_d).r;
                 float maxY=abs(rawDepth_y_d-rawDepth_y_u);
                 float res =max(maxX,maxY);
                 res = smoothstep(0, 0.006, res);
                 return res;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float2 uv = i.uv - _JitterUV.xy;

                float4 currColor = tex2D(_MainTex, uv);
                #if USE_YCOCG
                    float luma= Luminance(currColor.rgb);
                    currColor.rgb = sim_tonemapping(currColor.rgb,luma);
                    currColor.rgb = RGBToYCoCg(currColor.rgb);
                #endif

                #if USE_MOTIONVECTOR
                    float3 motionVector = tex2D(_MotionVectorTexture, i.uv);
                    float3 prevColor = sample_color(_PrevTex, i.uv - motionVector.xy);
                #else
                
                    float3 prevColor = sample_color(_PrevTex, i.uv);
                #endif
                // Clamping
                float2 ss_offset01 = float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y)*0.2;
                float2 ss_offset11 = float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y)*0.2;

                //
                float3 c00 = sample_color(_MainTex, uv - ss_offset11);
                float3 c10 = sample_color(_MainTex, uv - ss_offset01);
                float3 c01 = sample_color(_MainTex, uv + ss_offset01);
                float3 c11 = sample_color(_MainTex, uv + ss_offset11);
                //
                float3 cmin = min(c00, min(c10, min(c01, c11)));
                float3 cmax = max(c00, max(c10, max(c01, c11)));

                #if USE_YCOCG
                    float2 chroma_extent = 0.25 * 0.5 * (cmax.r - cmin.r);
                    float2 chroma_center = currColor.gb;
                    cmin.yz = chroma_center - chroma_extent;
                    cmax.yz = chroma_center + chroma_extent;
                #endif

                prevColor = clip_aabb(cmin, cmax, prevColor);
                
                // Feedback
                #if USE_YCOCG
                    float lum0 = currColor.r;
                    float lum1 = prevColor.r;
                #else
                    float lum0 = Luminance(currColor.rgb);
                    float lum1 = Luminance(prevColor.rgb);
                #endif

                float unbiased_diff = abs(lum0 - lum1) / max(lum0, max(lum1, 0.2));
                float unbiased_weight = 1.0 - unbiased_diff;
                float unbiased_weight_sqr = unbiased_weight * unbiased_weight;
                float k_feedback = lerp(_FeedbackMin, _FeedbackMax, unbiased_weight_sqr);

                float3 finalColor = lerp(currColor.rgb, prevColor, k_feedback);

                return float4(resvolve_color(finalColor), currColor.a);
            }

            //float4 frag (Varyings i) : SV_Target
            //{
            //    float2 uv = i.uv - _JitterUV.xy;

            //    float4 currColor = tex2D(_MainTex, uv);
            //    #if USE_YCOCG
            //        currColor.rgb = RGBToYCoCg(currColor.rgb);
            //    #endif

            //    #if USE_MOTIONVECTOR
            //        float3 motionVector = tex2D(_MotionVectorTexture, i.uv);
            //        float3 prevColor = sample_color(_PrevTex, i.uv - motionVector.xy);
            //    #else
                
            //        float3 prevColor = sample_color(_PrevTex, i.uv);
            //    #endif
            //    // Clamping
            //    float2 ss_offset01 = float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y);
            //    float2 ss_offset11 = float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y);

            //    //
            //    float3 c00 = sample_color(_MainTex, uv - ss_offset11);
            //    float3 c10 = sample_color(_MainTex, uv - ss_offset01);
            //    float3 c01 = sample_color(_MainTex, uv + ss_offset01);
            //    float3 c11 = sample_color(_MainTex, uv + ss_offset11);
            //    //
            //    float3 cmin = min(c00, min(c10, min(c01, c11)));
            //    float3 cmax = max(c00, max(c10, max(c01, c11)));

            //    #if USE_YCOCG
            //        float2 chroma_extent = 0.25 * 0.5 * (cmax.r - cmin.r);
            //        float2 chroma_center = currColor.gb;
            //        cmin.yz = chroma_center - chroma_extent;
            //        cmax.yz = chroma_center + chroma_extent;
            //    #endif

            //    prevColor = clip_aabb(cmin, cmax, prevColor);
                
            //    // Feedback
            //    #if USE_YCOCG
            //        float lum0 = currColor.r;
            //        float lum1 = prevColor.r;
            //    #else
            //        float lum0 = Luminance(currColor.rgb);
            //        float lum1 = Luminance(prevColor.rgb);
            //    #endif

            //    float unbiased_diff = abs(lum0 - lum1) / max(lum0, max(lum1, 0.2));
            //    float unbiased_weight = 1.0 - unbiased_diff;
            //    float unbiased_weight_sqr = unbiased_weight * unbiased_weight;
            //    float k_feedback = lerp(_FeedbackMin, _FeedbackMax, unbiased_weight_sqr);

            //    float rawDepth =GetDepth(uv);
            //    //return rawDepth;
            //    prevColor=lerp(currColor.rgb,prevColor.rgb,rawDepth);
            //    float3 finalColor = lerp(currColor.rgb, prevColor, k_feedback);

            //    return float4(resvolve_color(finalColor), currColor.a);
            //}
            ENDHLSL
        }
    }
}
