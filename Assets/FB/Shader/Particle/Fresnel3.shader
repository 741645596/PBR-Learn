Shader "FB/Particle/Fresnel3"
{
    Properties
    {
        [KeywordEnum(Off,On)] _Fresnel_VertexAlpha("Fresnel VertexAlpha",Int) = 0

        [Header(Blend Mode)]
        //[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("混合层1 ，one one 是ADD", int) = 1
        //[Enum(Add, 1, AlphaBlend, 11)]_DestBlend ("混合层", int) = 1
        // [Header(Cull Mode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0
        // [Space(10)]
        // [Enum(LEqual,4,Always,8)]_Zalways ("层级显示：LEqual默认层级，Always永远在最上层", int ) = 0
        [Space(10)]
        [HDR]_FresnelColor ("Fresnel 颜色", Color) = (0.5, 0.5, 0.5, 1)
        [MaterialToggle(USINGTOGGLEFRESNEL)]_ToggleFresnel("反向Fresnel开关", int) = 0
        _Fresnelintensity ("Fresnel 强度", Range(0, 3)) = 1
        _FresnelRange ("FresnelRange 范围", Range(0.01, 1)) = 0.5
        [Header(Texture)]
        [HDR]_TintColor ("MainColor", Color) = (0.5, 0.5, 0.5, 1)
        [MainTexture]_MainTex ("Main tex", 2D) = "white" { }

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _Masktex ("Mask tex", 2D) = "white" { }

        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _MaskUSpeed("Mask U Speed", Float) = 0
        _MaskVSpeed("Mask V Speed", Float) = 0
        _Alpha ("All Alpha", Range(0, 1)) = 1
        _HurtColor("HurtColor", vector) = (0,0,0,0)
        //[HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector] _PlayerId("Player ID", float) = 0
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Pass
        {
            //Blend [_SrcBlend] [_DestBlend]
            Blend One One
            Cull [_CullMode]
            ZWrite On
            //ZTest [_Zalways]
            
            HLSLPROGRAM
            
            //菲涅尔是否收到顶点Alpha影响
            #pragma multi_compile _ _FRESNEL_VERTEXALPHA_ON
            #pragma multi_compile _ USINGTOGGLEFRESNEL
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _TintColor, _FresnelColor;
                half _Fresnelintensity;
                half _FresnelRange, _Alpha;
                float4 _Masktex_ST, _MainTex_ST;
                half _Opacity;
                uniform float _MaskUSpeed;
                uniform float _MaskVSpeed;
                int _Fresnel_VertexAlpha;
                int _ToggleFresnel;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;
            CBUFFER_END
            
            TEXTURE2D(_Masktex);SAMPLER(sampler_Masktex);
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct VertexInput
            {
                float3 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 uv: TEXCOORD0;
                half4 vertexColor: COLOR;
            };
            struct VertexOutput
            {
                float4 positionCS: SV_POSITION;
                float4 uv: TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float3 WorldNormal: TEXCOORD2;
                half4 vertexColor: TEXCOORD3;
                // float2 uv1: TEXCOORD4;
            };
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.vertexColor = v.vertexColor;
                //o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.WorldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                float2 anim = float2(_MaskUSpeed * _Time.g, _MaskVSpeed * _Time.g);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _Masktex) + anim;

                return o;
            }
            half4 frag(VertexOutput i): COLOR
            {
                
                float3 normalDirection = normalize(i.WorldNormal);
                float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                half fresnel;
                fresnel = pow(saturate(1.0 - dot(normalDirection, worldViewDir)), _FresnelRange * 3) * _Fresnelintensity * 2;

                #if defined(USINGTOGGLEFRESNEL)
                    fresnel = pow(saturate(dot(normalDirection, worldViewDir)), _FresnelRange * 3) * _Fresnelintensity * 2;
                #endif
                half4 fresnelColor = fresnel * _FresnelColor;

                #if _FRESNEL_VERTEXALPHA_ON
					float alphaA = dot(i.vertexColor.rgb, half3(1, 1, 1))/1.732051;
                    fresnel *= alphaA;
                #endif

                float2 uvMask = GetUV(i.uv.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _Masktex_ST);
                half4 maskTex = SAMPLE_TEXTURE2D(_Masktex, sampler_Masktex, uvMask);

                float2 uvMain = GetUV(i.uv.xy, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);

                float4 finalColor = i.vertexColor * _TintColor * maskTex * mainTex;
                finalColor += (fresnel * maskTex);
                finalColor *= _Alpha*_Opacity;
                return finalColor;

            }
            ENDHLSL
            
        }
    }
}
