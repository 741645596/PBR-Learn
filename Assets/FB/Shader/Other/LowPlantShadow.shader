Shader "FB/Other/LowPlantShadow" {
    Properties {
        [MainTexture] _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"}
        Pass {

            Blend Zero SrcColor
            ZWrite Off
            Cull Off
            Lighting Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                uniform float4 _MainTex_ST;

            CBUFFER_END
            
            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.pos = TransformObjectToHClip( v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target{
                UNITY_SETUP_INSTANCE_ID(i);
                half4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv0);
                return _MainTex_var;
            }

            ENDHLSL
        }
    }
}
