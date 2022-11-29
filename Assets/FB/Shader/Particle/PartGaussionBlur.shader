//高斯模糊  这个是简单版本的高斯模糊 没有for循环
//当径向模糊与高斯模糊同时出现的时候会非常耗 "LightMode" = "GaussianBlurPass" "LightMode" = "ScreenDirectionBlurPass"
Shader "FB/Particle/PartGaussionBlur"
{
    Properties
    {
        _BlurSize("模糊精度",Range(0,3)) = 1
        _BlurPower("模糊强度",Range(0,1)) = 0.3
    }

    SubShader
    {
       Tags {  
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Tags {
                "LightMode" = "GaussianBlurPass"
            }

            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ ENABLE_FULLSCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            CBUFFER_START(UnityPerMaterial)
                half _BlurSize;
                half _BlurPower;
            CBUFFER_END

            struct VertexInput
            {
                float3 positionOS: POSITION;
                float4 uv: TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                #if defined(ENABLE_FULLSCREEN)
                    o.positionCS = float4(v.positionOS.xz*2,1, 1.0);
                #else
                    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                #endif
                o.uv = v.uv.xy;
                return o;
            }

            //outBuffer0 - 高斯模糊参数 //r:模糊强度 g:模糊精度
            //outBuffer1 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
            void frag(VertexOutput i,out half4 outBuffer0 : SV_Target0,out half4 outBuffer1 : SV_Target1)
            {
                //高斯模糊 //r:模糊强度 g:模糊精度
                outBuffer0=half4(_BlurPower,_BlurSize/100,0,0);
                //r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
                outBuffer1=half4(0,0,0,1);
            }

            ENDHLSL
            
        }

    }
}
