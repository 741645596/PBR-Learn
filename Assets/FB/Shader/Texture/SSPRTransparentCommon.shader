
//SSPR 镜面反射 适用于移动端,缺点: Draw Call会翻倍
//如果是非移动端，可以考虑使用SSR屏幕空间反射
//需要 SSPRCamera.cs 支持
// 适用场景：平面反射
Shader "FB/Texture/SSPRTransparentCommon" {

    Properties{
        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0

        [MainTexture] _BaseMap("MainTexture", 2D) = "white" {}
        [MainColor]_Color("MainColor", Color) = (1,1,1,1)

        _BaseMapTilingOffset("MainTexTilingOffset", Vector) = (1,1,0,0)

        _ReflectionLerp("ReflectionLerp",range(0,1)) = 0.3
    }

    SubShader{

        Tags {
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            //ZTest On
            ZTest Always
            ZWrite Off

            Cull[_CullMode]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ ENABLE_SSPR
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D_X(_ReflectionScreenTex);
            SAMPLER(sampler_ReflectionScreenTex);

            CBUFFER_START(UnityPerMaterial)
                half4  _Color;
                float4 _BaseMapTilingOffset;
                half _ReflectionLerp;
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
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD1;
                    float3  normalWS : TEXCOORD2;
                #endif
                float4 screenPos : TEXCOORD3;
            };

            float2 GetUv(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    o.uv0 = GetUv(v.texcoord0, _BaseMapTilingOffset);

                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    #if defined(UNITY_INSTANCING_ENABLED)
                        o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                    #endif

                    o.screenPos = ComputeScreenPos(o.pos);

                    return o;
            }

            half4 frag(VertexOutput i) : SV_Target{
               UNITY_SETUP_INSTANCE_ID(i);

                half4 mainTex =  SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0);

               half4 reflectionScreenTex = SAMPLE_TEXTURE2D(_ReflectionScreenTex,sampler_ReflectionScreenTex, i.screenPos.xy/i.screenPos.w);
               half4 resColor = lerp(half4(mainTex.rgb,1),half4(reflectionScreenTex.rgb,1),_ReflectionLerp)*mainTex.a*_ReflectionLerp;
               return resColor;
            }

            ENDHLSL

        }
    }
    FallBack off
}
