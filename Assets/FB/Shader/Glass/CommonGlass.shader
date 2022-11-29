Shader "FB/Glass/CommonGlass"
{
    Properties
    {

        [Space(15)]
        //[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        //[Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1.0 //"On"
        _ColorCubemap("ColorCubemap(环境反射颜色)", Color) = (1,1,1,1)
        _PowerFresnel("FresnelPower(菲尼尔Pow)", Float) = 1
        _GlobalIlluminationIns("GlobalIlluminationIns(环境强度)", range(0,5)) = 1
        _IndexofRefraction("Refraction(折射强度)", range(0,1)) = 0.2
        _ChromaticAberration("ChromaticAberration(偏光)", Range(0 , 1)) = 0.1
        _OpaqueColor("OpaqueColor(背景颜色)", Color) = (1,1,1,1)    //

        //PBR
        _SpecIntensity("SpecIntensity(高光强度)", Range(0 , 1)) = 0.3

        //[MaterialToggle(_PS_ON)] _PSON("PSON(明度饱和度)", int) = 0

        [MaterialToggle(_PBR_ON)] _PBRON("PBRON(PBR高光)", int) = 0

        [Header(MainTex)]
        //_Brightness("Brightness(明度)", Range(1 , 16)) = 1
        //_Saturation("Saturation(饱和度)",range(-1,100)) = 0
        [NoScaleOffset] [MainTexture] _BaseMap("MainTex(A:透明度)", 2D) = "white" {}
        [MainColor] _BaseColor("MainColor", Color) = (0,0,0,0)
        _BaseMap_TilingOffset("TilingOffset", vector) = (1,1,0,0)
        _NormalScale("NormalScale", Float) = 1.0
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        [HDR]_MainEmissionColor("MainEmissionColor", Color) = (0,0,0,1)
        [NoScaleOffset]_MainEmission("MainEmission", 2D) = "white" {}
        _MainMetallicStrength("MainMetallicStrength(金属度)", range(0,1)) = 0
        _MainSmoothnessStrength("MainSmoothnessStrength(光滑度)", range(0,1)) = 1
        _MainAOStrength("MainAOStrength(AO)", range(0,1)) = 1
        [NoScaleOffset]_MainMTex("MainMTex(R:金属度 G:AO B: A:光滑度)", 2D) = "white" {}

        //_DECAL_ON
        [MaterialToggle(_DECAL_ON)] _DECALON("DECALON(细节)", int) = 0
        [Space(25)]
        //_SaturationDecal("SaturationDecal(饱和度)",range(-1,100)) = 0
        //_BrightnessDecal("Brightness(明度)", Range(1 , 16)) = 1
        _DetailColor("DetailColor", Color) = (0,0,0,0)
        [NoScaleOffset]_DetailAlbedo("DetailAlbedo(A:透明度)", 2D) = "white" {}
        [NoScaleOffset]_DetailAlbedoMask("DetailAlbedo(R:细节纹理范围遮罩)", 2D) = "black" {}
        _Detail_TilingOffset("TilingOffset", vector) = (1,1,0,0)
        _NormalDetailScale("DetailNormalScale", Float) = 1.0
        [NoScaleOffset]_NormalMapDetail("DetailNormalMap", 2D) = "bump" {}
        _BumpScaleDecal("BumpScaleDecal(细节法线混合占比)",range(0,1)) = 0.5
        [Space(5)]
        [HDR]_DecalEmissionColor("DecalEmissionColor", Color) = (0,0,0,1)
        [NoScaleOffset]_DecalEmission("DecalEmission", 2D) = "white" {}
        _DecalMetallicStrength("DecalMetallicStrength(金属度)", range(0,1)) = 0
        _DecalSmoothnessStrength("DecalSmoothnessStrength(光滑度)", range(0,1)) = 1
        _DecalAOStrength("DecalAOStrength(AO)", range(0,1)) = 1
        [NoScaleOffset]_DecalMTex("DecalMTex(R:金属度 G:AO B: A:光滑度)", 2D) = "white" {}

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


        //平面阴影
        _ShadowColor("Shadow Color", Color) = (0.83,0.89,0.97,0.25)
        _ShadowHeight("Shadow Height", float) = 0
        _ShadowOffsetX("Shadow Offset X", float) = 0.0
        _ShadowOffsetZ("Shadow Offset Y", float) = 0.0
        _ProGameOutDir("ProGameOutDir", vector) = (-1.04, 1.9, 1.61,0)
        _PlantShadowOpen("PlantShadowOpen", float) = 1
    }

    HLSLINCLUDE
    #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"

    #if defined(_DECAL_ON)
        TEXTURE2D_X(_NormalMapDetail);
        SAMPLER(sampler_NormalMapDetail);
        TEXTURE2D_X(_DetailAlbedo);//
        SAMPLER(sampler_DetailAlbedo);
        TEXTURE2D_X(_DetailAlbedoMask);
        SAMPLER(sampler_DetailAlbedoMask);
        TEXTURE2D_X(_DecalEmission);
        SAMPLER(sampler_DecalEmission);
        TEXTURE2D_X(_DecalMTex);
        SAMPLER(sampler_DecalMTex);

    #endif

    TEXTURE2D_X(_BaseMap);
    SAMPLER(sampler_BaseMap);
    TEXTURE2D_X(_NormalMap);
    SAMPLER(sampler_NormalMap);
    TEXTURE2D_X(_MainEmission);
    SAMPLER(sampler_MainEmission);
    TEXTURE2D_X(_MainMTex);
    SAMPLER(sampler_MainMTex);
    //TEXTURE2D_X(_CameraColorTexture);
    //SAMPLER(sampler_CameraColorTexture);
    sampler2D _CameraColorTexture;

    CBUFFER_START(UnityPerMaterial)

        half _SaturationDecal;
        half _BumpScaleDecal;
        half _BrightnessDecal;
        half4 _DecalEmissionColor;
        half _DecalMetallicStrength;
        half _DecalSmoothnessStrength;
        half _DecalAOStrength;
        half _NormalDetailScale;
        float4 _Detail_TilingOffset;
        half4 _DetailColor;

        half4 _BaseColor;
        half _NormalScale;
        float4 _BaseMap_TilingOffset;
        half _Saturation;
        half _Brightness;
        half _PowerFresnel;
        half4 _ColorCubemap;
        half4 _MainEmissionColor;
        half _MainMetallicStrength;
        half _MainSmoothnessStrength;
        half _MainAOStrength;
        half _IndexofRefraction;
        half _ChromaticAberration;
        half _SpecIntensity;
        half _GlobalIlluminationIns;
        half4 _OpaqueColor;

        float4 _BaseMap_ST;
        half _Cutoff;
    CBUFFER_END
    ENDHLSL

    SubShader
    {

        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"}

        ZWrite[_ZWrite]
        Cull[_Cull]
        Blend SrcAlpha OneMinusSrcAlpha

        //      Pass //2
        //{
            //	Name "ShadowBeforePost"
            //	Tags {"LightMode"="SGameShadowPass"}
            //	Stencil
            //	{
                //		Ref 0
                //		Comp equal
                //		Pass incrWrap
                //		Fail keep
                //		ZFail keep
            //	}
            //	
            //	Blend DstColor Zero
            //	ColorMask RGB
            //	ZWrite off
            //	
            //	HLSLPROGRAM
            //		#pragma vertex vertGameOut
            //		#pragma fragment frag
            //		#include "../ShaderLibrary/FlatShadow.hlsl"
            //	ENDHLSL
        //}

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            //Cull Front

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile _ _PBR_ON //PBR高光
            #pragma multi_compile _ _DECAL_ON //细节
            #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
            //#pragma multi_compile _ _PS_ON //明度 饱和度调节

            // -------------------------------------
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            // -------------------------------------
            // Unity defined keywords
            //#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            //#pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex GlassVertex
            #pragma fragment GlassFragment

            

            struct GlassInput {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VaryingsOUT {
                float4 uv0:TEXCOORD0; //xy：祝文里与法线UV zw:细节纹理与法线UV
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
                float3 positionWS               : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;
                float4 tangentWS                : TEXCOORD4;
                float4 shadowCoord              : TEXCOORD5;
                float4 projection : TEXCOORD6;
                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float2 UVTilingOffsetGlass(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            VaryingsOUT GlassVertex(GlassInput input)
            {
                VaryingsOUT output = (VaryingsOUT)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.uv0.xy = UVTilingOffsetGlass(input.texcoord.xy, _BaseMap_TilingOffset);
                #if defined(_DECAL_ON)
                    output.uv0.zw = UVTilingOffsetGlass(input.texcoord.xy, _Detail_TilingOffset);
                #endif
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);
                output.tangentWS = tangentWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.projection = ComputeScreenPos(output.positionCS);

                //shadow
                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF) && (!defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW))
                    //shadow
                    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                #else
                    output.shadowCoord = float4(0, 0, 0, 0);
                #endif
                return output;
            }

            float3 NormalBlendReoriented(float3 A, float3 B)
            {
                float3 t = A.xyz + float3(0.0, 0.0, 1.0);
                float3 u = B.xyz * float3(-1.0, -1.0, 1.0);
                return (t / t.z) * dot(t, u) - u;
            }

            //明度
            float4 CalculateContrast(float contrastValue, float4 colorTarget)
            {
                half halfA = colorTarget.a * 0.5;
                half halfContrastValue = contrastValue * halfA;
                halfContrastValue = halfA - halfContrastValue;
                half r = contrastValue * colorTarget.r + halfContrastValue;  //contrastValue * (colorTarget.r - halfA) + halfA;
                half g = contrastValue * colorTarget.g + halfContrastValue; //contrastValue * (colorTarget.g - halfA) + halfA;
                half b = contrastValue * colorTarget.b + halfContrastValue; //contrastValue * (colorTarget.b - halfA) + halfA;
                return half4(r, g, b, colorTarget.a);
            }

            half DirectBRDFSpecularGlass(half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, float roughness2MinusOne, half roughness2,half normalizationTerm)
            {
                float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));

                float NoH = saturate(dot(normalWS, halfDir));
                half LoH = saturate(dot(lightDirectionWS, halfDir));

                float d = NoH * NoH * roughness2MinusOne + 1.00001f;

                half LoH2 = LoH * LoH;
                half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);

                #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
                    specularTerm = specularTerm - HALF_MIN;
                    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
                #endif

                return specularTerm;
            }

            half3 LightingPhysicallyBasedGlass(half3 diffuse, half3 specular,
            half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
            half3 normalWS, half3 viewDirectionWS,float roughness2MinusOne,half roughness2, half normalizationTerm) {
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * saturate(NdotL));
                half3 brdf = diffuse;

                brdf += specular * DirectBRDFSpecularGlass(normalWS, lightDirectionWS, viewDirectionWS, roughness2MinusOne, roughness2, normalizationTerm);
                return brdf * radiance;
            }

            half4 GlassFragment(VaryingsOUT input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                //主纹理
                float4 mainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0.xy)* _BaseColor;
                half alpha = mainTex.a;

                //#if defined(_PS_ON)
                //    float saturationDot = dot(mainTex.rgb, float3(0.299, 0.587, 0.114));
                //    mainTex.rgb = lerp(mainTex.rgb, saturationDot.xxx, -_Saturation);
                //    mainTex = CalculateContrast(_Brightness, mainTex);
                //#endif

                //法线1
                half4 n = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv0.xy);
                half3 normalTex = UnpackNormalScale(n, _NormalScale);
                
                #if defined(_DECAL_ON)
                    //细节纹理
                    float4 detailAlbedoTex = SAMPLE_TEXTURE2D(_DetailAlbedo, sampler_DetailAlbedo, input.uv0.zw);
                    detailAlbedoTex = detailAlbedoTex * _DetailColor;
                    float4 detailAlbedoMaskTex = SAMPLE_TEXTURE2D(_DetailAlbedoMask, sampler_DetailAlbedoMask, input.uv0.zw);

                    //#if defined(_PS_ON)
                    //    float saturationDecalDot = dot(detailAlbedoTex.rgb, float3(0.299, 0.587, 0.114));
                    //    detailAlbedoTex.rgb = lerp(detailAlbedoTex.rgb, saturationDecalDot.xxx, -_SaturationDecal);
                    //    detailAlbedoTex = CalculateContrast(_BrightnessDecal, detailAlbedoTex);
                    //#endif

                    alpha = lerp(alpha, detailAlbedoTex.a, detailAlbedoMaskTex.r);
                    //细节法线2
                    n = SAMPLE_TEXTURE2D(_NormalMapDetail, sampler_NormalMapDetail, input.uv0.zw);
                    half3 normalDetailTex = UnpackNormalScale(n, _NormalDetailScale);
                    half3 normalTexLerp = lerp(normalDetailTex, NormalBlendReoriented(normalTex, normalDetailTex), _BumpScaleDecal);
                    normalTex = lerp(normalTex, normalTexLerp, detailAlbedoMaskTex.r);
                    //
                    half3 albedo = lerp(mainTex.rgb, detailAlbedoTex.rgb, detailAlbedoMaskTex.r).rgb;
                #else
                    half3 albedo = mainTex.rgb;
                #endif

                //
                float3 positionWS = input.positionWS;
                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                float3 normalWS = TransformTangentToWorld(normalTex, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                normalWS = normalWS+ 0.00001 * input.projection.xyz * normalWS;

                //金属度 光滑度 AO
                half3 specular = half3(0.0h, 0.0h, 0.0h);
                half4 mainMTexColor = SAMPLE_TEXTURE2D(_MainMTex, sampler_MainMTex, input.uv0.xy);
                mainMTexColor = half4(mainMTexColor.r * _MainMetallicStrength, LerpWhiteTo(mainMTexColor.g, _MainAOStrength), mainMTexColor.b, mainMTexColor.a * _MainSmoothnessStrength);

                #if defined(_DECAL_ON)
                    half4 decalMTexColor = SAMPLE_TEXTURE2D(_DecalMTex, sampler_DecalMTex, input.uv0.zw);
                    decalMTexColor = half4(decalMTexColor.r * _DecalMetallicStrength, LerpWhiteTo(decalMTexColor.g, _DecalAOStrength), decalMTexColor.b, decalMTexColor.a * _DecalSmoothnessStrength);
                    half4 mColor = lerp(mainMTexColor, decalMTexColor, detailAlbedoMaskTex.r);
                #else
                    half4 mColor = mainMTexColor;
                #endif

                half smoothness = mColor.a;
                half metallic = mColor.r;
                half occlusion = mColor.g;

                //
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);

                //PBR计算
                half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
                half reflectivity = 1.0 - oneMinusReflectivity;
                half3 brdfDiffuse = albedo * oneMinusReflectivity;
                half3 brdfSpecular = lerp(kDieletricSpec.rgb, albedo, metallic);

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
                        input.shadowCoord.x = HighQualityRealtimeShadow(positionWS);
                    #else
                        input.shadowCoord = input.shadowCoord;
                    #endif
                #else
                    input.shadowCoord = float4(0, 0, 0, 0);
                #endif

                half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
                half roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);
                half roughness2 = max(roughness * roughness, HALF_MIN);
                half grazingTerm = saturate(smoothness + reflectivity);
                #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
                    half4 shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                #elif !defined (LIGHTMAP_ON)
                    half4 shadowMask = unity_ProbesOcclusion;
                #else
                    half4 shadowMask = half4(1, 1, 1, 1);
                #endif

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if ENABLE_HQ_SHADOW
                        Light mainLight = GetMainLight(float4(0,0,0,0), positionWS, shadowMask);
                        #if defined(_RECEIVE_SHADOWS_OFF)
                            mainLight.shadowAttenuation=1;
                        #else
                            mainLight.shadowAttenuation = input.shadowCoord.x;
                        #endif
                    #elif defined(ENABLE_HQ_AND_UNITY_SHADOW)
                        Light mainLight = GetMainLight(input.shadowCoord);
                        #if defined(_RECEIVE_SHADOWS_OFF)
                            mainLight.shadowAttenuation=1;
                        #else
                            mainLight.shadowAttenuation = input.shadowCoord.x*mainLight.shadowAttenuation;
                        #endif
                    #else
                        Light mainLight = GetMainLight(input.shadowCoord, positionWS, shadowMask);
                    #endif
                #else
                    Light mainLight = GetMainLight(input.shadowCoord, positionWS, shadowMask);
                #endif

                half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, normalWS);
                MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI);
                float NV = dot(normalWS, viewDirWS);
                half NoV = saturate(NV);
                half3 reflectVector = reflect(-viewDirWS, normalWS);
                half fresnelTerm = pow(1.0 - NoV, _PowerFresnel);
                half3 indirectDiffuse = bakedGI * occlusion;
                half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);
                #if defined(UNITY_USE_NATIVE_HDR)
                    half3 irradiance = encodedIrradiance.rgb;
                #else
                    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                #endif
                half3 indirectSpecular = irradiance * occlusion;
                half3 globalIllumination = indirectDiffuse * brdfDiffuse;
                float surfaceReduction = 1.0 / (roughness2 + 1.0);
                globalIllumination += indirectSpecular* surfaceReduction * lerp(brdfSpecular, grazingTerm, fresnelTerm);
                globalIllumination = globalIllumination * _ColorCubemap.rgb* _GlobalIlluminationIns;

                #if defined(_PBR_ON)
                    half normalizationTerm = roughness * 4.0h + 2.0h;
                    half roughness2MinusOne = roughness2 - 1.0h;
                    half3 pbr = LightingPhysicallyBasedGlass(brdfDiffuse, brdfSpecular, mainLight.color, mainLight.direction, mainLight.distanceAttenuation * mainLight.shadowAttenuation,
                    normalWS, viewDirWS, roughness2MinusOne, roughness2, normalizationTerm);
                    #ifdef _ADDITIONAL_LIGHTS
                        uint pixelLightCount = GetAdditionalLightsCount();
                        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                        {
                            Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
                            #if defined(_SCREEN_SPACE_OCCLUSION)
                                light.color *= aoFactor.directAmbientOcclusion;
                            #endif
                            pbr += LightingPhysicallyBasedGlass(brdfDiffuse, brdfSpecular,
                            mainLight.color, mainLight.direction, mainLight.distanceAttenuation * mainLight.shadowAttenuation,
                            normalWS, viewDirWS, roughness2MinusOne, roughness2, normalizationTerm);
                        }
                    #endif
                    albedo = albedo + pbr * _SpecIntensity;
                #endif

                half4 emissionMain = SAMPLE_TEXTURE2D(_MainEmission, sampler_MainEmission, input.uv0.xy) * _MainEmissionColor;
                #if defined(_DECAL_ON)
                    half4 emissionDecal = SAMPLE_TEXTURE2D(_DecalEmission, sampler_DecalEmission, input.uv0.zw) * _DecalEmissionColor;
                    half3 emission = globalIllumination.rgb + lerp(emissionMain.rgb, emissionDecal.rgb, detailAlbedoMaskTex.r);
                #else
                    half3 emission = globalIllumination.rgb + emissionMain.rgb;
                #endif

                //抓图 
                float4 screenPos = input.projection;
                #if UNITY_UV_STARTS_AT_TOP
                    float scale = -1.0;
                #else
                    float scale = 1.0;
                #endif
                float halfPosW = screenPos.w * 0.5;
                screenPos.y = (screenPos.y - halfPosW) * _ProjectionParams.x * scale + halfPosW;
                float2 opaqueTexOffset = mul(UNITY_MATRIX_V, float4(normalWS, 0.0)).xy * _IndexofRefraction * (1 - NV);
                float2 projScreenPos = (screenPos / screenPos.w).xy;
                
                float2 grabUV = frac(projScreenPos + opaqueTexOffset);
                half3 opaqueTex =  tex2D(_CameraColorTexture,grabUV).r;
                grabUV = frac(projScreenPos + opaqueTexOffset * (1 - _ChromaticAberration));
                half opaqueTexG = tex2D(_CameraColorTexture,grabUV).g;
                grabUV = frac(projScreenPos + opaqueTexOffset * (1 + _ChromaticAberration));
                half opaqueTexB = tex2D(_CameraColorTexture,grabUV).b;
                opaqueTex = half3(opaqueTex.r, opaqueTexG, opaqueTexB);

                albedo = albedo + opaqueTex * (1- alpha)* _OpaqueColor.rgb;
                half4 finalColor;
                finalColor.rgb = albedo + emission;
                finalColor.rgb=clamp(finalColor.rgb,half3(0,0,0),half3(8,8,8));
                return half4(finalColor.rgb,alpha);
            }

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

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "FBShaderGUI.GlassShaderGUI"
}
