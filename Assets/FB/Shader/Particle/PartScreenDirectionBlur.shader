//径向模糊
//当径向模糊与高斯模糊同时出现的时候会非常耗 "LightMode" = "GaussianBlurPass" "LightMode" = "ScreenDirectionBlurPass"
Shader "FB/Particle/PartScreenDirectionBlur"
{
    Properties
    {
        _Center("径向中心",Vector)=(0.5,0.5,0,0)
        _Step("Step",Range(0.005,0.015)) = 0.01
        _BlurRange ("模糊范围", Range(0.01, 1)) = 0.5
        _BlurPower("模糊强度",Range(0.1,6)) = 3
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
                "LightMode" = "ScreenDirectionBlurPass"
            }

            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual
            Cull off

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile _ ENABLE_FULLSCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            CBUFFER_START(UnityPerMaterial)
                half _BlurRange;
                half _BlurPower;
                half _Step;
                half2 _Center;
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
                //#if defined(ENABLE_FULLSCREEN)
                    o.positionCS = float4(v.positionOS.xz*2,1, 1.0);
                //#else
                //    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                //#endif
                o.uv = v.uv.xy;
                return o;
            }

            //outBuffer0 - 径向模糊参数 //rg:偏移强度(0-1) //b:模糊强度 //a:_Step
            //outBuffer1 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
            //half4 frag(VertexOutput i) : SV_Target
            void frag(VertexOutput i,out half4 outBuffer0 : SV_Target0,out half4 outBuffer1 : SV_Target1)
            {
                float2 dir = i.uv.xy - _Center;
                float2 m_Dir = normalize(dir) * _BlurRange;
                //m_Dir.y=m_Dir.y*_ProjectionParams.x;
                m_Dir=m_Dir*0.5+0.5;
                float dis = length(dir);

                //径向模糊
                outBuffer0=half4(m_Dir,saturate(_BlurPower*dis),_Step*10);
                //r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
                outBuffer1=half4(0,0,1,0);
            }

            ENDHLSL
            
        }

    }
}
