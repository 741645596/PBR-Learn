Shader "FB/Charactor/SGameSkin"
{
    Properties
    {
        _BaseColor("RGB:颜色 A:透明度", Color) = (1,1,1,1)
        [NoScaleOffset]_BaseMap("颜色贴图", 2D) = "white" {}
        [NoScaleOffset]_NormalMap("法线贴图", 2D) = "bump" {}
        [NoScaleOffset]_SkinMap("RGB: 曲率 AO 光滑度", 2D) = "white" {}

        // _BlushArea("腮红位置", 2D) = "black"{}
        // _BlushColor("腮红颜色", Color) = (1,0,0,0)
        // _BlushInt("腮红强度", Range(0, 2)) = 1

        _SSSRange("3S额外强度", Range( 0 , .4)) = .2
        _Occlusion("AO强度", Range( 0 , 1)) = .5

        [Space(15)]
        _lobe0Smoothness("皮肤光滑度1", Range( 0 , 1)) = 1
        _lobe1Smoothness("皮肤光滑度2", Range( 0 , 1)) = 1
        _LobeMix("皮肤光滑度权重",Range( 0 , 1)) = 1

        _EnvDiffInt("环境补光强度", Range(1, 3)) = 1
        _PBRToDiffuse("PBR衰减效果衰减", Range(0, 1)) = 0.0
        _DiffusePower("SSS强度增益", Range(0, 1)) = 0.0

        [HideInInspector]_SSSLUT("3S查找表", 2D) = "black" {}

        _ThickMap("厚度贴图",2D) = "white" {}
        _BackLightIntensity("透光强度",Range(0, 1)) = 1
        _BackLightColor("透光颜色", Color) = (1.0,1.0,1.0,1.0)
        
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
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0

    }

    HLSLINCLUDE
    #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"
    #include "SkinFunction.hlsl"
    #include "Assets/Renders/Shaders/ShaderLibrary/Common/GlobalIllumination.hlsl"

    
    
    CBUFFER_START(UnityPerMaterial)
        half4 _BaseColor;

        float4 _BaseMap_ST;

        half  _SSSRange;
        float  _lobe0Smoothness;
        float _lobe1Smoothness;
        float _LobeMix;
        half  _Occlusion;
        half _EnvDiffInt;
        half _PBRToDiffuse;
        half _DiffusePower;
        half _BlushInt;
        half4 _BlushColor;
        half3 _BackLightColor;

        half  _BackLightIntensity;

        half _Cutoff;

        // shadow
        //阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
        half4 _ShadowColor;
        //阴影平面的高度 目前由外部脚本设定 UpdateShadowPlane.cs
        float _ShadowHeight;
        //XZ平面的偏移
        float _ShadowOffsetX;
        float _ShadowOffsetZ;

        //模型高度 由外部脚本设定 UpdateShadowPlane.cs
        float _MeshHight;
        //模型位置 由外部脚本设定 UpdateShadowPlane.cs
        float4 _WorldPos;
        //影子透明度
        half _AlphaVal;

        half3 _ProGameOutDir;
        half _ShadowStr=1;

    CBUFFER_END

    TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
    TEXTURE2D(_SkinMap);        SAMPLER(sampler_SkinMap);
    TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
    TEXTURE2D(_BlushArea);      SAMPLER(sampler_BlushArea);
    TEXTURE2D_HALF(_SSSLUT);    SAMPLER(sampler_SSSLUT);
    TEXTURE2D_HALF(_ThickMap);  SAMPLER(sampler_ThickMap);
    ENDHLSL

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "RenderType"="Opaque" 
        }
        
        Pass{

            Name "SGameSkin"
            Tags{ "LightMode" = "UniversalForward" }

            BlendOp[_BlendOp]
            Blend[_SrcBlend][_DstBlend]

            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM

            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW

            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _SHADOWS_SOFT
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ _LIGHT_LAYERS

            #pragma instancing_options renderinglayer
            

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 vertex           : POSITION;
                float3 normal           : NORMAL;
                float4 tangent          : TANGENT;
                float2 uv               : TEXCOORD0;
                float4 lightmapUV       : TEXCOORD1;
            };
            
            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float4 world_normal     : TEXCOORD1;
                float4 world_tangent    : TEXCOORD2;
                float4 world_binormal   : TEXCOORD3;

                float4 shadowCoord  : TEXCOORD4;

                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 5);
            };

            struct SurfaceDataSkin
            {
                // 为了传参方便
                // pbr参数
                half3   diffuseColor;
                half3   specularColor;
                half    metallic;
                half    smoothness;
                half    occlusion;
                float3  emission;
                half    clearCoat;
                half    clearCoatRoughness;
                
                // 3s参数
                half    skinArea;
                half    sssCurve;
                half    lobe0Smoothness;
                half    lobe1Smoothness;

                half    lobe0Roughness;
                half    lobe1Roughness;

                half    lobeMix;

                half    alpha;
            };

            struct CommonData
            {
                half3 lightColor;
                
                half4 shadowCoord;
                half shadow;

                float3 pos_world;

                half3 dir_normal;
                half3 dir_normal_blur;

                half3 dir_light;
                half3 dir_half;
                half3 dir_view;

                half NdotL;
                half NdotL_blur;
                half NdotV;
                half NdotH;
                half VdotH;
            };

            void InitData(Varyings i,out SurfaceDataSkin surfaceData,out CommonData commonData)
            {
                surfaceData                     = (SurfaceDataSkin)0;
                commonData                      = (CommonData)0;

                // half3 var_BlushArea = SAMPLE_TEXTURE2D(_BlushArea,sampler_LinearClamp,i.uv).rgb;

                half4 base_color                = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap,i.uv) * _BaseColor;
                // base_color = lerp(base_color,  base_color + base_color * _BlushColor * 2, var_BlushArea.r * _BlushInt);
                // base_color = lerp(base_color,  base_color  * 0.5, var_BlushArea.g * _BlushInt);
                
                base_color = min(1, base_color);
                half3 skin_map                  = SAMPLE_TEXTURE2D(_SkinMap , sampler_SkinMap,i.uv).xyz;

                surfaceData.diffuseColor        = base_color.rgb;
                surfaceData.alpha               = base_color.a;

                #if _ALPHATEST_ON
                    clip(surfaceData.alpha - _Cutoff);
                #endif


                surfaceData.sssCurve            = saturate(skin_map.r + _SSSRange) ;  // or GetCurvature(_SSSRange,_SSSPower,dir_normal,i.pos_world);
                // surfaceData.sssCurve            = saturate(skin_map.r * 2 - (1.2 - _SSSRange * 2));  

                surfaceData.occlusion           = lerp(1,skin_map.g,_Occlusion);

                half smoothness                 = skin_map.b * 0.999;

                surfaceData.specularColor       = half3(smoothness,smoothness,smoothness) * 0.028; // 

                surfaceData.lobe0Roughness     = max(0.01, 1 - smoothness * _lobe0Smoothness );
                surfaceData.lobe1Roughness     = max(0.01, 1 - smoothness * _lobe1Smoothness );

                surfaceData.smoothness          = lerp(surfaceData.lobe0Roughness, surfaceData.lobe1Roughness, _LobeMix);

                //-----
                half3 normal_data               = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv));
                // half3 nromal_data_blur          = normal_data; /// UnpackNormal(SAMPLE_TEXTURE2D_LOD(_NormalMap,sampler_LinearClamp,i.uv,1));    //4

                half3 dir_normal                = normalize(i.world_normal.xyz);
                half3 dir_tangent               = normalize(i.world_tangent.xyz);
                half3 dir_binormal              = normalize(i.world_binormal.xyz);
                float3x3 TBN                    = float3x3(dir_tangent,dir_binormal,dir_normal);

                commonData.pos_world            = half3(i.world_normal.w,i.world_tangent.w,i.world_binormal.w);

                commonData.dir_normal           = normalize(mul(normal_data,TBN));
                // commonData.dir_normal_blur      = normalize(mul(nromal_data_blur,TBN));
                commonData.dir_view             = normalize(_WorldSpaceCameraPos.xyz - commonData.pos_world);

                commonData.NdotV                = saturate(abs(dot(commonData.dir_normal,commonData.dir_view)) + 1e-5);
            }

            void UpdateLightData(inout CommonData commonData,Light light)
            {
                half3 dir_half          = SafeNormalize(light.direction + commonData.dir_view);

                commonData.lightColor   = light.color;
                
                commonData.dir_light    = light.direction;
                commonData.dir_half     = dir_half;

                commonData.NdotH        = saturate(dot(commonData.dir_normal , dir_half));
                commonData.NdotL        = dot(commonData.dir_normal , light.direction);
                // commonData.NdotL_blur   = dot(commonData.dir_normal_blur , light.direction);

                commonData.VdotH        = saturate(dot(commonData.dir_view , dir_half));
                
                
                commonData.shadow       =  light.shadowAttenuation * light.distanceAttenuation;
            }

            float3 SkinBRDF( SurfaceDataSkin surfaceData,CommonData commonData)
            {
                // sss color
                float NoL_Warp          = commonData.NdotL * 0.5 + 0.5;
                // float NoLBlur_Warp      = commonData.NdotL_blur * 0.5 + 0.5;
                // NoLBlur_Warp            = pow(NoLBlur_Warp, 0.95) ;
                half3 DiffuseShadow     = lerp(half3(0.11,0.025,0.012),float3(1,1,1), lerp(commonData.shadow, 1, saturate( pow(-commonData.NdotL,5))));//hard code
                float2 uv_sss           = float2(max(0.0, NoL_Warp),surfaceData.sssCurve);

                float3 sss_color        = SAMPLE_TEXTURE2D(_SSSLUT, sampler_SSSLUT,uv_sss).rgb;
                
                
                //sss_color               = saturate(sss_color + 0.2 * max(0.02,pow(1- commonData.NdotV, 4)));    // light up the face rim
                sss_color               = pow(sss_color,  1 - _DiffusePower * _DiffusePower);

                // float3 radiance         = saturate(commonData.NdotL)  * commonData.lightColor ;
                float3 radiance         = sss_color  * commonData.lightColor * commonData.shadow ;
                

                // radiance
                // float3 DiffIrradiance   = sss_color * commonData.lightColor * DiffuseShadow;
                float3 DiffIrradiance = sss_color * commonData.lightColor * DiffuseShadow;
                DiffIrradiance = lerp(DiffIrradiance,1, _PBRToDiffuse * 0.5) ;

                // skin diffuse
                float3 skinDiffuse      = surfaceData.diffuseColor * radiance;

                half perceptualRoughness = surfaceData.lobe0Roughness;
                half roughness = max(perceptualRoughness* perceptualRoughness, M_HALF_MIN_SQRT);
                half roughness2 = max( roughness *  roughness, M_HALF_MIN);
                half roughness2MinusOne =  roughness2 - 1.0h;
                half normalizationTerm =  roughness * 4.0h + 2.0h;

                half perceptualRoughness1 = surfaceData.lobe1Roughness;
                half roughness1 = max(perceptualRoughness1* perceptualRoughness1, M_HALF_MIN_SQRT);
                half roughness21 = max( roughness1 *  roughness1, M_HALF_MIN);
                half roughness2MinusOne1 =  roughness21 - 1.0h;
                half normalizationTerm1 =  roughness1 * 4.0h + 2.0h;
                
                // skin specular

                // Beckmann
                // float3 SpecularBRDF = DualSpecularBeckmann(surfaceData.lobe0Roughness, surfaceData.lobe1Roughness, 0.5,surfaceData.specularColor,commonData.NdotH,commonData.NdotV,saturate(commonData.NdotL),commonData.VdotH);
                
                // Single GGX
                // float3 SpecularBRDF = 0.04 * BRDFSpecular(commonData.dir_normal, commonData.dir_half, commonData.dir_view,roughness2MinusOne,roughness2,normalizationTerm);
                
                // Dual GGX
                half D1 = 0.028 * UnitySpecular(commonData.dir_normal, commonData.dir_half, commonData.dir_view,roughness2MinusOne,roughness2,normalizationTerm);
                half D2 = 0.028 * UnitySpecular(commonData.dir_normal, commonData.dir_half, commonData.dir_view,roughness2MinusOne1,roughness21,normalizationTerm1);
                
                float3 SpecularBRDF = lerp(D1,D2,_LobeMix);

                float3 skinSpecular = SpecularBRDF * radiance * PI;

                float CustomF = 1 - pow(1-commonData.VdotH, 4);
                CustomF = lerp( 0.00,1-0.028, CustomF);
                
                return skinDiffuse + skinSpecular;
            }

            half3 GI(half3 V,half3 N,half occlusion,half smoothness,half metallic,half3 bakedGI,half3 diffuseColor,half3 specularColor)
            {
                half3 reflectVector = reflect(-V,N);

                half NdotV = saturate(dot(N, V));
                

                half3 indirectDiffuse = occlusion * bakedGI;
                half perceptualRoughness = 1 - smoothness;

                // half fresnelTerm = Pow4(1.0 - NdotV);
                // half oneMinusDielectricSpec = kDieletricSpec.a;
                // half roughness = max(perceptualRoughness * perceptualRoughness, M_HALF_MIN_SQRT);
                // half roughness2 = max(roughness * roughness, M_HALF_MIN);
                // half oneMinusReflectivity = oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
                // half reflectivity = 1.0 - oneMinusReflectivity;
                // half grazingTerm = saturate(smoothness + reflectivity);
                // half normalizationTerm = roughness * 4.0h + 2.0h;
                // half roughness2MinusOne = roughness2 - 1.0h;

                half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

                #if defined(UNITY_USE_NATIVE_HDR)
                    half3 irradiance = encodedIrradiance.rgb;
                #else
                    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                #endif

                half3 indirectSpecular = irradiance ;

                float CustomF = 1 - pow(1-NdotV, 2.42);
                float3 CustomFColor = lerp(float3(0.3,0.2, 0.1), 1, CustomF);

                half3 c = indirectDiffuse * diffuseColor * CustomFColor;
                
                // float surfaceReduction = 1.0 / (roughness2 + 1.0);
                // c += indirectSpecular * half3(surfaceReduction * lerp(specularColor, grazingTerm, fresnelTerm));
                c += indirectSpecular  * 0.04;//EnvBRDFApprox(specularColor,roughness,NdotV);

                return c;
            }

            half4 SkinColor(SurfaceDataSkin surfaceData,CommonData commonData,Varyings i,Light mainLight, uint meshRenderingLayers)
            {
                // skin color
                half3 DirectLighting_MainLight = 0;
                if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
                {
                    DirectLighting_MainLight = SkinBRDF(surfaceData,commonData);
                }
                float4 ShadowMask = float4(1.0,1.0,1.0,1.0);
                half3 DirectLighting_AddLight = half3(0,0,0);

                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for(uint lightIndex = 0; lightIndex < pixelLightCount ; ++lightIndex)
                    {
                        
                        Light light = GetAdditionalLight(lightIndex,commonData.pos_world,ShadowMask);
                        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                        {
                            UpdateLightData(commonData,light);

                            DirectLighting_AddLight += SkinBRDF(surfaceData,commonData);
                        }
                    }
                #endif

                float3 skin_color = DirectLighting_MainLight + DirectLighting_AddLight * surfaceData.occlusion;
                
                half oneMinusDielectricSpec = kSkinSpec.a;
                half oneMinusReflectivity = oneMinusDielectricSpec - surfaceData.metallic * oneMinusDielectricSpec;

                half3 brdfDiffuse = surfaceData.diffuseColor * oneMinusReflectivity;
                half3 brdfSpecular = lerp(kSkinSpec.rgb, surfaceData.diffuseColor, surfaceData.metallic);

                // indirect color
                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, commonData.dir_normal) * _EnvDiffInt;
                float3 indirect_color = GI(commonData.dir_view,commonData.dir_normal,surfaceData.occlusion, 1 - surfaceData.smoothness,surfaceData.metallic,bakedGI,brdfDiffuse,brdfSpecular);

                // back light
                half thickness = SAMPLE_TEXTURE2D(_ThickMap,sampler_ThickMap,i.uv).r;
                thickness = 1 - saturate(thickness * 3.5) ;

                float VoL = clamp(dot(commonData.dir_view, -commonData.dir_light) + 0.4,0.4, 1);
                // VoL = 1;
                half3 back_color = VoL * (thickness) * surfaceData.diffuseColor * commonData.lightColor * surfaceData.occlusion * (_BackLightIntensity * _BackLightColor);

                return half4(skin_color + indirect_color + back_color,surfaceData.alpha);
            }

            Varyings vert( Attributes v)
            {
                Varyings o= (Varyings)0;

                o.vertex                = TransformObjectToHClip(v.vertex.xyz);
                o.uv                    = v.uv;
                o.world_normal.xyz      = TransformObjectToWorldNormal(v.normal);
                o.world_tangent.xyz     = TransformObjectToWorldDir(v.tangent.xyz);
                o.world_binormal.xyz    = cross(o.world_normal,o.world_tangent) * v.tangent.w;

                half3 pos_world         = TransformObjectToWorld(v.vertex.xyz);
                o.world_normal.w        = pos_world.x;
                o.world_tangent.w       = pos_world.y;
                o.world_binormal.w      = pos_world.z;
                
                #if defined(_MAIN_LIGHT_SHADOWS)
                    #if !defined(ENABLE_HQ_SHADOW)
                        o.shadowCoord           = TransformWorldToShadowCoord(pos_world);
                    #endif
                #endif
                
                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.world_normal, o.vertexSH);

                return o;
            }
            
            float4 frag(Varyings i):SV_TARGET
            {
                SurfaceDataSkin surfaceData;
                CommonData commonData;

                InitData(i,surfaceData,commonData);

                
                uint meshRenderingLayers = GetMeshRenderingLightLayer();
                Light light = GetMainLight_SGame(commonData.pos_world,i.shadowCoord);

                UpdateLightData(commonData,light);
                // commonData.NdotL += var_BlushArea.g;
                
                float4 skin_color = SkinColor(surfaceData,commonData,i,light,meshRenderingLayers );

                return skin_color;

            }
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

            #include "Assets/Renders/Shaders/ShaderLibrary/Shadow/FlatShadow.hlsl"
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

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        // UsePass "Universal Render Pipeline/Lit/DepthNormals"
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
    CustomEditor "FBShaderGUI.SGameSkinGUI"
}
