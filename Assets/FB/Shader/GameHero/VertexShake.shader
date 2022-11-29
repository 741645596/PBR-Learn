

Shader "FB/GameHero/VertexShake" {

    Properties{
        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0

        _BaseMap("MainTexture", 2D) = "white" {}
        _Color("MainColor", Color) = (1,1,1,1)

         _ShakeNoiseMap("ShakeNoiseMap", 2D) = "white" {}
         _ShakeStrength("ShakeStrength(强度)", range(0,1)) = 1
         _ShakeFrequency("ShakeFrequency(频率)", range(0.1,10)) = 6
         _ShakeVertexTwist("ShakeVertexTwist(顶点扭动)", range(0,1)) = 0
         _ShakeHorizontalStrength("ShakeHorizontalStrength(水平强度)", range(0,1)) = 0.15
         _ShakeVerticalStrength("ShakeVerticalStrength(垂直强度)", range(0,1)) = 0.05

        _BaseMapTilingOffset("MainTexTilingOffset", Vector) = (1,1,0,0)
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

            #pragma multi_compile _ _HURT_EFFECT_ON

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(URPGroups)

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D_X(_ShakeNoiseMap);
            SAMPLER(sampler_ShakeNoiseMap);
            half4 _Color;
            float4 _BaseMapTilingOffset;

            #if defined(_HURT_EFFECT_ON)
                half _ShakeFrequency;
                half _ShakeVertexTwist;
                half _ShakeHorizontalStrength;
                half _ShakeVerticalStrength;
                half _ShakeStrength;
            #endif

            CBUFFER_END

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD1;
                    float3  normalWS : TEXCOORD2;
                #endif
            };

            float2 GetUv(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            half3 InverseTonemapping(half3 color){
                half3 x = saturate(color);
                half3 a = -10127.0*x*x+13702.0*x+9.0;
                half3 b = 5.0*pow(a,0.5)+295.0*x-15.0;
                half3 c = b/(2008.0-1994*x);
                return c;
            }

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    o.uv0.xy = GetUv(v.texcoord0, _BaseMapTilingOffset);
                    float3 wsPos=TransformObjectToWorld(v.vertex.xyz);

                    #if defined(_HURT_EFFECT_ON)
                        float t=_Time.z*_ShakeFrequency;
                        float offsetU=sin(t);
                        float offsetV=sin(t+offsetU);
                        offsetU = offsetU.x*0.5+0.5;
                        offsetV = offsetV.x*0.5+0.5;
                        float3 fX = SAMPLE_TEXTURE2D_X_LOD(_ShakeNoiseMap,sampler_ShakeNoiseMap, float2(offsetU,-offsetV),0).rgb;
                        fX.xy=(fX.xy-0.5)*2;

                        float vertexU=frac(abs(wsPos.y*offsetV));
                        float vertexOffset =SAMPLE_TEXTURE2D_X_LOD(_ShakeNoiseMap,sampler_ShakeNoiseMap, float2(vertexU,vertexU),0).r;
                        vertexOffset=clamp(vertexOffset,0,1);
                        vertexOffset =lerp(1,vertexOffset,_ShakeVertexTwist);  
                        wsPos.xzy=wsPos.xzy+ float3(fX.xy*_ShakeHorizontalStrength,fX.z*_ShakeVerticalStrength)*vertexOffset*_ShakeStrength;
                    #endif

                    o.pos = TransformWorldToHClip(wsPos);
                    #if defined(UNITY_INSTANCING_ENABLED)
                        o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                    #endif
                    return o;
            }

            half4 frag(VertexOutput i) : COLOR{
               UNITY_SETUP_INSTANCE_ID(i);
               half4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0.xy)* _Color;
               return c;
            }

            ENDHLSL

        }
    }
    FallBack off
}
