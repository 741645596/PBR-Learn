Shader "FB/Particle/MaskDistort"
{
    Properties
    {
        [Header(Render Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("混合层1 ，one one 是ADD",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式 : Off是双面显示，否则一般用 Back",int) =0
        [Space(25)]
        _Intensity("整体亮度Intensity",int) = 1
        [HDR]_Color("颜色Color",Color) = (1,1,1,1)
        [Space(5)]
        [MainTexture]_MainTex ("主贴图Texture", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _uvSpeeyX("主贴图uv流速X",int) = 0
        _uvSpeeyY("主贴图uv流速Y",int) = 0
        [Space(25)]
        [Toggle]_MaskEnable("是否启用Mask",int) = 0
        _MaskTex("遮罩MaskTex",2D) = "white" {}

        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _uvMSpeedX("遮罩uv流速X",int) = 0
        _uvMSpeedY("遮罩uv流速Y",int) = 0
        [Space(25)]
        [MaterialToggle(DISTORTENABLE)]_DistortEnable("是否启用扭曲",int) = 0
        _DistortTex("扭曲贴图DistortTex",2D) = "white"{}

        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _Distort("扭曲强度",Range(0,1)) = 1
        _uvDistortSpeedX("扭曲uv流速X",int) = 0
        _uvDistortSpeedY("扭曲uv流速Y",int) = 0
        //_Clip("Clip Amounts",Range(0,1)) = 1
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderPipeline" = "UniversalPipeline"}
        Blend [_SrcFactor] [_DstFactor]
        Cull [_Cull]
        ZWrite Off

        Pass
        {
            AlphaToMask On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //两种shader_feature写法 ,对应属性的 MaterialToggle
            #pragma shader_feature _ _MASKENABLE_ON
            #pragma shader_feature _ DISTORTENABLE 
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
                TEXTURE2D_X(_DistortTex); SAMPLER(sampler_DistortTex);
                float4 _MainTex_ST;
                float _uvSpeeyX,_uvSpeeyY;
                half4 _Color;
                float _Clip;
                half _Intensity;
                float4 _MaskTex_ST;
                float _uvMSpeedX,_uvMSpeedY;
                float4 _DistortTex_ST;
                float _Distort;
                float _uvDistortSpeedX,_uvDistortSpeedY;
                half _Opacity;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;
                float _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV;

            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 uv2 : TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertexColor = v.vertexColor;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex)+float2(_uvSpeeyX,_uvSpeeyY)*_Time.y;
                //顶点着色采样也要做宏处理优化不必要的计算
                #ifdef _MASKENABLE_ON
                    o.uv.zw = TRANSFORM_TEX(v.uv,_MaskTex) + float2(_uvMSpeedX,_uvMSpeedY)*_Time.y;
                #endif
                #ifdef DISTORTENABLE
                    o.uv2 = TRANSFORM_TEX(v.uv,_DistortTex)+float2(_uvDistortSpeedX,_uvDistortSpeedY)*_Time.y;
                #endif

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 c;
                    c = _Color*_Intensity*i.vertexColor;
                float2 distort = i.uv.xy;

                #ifdef DISTORTENABLE
                    float2 uvDistort = GetUV(i.uv2, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV, _DistortTex_ST);
                    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, uvDistort); //要扭曲，先要采样扭曲贴图。
                    distort = lerp(i.uv.xy,distortTex,_Distort);
                #endif

                    float2 uvMain = GetUV(distort, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                    half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain); //原i.uv.xy采样distort
                    c *= maintex;

                #ifdef _MASKENABLE_ON
                    float2 uvMask = GetUV(i.uv.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                    half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                    c *= mask;
                    float alphaChnael = mask.a * maintex.a;
                #endif
                
                c = half4(c.rgb,(_Color.a * maintex.a * i.vertexColor.a)); //.所有的alpha通道相乘得到c的四维向量。
                c.a=c.a*   _Opacity;
                return c;
            }

            ENDHLSL
        }
    }
}
