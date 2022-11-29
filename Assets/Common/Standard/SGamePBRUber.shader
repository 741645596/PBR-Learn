
Shader "FB/Standard/SGamePBRUber"
{
    Properties
    {
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // PBR
        [NoScaleOffset][MainTexture] _BaseMap("颜色贴图", 2D) = "white" {}
        [MainColor] _BaseColor("RGB:颜色 A:透明度", Color) = (1,1,1,1)

        [NoScaleOffset][Normal]_NormalMap("法线贴图", 2D) = "bump" {}

        [NoScaleOffset]_MetallicGlossMap("RGB: 金属度 AO 光滑度", 2D) = "white" {}
        _Metallic("金属度", Range(0.0, 1.0)) = 0.0
        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength("AO强度", Range(0.0, 1.0)) = 1.0
        _SpecularOcclusionStrength("高光AO强度", Range(0, 1)) = 0

        _Reflectance("反射率", Range(0.0, 1.0)) = 1.0

        [MaterialToggle(_EMISSION_ON)] _Emission  ("Emission", float) = 0
        [NoScaleOffset]_EmissionMap("自发光遮罩", 2D) = "white" {}
        [HDR] _EmissionColor("自发光颜色", Color) = (0,0,0,1)


        // 清漆
        [MaterialToggle(_CLEARCOAT_ON)] _ClearCoat("ClearCoat", Float) = 0.0
        _ClearCoatMap("清漆遮罩(透明度)", 2D) = "white" {}
        _ClearCoatCubeMap("清漆反射球", Cube) = "white" {}
        _ClearCoatMask("清漆透明度", Range( 0 , 1)) = 0.8
        _ClearCoatSmoothness("清漆光滑度", Range( 0 , 1)) = 0.8
        _ClearCoatDownSmoothness("清漆底层光滑度", Range( 0 , 1)) = 0.8
        _ClearCoat_Detail_Factor("清漆 Detail 强度",Range(0 , 1))= 0

        // 细节贴图 Unity
        [MaterialToggle(_DETAILMAP_ON)]_UseDetailMap("细节开启", Float) = 0
        [NoScaleOffset]_Detail_ID("细节 ID", 2D) = "white" {}
        
        [Space(15)]
        [IntRange]_Detail_Layer("细节层数",Range(1,4)) = 1
        
        [NoScaleOffset]_DetailMap_1("细节贴图1", 2D) = "linearGrey" {}
        _DetailMap_Tilling_1("_DetailMap_Tilling_1",Range( 1 , 200))= 60
        _DetailAlbedoScale_1("Albedo 强度", Range(0, 1)) = 0.8
        _DetailAlbedoColor_1("Albedo 颜色",Color) = (0,0,0,1)
        _DetailNormalScale_1("法线强度", Range(0, 1)) = 0.8
        _DetailSmoothnessScale_1("光滑度", Range(0, 1)) = 0.8
        [Space(15)]
        _DetailMap_2("细节贴图2", 2D) = "linearGrey" {}
        _DetailMap_Tilling_2("_DetailMap_Tilling_2",Range( 1 , 200))= 60
        _DetailAlbedoScale_2("Albedo 强度", Range(0, 1)) = 0.8
        _DetailAlbedoColor_2("Albedo 颜色",Color) = (0,0,0,1)
        _DetailNormalScale_2("法线强度", Range(0, 1)) = 0.8
        _DetailSmoothnessScale_2("光滑度", Range(0, 1)) = 0.8
        [Space(15)]
        _DetailMap_3("细节贴图3", 2D) = "linearGrey" {}
        _DetailMap_Tilling_3("_DetailMap_Tilling_3",Range( 1 , 200))= 60
        _DetailAlbedoScale_3("Albedo 强度", Range(0, 1)) = 0.8
        _DetailAlbedoColor_3("Albedo 颜色",Color) = (0,0,0,1)
        _DetailNormalScale_3("法线强度", Range(0, 1)) = 0.8
        _DetailSmoothnessScale_3("光滑度", Range(0, 1)) = 0.8
        [Space(15)]
        _DetailMap_4("细节贴图4", 2D) = "linearGrey" {}
        _DetailMap_Tilling_4("_DetailMap_Tilling_4",Range( 1 , 200))= 60
        _DetailAlbedoScale_4("Albedo 强度", Range(0, 1)) = 0.8
        _DetailAlbedoColor_4("Albedo 颜色",Color) = (0,0,0,1)
        _DetailNormalScale_4("法线强度", Range(0, 1)) = 0.8
        _DetailSmoothnessScale_4("光滑度", Range(0, 1)) = 0.8

        // 风格化镭射 TX
        [MaterialToggle(_LASER_ON)] _UseLaser  ("镭射开启", float) = 0
        _LaserMap("镭射遮罩", 2D) = "white" {}
        _LaserStrength("镭射强度",Range(0,5)) = 1
        _LaserBrdfIntensity("PBR效果强度",Range(0,1)) = 1
        _LaserAnisotropy("镭射各向异性方向",Range(-1,1)) = 0
        _LaserIOR("颜色区间",Range(-1,1)) = .3
        _LaserThickness("材质厚度",Range(0,1)) = 0.137
        [HDR]_LaserColor("镭射颜色", Color) = (1,1,1,1)
        _LaserSmoothstepValue_1("镭射区间1", Range(0,1)) = 0
        _LaserSmoothstepValue_2("镭射区间2", Range(0,1)) = 1
        [Toggle]_LaserUniversal("万象镭射", Range(0,1)) = 0
        _LaserAreaCubemapInt("环境球强度", Range(0,1)) = 0

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
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0

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
            Name "SGameForwardUber"
            Tags{"LightMode" = "UniversalForward"}

            BlendOp[_BlendOp]
            Blend[_SrcBlend][_DstBlend]

            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM

            // Universal Pipeline keywords
            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _SHADOWS_SOFT
            #pragma multi_compile_fog

            // Material keywords
            #pragma multi_compile NORMALMAP_ON
            #pragma multi_compile _ ENABLE_HQ_SHADOW

            #pragma multi_compile _ _EMISSION_ON

            #pragma multi_compile _ _CLEARCOAT_ON 
            // #pragma multi_compile _ _CLEARCOATCUBEMAP_ON 
            #pragma multi_compile _ _DETAILMAP_ON
            #pragma multi_compile _ _LASER_ON

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
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

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
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

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
        // UsePass "FB/Standard/SGamePBR/SGameMeta"
        // UsePass "Universal Render Pipeline/Lit/DepthNormals"

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "FBShaderGUI.SGamePBRShaderGUI"
}
