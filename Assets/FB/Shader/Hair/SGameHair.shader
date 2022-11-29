Shader "FB/Charactor/SGameHair"  
{
       Properties{

        _SpecularTint("高光1 颜色", Color) = (1.0,1.0,1.0,1.0)
        _SecondarySpecularTint("高光2 颜色", Color) = (1.0,1.0,1.0,1.0)
        _BaseMap("颜色贴图",2D) = "white"{}
        [normal]_BumpMap("法线贴图",2D) = "Bump"{}
        _OcclusionMap("AO",2D) = "white"{}
        _OcclusionStrength("AO 强度", Range(0,1)) = 0.5
        _JitterMap("高光偏移贴图", 2D) = "Black"{}
        _FirstSpecularShift("高光偏移", Range(-1,1)) = 0
        _SecondSpecularShift("高光间距", Range(-1,1)) = 0.3
        _AnisotropyInt("锯齿强度", Range(-1,1)) = 0.5
        _OffsetInt("高光锯齿强度", vector) = (10.0,1.0,0.0,0.0)
        _SpecularInt("高光亮度", Range(0, 1)) = 0.3
        _SpecularRange("高光范围", Range(0, 1)) = 0.3
        
        _UnderSpecular("底色提亮", Range(0,1)) = 0.2

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
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Opaque"
        }
        pass
        {

            cull off

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            #define _SHADOWS_SOFT
            #pragma multi_compile _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            sampler2D _JitterMap;
            sampler2D _BaseMap;
            sampler2D _BumpMap;
            sampler2D _OcclusionMap;

            CBUFFER_START(UnityPerMaterial)

                half4 _SpecularTint;
                
                half4 _SecondarySpecularTint;

                float _AnisotropyInt;
                float _SecondSpecularShift;
                float _FirstSpecularShift;
                float2 _OffsetInt;

                half _SpecularInt;
                half _SpecularRange;
                half _UnderSpecular;
                half _OcclusionStrength;

            CBUFFER_END

            struct a2v
            {
                float4 vertex:POSITION;
                float2 uv0 :TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 lightmapUV       : TEXCOORD1;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv0: TEXCOORD0;
                float3 posWS: TEXCOORD1;
                float3 nDirWS: TEXCOORD2;
                float3 tDirWS: TEXCOORD3;
                float3 bDirWS: TEXCOORD4;

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    float4 shadowCoord  : TEXCOORD5;
                #endif

                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);


            };
            
             float KKDiffuse(float ndl, float ndv)
            {
                float curve = 0.5;
                float inv = (1 - curve);
                float xx = (ndl * inv + curve);
                return xx * xx * (ndv * inv + curve);
            }
            half HairSpecular(float3 hDirWS, float3 nDirWS,  half specularWidth) {

                float hDotn = dot(hDirWS, nDirWS);
                float sinTH = (sqrt(1 - pow(hDotn,2)));
                half dirAtten = smoothstep(-1, 0, hDotn);
                half specular = dirAtten * saturate(pow(sinTH, specularWidth));
                return (specular);
            }

            v2f vert(a2v i)
            {
                v2f o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(i.normal);
                o.tDirWS = normalize(TransformObjectToWorldDir(i.tangent));
                o.bDirWS = normalize(cross(o.tDirWS, o.nDirWS) * i.tangent.w * unity_WorldTransformParams.w);
                o.uv0 = i.uv0;

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF) && (!defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW))
                    //shadow
                    //output.shadowCoord    = TransformWorldToShadowCoord(output.positionWS);
                    #if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
                        o.shadowCoord           = TransformWorldToShadowCoord(o.posWS);
                    #else
                        o.shadowCoord.x         = HighQualityRealtimeShadow(o.posWS);
                    #endif
                #endif

                OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.nDirWS, o.vertexSH);

                return o;
            }

            half4 frag(v2f i) :SV_TARGET
            {
                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
                        i.shadowCoord.x = HighQualityRealtimeShadow(i.posWS);
                    #endif
                #endif

                float shadowMask = float4(1.0,1.0,1.0,1.0);

                #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
                    #if defined(ENABLE_HQ_SHADOW)
                        Light mainLight = GetMainLight(float4(0,0,0,0), i.posWS, shadowMask);
                        #if defined(_RECEIVE_SHADOWS_OFF)
                            mainLight.shadowAttenuation = 1;
                        #else
                            mainLight.shadowAttenuation = i.shadowCoord.x;
                        #endif
                    #elif defined(ENABLE_HQ_AND_UNITY_SHADOW)
                        Light mainLight = GetMainLight(i.shadowCoord);
                        #if defined(_RECEIVE_SHADOWS_OFF)
                            mainLight.shadowAttenuation = 1;
                        #else
                            mainLight.shadowAttenuation = i.shadowCoord.x * mainLight.shadowAttenuation;
                        #endif
                    #else
                        Light mainLight = GetMainLight(i.shadowCoord, i.posWS, shadowMask);
                    #endif
                #else
                    Light mainLight = GetMainLight();
                #endif

                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirTS = UnpackNormal(tex2D(_BumpMap, i.uv0));
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 lDirWS = normalize(mainLight.direction);
                float Var_offstTex = tex2D(_JitterMap, i.uv0 * _OffsetInt) - 0.5;
                Var_offstTex *= _AnisotropyInt;
                float3 n1DirWS = normalize(nDirWS * (Var_offstTex + _FirstSpecularShift) + i.bDirWS );
                float3 n2DirWS = normalize(n1DirWS + nDirWS * (_SecondSpecularShift ));
                float3 n3DirWS = normalize(nDirWS * -0.5 + n1DirWS);
                float3 vDirWS = normalize(i.posWS - _WorldSpaceCameraPos.xyz);
                float3 hDirWS = normalize(-vDirWS + lDirWS);


                half3 lightColor = mainLight.color;
                half3 var_BaseMap = tex2D(_BaseMap,i.uv0);
                half var_OcclusionMap = lerp(1, tex2D(_OcclusionMap,i.uv0).g,_OcclusionStrength);

                half nDotl = dot(lDirWS, nDirWS);//*mainLight.shadowAttenuation;

                half specular1 = HairSpecular(hDirWS,  n1DirWS,  20 + 400 * _SpecularRange);
                half specular2 = HairSpecular(hDirWS,  n2DirWS,  20 + 200 * _SpecularRange);
                half specular3 = HairSpecular(hDirWS,  n3DirWS ,  50);

                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, nDirWS);
                float3 indirect_color = bakedGI * var_BaseMap;

                // Mix Color
                half3 color = 0;
                color = var_BaseMap * (KKDiffuse(nDotl, dot(nDirWS,vDirWS)) + 0.3)* mainLight.shadowAttenuation;//min(1.2, max(nDotl + max(0, specular3 * _UnderSpecular), 0.2));
                color = var_BaseMap  * min(1.2, max(nDotl + max(0, specular3 * _UnderSpecular), 0.2));
                color = color + var_OcclusionMap * max(nDotl,0.4) * _SpecularInt * (specular1 * _SpecularTint + specular2 * _SecondarySpecularTint * var_BaseMap) * lightColor ;

                //color = nDotl;
                return half4(color + indirect_color * var_OcclusionMap, 1);
            }
            ENDHLSL
        }

        UsePass "FB/Standard/SGamePBR/ShadowBeforePost"
        UsePass "FB/Standard/SGamePBR/DepthOnly"
        UsePass "FB/Standard/SGamePBR/ShadowCaster"
        // UsePass "Universal Render Pipeline/Lit/DepthNormals"
    }
}