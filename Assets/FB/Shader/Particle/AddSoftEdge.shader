Shader "FB/Particle/AddSoftEdge" {
    Properties {
        [Header(Cull Mode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式 : Off是双面显示，否则一般用 Back",int) =0
        [Header(ZTest Mode)]
        [Enum(LEqual,4,Always,8)]_ZAlways("层级显示：LEqual默认层级，Always永远在最上层",int) = 4
        // [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层1 ，one one 是ADD",int) = 1
        // [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 0
        [MainTexture]_MainTex ("MainTex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HDR]_TintColor ("Color", Color) = (0.5,0.5,0.5,0.5)
        _Light ("Light", Float ) = 2
        _EdgaSoft ("Edga Soft", Range(0.01, 1)) = 0.15
        _SoftHeight ("Height", Range(-1, 1)) = 0
         [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Blend one one
            Cull [_CullMode]
            ZWrite Off
            ZTest [_ZAlways]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            #pragma target 2.0

            CBUFFER_START(UnityPerMaterial)

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                uniform float4 _MainTex_ST;
                uniform float4 _TintColor;
                uniform float _Light;
                uniform float _EdgaSoft;
                uniform float _SoftHeight;
                uniform half _Opacity;
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
                float4 posWorld : TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            half4 frag(VertexOutput i) : SV_Target{

                float2 uvMain = GetUV(TRANSFORM_TEX(i.uv0, _MainTex), _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                float4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                float3 emissive = (_MainTex_var.rgb * _TintColor.rgb * i.vertexColor.rgb) * _Light; 
                float alpha = i.vertexColor.a * _TintColor.a * _MainTex_var.a*_Opacity;
                float3 finalColor = alpha * emissive*saturate((i.posWorld.g - _SoftHeight)/((_SoftHeight + _EdgaSoft) - _SoftHeight));
                return half4(finalColor,alpha);
            }
            ENDHLSL
        }
    }  
    //CustomEditor "CustomShader_AddAB"
    //Fallback "Hidden/InternalErrorShader"
}
