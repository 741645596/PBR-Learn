

Shader "FB/Texture/AlphaTestCommon" {

    Properties{
        [MainTexture] _BaseMap("MainTexture", 2D) = "white" {}
        [MainColor]_BaseColor("MainColor", Color) = (1,1,1,1)
        _AlphaClip("AlphaClip",Float) = 0.5
    }

    SubShader{

        Tags {
            "IgnoreProjector" = "True"
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest On
            ZWrite On

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
                UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(half, _AlphaClip)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    o.uv0 = v.texcoord0;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    return o;
            }

            half4 frag(VertexOutput i) : SV_Target{
               half4 _Diffuse_var =  SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0);
               half4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
               half alpha = _Diffuse_var.a * baseColor.a;
            //    clip(alpha-UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _AlphaClip));
               return _Diffuse_var * baseColor;
            }

            ENDHLSL

        }
    }
    FallBack off
}
