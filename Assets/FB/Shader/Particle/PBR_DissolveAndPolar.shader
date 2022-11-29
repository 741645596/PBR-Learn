
Shader "FB/Particle/PBR_DissolveAndPolar"
{
    Properties
    {
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Space(25)]
        [MainTexture] _BaseMap("Albedo(底色)", 2D) = "white" {}
        [MainColor] _BaseColor("Color(底色)", Color) = (1,1,1,1)

        [Space(25)]
        _BumpScale("NormalScale(法线)", Float) = 1.0
        [NoScaleOffset]_BumpMap("Normal Map(法线)", 2D) = "bump" {}

        [Space(25)]
        [NoScaleOffset]_MetallicGlossMap("Metallic(R:金属度 G:AO B:皮肤范围 A:光滑度)", 2D) = "white" {}
        _Smoothness("Smoothness(光滑度)", Range(0.0, 1.0)) = 0.85
        _Metallic("Metallic(金属度)", Range(0.0, 1.0)) = 1
        _OcclusionStrength("AOStrength(ao强度)", Range(0.0, 1.0)) = 1.0

        [Space(25)]
        [HDR] _EmissionColor("Color(自发光,A通道阴影强度)", Color) = (0,0,0)
        [NoScaleOffset]_EmissionMap("Emission(自发光,A通道阴影强度)", 2D) = "white" {}

        [Space(25)]
        _SpecularTwoLobesA("SpecularTwoLobesA(底层粗糙度)", Range(0 , 1)) = 0.5
        _SpecularTwoLobesB("SpecularTwoLobesB(顶层高光比例)", Range(0 , 1)) = 0.354
        
        //溶解相关
        [Space(25)]
        _DissolveMap("溶解贴图",2D) = "black"{}
        _DissolveStrength("溶解强度",Range(0.0,1.0)) = 0.5
        _DissolveEdgeWidth("溶解边宽",Range(0.0,0.1)) = 0.03
        
        [HDR] _EdgeEmission("边界自发光颜色",Color) = (1,1,1,1)

        //极坐标相关
        [Space(25)]
        [MaterialToggle(USINGPOLAR)]_PolarEnable("是否启用极坐标", int) = 0
        _UVDissolveSpeed("流动速度",Vector) = (0.5,0.5,0,0)
        _DissolveTexAngle("扭曲贴图旋转角度",Range(0, 360)) = 0

        [Space(25)]
        [KeywordEnum(Off,Shadow,And_Unity_Shadow)] ENABLE_HQ("ShadowType",Int) = 0

        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0

        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

        _StencilToggle("Stencil Toggle", Float) = 0
        [HideInInspector]_Stencil("Stencil ID Ref 0-255", Float) = 0
        [HideInInspector]_StencilComp("Comparison", Float) = 8
        [HideInInspector]_PassStencilOp("Pass OP", Float) = 0
        [HideInInspector]_FailPassStencilOp("Fail OP", Float) = 0
        [HideInInspector]_ZFailPassStencilOp("ZFail OP", Float) = 0
        [HideInInspector]_StencilReadMask("Read Mask", Float) = 255
        [HideInInspector]_StencilWriteMask("Write Mask", Float) = 255

        //平面阴影
		_ShadowColor("Shadow Color", Color) = (0.83,0.89,0.97,0.25)
		_ShadowHeight("Shadow Height", float) = 0
		_ShadowOffsetX("Shadow Offset X", float) = 0.0
		_ShadowOffsetZ("Shadow Offset Y", float) = 0.0
        _ProGameOutDir("ProGameOutDir", vector) = (-1.04, 1.9, 1.61,0)
        [HideInInspector]_PlantShadowOpen("PlantShadowOpen", float) = 1
    }

    SubShader
    {

        Tags{
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline" 
         }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Stencil
            {
                Ref[_Stencil]
                Comp[_StencilComp]
                Pass[_PassStencilOp]
                Fail[_FailPassStencilOp]
                ZFail[_ZFailPassStencilOp]
                ReadMask[_StencilReadMask]
                WriteMask[_StencilWriteMask]
            }

            BlendOp[_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #define _SHADOWS_SOFT
            #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex SSSPassVertex
            #pragma fragment SSSRangeFragment
            #include "UnityParticlePBRInput.hlsl"
            #include "UnityParticlePBRForward.hlsl"
            #include "ParticlePBRInputDissolve.hlsl"
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
            #include "UnityPBRLightingDissolve.hlsl"//引用渲染函数
            #include "UnityParticlePBRLighting.hlsl"
            
            ENDHLSL
        }

        UsePass "FB/Standard/SGamePBR/ShadowBeforePost"
        UsePass "FB/Standard/SGamePBR/DepthOnly"
        UsePass "FB/Standard/SGamePBR/ShadowCaster"
        UsePass "FB/Standard/SGamePBR/SGameMeta"

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "FBShaderGUI.UnityPBRDissolveShaderGUI"
}