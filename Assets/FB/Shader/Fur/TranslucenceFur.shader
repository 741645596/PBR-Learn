// todo : remove unused feature

Shader "FB/Fur/TranslucenceFur"
{
    Properties
    {
        _FurParams ("Fur Parameters(Length, Density, Thinness, Step)", Vector) = (0.1, 0.01, 1, 0)
        _FurPatternMap ("Fur Pattern Map", 2D) = "white" {}

        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0

        [MainTexture] _BaseMap("MainTexture", 2D) = "white" {}
        [MainColor]_Color("MainColor", Color) = (1,1,1,1)

                _FurPow("FurPow",range(0,5)) = 1

    }

    SubShader
    {
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMapTilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
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
            };

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    o.uv0 = TRANSFORM_TEX(v.texcoord0, _BaseMap);
                    o.pos = TransformObjectToHClip(v.vertex.xyz);

                    return o;
            }

            half4 frag(VertexOutput i) : COLOR{
               UNITY_SETUP_INSTANCE_ID(i);
               half4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0)* UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
               return c;
            }

            ENDHLSL

        }

        Pass {
            Tags{"LightMode" = "Translucence Fur"}

            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest On
            ZWrite Off

            Cull[_CullMode]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMapTilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            float4 _FurParams;
            float    _TranslucenceFurStep;
            float _TranslucenceFurAlphaMul;
           float _FurPow;

            TEXTURE2D_X(_FurPatternMap);
            SAMPLER(sampler_FurPatternMap);

            #define FurLength       _FurParams.x
            #define FurDensity      _FurParams.y
            #define FurThinness     _FurParams.z
            #define FurStep         _TranslucenceFurStep

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            VertexOutput vert(VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _BaseMap);
                float3 positionOS = v.vertex.xyz + v.normal * FurLength *FurStep*lerp(1.5,0.5,FurStep);
                o.pos = TransformObjectToHClip(positionOS);
                return o;
            }

            half4 frag(VertexOutput i) : COLOR{
               UNITY_SETUP_INSTANCE_ID(i);
               float furPatternMapR=SAMPLE_TEXTURE2D(_FurPatternMap, sampler_FurPatternMap, i.uv0*FurThinness).r;
           
               //furPatternMapR=saturate(_TranslucenceFurAlphaMul*(furPatternMapR - (FurStep * FurStep) * FurDensity));
               furPatternMapR=saturate(1*(furPatternMapR - FurStep * FurDensity));

               furPatternMapR=pow(furPatternMapR,_FurPow);

               half4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0)* UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
               c.a=c.a*furPatternMapR;
               return c;
            }

            ENDHLSL

        }

    }


}
