
Shader "FB/GameHero/HeroBattleSimpleShadow" {

    Properties{
        _AlphaVal("AlphaVal", range(0,1)) = 1
    }

    SubShader{

        Tags {
            "IgnoreProjector" = "True"
            "Queue" = "Transparent-1"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            Cull back

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _AlphaVal)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD2;
                    float3  normalWS : TEXCOORD3;
                #endif
            };

            float2 GetUv(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    o.uv0 = v.texcoord0;
                    o.pos = TransformObjectToHClip(v.vertex);

                    #if defined(UNITY_INSTANCING_ENABLED)
                        o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                    #endif
                    

                    return o;
            }

            half4 frag(VertexOutput i) : COLOR{
               UNITY_SETUP_INSTANCE_ID(i);
               half min=0.001;
               half max = 0.22;
               half x = i.uv0.x-0.5;
               half y = i.uv0.y-0.5;
               float len = x*x+y*y;
               len = clamp(len,min,max);
               len = (len-min)/(max-min);
               float a = lerp(1,0,len) * 0.8 * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_AlphaVal);

               return half4(0,0,0,a);
            }

            ENDHLSL

        }
    }
    FallBack off
}
