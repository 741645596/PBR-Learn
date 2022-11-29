Shader "WB/AddBlend" {
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendRGB ("BlendSrcRGB", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendRGB ("BlendDstRGB", Float) = 1
        [Space(20)]
        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 4
        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)
        _GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1
    }

    SubShader {
        Tags {
            "Queue" = "Transparent" "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "PerformanceChecks" = "False"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Name "AddBlend"
            Blend[_SrcBlendRGB][_DstBlendRGB]//, [_SrcBlendA][_DstBlendA]
            Cull[_Cull]
            ZWrite[_ZWriteMode]
            Lighting Off
            ZTest [_ZTest]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _GlowScale;
            float _AlphaScale;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float3 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord :TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float2 texcoord :TEXCOORD0;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;
                output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.vertex);
                output.color = input.color;

                return output;
            }

            float4 frag(Varyings in_f) : SV_TARGET
            {
                float2 uv = in_f.texcoord;
                float4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                float4 vertColor = in_f.color;

                float4 col = vertColor * baseCol * _BaseColor;
                col.rgb *= _GlowScale;
                col.a = saturate(col.a * _AlphaScale);
                return col;
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}