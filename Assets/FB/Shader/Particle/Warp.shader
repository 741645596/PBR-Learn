Shader "FB/Particle/Wrap"
{
    Properties
    {
        _NoiseTex("NoiseTex(噪音)", 2D) = "black" {}

        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _NoiseTex_Panner("NoiseTex_Panner", Vector) = (0,0,0,0)
        _NoiseStrenght("NoiseStrenght(噪音强度)", Range(0, 1)) = 0.1
        _NoiseCenter("NoiseCenter(阈值)", Range(0.1, 0.9)) = 0.3
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式", Float) = 0
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
                "LightMode" = "WrapPass"
            }
            Cull  [_Cull]
            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)

                float4 _NoiseTex_ST;

                half _NoiseStrenght;
                half _NoiseCenter;
                half2 _NoiseTex_Panner;
                half _DistortTexClamp;
                half _DistortTexRepeatU;
                half _DistortTexRepeatV;

            CBUFFER_END

            TEXTURE2D_X(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            TEXTURE2D_X(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 vertexColor : TEXCOORD1;
                //half4 projection:TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv,_NoiseTex) + frac(_NoiseTex_Panner.xy * _Time.y);
                o.vertexColor = v.vertexColor;
                return o;
            }

            //outBuffer0 - rg:扭曲 ba:色散
            //outBuffer1 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊 a>0 -- 开启了高斯模糊
            //half4 frag(v2f i) : SV_Target
            void frag(v2f i,out half4 outBuffer0 : SV_Target0)
            {
                float2 uvDistort = GetUV(i.uv, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV, _NoiseTex_ST);
                half4 noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvDistort);
                half2 wrapXY = noiseTex * _NoiseStrenght * i.vertexColor.a;

                //表示扭曲  xy:扭曲强度 zw:色散强度
                outBuffer0 = half4(wrapXY,0,0);

            }

            ENDHLSL
        }
    }
    //CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
