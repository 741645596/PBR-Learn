

Shader "FB/Texture/DefaultColorCommon" {

    Properties{
        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0
        [MainColor]_Color("MainColor", Color) = (1,1,1,1)
    }

    SubShader{

        Tags {
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            ZTest On
            ZWrite On

            Cull[_CullMode]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v, o);
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    return o;
            }

            half4 frag(VertexOutput i) : SV_Target{
               UNITY_SETUP_INSTANCE_ID(i);
               return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
            }

            ENDHLSL

        }
    }
    FallBack off
}
