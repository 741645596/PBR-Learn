Shader "FeiYun/Scene/Tree"
{
    Properties {
        _MainTex ("Base Map", 2D) = "white" { }
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("裁切模式", float) = 0.0
        _Color("Base 颜色", Color) = (1.00, 1.00, 1.00, 1.00)
        _BumpTex ("法线贴图(RGB)  Specular(A)", 2D) = "bump" { }
        _TY_LightMap ("LightMap", 2D) = "white" {}
        _Cutoff ("透明度采样", Range(0, 1)) = 0.5
        _SSSColor ("SSS Color Day", Color) = (1,1,1,1)
        _SSSColorSecondary ("SSS Color Night", Color) = (1,1,1,1)
        _NightScale("Day-Night 权重", Range(0, 1)) = 0.0
        _CombinedProps0 ("x(摆动频率) y(摆动范围)", Vector) = (6.23, 0.164, 0, 0)
         _WaveForceWeather("摆动速度", float) = 1.86
        _CombinedSpecularProps ("x(高光范围) y(高光强度)", Vector) = (50,1,0.5,0.5)
        _SpecularColor ("高光颜色", Color) = (1,1,1,1)
        _SceneLightGlobalParams("光照亮度倍乘", Float) = 1.0
        _BakedShadowBase("烘培图叠加系数", Float) = 0.00
        _AmbientColor("环境光颜色（保持#354178）", Color) = (0.20692, 0.25445, 0.4717, 1.00)
        _EnvColor("环境光染色", Color) = (0.76981, 0.71009, 0.64272, 0.00)
        _EnvStrength("环境光染色强度", Float) = 0.60
        _AutoExposure("曝光度", Float) = 1.0
        // isNotUnderWater("isNotUnderWater", Float) = 1.0
        _FoliageColorScale("_FoliageColorScale", Range(0, 1)) = 0.9
        _AO("AO强度",Range(0,1)) = 0.5
    }
    SubShader 
    {
        Tags { "RenderType" = "TransparentCutout" }
        Pass 
        {
            LOD 200
            Tags { "RenderPipeline"="UniversalRenderPipeline" "LIGHTMODE" = "UniversalForward"  "RenderType" = "Opaque" }

            Cull [_CullMode]
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP

            // -------------------------------------
            // Universal Render Pipeline keywords
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE     
            // #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED            
            #pragma multi_compile _ LIGHTMAP_ON

            struct Attributes
            {
                half4 positionOS   : POSITION;
                half3 normalOS     : NORMAL;
                half4 tangentOS    : TANGENT;
                // half4 center        : COLOR0;    
                half3 color        : COLOR;    
                half2 uv           : TEXCOORD0;
            // #if LIGHTMAP_ON
                half2 lightmapUV   : TEXCOORD1;
            // #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                half4 positionCS       : SV_POSITION;
                half2 uv               : TEXCOORD0;
                // DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            // #if LIGHTMAP_ON
                half2 lightmapUV       : TEXCOORD1;
            // #endif
                half3 worldNormal      : TEXCOORD2;
                half3 worldTangent     : TEXCOORD3;
                half3 worldBinormal    : TEXCOORD4;
                half   fogFactor        : TEXCOORD5;   
                half3 worldPos         : TEXCOORD6;    
                half3 color             :TEXCOORD7;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half2 _CombinedProps0;
            half4 _CombinedSpecularProps;
            half _Cutoff;
            half4 _SSSColorSecondary;
            half4 _SSSColor;
            half4 _SpecularColor;
            half4 _MainTex_ST;
            half _WaveForceWeather;
            half _EnvStrength;
            half _AutoExposure;
            // half3 _PlayerPos;
            half _SceneLightGlobalParams;
            half _BakedShadowBase;
            half4 _AmbientColor;
            // half isNotUnderWater;
            half _FoliageColorScale;
            half _NightScale;
            half4 _EnvColor;
            half _AO;
            CBUFFER_END

            half3 _SceneLightDir;
            half3 _SceneLightColor;
            float _SceneLightIntensity;

            sampler2D _MainTex;
            sampler2D _BumpTex;
            sampler2D _EnvTexPBR;
            sampler2D _TY_LightMap;

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0; 
                UNITY_SETUP_INSTANCE_ID(v)
                o.color = v.color;
 
                half offset = v.positionOS.y + v.positionOS.x + v.positionOS.z;
                offset += _Time.y;
                offset *= _CombinedProps0.x;
                half3 pos;
                pos.z = sin(offset);
           
                pos.y =  0.2*_WaveForceWeather* _CombinedProps0.y;
                pos.x = pos.z * pos.y;
                half3 offset2 = half3(0.5, 0.0, pos.y);
                pos = pos * offset2 + v.positionOS.xyz;
               
                half4 realWorldPos = mul(GetObjectToWorldMatrix(), half4(pos, 1.0));
                // half4 realWorldPos = mul(GetObjectToWorldMatrix(), v.positionOS);
                o.worldPos = realWorldPos.xyz;
                o.positionCS = TransformWorldToHClip(realWorldPos.xyz);
                realWorldPos.xyz = realWorldPos.www * realWorldPos.xyz;
                o.uv = TRANSFORM_TEX(v.uv.xy, _MainTex);
                      
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.worldNormal = normalInputs.normalWS;
                o.worldTangent = normalInputs.tangentWS;
                o.worldBinormal = normalInputs.bitangentWS;
                  
                // OUTPUT_LIGHTMAP_UV(v.uvLightmap, unity_LightmapST, o.uvLightmap)
                o.lightmapUV.xy = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                o.fogFactor = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            //https://zhuanlan.zhihu.com/p/412828170
            half4 frag(Varyings i): SV_Target
            {
                half4 texColor = tex2D(_MainTex, i.uv);
                clip(texColor.w - _Cutoff);

                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                half3 VaddL = viewDir + _SceneLightDir;
                half LdotV = saturate(dot(_SceneLightDir, -viewDir));
                half LdotVpow = pow(LdotV, 2);
                half3 halfDir = normalize(VaddL);

                half4 oriNormal = tex2D(_BumpTex, i.uv);
                half3 normal = half3(oriNormal.xy * 2 - 1, 1);
                half3x3 rotation = half3x3(i.worldTangent, i.worldBinormal, i.worldNormal);
                half3 worldNormal = normalize(mul(normal.xyz, rotation));
                half NdotL = saturate(dot(worldNormal, _SceneLightDir));
               
                NdotL = lerp(1.0, NdotL, _FoliageColorScale);
                half NdotH = dot(worldNormal, halfDir);
                NdotH = max(NdotH, 0);
                half NdotHpow = pow(NdotH, _CombinedSpecularProps.x);
                half specularParam = oriNormal.w * NdotHpow;
                specularParam *= _CombinedSpecularProps.y;
                half specularParam2 = pow(LdotVpow, 3);
                specularParam2 = specularParam2 * 0.9 + 0.1;
                
                half4 bakelightGIShadow = tex2D(_TY_LightMap, i.lightmapUV);
                //half4 bakelightGIShadow = half4(0.5, 0.5, 0.5, 1);
                half shadowStrength = saturate(pow(bakelightGIShadow.w, 2) + _BakedShadowBase);

                half3 bakeLight = bakelightGIShadow.xyz;
                half shadowParam = specularParam2 * shadowStrength;
                half3 SSSColor = lerp(_SSSColor.xyz, _SSSColorSecondary.xyz, _NightScale);
                half3 lightColor = shadowStrength * pow(_SceneLightColor, 2.2) * _SceneLightIntensity;
                half shadowStrength2 = shadowStrength + 0.4;
                SSSColor = lerp(lightColor.xyz, lightColor * SSSColor, shadowParam);
                half colorParam = dot(bakeLight, half3(0.3, 0.59, 0.11));
                half colorParam2 = max(colorParam, 0);
                half2 colorParam3 = min(half2(shadowStrength2, colorParam2), half2(1.0, 1.0));
                // bakeLight /= colorParam3.y;
                half colorParam4 = colorParam3.y * 16.0 - 8.0;    
                colorParam4 = exp2(colorParam4);
                colorParam4 -= 0.00390625;
                // bakeLight *=  colorParam4;
                bakeLight *= _SceneLightGlobalParams;
                half3 mixColor = bakeLight * 1.8 + SSSColor;
                bakeLight *= 0.6;
                half3 mixColor2 = SSSColor * NdotL + bakeLight;
                mixColor2 += _AmbientColor.xyz;
                half3 specularPart = _AmbientColor.xyz * 0.1 + mixColor;
                specularPart *= _SpecularColor.xyz;
                specularPart *= specularParam;
                half3 envColor = _EnvColor.xyz * _EnvStrength;
                half3 specular = colorParam3.x * envColor;
                specular = specular * 0.037 + specularPart;
                texColor.xyz *= _Color.xyz;
                half3 finalColor = texColor.xyz * mixColor2 + specular;
                finalColor *= _AutoExposure;
                finalColor *= lerp(1, i.color, _AO);
                finalColor = MixFog(finalColor, i.fogFactor);
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }   
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}