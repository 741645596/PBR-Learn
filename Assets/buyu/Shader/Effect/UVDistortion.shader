Shader "WB/UVDistortion" {
    // 纹理扰动效果，扰动数值，扰动的速度以及方向
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("BlendSource", Float) = 5
        [Enum(One, 1 , OneMinusSrcAlpha, 10 )] _DstBlend ("BlendDestination", Float) = 1
        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 4
        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)
        _GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1
        _MainSpeed("MainTex Speed", Vector) = (0,0,0,0)

        _UVNoiseTex("NoiseTex", 2D) = "black" {}
        _UVDistortion("UVDistortion", Float) = 0.5
        _NoiseScroll("NoiseScroll", Vector) = (0,-0.1,1,1)

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
            Name "AddBlend"
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
            float4 _MainSpeed;
            float _GlowScale;
            float _AlphaScale;

            float4 _UVNoiseTex_ST;
            float _UVDistortion;
            float4 _NoiseScroll;

            CBUFFER_END
            sampler2D _UVNoiseTex;
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
                float2 texcoordNoise: TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.texcoordNoise = TRANSFORM_TEX(input.texcoord, _UVNoiseTex);
                output.positionCS = TransformObjectToHClip(input.vertex);
                output.color = input.color;
                return output;
            }


            float4 frag(Varyings in_f) : SV_TARGET
            {
                float2 uvMain = in_f.texcoord;
                float t = abs(frac(_Time.y * 0.01));
                float calcTime = t * 100;

                uvMain += _MainSpeed.xy * calcTime;
                float2 pivot = 0.5; //_UVRotate.xy;
                roateUV(_MainSpeed.zw, calcTime, pivot, uvMain);

                float2 noiseScrollXY = _NoiseScroll.xy;
                in_f.texcoordNoise.xy += float2(calcTime * noiseScrollXY);
                float2 noiseMask = tex2D(_UVNoiseTex, in_f.texcoordNoise.xy).xy * _UVDistortion * _NoiseScroll.zw;
                uvMain.xy += noiseMask;

                float4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvMain);
                float4 col = in_f.color * baseCol * _BaseColor;
                col.rgb *= _GlowScale;
                col.a = saturate(col.a * _AlphaScale);
                return col;
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}