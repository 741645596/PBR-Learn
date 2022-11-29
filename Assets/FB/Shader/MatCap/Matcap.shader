Shader "FB/Matcap/Matcap"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "black" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        _MatcapMap ("Matcap Map", 2D) = "black" {}
        _MatcapScale ("Matcap Scale", Range(0, 2)) = 1.0

        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0, 2)) = 1.0

        _NormalAnimToggle("NormalAnim",int) = 0
        _NormalAnim ("NormalAnim", vector) = (0,0,0,0)

        _UVScale("UVScale",float) = 1

        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 0.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        [HideInInspector] [Toggle] _EnvLight ("Env Lighting", Float) = 0.0
        [HideInInspector] _ColorBlendMode ("Blend Mode", Float) = 2.0

    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        Pass
        {
            Name "Matcap"
            Tags { "LightMode" = "UniversalForward" }
            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM
            // Platform
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // Instancing
            #pragma multi_compile_instancing

            #pragma shader_feature ENABLE_NORMALMAP
            #pragma shader_feature ENABLE_MATCAP
            #pragma shader_feature _ ENABLE_NORMALANIMTOGGLE
            #pragma shader_feature MATCAP_OVERLAY MATCAP_MULTIPLY MATCAP_ADDITIVE MATCAP_SOFTLIGHT MATCAP_PINLIGHT MATCAP_LIGHTEN MATCAP_DARKEN

            #pragma vertex MatcapVertex
            #pragma fragment MatcapFragment

            #include "MatcapInput.hlsl"
            #include "MatcapForward.hlsl"
            
            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.MatcapShaderGUI"
}
