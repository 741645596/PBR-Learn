Shader "FB/Charactor/SGameHair_Alpha"  
{
    Properties
    {
        _BaseColor("Main Color", Color) = (1,1,1,1)
        _BaseMap("Albedo", 2D) = "white" {}
        _ColorShift("主颜色<-颜色偏向->高光颜色", Range(0.0, 1.0)) = 1.0

        [Space(25)]
        _MetallicGlossMap("R(Anisotropy)G(AO)B(Smoothness)", 2D) = "white" {}
        _Anisotropy("Anisotropy", Range(0.0, 1.0)) = 1.0
        _GlossMapScale("Smoothness", Range(0.0, 1.0)) = 1.0
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 0.5

        _OcclusionUV1("UV2 AO", 2D) = "white"{}
        
        [Header(Specular 1)]
        _SpecColor1("高光颜色1", Color) = (1,1,1,1)
        _PrimaryShift("高光位移", Range(-1, 1)) = 0.02
        _SpecularMultiplier("光滑度", Range(0, 1)) = .5
        _EnvBoost1k("亮度", Range(0, 2)) = 1
        
        [Header(Specular 2)]
        _SpecColor2("高光颜色2", Color) = (1,1,1,1)
        _SecondaryShift("高光位移", Range(-1, 1)) = -0.6
        _SpecularMultiplier2("光滑度", Range(0, 1)) = .5
        _EnvBoost2k("高光亮度", Range(0.5, 2)) = 1
        
        [Space(25)]
        _Cutoff("Cut Off", Range(0.0, 1.0)) = 0.02
        // _SCutOff("Shadow Cut Off", Range(0.0, 1.0)) = 0.2

        _DitherHair("Dither", Range(-32.0, 32.0)) = 11
        _DitherIntensity("DitherIntensity", Range(0.0, 1.0)) = 0

        _ShadowInt("阴影强度", Range(0, 1)) = 0.5

        //平面阴影
        _ShadowColor("Shadow Color", Color) = (0.83,0.89,0.97,0.25)
        _ShadowHeight("Shadow Height", float) = 0
        _ShadowOffsetX("Shadow Offset X", float) = 0.0
        _ShadowOffsetZ("Shadow Offset Y", float) = 0.0

        [HideInInspector]_MeshHight("_MeshHight", float) = 0.0
        [HideInInspector]_WorldPos("_WorldPos", vector) = (0,0,0,0)

        _ProGameOutDir("ProGameOutDir", vector) = (-1.04, 1.9, 1.61,0)
        [HideInInspector]_PlantShadowOpen("PlantShadowOpen", float) = 1
    }

    HLSLINCLUDE

    // Material Keywords
    #pragma shader_feature _ALPHATEST_ON
    #pragma shader_feature _RECEIVE_SHADOWS_OFF
    #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW

    // Universal Pipeline keywords
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
    #pragma multi_compile _ SHADOWS_SHADOWMASK

    #define _SHADOWS_SOFT

    #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"
    #include "Assets/Renders/Shaders/ShaderLibrary/Common/GlobalIllumination.hlsl"

    #define XColorSpaceDielectricSpecHair half4(0.08, 0.08, 0.08, 1.0 - 0.08) // standard dielectric reflectivity coef at incident angle (= 4%)

    CBUFFER_START(UnityPerMaterial)
        half4  _BaseColor;

        half4 _SpecColor1;
        half4 _SpecColor2;

        float4 _BaseMap_ST;
        float4 _MetallicGlossMap_ST;

        half   _Anisotropy;
        half   _GlossMapScale;
        half   _OcclusionStrength;

        float  _Cutoff;
        // float _SCutOff;

        float  _EnvBoost1k;
        float  _EnvBoost2k;

        float  _SpecularMultiplier;
        float  _SpecularMultiplier2;
        float  _PrimaryShift;
        float  _SecondaryShift;

        half _DitherHair;
        half _DitherIntensity;

        half _ColorShift;
        half _ShadowInt;

        // shadow
        half4  _ShadowColor;		//阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
        
        float  _ShadowHeight;		//阴影平面的高度 目前由外部脚本设定 UpdateShadowPlane.cs
        
        float  _ShadowOffsetX;		//XZ平面的偏移
        float  _ShadowOffsetZ;

        float  _MeshHight;			//模型高度 由外部脚本设定 UpdateShadowPlane.cs
        float4 _WorldPos;			//模型位置 由外部脚本设定 UpdateShadowPlane.cs
        
        half  _AlphaVal;			//影子透明度

        half3 _ProGameOutDir;
    CBUFFER_END
    
    TEXTURE2D(_BaseMap);
    
    SAMPLER(sampler_BaseMap);

    TEXTURE2D(_MetallicGlossMap);
    SAMPLER(sampler_MetallicGlossMap);

    TEXTURE2D(_OcclusionUV1);
    SAMPLER(sampler_OcclusionUV1);

    half3 ShiftTangent(half3 T, half3 N, float shift)
    {
        half3 shiftedT = T + shift * N;
        return normalize(shiftedT);
    }

    float StrandSpecular(half3 T, half3 V, half3 L, float exponent)
    {
        half3 H = normalize(L + V);
        float dotTH = dot(T, H);
        float sinTH = sqrt(1 - dotTH * dotTH);
        float dirAtten = smoothstep(-1, 0, dotTH);
        return dirAtten * pow(sinTH, exponent);
    }

    float StrandSpecularS(half3 T, half3 V, float exponent)
    {
        float dotTH = dot(T, V);
        float sinTH = sqrt(1 - dotTH * dotTH);
        float dirAtten = smoothstep(-1, 0, dotTH);
        return dirAtten * pow(sinTH, exponent);
    }

    // 要改
    float XSSSDiffuse(float ndl, float ndv)
    {
        float curve = 0.5;
        float inv = (1 - curve);
        float xx = (ndl * inv + curve);
        return xx * xx * (ndv * inv + curve);
    }

    half4 Hair_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half rough,
    float3 normal, float3 bitangent, float3 viewDir,
    Light light, float3 indirectDiffuse ,float3 indirectSpecular, float anisotropy, float3 occlusion,float3 positionWS)
    {
        float3 h = float3(light.direction) + viewDir; // Unnormalized half-way vector
        float3 halfDir = SafeNormalize(h);

        half onl = dot(normal, light.direction);
        half nl = saturate(onl);
        float nh = saturate(dot(normal, halfDir));
        half nv = saturate(dot(normal, viewDir));
        float lh = saturate(dot(light.direction, halfDir));

        // Specular term
        half perceptualRoughness = (rough);
        half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
        roughness = pow(roughness,2);

        half shiftTex = anisotropy;
        half3 T = bitangent;

        half3 t1 = ShiftTangent(T, normal, _PrimaryShift + shiftTex) ;
        half3 t2 = ShiftTangent(T, normal, _SecondaryShift + shiftTex) ;

        //Specular term
        float3 specularTerm;
        float attenSpec =  (onl * 0.5 + 0.5);
        specularTerm = _EnvBoost1k * StrandSpecular(t1, viewDir, light.direction, _SpecularMultiplier* _SpecularMultiplier * 1000) * attenSpec * _SpecColor1.rgb;
        specularTerm += _EnvBoost2k * StrandSpecularS(t2, viewDir, _SpecularMultiplier2 * _SpecularMultiplier2 * 1000) * attenSpec * _SpecColor2.rgb;

        specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles

        float EdotH = abs(dot(viewDir, halfDir));

        half3 radiance = light.color * (light.distanceAttenuation * lerp(diffColor*0.3, 1, lerp(light.shadowAttenuation , 1 , 1 - _ShadowInt)) * nl);
        // radiance = light.color * (light.distanceAttenuation * lerp(light.shadowAttenuation , 1 , 0.5) * nl);
        // radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation * nl);

        half3 direct_color = (diffColor * XSSSDiffuse(nl, nv) + specColor * specularTerm) * max(light.color, 0.7);


        // half3 indirect_color = indirectDiffuse * (bakedGI + min(EdotH, 0.2) + 0.5 * saturate(0.5-0.5 * onl) * nv) * diffColor + indirectSpecular;
        float3 new_t = normalize(normal+T*(shiftTex*2-1));
        
        float3 reflectVector = reflect(-viewDir, new_t);
        half3 indirect_color = (indirectDiffuse * diffColor + UEIBL(reflectVector,positionWS, rough,specColor,nv,1));

        half3 final_color = (direct_color * radiance + indirect_color * occlusion)  ;
        // final_color = (direct_color + indirect_color )  * occlusion;

        return half4(final_color, 1);
    }
    ENDHLSL

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
        
        }
        
        Pass
        {
            Tags {"LightMode"="SRPDefaultUnlit"}

            Cull Off

            HLSLPROGRAM

            #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"

            #pragma vertex vertBase
            #pragma fragment fragBase

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0; 	
                float4 positionSC   : TEXCOORD1; 
            };

            //顶点着色
            Varyings vertBase(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.positionSC = ComputeScreenPos(o.positionCS);
                return o;
            }

            float ScreenDitherToAlpha(float2 uv, float c0, float ditherA)
            {
                uv *= _ScreenParams.xy;

                const float dither[64] = {
                    0, 32, 8, 40, 2, 34, 10, 42,
                    48, 16, 56, 24, 50, 18, 58, 26 ,
                    12, 44, 4, 36, 14, 46, 6, 38 ,
                    60, 28, 52, 20, 62, 30, 54, 22,
                    3, 35, 11, 43, 1, 33, 9, 41,
                    51, 19, 59, 27, 49, 17, 57, 25,
                    15, 47, 7, 39, 13, 45, 5, 37,
                63, 31, 55, 23, 61, 29, 53, 21 };

                // int xMat = int(uv.x) % 8;
                // int yMat = int(uv.y) % 8;

                int xMat = int(uv.x) & 7;
                int yMat = int(uv.y) & 7;

                float limit = (dither[yMat * 8 + xMat] + ditherA) / 64.0;
                return step(limit, c0);
            }

            half Dither4x4Bayer(float4 positionCS)
            {
                const half4x4 dither = 
                {
                    1.0 / 17.0 , 9.0 / 17.0 , 3.0 / 17.0 , 11.0 / 17.0,
                    13.0 / 17.0 , 5.0 / 17.0 , 15.0 / 17.0 , 7.0 / 17.0,
                    4.0 / 17.0 , 12.0 / 17.0 , 2.0 / 17.0 , 10.0 / 17.0,
                    16.0 / 17.0 , 8.0 / 17.0 , 14.0 / 17.0 , 6.0 / 17.0
                };

                return dither[(positionCS.x % 4.0)][(positionCS.y % 4.0)];
            }

            half4 fragBase(Varyings i) : SV_Target
            {
                half4 base_color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv) * _BaseColor;
                // ScreenDitherToAlpha(i.positionSC.xy / i.positionSC.w, base_color.a, _DitherHair)
                half alpha = lerp(base_color.a,base_color.a - ScreenDitherToAlpha(i.positionSC.xy / i.positionSC.w, base_color.a, _DitherHair),_DitherIntensity);
                clip(alpha - (1 - _Cutoff));
                // clip(base_color.a - Dither4x4Bayer(i.positionCS));
                
                return float4(base_color.rgb,1);
            }

            ENDHLSL
        }

        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            // Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest Equal
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;

                float4 tangentOS    : TANGENT;

                float2 uv     		: TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float4 lightmapUV   : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0; 	
                float2 uv1                      : TEXCOORD1;
                float3 positionWS               : TEXCOORD2;

                half3 normalWS                 	: TEXCOORD3;

                half4 tangentWS                	: TEXCOORD4;    // xyz: tangent, w: sign

                half3 viewDirWS                	: TEXCOORD5;

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    float4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
                #else
                    float  fogFactor                 : TEXCOORD6;
                #endif

                // #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                float4 shadowCoord              : TEXCOORD7;
                // #endif
                
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 8);
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                // Instance
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // Vertex
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;

                // UV
                output.uv = input.uv;
                output.uv1 = input.uv1;


                // Direction
                VertexNormalInputs normalInput;
                normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);

                output.normalWS = normalInput.normalWS;
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;;

                // Indirect light
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                // VertexLight And Fog
                float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    vertexLight = VertexLighting(output.positionWS, output.normalWS);
                    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                // shadow
                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
                        output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                    #endif
                #endif

                return output;
            }
            
            

            float4 frag(Varyings i, half facing : VFACE):SV_TARGET
            {

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
                        i.shadowCoord.x = HighQualityRealtimeShadow(i.positionWS);
                    #endif
                #endif

                Light light_data = GetMainLight_SGame(i.positionWS,i.shadowCoord);  // brdfData.shadowMask
                half3 light_dir = normalize(light_data.direction);

                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);

                half3 normal_dir = normalize(i.normalWS);
                half3 tangent_dir = normalize(i.tangentWS.xyz);
                
                bool backface = facing < 0.0;
                if (backface)
                normal_dir = -normal_dir;

                float sgn = i.tangentWS.w;      // should be either +1 or -1
                float3 binormal_dir = sgn * cross(normal_dir,tangent_dir);

                float3 reflect_dir = reflect(-view_dir,normal_dir);

                //---------------
                float4 base_color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv * _BaseMap_ST.xy + _BaseMap_ST.zw) * _BaseColor;

                half3 hair_map = SAMPLE_TEXTURE2D(_MetallicGlossMap,sampler_MetallicGlossMap ,i.uv* _MetallicGlossMap_ST.xy + _MetallicGlossMap_ST.zw).rgb;

                half anisotropy = hair_map.r * _Anisotropy;
                half roughness = (1 - hair_map.b) * (1 - _GlossMapScale); //lerp(1 - metaGloss.b * _GlossMapScale, 0, _GlobalLightSetting.z);
                half occlusionUV1 = SAMPLE_TEXTURE2D(_OcclusionUV1, sampler_OcclusionUV1 , i.uv1).r;
                half occlusion = lerp(1,hair_map.g * occlusionUV1, _OcclusionStrength);

                // return float4(occlusionUV1,x;
                // return float4(i.uv1,0,1);

                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, normal_dir);

                half4 lum = max(max(base_color.r, base_color.g), base_color.b);
                half4 mDielectricSpec = lerp(XColorSpaceDielectricSpecHair, kDieletricSpec, lum);

                half oneMinusReflectivity = mDielectricSpec.a;
                half3 diffColor = base_color.rgb * oneMinusReflectivity;
                half3 specColor = lerp(base_color.rgb , mDielectricSpec.rgb, _ColorShift) * _SpecColor1.rgb;

                half3 indirectDiffuse = bakedGI;
                half3 indirectSpecular = GlossyEnvironmentReflection(reflect_dir,i.positionWS,max(roughness, 0.1),1.0);

                // indirectSpecular
                // bakedGI
                
                half3 color = Hair_PBS(diffColor,specColor, oneMinusReflectivity, roughness, normal_dir, binormal_dir, view_dir, light_data, indirectDiffuse,indirectSpecular, anisotropy, occlusion,i.positionWS).rgb;
                
                float alpha = base_color.a ;//* _Alpha;


                return half4(clamp(color.rgb, 0, 36), saturate(alpha));
            }

            
            
            ENDHLSL 
        }

            Pass{
            
            Tags{ "LightMode" = "hairAlphaBlend" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest less
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;

                float4 tangentOS    : TANGENT;

                float2 uv     		: TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float4 lightmapUV   : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0; 	
                float2 uv1                      : TEXCOORD1;
                float3 positionWS               : TEXCOORD2;

                half3 normalWS                 	: TEXCOORD3;

                half4 tangentWS                	: TEXCOORD4;    // xyz: tangent, w: sign

                half3 viewDirWS                	: TEXCOORD5;

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    float4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
                #else
                    float  fogFactor                 : TEXCOORD6;
                #endif

                // #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                float4 shadowCoord              : TEXCOORD7;
                // #endif
                
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 8);
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                // Instance
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // Vertex
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;

                // UV
                output.uv = input.uv;
                output.uv1 = input.uv1;


                // Direction
                VertexNormalInputs normalInput;
                normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);

                output.normalWS = normalInput.normalWS;
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;;

                // Indirect light
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                // VertexLight And Fog
                float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    vertexLight = VertexLighting(output.positionWS, output.normalWS);
                    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                // shadow
                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
                        output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                    #endif
                #endif

                return output;
            }
            
            

            float4 frag(Varyings i, half facing : VFACE):SV_TARGET
            {

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
                        i.shadowCoord.x = HighQualityRealtimeShadow(i.positionWS);
                    #endif
                #endif

                Light light_data = GetMainLight_SGame(i.positionWS,i.shadowCoord);  // brdfData.shadowMask
                half3 light_dir = normalize(light_data.direction);

                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);

                half3 normal_dir = normalize(i.normalWS);
                half3 tangent_dir = normalize(i.tangentWS.xyz);
                
                bool backface = facing < 0.0;
                if (backface)
                normal_dir = -normal_dir;

                float sgn = i.tangentWS.w;      // should be either +1 or -1
                float3 binormal_dir = sgn * cross(normal_dir,tangent_dir);

                float3 reflect_dir = reflect(-view_dir,normal_dir);

                //---------------
                float4 base_color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv * _BaseMap_ST.xy + _BaseMap_ST.zw) * _BaseColor;

                half3 hair_map = SAMPLE_TEXTURE2D(_MetallicGlossMap,sampler_MetallicGlossMap ,i.uv* _MetallicGlossMap_ST.xy + _MetallicGlossMap_ST.zw).rgb;

                half anisotropy = hair_map.r * _Anisotropy;
                half roughness = (1 - hair_map.b) * (1 - _GlossMapScale); //lerp(1 - metaGloss.b * _GlossMapScale, 0, _GlobalLightSetting.z);
                half occlusionUV1 = SAMPLE_TEXTURE2D(_OcclusionUV1, sampler_OcclusionUV1 , i.uv1).r;
                half occlusion = lerp(1,hair_map.g * occlusionUV1, _OcclusionStrength);

                // return float4(occlusionUV1,x;
                // return float4(i.uv1,0,1);

                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, normal_dir);

                half4 lum = max(max(base_color.r, base_color.g), base_color.b);
                half4 mDielectricSpec = lerp(XColorSpaceDielectricSpecHair, kDieletricSpec, lum);

                half oneMinusReflectivity = mDielectricSpec.a;
                half3 diffColor = base_color.rgb * oneMinusReflectivity;
                half3 specColor = lerp(base_color.rgb , mDielectricSpec.rgb, _ColorShift) * _SpecColor1.rgb;

                half3 indirectDiffuse = bakedGI;
                half3 indirectSpecular = GlossyEnvironmentReflection(reflect_dir,i.positionWS,max(roughness, 0.1),1.0);

                // indirectSpecular
                // bakedGI
                
                half3 color = Hair_PBS(diffColor,specColor, oneMinusReflectivity, roughness, normal_dir, binormal_dir, view_dir, light_data, indirectDiffuse,indirectSpecular, anisotropy, occlusion,i.positionWS).rgb;
                
                float alpha = base_color.a / (1 - _Cutoff) ;//* _Alpha;

                //return 1;
                return half4((color.rgb), saturate(alpha));
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
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
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
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment_Hair

            #pragma multi_compile _ALPHATEST_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            half4 ShadowPassFragment_Hair(Varyings input) : SV_TARGET
            {
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, 1 - _Cutoff);
                return 0;
            }
            ENDHLSL
        }
        
        // Pass
        // {
        //     Name "DepthNormals"
        //     Tags{"LightMode" = "DepthNormals"}

        //     ZWrite On
        //     Cull[_Cull]

        //     HLSLPROGRAM
        //     #pragma exclude_renderers gles gles3 glcore
        //     #pragma target 4.5

        //     #pragma vertex DepthNormalsVertex
        //     #pragma fragment DepthNormalsFragment

        //     // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
        //     ENDHLSL
        // }

    }
    
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
