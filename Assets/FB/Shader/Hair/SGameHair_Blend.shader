Shader "FB/Charactor/SGameHair_Blend"  
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        // _BumpMap("Normal Map", 2D) = "bump" {}
        
        _MetallicGlossMap("R(Anisotropy)G(AO)B(Smoothness)", 2D) = "white" {}
        _Metallic("Anisotropy", Range(0.0, 1.0)) = 1.0
        _GlossMapScale("Smoothness", Range(0.0, 1.0)) = 1.0
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 0.5
        
        _SpecularMultiplier("Specular Multiplier", float) = 128
        _PrimaryShift("Specular Primary Shift", float) = 0.02
        _EnvBoost1k("Specular Primary Boost", Range(0.5, 2)) = 1

        _SpecularMultiplier2("Secondary Specular Multiplier", float) = 128
        _SecondaryShift("Specular Secondary Shift", float) = -0.6
        _EnvBoost2k("Specular Secondary Boost", Range(0.5, 2)) = 1
        
        _CutOff("Cut Off", Range(0.0, 1.0)) = 0.02
        _SCutOff("Shadow Cut Off", Range(0.0, 1.0)) = 0.2

    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "Queue" = "Transparent"
        }
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha, One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW

            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_instancing
            #define _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag


            #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

            #define XColorSpaceDielectricSpecHair half4(0.08, 0.08, 0.08, 1.0 - 0.08) // standard dielectric reflectivity coef at incident angle (= 4%)

            CBUFFER_START(UnityPerMaterial)
                half4  _Color;
                float4 _MainTex_ST;

                half   _Metallic;
                half   _GlossMapScale;
                half   _OcclusionStrength;

                float  _CutOff;

                float  _EnvBoost1k;
                float  _EnvBoost2k;

                float  _SpecularMultiplier;
                float  _SpecularMultiplier2;
                float  _PrimaryShift;
                float  _SecondaryShift;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // TEXTURE2D(_BumpMap);
            // SAMPLER(sampler_BumpMap);

            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;

                float4 tangentOS    : TANGENT;

                float2 uv     		: TEXCOORD0;
                float4 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0; 	
                float3 positionWS               : TEXCOORD1;

                half3 normalWS                 	: TEXCOORD2;

                half4 tangentWS                	: TEXCOORD3;    // xyz: tangent, w: sign

                half3 viewDirWS                	: TEXCOORD4;

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    float4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
                #else
                    float  fogFactor                 : TEXCOORD5;
                #endif

                // #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                float4 shadowCoord              : TEXCOORD6;
                // #endif
                
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);
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

            float XSSSDiffuse(float ndl, float ndv)
            {
                float curve = 0.5;
                float inv = (1 - curve);
                float xx = (ndl * inv + curve);
                return xx * xx * (ndv * inv + curve);
            }

            half4 Hair_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half rough,
            float3 normal, float3 bitangent, float3 viewDir,
            Light light, float3 indirectDiffuse ,float3 indirectSpecular, float anisotropy, float3 ambient)
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

                half shiftTex = anisotropy;
                half3 T = bitangent;

                half3 t1 = ShiftTangent(T, normal, _PrimaryShift + shiftTex) ;
                half3 t2 = ShiftTangent(T, normal, _SecondaryShift + shiftTex) ;

                //Specular term
                float specularTerm;
                float attenSpec =  (onl * 0.5 + 0.5);
                specularTerm = _EnvBoost1k * StrandSpecular(t1, viewDir, light.direction, _SpecularMultiplier)* attenSpec;
                specularTerm += _EnvBoost2k * StrandSpecularS(t2, viewDir, _SpecularMultiplier2)* attenSpec;

                specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles

                float EdotH = abs(dot(viewDir, halfDir));

                half3 color = (diffColor * XSSSDiffuse(nl, nv) + specColor * specularTerm) * max(light.color, 0.7)
                + indirectDiffuse * (ambient + min(EdotH, 0.2) + 0.5*saturate(0.5-0.5*onl)*nv) * diffColor
                + indirectSpecular;

                return half4(color, 1);
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
                float sgn = i.tangentWS.w;      // should be either +1 or -1
                float3 binormal_dir = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);

                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);

                // float4 normal_map = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,i.uv);
                // float3 normal_data = UnpackNormal(normal_map);
                // normal_dir = normalize(mul(normal_data,TBN));

                bool backface = facing < 0.0;

                if (backface)
                normal_dir = -normal_dir;

                float3 reflect_dir = reflect(-view_dir,normal_dir);

                //---------------
                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, normal_dir);
                
                float4 base_color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Color;
                half3 hair_map = SAMPLE_TEXTURE2D(_MetallicGlossMap,sampler_MetallicGlossMap,i.uv).rgb;

                half metallic = hair_map.r * _Metallic;
                half roughness = (1 - hair_map.b) * _GlossMapScale; //lerp(1 - metaGloss.b * _GlossMapScale, 0, _GlobalLightSetting.z);
                half occlusion = lerp(1,hair_map.g, _OcclusionStrength);

                half4 lum = max(max(base_color.r, base_color.g), base_color.b);
                half4 mDielectricSpec = lerp(XColorSpaceDielectricSpecHair, kDieletricSpec, lum);

                half oneMinusReflectivity = mDielectricSpec.a;
                half3 diffColor = base_color.rgb * oneMinusReflectivity;
                half3 specColor = lerp(base_color , mDielectricSpec.rgb, 0.6);

                half3 indirectDiffuse = occlusion;
                // half3 indirectSpecular = occlusion * GlossyEnvironmentReflection(reflect_dir,i.positionWS,max(roughness, 0.1),1.0);
                half3 indirectSpecular = 0;

                // indirectSpecular
                // bakedGI
                
                half3 color = Hair_PBS(diffColor,  specColor, oneMinusReflectivity, roughness, normal_dir, binormal_dir, view_dir, light_data, indirectDiffuse,indirectSpecular, metallic, bakedGI).rgb;
                
                float alpha = base_color.a ;//* _Alpha;


                return half4(clamp(color.rgb, 0, 36), saturate(alpha));
            }
            ENDHLSL 
        }
    }
}
