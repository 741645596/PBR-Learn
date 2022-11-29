Shader "WB/FXUVDistMskExt" {
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("BlendSource", Float) = 5
        [Enum(One, 1 , OneMinusSrcAlpha, 10 )] _DstBlend ("BlendDestination", Float) = 1
        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 2

        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)
        _GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1

        _MainSpeed("MainTex Speed", Vector) = (0,0,0,0)
        [ToggleUI] _CustomUV("自定义主贴图UV偏移曲线TEXCOORD1.xy", Float) = 1.0

        [Space(20)]
        _UVNoiseTex("UVNoiseTex", 2D) = "black" {}
        _UVDistortion("UVDistortion", Float) = 0
        _UVScrollDir("NoiseScroll", Vector) = (0,0,1,1)

        [Space(20)]
        _MaskTex("Mask ( R Channel )", 2D) = "white" {}
        _MaskSpeed("MaskTex Speed", Vector) = (0,0,0,0)

        [Space(20)]
        _CutOut("CutOut", Range(0, 1)) = 0
        [ToggleUI] _CustomCutOut("自定义CutOut曲线TEXCOORD1.z", Float) = 0
        _UseSoftCutout("Use Soft Cutout", Int) = 0
        _UseParticlesAlphaCutout("Use Particles Alpha", Int) = 0
        [ToggleUI] _UseCutoutTex("Use Cutout Texture", Float) = 0
        _CutoutTex("Cutout Tex(R)", 2D) = "white" {}
        [HDR]_CutoutColor("Cutout Color", Color) = (0,0,0,1)
        _UVCutOutScroll("Cutout UVScroll", Vector) = (0,0,0,0)
        _CutoutThreshold("Cutout Threshold", Range(0, 1)) = 0
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
            Name "ForwardLit"
            Blend[_SrcBlend][_DstBlend]
            Cull[_Cull]
            ZWrite[_ZWriteMode]
            Lighting Off
            ZTest [_ZTest]
            HLSLPROGRAM
            #include "../ColorCore.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _MainSpeed;
            float _CustomUV;
            float4 _MaskTex_ST;

            float4 _UVNoiseTex_ST;
            float4 _UVScrollDir;
            float _UVDistortion;

            float _UseCutoutTex;
            float4 _CutoutTex_ST;
            float _CutOut;
            float _CustomCutOut;
            float _UseSoftCutout;
            float _UseParticlesAlphaCutout;
            float4 _CutoutColor;
            float _CutoutThreshold;
            float2 _UVCutOutScroll;

            float _GlowScale;
            float _AlphaScale;
            float4 _MaskSpeed;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);

            TEXTURE2D(_UVNoiseTex);
            SAMPLER(sampler_UVNoiseTex);

            TEXTURE2D(_CutoutTex);
            SAMPLER(sampler_CutoutTex);
            struct AttributesParticle
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float4 texCoord0 : TEXCOORD0;
                float4 texCoordCst : TEXCOORD1;
            };

            struct VaryingsParticle
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;

                float2 texcoord : TEXCOORD0;
                float4 texcoordNoise: TEXCOORD1;
                float2 texcoordMask : TEXCOORD4;
                float3 CustData : TEXCOORD3;
            };

            void distorUVbyTex(float2 noiseUV,float calcTime, inout float2 uvMain)
            {
                float2 scrollDir = _UVScrollDir.xy;
                float2 distStr = _UVScrollDir.zw;

                noiseUV += float2(scrollDir * calcTime);
                float2 uvOffset = SAMPLE_TEXTURE2D(_UVNoiseTex, sampler_UVNoiseTex, noiseUV).xy * _UVDistortion * distStr;
                uvMain += uvOffset;
            }

            VaryingsParticle vertParticleUnlit(AttributesParticle input)
            {
                VaryingsParticle output = (VaryingsParticle)0;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                //
                output.color = input.color;
                output.texcoord.xy = TRANSFORM_TEX(input.texCoord0, _BaseMap);

                output.CustData.xy = _CustomUV ? input.texCoordCst.xy : float2(0, 0);
                output.CustData.z = input.texCoordCst.z;
                output.texcoordMask = TRANSFORM_TEX(input.texCoord0, _MaskTex);
                output.texcoordNoise.xy = TRANSFORM_TEX(input.texCoord0, _UVNoiseTex);
                output.texcoordNoise.zw = TRANSFORM_TEX(input.texCoord0, _CutoutTex);
                return output;
            }


            float4 fragParticleUnlit(VaryingsParticle fInput) : SV_Target
            {
                float t = abs(frac(_Time.y * 0.01));
                float calcTime = t * 100;

                float4 vertColor = fInput.color;
                float2 uvMain = fInput.texcoord.xy;
                uvMain += _MainSpeed.xy * calcTime;
                float2 pivot = 0.5; //_UVRotate.xy;
                roateUV(_MainSpeed.zw, calcTime, pivot, uvMain);
                uvMain += fInput.CustData.xy;
                distorUVbyTex(fInput.texcoordNoise.xy, calcTime,uvMain);

                float4 mainTexColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvMain);


                float2 uvMask = fInput.texcoordMask;
                uvMask.xy += _MaskSpeed.xy * calcTime;
                roateUV(_MaskSpeed.zw,calcTime, pivot, uvMask);

                float4 col = mainTexColor * _BaseColor;
                col *= vertColor;
                col.rgb *= _GlowScale;

                {
                    //CutOut
                    float cutout = _CustomCutOut ? fInput.CustData.z : _CutOut;

                    cutout = lerp(cutout, (1.001 - vertColor.a + cutout), _UseParticlesAlphaCutout);

                    float2 cutoutUV = fInput.texcoordNoise.zw + _UVCutOutScroll.xy * calcTime;
                    float mask = SAMPLE_TEXTURE2D(_CutoutTex, sampler_CutoutTex, cutoutUV).r;
                    mask = _UseCutoutTex ? mask : mainTexColor.a;

                    float diffMask = mask - cutout;
                    float alphaMask = lerp(
                        saturate(diffMask * 10000) * col.a,
                        saturate(diffMask * 2) * col.a,
                        _UseSoftCutout);

                    float alphaMaskThreshold = saturate((diffMask - _CutoutThreshold) * 10000) * col.a;
                    float3 col2 = lerp(col.rgb, _CutoutColor.rgb, saturate((1 - alphaMaskThreshold) * alphaMask));
                    col.rgb = lerp(col.rgb, col2, step(0.01, _CutoutThreshold));
                    col.a = alphaMask;
                }

                float4 maskTexColor = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                col.a = saturate(col.a * _AlphaScale);
                col.a = saturate(col.a * maskTexColor.r);
                return col;
            }
            #pragma vertex vertParticleUnlit
            #pragma fragment fragParticleUnlit
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}