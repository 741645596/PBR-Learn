
Shader "FB/Particle/NoiseWarp"
{

    Properties {
        _MainColor("Color", Color) = (1,1,1,1)
        _DistortTex ("NoiseTexture(噪音遮罩)", 2D) = "black" {}
        _Distort ("NoiseIntensity(扭曲程度)", Range(0, 1)) = 0
        _AlphaMask("透明度遮罩", 2D) = "white" {}
    }

    SubShader {
        //Opaque Transparent
        Tags {
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }

        Pass {
            Tags {
                "LightMode" = "WrapPass"
            }

            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual
            ColorMask RG
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            TEXTURE2D_X(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);
            TEXTURE2D_X(_AlphaMask);
            SAMPLER(sampler_AlphaMask);
            TEXTURE2D_X(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            CBUFFER_START(UnityPerMaterial)
                half4 _NoiseTexture_ST;
                half _NoiseIntensity;
                half4 _MainColor;
            CBUFFER_END

            struct VertexInput {
                half4 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
                half4 vertexColor : COLOR;
            };

            struct VertexOutput {
                half4 pos : SV_POSITION;
                half4 vertexColor : COLOR;
                half2 uv : TEXCOORD2;
                half4 projection:TEXCOORD1;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTexture);

                float3 posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.projection = ComputeScreenPos(o.pos);
                o.projection.z = -TransformWorldToView(posWorld.xyz).z;

                return o;
            }

            ////outBuffer0 - rg:扭曲 ba:色散
            ////outBuffer1 - 径向模糊参数
            ////outBuffer2 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊
            ////half4 frag(VertexOutput i) : SV_Target
            //void frag(VertexOutput i,out half4 outBuffer0 : SV_Target0,out half4 outBuffer1 : SV_Target1,out half4 outBuffer2 : SV_Target2)
            //{
            //    float2 screenUV = i.projection.xy / i.projection.w;
            //    screenUV.y=-_ProjectionParams.x*screenUV.y+clamp(_ProjectionParams.x,0,1);
            //    float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
            //    float  sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams) - _ProjectionParams.g;
            //    sceneZ = max(0, sceneZ);
            //    float partZ = max(0, i.projection.z - _ProjectionParams.g);
            //    float d = smoothstep(0,0.01, sceneZ - partZ);

            //    half4 _alphaTexture = SAMPLE_TEXTURE2D(_AlphaMask, sampler_AlphaMask ,i.uv.xy);
            //    half4 _noiseTexture = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture ,i.uv.xy)*_NoiseIntensity;
            //    half2 wrapXY = (_noiseTexture*d*i.vertexColor.a*_alphaTexture.r*_MainColor.a).xy;

            //    //表示扭曲  xy:扭曲强度 zw:色散强度
            //    outBuffer0 = half4(wrapXY,0,0);
            //    //径向模糊
            //    outBuffer1=half4(0,0,0,0);
            //    //r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊
            //    outBuffer2=half4(1,0,0,0);
            //}

            //outBuffer0 - rg:扭曲 ba:色散
            //outBuffer1 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
            //half4 frag(VertexOutput i) : SV_Target
            void frag(VertexOutput i,out half4 outBuffer0 : SV_Target0)
            {
                float2 screenUV = i.projection.xy / i.projection.w;
                screenUV.y=-_ProjectionParams.x*screenUV.y+clamp(_ProjectionParams.x,0,1);
                float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                float  sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams) - _ProjectionParams.g;
                sceneZ = max(0, sceneZ);
                float partZ = max(0, i.projection.z - _ProjectionParams.g);
                float d = smoothstep(0,0.01, sceneZ - partZ);

                half4 _alphaTexture = SAMPLE_TEXTURE2D(_AlphaMask, sampler_AlphaMask ,i.uv.xy);
                half4 _noiseTexture = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture ,i.uv.xy)*_NoiseIntensity;
                half2 wrapXY = (_noiseTexture*d*i.vertexColor.a*_alphaTexture.r*_MainColor.a).xy;

                //表示扭曲  xy:扭曲强度 zw:色散强度
                outBuffer0 = half4(wrapXY,0,0);

            }

            ENDHLSL
        }

    }
    Fallback "Mobile/Particles/Additive"
    CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
