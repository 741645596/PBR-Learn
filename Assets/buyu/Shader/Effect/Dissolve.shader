Shader "WB/Dissolve" {
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("BlendSource", Float) = 5
        [Enum(One, 1 , OneMinusSrcAlpha, 10 )] _DstBlend ("BlendDestination", Float) = 1

        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 2

        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)

        _UVBaseScroll("Base UVScroll", Vector) = (0,0,0,0)


        _GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1

        _CutOut("CutOut", Range(0, 1)) = 1
        _UseSoftCutout("Use Soft Cutout", Int) = 0
        _UseParticlesAlphaCutout("Use Particles Alpha", Int) = 0

        [Toggle(USE_CUTOUT_TEX)] _UseCutoutTex("Use Cutout Texture", Int) = 0
        _CutoutTex("Cutout Tex(R)", 2D) = "white" {}
        [HDR]_CutoutColor("Cutout Color", Color) = (0,0,0,1)
        _UVCutOutScroll("Cutout UVScroll", Vector) = (0,0,0,0)
        _CutoutThreshold("Cutout Threshold", Range(0, 1)) = 0.015
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

        // ------------------------------------------------------------------
        //  Forward pass.
        Pass {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Blend[_SrcBlend][_DstBlend]
            Cull[_Cull]
            ZWrite[_ZWriteMode]
            Lighting Off
            ZTest [_ZTest]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile __ USE_CUTOUT_TEX
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float2 _UVBaseScroll;

            #ifdef USE_CUTOUT_TEX
            float4 _CutoutTex_ST;
            #endif

            float _UseSoftCutout;
            float _UseParticlesAlphaCutout;

            float _CutOut;
            float4 _CutoutColor;
            float _CutoutThreshold;

            float2 _UVCutOutScroll;

            float _GlowScale;
            float _AlphaScale;

            CBUFFER_END
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_CutoutTex);
            SAMPLER(sampler_CutoutTex);

            struct AttributesParticle
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float3 texcoord : TEXCOORD0;
            };

            struct VaryingsParticle
            {
                float4 positionCS : SV_POSITION;
                float4 mainUV : TEXCOORD0;
                float4 color : COLOR;
                float age_percent : TEXCOORD3;
            };

            VaryingsParticle vertParticleUnlit(AttributesParticle input)
            {
                VaryingsParticle output = (VaryingsParticle)0;

                output.positionCS = TransformObjectToHClip(input.vertex.xyz);

                output.color = input.color;

                output.mainUV.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);

                if (input.texcoord.z == 0)
                    output.age_percent = 1;
                else
                    output.age_percent = input.texcoord.z;

                #ifdef USE_CUTOUT_TEX
                output.mainUV.zw = TRANSFORM_TEX(input.texcoord, _CutoutTex);
                #endif
                return output;
            }

            float4 fragParticleUnlit(VaryingsParticle fInput) : SV_Target
            {
                float4 vertColor = fInput.color;
                float2 uv = fInput.mainUV.xy;

                float t = abs(frac(_Time.y * 0.01));
                float calcTime = t * 100;

                float4 mainTexColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv + calcTime * _UVBaseScroll.xy);

                half4 col = mainTexColor * _BaseColor;

                float cutout = _CutOut * fInput.age_percent;
                cutout = lerp(cutout, (1.001 - vertColor.a + cutout), _UseParticlesAlphaCutout);

                #ifdef USE_CUTOUT_TEX
                float2 cutoutUV = fInput.mainUV.zw + _UVCutOutScroll.xy * calcTime;
                float mask = SAMPLE_TEXTURE2D(_CutoutTex, sampler_CutoutTex, cutoutUV).r;
                #else
                    float mask = mainTexColor.a;
                #endif

                float diffMask = mask - cutout;
                float alphaMask = lerp(
                    saturate(diffMask * 10000) * col.a,
                    saturate(diffMask * 2) * col.a,
                    _UseSoftCutout);

                float alphaMaskThreshold = saturate((diffMask - _CutoutThreshold) * 10000) * col.a;
                float3 col2 = lerp(col.rgb, _CutoutColor.rgb, saturate((1 - alphaMaskThreshold) * alphaMask));
                col.rgb = lerp(col.rgb, col2, step(0.01, _CutoutThreshold));
                col.a = alphaMask;

                col *= vertColor;

                col.a = saturate(col.a * _AlphaScale);
                return col;
            }

            #pragma vertex vertParticleUnlit
            #pragma fragment fragParticleUnlit
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}