
Shader "FB/Standard/SGamePBR"
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

        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Toggle]_PreZ("预写入深度", Float) = 0

        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        // Shadow Setting
        [KeywordEnum(Unity Shadow,HQ Shadow)] ENABLE_HQ("ShadowType",Int) = 0

        // Planar Shadow
        [MaterialToggle(Planar Shadow)] _PlanarShadow  ("_PlanarShadow", float) = 0
        _ShadowColor("Shadow Color", Color) = (0.83,0.89,0.97,0.25)
        _ShadowHeight("Shadow Height", float) = 0
        _ShadowOffsetX("Shadow Offset X", float) = 0.0
        _ShadowOffsetZ("Shadow Offset Y", float) = 0.0
        _ProGameOutDir("ProGameOutDir", vector) = (-1.04, 1.9, 1.61,0)

        [HideInInspector]_MeshHight("_MeshHight", float) = 0.0
        [HideInInspector]_WorldPos("_WorldPos", vector) = (0,0,0,0)
    }

    SubShader
    {

        Tags{"RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "PBR fect PrePass"
            Tags{"LightMode" = "SGameShadowPassTrans"}
            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma target 3.5
            #include "SGamePBRLighting.hlsl"

            #pragma vertex vert_preZ
            #pragma fragment frag_preZ

            Varyings_SGame vert_preZ( Attributes_SGame v)
            {
                Varyings_SGame o = (Varyings_SGame)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half frag_preZ(Varyings_SGame i):SV_TARGET
            {
                return 1;
            }
            ENDHLSL
        }


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
            #pragma multi_compile _ ENABLE_HQ_SHADOW
            #pragma multi_compile _ _EMISSION_ON

            // Key Word End----------------------------------

            #pragma vertex Vert_SGame
            #pragma fragment PBRFragment
            
            #include "SGamePBRLighting.hlsl"

            ENDHLSL
        }

        Pass //2
        {
            Name "ShadowBeforePost"
            Tags {"LightMode"="SGameShadowPass"}
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
            
            Blend DstColor Zero
            ColorMask RGB
            ZWrite off
            
            HLSLPROGRAM
            #pragma target 3.5
            
            #pragma vertex vertGameOut
            #pragma fragment frag

            #include "SGamePBRLighting.hlsl"
            #include "Assets/Common/ShaderLibrary/Shadow/FlatShadow.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma target 3.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "SGamePBRLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "SGamePBRLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "FBShaderGUI.SGamePBRShaderGUI"
}
