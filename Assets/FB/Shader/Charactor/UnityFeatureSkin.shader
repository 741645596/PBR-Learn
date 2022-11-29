Shader "FB/UnityShader/FeatureSkin"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 0)
        [NoScaleOffset]_BaseMap("Base Map", 2D) = "white" {}
        [Normal][NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset]_MaskMap("Mask Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
        Color_bb76cedad9dd414e8ba2c027432df5de("Occlusion Color Bleeding", Color) = (0, 0, 0, 0)
        [NoScaleOffset]_ThicknessMap("Thickness Map", 2D) = "white" {}
        _ThicknessMin("Thickness Min", Range(0, 1)) = 0
        _ThicknessMax("Thickness Max", Range(0, 1)) = 1
        [HDR]_EmissionColor("Emission Color", Color) = (0, 0, 0, 0)
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}
        [HideInInspector]_DiffusionProfileHash("Float", Float) = 0
        [HideInInspector]_DiffusionProfileAsset("Vector4", Vector) = (0, 0, 0, 0)
        [HideInInspector]_WorkflowMode("_WorkflowMode", Float) = 1
        [HideInInspector]_CastShadows("_CastShadows", Float) = 1
        [HideInInspector]_ReceiveShadows("_ReceiveShadows", Float) = 1
        [HideInInspector]_Surface("_Surface", Float) = 0
        [HideInInspector]_Blend("_Blend", Float) = 0
        [HideInInspector]_AlphaClip("_AlphaClip", Float) = 0
        [HideInInspector]_SrcBlend("_SrcBlend", Float) = 1
        [HideInInspector]_DstBlend("_DstBlend", Float) = 0
        [HideInInspector][ToggleUI]_ZWrite("_ZWrite", Float) = 1
        [HideInInspector]_ZWriteControl("_ZWriteControl", Float) = 0
        [HideInInspector]_ZTest("_ZTest", Float) = 4
        [HideInInspector]_Cull("_Cull", Float) = 2
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = 1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

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
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry+1"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="SubsurfaceScatteringShaderGraphTarget"
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
                #include "Assets/Renders/Shaders/ShaderLibrary/Shadow/FlatShadowInput.hlsl"
				#include "Assets/Renders/Shaders/ShaderLibrary/Shadow/FlatShadow.hlsl"
			ENDHLSL
		}

        Pass
        {
            Name "SubsurfaceNormalForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        Stencil
        {
        Ref [_RenderRef]
        CompFront Always
        ZFailFront Keep
        PassFront Replace
        CompBack Always
        ZFailBack Keep
        PassBack Replace
        }
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        //#pragma target 4.5
        //#pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACENORMALFORWARDLIT
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };

        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };

        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };

        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringPBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPass"
            Tags
            {
                "LightMode" = "SplitForward"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASS
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPassDownsampling"
            Tags
            {
                "LightMode" = "SplitForwardDownsampling"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASSDOWNSAMPLING
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPassDownsampling.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPassAlbedo"
            Tags
            {
                "LightMode" = "SplitForwardAlbedo"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASSALBEDO
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPassAlbedo.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.texCoord1;
            output.interp2.xyzw =  input.texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.texCoord1 = input.interp1.xyzw;
            output.texCoord2 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull [_Cull]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry+1"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="SubsurfaceScatteringShaderGraphTarget"
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
                #include "Assets/Renders/Shaders/ShaderLibrary/Shadow/FlatShadowInput.hlsl"
				#include "Assets/Renders/Shaders/ShaderLibrary/Shadow/FlatShadow.hlsl"
			ENDHLSL
		}

        Pass
        {
            Name "SubsurfaceNormalForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        Stencil
        {
        Ref [_RenderRef]
        CompFront Always
        ZFailFront Keep
        PassFront Replace
        CompBack Always
        ZFailBack Keep
        PassBack Replace
        }
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACENORMALFORWARDLIT
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringPBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPass"
            Tags
            {
                "LightMode" = "SplitForward"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASS
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPassDownsampling"
            Tags
            {
                "LightMode" = "SplitForwardDownsampling"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASSDOWNSAMPLING
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPassDownsampling.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SubsurfaceScatteringSupportPassAlbedo"
            Tags
            {
                "LightMode" = "SplitForwardAlbedo"
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        #pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF
        // GraphKeywords: <None>
        
        // Defines
        #define _ADDITIONAL_LIGHTS
        #define _SHADOWS_SOFT
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SUBSURFACESCATTERINGSUPPORTPASSALBEDO
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float3 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float2 interp6 : INTERP6;
             float3 interp7 : INTERP7;
             float4 interp8 : INTERP8;
             float4 interp9 : INTERP9;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp6.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp7.xyz =  input.sh;
            #endif
            output.interp8.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp9.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp5.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp6.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp7.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp8.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp9.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        struct Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float
        {
        };
        
        void SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float(float Vector1_B234B389, float Vector1_42815DCE, float Vector1_E757BA52, Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float IN, out float Out_0)
        {
        float _Property_33e372de9bb01683a13ccc425980bcf1_Out_0 = Vector1_B234B389;
        float _Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0 = Vector1_42815DCE;
        float _Property_09d8c8648d3876819ef693ea9d96110e_Out_0 = Vector1_E757BA52;
        float4 _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4;
        float3 _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5;
        float2 _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6;
        Unity_Combine_float(_Property_41c27fd845bd5087bfb8400d87ee46b5_Out_0, _Property_09d8c8648d3876819ef693ea9d96110e_Out_0, 0, 0, _Combine_49f403a6ef725e82ac55b1178ba49410_RGBA_4, _Combine_49f403a6ef725e82ac55b1178ba49410_RGB_5, _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6);
        float _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        Unity_Remap_float(_Property_33e372de9bb01683a13ccc425980bcf1_Out_0, float2 (0, 1), _Combine_49f403a6ef725e82ac55b1178ba49410_RG_6, _Remap_985ee458b48c03898c61855d172c5222_Out_3);
        Out_0 = _Remap_985ee458b48c03898c61855d172c5222_Out_3;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float3 Specular;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
            float DiffusionProfileHashValue;
            float SubsurfaceRadiusMap;
            float Thickness;
            float3 OcclusionColorBleeding;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            UnityTexture2D _Property_a69dc989a9444dd8b545d005cff71b58_Out_0 = UnityBuildTexture2DStructNoScale(_MaskMap);
            float4 _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a69dc989a9444dd8b545d005cff71b58_Out_0.tex, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.samplerstate, _Property_a69dc989a9444dd8b545d005cff71b58_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.r;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.g;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.b;
            float _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7 = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_RGBA_0.a;
            float _Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0 = _Smoothness;
            float _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            Unity_Multiply_float_float(_Property_948fee8baa2c46f6abcdb95ca800cf91_Out_0, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_A_7, _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2);
            float _Property_d614b7c87e34412a839edea0a7a83d98_Out_0 = _OcclusionStrength;
            float _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            Unity_Lerp_float(1, _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_G_5, _Property_d614b7c87e34412a839edea0a7a83d98_Out_0, _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3);
            UnityTexture2D _Property_a388475868454ded8fb3de7885b948f0_Out_0 = UnityBuildTexture2DStructNoScale(_ThicknessMap);
            float4 _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a388475868454ded8fb3de7885b948f0_Out_0.tex, _Property_a388475868454ded8fb3de7885b948f0_Out_0.samplerstate, _Property_a388475868454ded8fb3de7885b948f0_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_R_4 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.r;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_G_5 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.g;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_B_6 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.b;
            float _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_A_7 = _SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0.a;
            float _Property_d22711039a7640d38367760e105049c1_Out_0 = _ThicknessMin;
            float _Property_e8610261809c4794b0b368239fda06d2_Out_0 = _ThicknessMax;
            Bindings_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float _RemapMinMax_09999e94508046429504b318e5fdb139;
            float _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            SG_RemapMinMax_55b3abe4082ae4d4c99b76de292d58e0_float((_SampleTexture2D_12655a9930cd43d084fc64c3ecb2d86e_RGBA_0).x, _Property_d22711039a7640d38367760e105049c1_Out_0, _Property_e8610261809c4794b0b368239fda06d2_Out_0, _RemapMinMax_09999e94508046429504b318e5fdb139, _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0);
            float4 _Property_169b239e7697495abf19850baa64568a_Out_0 = Color_bb76cedad9dd414e8ba2c027432df5de;
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Metallic = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_R_4;
            surface.Specular = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
            surface.Smoothness = _Multiply_019ef3fb1ca94b798ed352f2eefafc17_Out_2;
            surface.Occlusion = _Lerp_390ca259a5e14109a9eac5ce8f4fd9e7_Out_3;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            surface.DiffusionProfileHashValue = ((asuint(_DiffusionProfileHash) != 0) ? _DiffusionProfileHash : asfloat(uint(1)));
            surface.SubsurfaceRadiusMap = _SampleTexture2D_a30186b081044b3d8ecbf4b2fbe32c95_B_6;
            surface.Thickness = _RemapMinMax_09999e94508046429504b318e5fdb139_Out_0;
            surface.OcclusionColorBleeding = (_Property_169b239e7697495abf19850baa64568a_Out_0.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringInput.hlsl"
        #include "Packages/com.unity.charactershader/Runtime/Material/SubsurfaceScattering/ShaderLibrary/SubsurfaceScatteringUtility.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.charactershader/Editor/Material/ShaderGraph/SubsurfaceScattering/Includes/SubsurfaceScatteringSupportPassAlbedo.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
            float4 _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0 = SAMPLE_TEXTURE2D(_Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.tex, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.samplerstate, _Property_571777e36b9d4c26a1d38f5fd40b368c_Out_0.GetTransformedUV(IN.uv0.xy));
            _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0);
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_R_4 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.r;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_G_5 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.g;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_B_6 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.b;
            float _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_A_7 = _SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.a;
            float3 _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_f70ec8dde0b2465ca975a8bfeb28aac9_RGBA_0.xyz), 1, _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2);
            surface.NormalTS = _NormalStrength_856537a4e0834b03bfc3c321a42d6f93_Out_2;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            output.interp1.xyzw =  input.texCoord1;
            output.interp2.xyzw =  input.texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            output.texCoord1 = input.interp1.xyzw;
            output.texCoord2 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0 = _BaseColor;
            UnityTexture2D _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
            float4 _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0 = SAMPLE_TEXTURE2D(_Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.tex, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.samplerstate, _Property_e28e07fe46f74b63af656ee44531b3e5_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_R_4 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.r;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_G_5 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.g;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_B_6 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.b;
            float _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_A_7 = _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0.a;
            float4 _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2;
            Unity_Multiply_float4_float4(_Property_1b54a674f57a4f3c84ee6927cf60e53b_Out_0, _SampleTexture2D_c5ef033926d7455d96c35f29084fa7af_RGBA_0, _Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2);
            float4 _Property_59b009d8a4a7426588813fd83616a47f_Out_0 = IsGammaSpace() ? LinearToSRGB(_EmissionColor) : _EmissionColor;
            UnityTexture2D _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
            float4 _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.tex, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.samplerstate, _Property_6bb9a4b39acb4258ad5a5d8b854db5be_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_R_4 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.r;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_G_5 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.g;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_B_6 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.b;
            float _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_A_7 = _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0.a;
            float4 _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2;
            Unity_Multiply_float4_float4(_Property_59b009d8a4a7426588813fd83616a47f_Out_0, _SampleTexture2D_d447fd3dc6074f19aecefa3bcaec55e0_RGBA_0, _Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2);
            surface.BaseColor = (_Multiply_b4f6a72d4459424cb2d9ad2e2d6f5946_Out_2.xyz);
            surface.Emission = (_Multiply_2bec5d8088064f0e821faa1f19898ad7_Out_2.xyz);
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull [_Cull]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffusionProfileAsset;
        float _DiffusionProfileHash;
        float4 _BaseMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float _ThicknessMax;
        float _Smoothness;
        float4 _MaskMap_TexelSize;
        float _OcclusionStrength;
        float4 _ThicknessMap_TexelSize;
        float4 Color_bb76cedad9dd414e8ba2c027432df5de;
        float4 _EmissionColor;
        float4 _EmissionMap_TexelSize;
        float4 _BaseColor;
        float _ThicknessMin;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MaskMap);
        SAMPLER(sampler_MaskMap);
        TEXTURE2D(_ThicknessMap);
        SAMPLER(sampler_ThicknessMap);
        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            surface.Alpha = 1;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraph.DiffusionProfileCustomShaderGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}
