Shader "WB/UVMask" {
    // 纹理流动效果，UV速度调整，Mask遮罩，Mask 速度调整
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("BlendSource", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("BlendDestination", Float) = 1
        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 4
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)
        _GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1
        _BaseColorSpeed("Base Color Speed", Vector) = (1,1,0,0)

        _Mask("Mask", 2D) = "white" {}
        _MaskSpeed("mask speed", Vector) = (0,0,0,0)
    }

    SubShader {
        Tags {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "PerformanceChecks" = "False"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Name "UVMask"
            Blend[_SrcBlend][_DstBlend]
            Cull[_Cull]
            ZWrite[_ZWriteMode]
            Lighting Off
            ZTest [_ZTest]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../ColorCore.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _GlowScale;
            float _AlphaScale;
            float4 _BaseColorSpeed;
            float4 _Mask_ST;
            float4 _MaskSpeed;

            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);

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
                float2 texcoordMask: TEXCOORD1;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;
                output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.texcoordMask = TRANSFORM_TEX(input.texcoord, _Mask);
                output.positionCS = TransformObjectToHClip(input.vertex);
                output.color = input.color;
                return output;
            }

            float4 frag(Varyings in_f) : SV_TARGET
            {
                float2 pivot = 0.5; //_UVRotate.xy;
                float t = abs(frac(_Time.y * 0.01));
                float calcTime = t * 100;

                float2 uv = in_f.texcoord;
                uv += _BaseColorSpeed.xy * calcTime;
                roateUV(_BaseColorSpeed.zw, calcTime, pivot, uv);
                float4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                float2 uvMask = in_f.texcoordMask;
                uvMask += _MaskSpeed.xy * calcTime;
                roateUV(_MaskSpeed.zw, calcTime, pivot, uvMask);
                float4 maskCol = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, uvMask);

                float4 col = in_f.color * baseCol * _BaseColor;
                col.rgb *= _GlowScale;
                col.a = saturate(col.a) * _AlphaScale;

                col.a = saturate(col.a * maskCol.r * in_f.color.a * _BaseColor.a);
                return col;
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}