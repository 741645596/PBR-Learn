Shader "FB/Particle/AlphaBlend" {
    Properties {
        [Enum(LEqual, 4, Always, 8)] _ZAlways("�㼶��ʾ��LEqualĬ�ϲ㼶��Always��Զ�����ϲ�", int) = 4
        [MainTexture] _MainTex ("MainTex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        [HDR]_TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        _Intensitity ("Intensitity", Float ) = 2
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        ZTest[_ZAlways]
        Pass {

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                uniform float4 _MainTex_ST;
                half4 _TintColor;
                float _Intensitity;
                half _Opacity;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;

            CBUFFER_END

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip( v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target{

                float2 uvMain = GetUV(i.uv0, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV,_MainTex_ST);
                half4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uvMain);
                //_MainTex_var = GetTextColor(_MainTex_var, uvMain, _MainTexRepeatU, _MainTexRepeatV);

                float _alphaChanel = (_MainTex_var.a*i.vertexColor.a*_TintColor.a)*_Opacity;
                float3 emissive = ((_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*_Intensitity)*_alphaChanel);
                float3 finalColor = emissive;
                return half4(finalColor,_alphaChanel);
            }
            ENDHLSL
        }
    }
}
