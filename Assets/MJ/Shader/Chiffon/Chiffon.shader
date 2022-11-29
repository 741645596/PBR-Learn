Shader "FeiYun/Chiffon"
{
    Properties
    {
        [MainTexture] _BaseMap("颜色贴图", 2D) = "white" {}
        [MainColor] _BaseColor("RGB:颜色 A:透明度", Color) = (1,1,1,1)

        [NoScaleOffset][Normal]_NormalMap("法线贴图", 2D) = "bump" {}

        [NoScaleOffset]_MetallicGlossMap("RGB: 金属度 AO 光滑度", 2D) = "white" {}
        _Metallic("金属度", Range(0.0, 1.0)) = 0.0
        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength("AO强度", Range(0.0, 1.0)) = 1.0

        _Reflectance("反射率", Range(0.0, 1.0)) = 0.5

        [MaterialToggle(_EMISSION_ON)] _Emission  ("Emission", float) = 0
        [NoScaleOffset]_EmissionMap("自发光遮罩", 2D) = "white" {}
        [HDR] _EmissionColor("自发光颜色", Color) = (0,0,0,1)
        // 闪点
        _SparkleTex("闪点贴图", 2D) = "white" {}
        _SparkleMaskTex("闪点遮罩图", 2D) = "white" {}
        _SparkleSize("_SparkleSize", vector) = (500.00, 500.00, 0.002, 0.002)
        _SparkleDependency("Sparkle Dependency", Range(0, 1)) = 0.5
        _SparkleRoughness("闪点光滑度", Range(0, 1)) = 0.5
        [HDR]_SparkleColor("_SparkleColor", Color) = (10.59746, 10.1835, 15.8134)
        _SparkleScaleMin("Sparkle Min[大小]", Range(0, 1)) = 1
        _SparkleDensity("Sparkle Density[密度]", Range(0, 1.2)) = 0

        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }

    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            Name "SGameForward"
            Tags{"LightMode" = "UniversalForward"}

            BlendOp[_BlendOp]
            Blend[_SrcBlend][_DstBlend]

            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 3.5
            
            // Key Word Start----------------------------------

            // Universal Pipeline keywords
            #pragma multi_compile _MAIN_LIGHT_SHADOWS

            // _ADDITIONAL_LIGHTS
            // _ADDITIONAL_LIGHTS_VERTEX
            #pragma multi_compile _ADDITIONAL_LIGHTS
            #pragma multi_compile _SHADOWS_SOFT

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _ALPHATEST_ON

            #pragma multi_compile_fog
            
            // Material Mutil_Compile
            #pragma multi_compile _ _EMISSION_ON

            // Key Word End----------------------------------

            #pragma vertex Vert_SGame
            #pragma fragment PBRFragment
            
            #include "CPBRLighting.hlsl"

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "FBShaderGUI.FeiYunChiffonGUI"
}
