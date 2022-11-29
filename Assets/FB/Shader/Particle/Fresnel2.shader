Shader "FB/Particle/Fresnel2" {
    Properties {
        [KeywordEnum(Off,On)] _Fresnel_VertexAlpha("Fresnel VertexAlpha",Int) = 0

        [Header(Blend Mode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层1 ，one one 是ADD",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 1
        // [Header(Cull Mode)]
        // [Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式 : Off是双面显示，否则一般用 Back",int) =0
        // [Space(10)]
        // [Enum(LEqual,4,Always,8)]_Zalways("层级显示：LEqual默认层级，Always永远在最上层" , int ) = 0
        [HDR]_TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        [MaterialToggle(USINGTOGGLEFRESNEL)]_ToggleFresnel("反向Fresnel开关", int) = 0
        _Fresnelintensity ("Fresnel  intensity", Float ) = 2
        _EXP ("EXP", Float ) = 2
        _Masktex ("Mask tex", 2D) = "white" {}

        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        //[HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector]_Opacity ("Opacity", float) = 1
        _JianBian("JianBian", 2D) = "white" {}

        [HideInInspector]_JianBianClamp("JianBianClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_JianBianRepeatU("JianBianRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_JianBianRepeatV("JianBianRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Blend [_SrcBlend] [_DestBlend]
            Cull back
            ZWrite Off
            //ZTest [_Zalways]
            Offset -1,1
            
            HLSLPROGRAM

            //菲涅尔是否收到顶点Alpha影响
            #pragma multi_compile _ _FRESNEL_VERTEXALPHA_ON
            #pragma multi_compile _ USINGTOGGLEFRESNEL
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                uniform float4 _TintColor;
                uniform float _Fresnelintensity;
                uniform float _EXP;
                int _ToggleFresnel;
                uniform sampler2D _Masktex; uniform float4 _Masktex_ST;
                uniform sampler2D _JianBian; uniform float4 _JianBian_ST;
                half _Opacity;
                int _Fresnel_VertexAlpha;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;
                float _JianBianClamp, _JianBianRepeatU, _JianBianRepeatV;
            CBUFFER_END

            struct VertexInput {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                half4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 WorldNormal : TEXCOORD2;
                half4 vertexColor : COLOR;
             
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                //o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.WorldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                return o;
            }
            half4 frag(VertexOutput i) : COLOR {
                
                float3 normalDirection = normalize(i.WorldNormal);
                float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);  
                float fresnelValue = abs(1.0 - max(0, dot(normalDirection, worldViewDir)));
                
                #if defined(USINGTOGGLEFRESNEL)
                    fresnelValue = saturate(dot(normalDirection, worldViewDir));
                #endif

                float2 jianBianUV = GetUV(TRANSFORM_TEX(float2(fresnelValue, 0), _JianBian), _JianBianClamp, _JianBianRepeatU, _JianBianRepeatV, _JianBian_ST);
                half4 _JianBian_var = tex2D(_JianBian, jianBianUV);
                fresnelValue = fresnelValue * _JianBian_var;

                float fresnel = (pow(fresnelValue,_EXP) * _Fresnelintensity);

                #if _FRESNEL_VERTEXALPHA_ON
					float alphaA = dot(i.vertexColor.rgb, half3(1, 1, 1))/1.732051;
                    fresnel = fresnel * alphaA;
                #endif

                float2 uvMask = GetUV(TRANSFORM_TEX(i.uv0, _Masktex), _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _Masktex_ST);
                half4 _Masktex_var = tex2D(_Masktex, uvMask);
                float3 finalColor = (fresnel * i.vertexColor.rgb * _TintColor.rgb * 2.0 * _Masktex_var.rgb);
                float alpha = fresnel.r * i.vertexColor.a * _TintColor.a * (_Masktex_var.r*_Masktex_var.a)*_Opacity;
                return half4(finalColor * alpha ,alpha);
                
                //return fresnel;
            }
            ENDHLSL
        }
    }
}
