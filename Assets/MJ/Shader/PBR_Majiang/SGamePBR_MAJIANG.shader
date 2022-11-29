
Shader "FeiYun/SGamePBR_MAJIANG"
{
    Properties
    {
        
        [IntRange]_Row("行",Range(0,5.1)) = 0
        [IntRange]_Col("列",Range(0,8.1)) = 0

        [MainTexture] _BaseMap("颜色贴图", 2D) = "white" {}
        [MainColor] _BaseColor("RGB:颜色 A:透明度", Color) = (1,1,1,1)

        [NoScaleOffset][Normal]_NormalMap("法线贴图", 2D) = "bump" {}
        [NoScaleOffset]_CurveMap("曲率贴图", 2D) = "black"{}
        _TransmitColor("散射颜色", Color) = (1.0,1.0,1.0,1.0)
        _TransmitInt("散射强度", Range(0,10 )) = 0.5

        // 换遮罩
        [NoScaleOffset]_MetallicGlossMap("RGB: 金属度 AO 光滑度", 2D) = "white" {}
        _Metallic("金属度", Range(0.0, 1.0)) = 0.0
        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength("AO强度", Range(0.0, 1.0)) = 1.0
        _Test("测试", Range(0.0, 1.0)) = 1.0
        _DiffuseRamp("光照Ramp图", 2D) = "black" {}


        [HideInInspector]_EnergyLUT("_EnergyLUT", 2D) = "black" {}

        [MaterialToggle(_EMISSION_ON)] _Emission  ("Emission", float) = 0
        [NoScaleOffset]_EmissionMap("自发光遮罩", 2D) = "white" {}
        [HDR] _EmissionColor("自发光颜色", Color) = (0,0,0,1)

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
        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }

    SubShader
    {

        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "SGameForward"
            Tags{"LightMode" = "UniversalForward"}

            BlendOp[_BlendOp]
            Blend[_SrcBlend][_DstBlend]

            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            // #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
            #pragma shader_feature _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW

            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #define _SHADOWS_SOFT

            // #pragma multi_compile_instancing
            // #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            // Material Shader Feature
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _EMISSION_MAP
            
            #pragma vertex PBRVert
            #pragma fragment PBRFragment
            
            #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
            #include "Assets/Common/ShaderLibrary/Surface/ShadingModel.hlsl"
            
            #include "SGamePBRLighting.hlsl"

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
   CustomEditor "FBShaderGUI.SGamePBR_MAJIANGShaderGUI"
}
