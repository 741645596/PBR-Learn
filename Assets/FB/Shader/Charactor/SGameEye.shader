Shader "FB/Charactor/SGameEye"  
{
    Properties{
        
        [HDR]_HighLightColor1("高光1 颜色", Color) = (1.0,1.0,1.0,1.0)
        [HDR]_HighLightColor2("高光2 颜色", Color) = (0.5,0.5,0.5,1.0)
        _MainTexture("颜色贴图",2D) = "gray"{}
        _MaskTex("视差遮罩", 2D) = "Black"{}
        parallaxInt("视差强度",Range(0,1.0)) = 0.3
        _ShadowInt("阴影强度",Range(0,1)) = 1
        _CausticTex("焦散贴图",2D) = "black"{}
        _CausticIntensity("焦散强度", Range(0,1)) = 0.5
        _ReflectMatcap("反射 Matcap", 2D) = "balck"{}
        [HDR]_MatcapColor("Matcap 反射颜色", Color) = (1.0,1.0,1.0,1.0)
        [Space][Space][Space]
        _SpecularSize("高光大小", Range(0.01,1)) = 0.5
        _HighLightOffset("高光偏移", vector) = (0.0,0.0,0.0,0.0)
        _SceondLightOffset("第二高光偏移", vector) = (0.5,0.5,0.5,0.0)
        _CausticCenter("眼球中心偏移,XY位移ZW缩放", vector) = (0.0,0.0,1.0,1.0)
        _LightEnhance("亮度增强", Range(0, 0.5)) = 0.2
        
    }
    SubShader
    {
        Tags{
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"="Opaque"
        }
        pass
        {

            cull off 

            HLSLPROGRAM

            #include "Assets/Common/ShaderLibrary/Common/GlobalIllumination.hlsl"
            
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOW_SOFT

            sampler2D _MaskTex; 
            sampler2D _MainTexture;
            sampler2D _CausticTex;
            sampler2D _ReflectMatcap;
            CBUFFER_START(UnityPerMaterial) 

                half4 _Color;
                half parallaxInt;
                half _ShadowInt;
                half _LightEnhance;
                
                
                half4 _HighLightColor1;
                half4 _HighLightColor2;
                half4 _MatcapColor;
                half _SpecularSize;


                float4 _SceondLightOffset;
                float4 _CausticCenter;
                float _CausticIntensity;
                float3 _HighLightOffset;


            CBUFFER_END

            struct a2v
            {
                float4 vertex:POSITION;
                float2 uv0 :TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 lightmapUV   : TEXCOORD1;
            };
            
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv0: TEXCOORD0;
                float2 uv1: TEXCOORD1;
                float3 nDirWS: TEXCOORD2;
                float3 tDirWS: TEXCOORD3;
                float3 bDirWS: TEXCOORD4;
                float3 posWS: TEXCOORD5;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);
                
            };

            v2f vert(a2v i)
            {
                v2f o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                o.nDirWS = TransformObjectToWorldDir(i.normal);
                o.tDirWS = TransformObjectToWorldDir(i.tangent);
                o.bDirWS = normalize(cross(o.tDirWS, o.nDirWS)) * i.tangent.w * unity_WorldTransformParams.w;
                o.uv0 = i.uv0;
                o.uv1 = (i.uv0 + _CausticCenter.xy) * _CausticCenter.zw;
                
                OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.nDirWS.xyz, o.vertexSH);

                return o;
            }

            half4 frag(v2f i):SV_TARGET
            {
                // Vectors
                Light mainLight = GetMainLight();
                float3 lDirWS = normalize(mainLight.direction);
                float3 l1DirWS = normalize(lDirWS + TransformObjectToWorld(_HighLightOffset));
                float3 l2DirWS = normalize(l1DirWS + _SceondLightOffset);
                float3 nDirWS = normalize(i.nDirWS);
                float3 vPosWS = _WorldSpaceCameraPos.xyz;

                float3 vDirWS = normalize(i.posWS - vPosWS);
                // float3 vDirWS = normalize(TransformObjectToWorld(float3(0,2,0)) - vPosWS);
                
                float3 h1DirWS = normalize(-vDirWS + l1DirWS);
                float3 h2DirWS = normalize(-vDirWS + l2DirWS);
                float3 upDirWS = TransformObjectToWorldDir(float3(0,1,0));
                float3 rightDirWS = TransformObjectToWorldDir(float3(1,0,0));
                float3 frontDirWS = TransformObjectToWorldDir(float3(0,0,1));

                float3 rDirWS = reflect(vDirWS, nDirWS);

                half3 lightColor = mainLight.color;

                // Dot
                half nDotl = dot(lDirWS, nDirWS);
                half nDotv = dot(-vDirWS, nDirWS);
                float vDott = dot(vDirWS, i.tDirWS);
                float vDotb = dot(vDirWS, i.bDirWS);
                half nDoth1 = dot(h1DirWS, nDirWS);
                half nDoth2 = dot(h2DirWS, nDirWS);
                float vDotUP = dot(-vDirWS, upDirWS);
                float vDotright = dot(-vDirWS, rightDirWS);
                

                // Parallax
                half3 mask = tex2D(_MaskTex,i.uv1).rgb;
                float2 parallaxUV = i.uv0 + float2(vDott,-vDotb) * 0.3 * parallaxInt * mask.r * (1.0 - nDotv);
                // float2 parallaxUV = i.uv0 + pow(float2(vDott,-vDotb),3) * 0.3 * parallaxInt * mask.r;

                // Caustic
                float2 uvRotate = i.uv1 - 0.5;
                float2 sincosangle = normalize(float2(vDotUP, vDotright)); //float2 sincosangle = normalize(float2(dot(-vDirWS, -frontDirWS), (dot(-vDirWS, rightDirWS))));
                float cosa = sincosangle.x;
                float sina = sincosangle.y;
                float2x2 rotateMatrix = float2x2(cosa, -sina, sina, cosa);
                uvRotate = mul(uvRotate, rotateMatrix);
                uvRotate += 0.5;
                half caustic = tex2D(_CausticTex,uvRotate);
                
                // Matcap
                float3 nDirVS = TransformWorldToViewDir(i.nDirWS);
                float2 matcapUV = nDirVS.xy * 0.5 + 0.5;
                half matcap = tex2D(_ReflectMatcap,matcapUV).r * pow(mask.r,1);

                // blinnPhong
                half3 blinnPhong = max(smoothstep(0.1,0.8,pow(nDoth1, 560 * _SpecularSize))  * _HighLightColor1 , smoothstep(0.1,0.8,pow(nDoth2, 1440 * _SpecularSize)) * _HighLightColor2);


                // Mix Color
                half3 color = tex2D(_MainTexture,parallaxUV);
                
                // gi
                float3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, nDirWS);
                // float3 gi = GlobalIllumination_Filament(i.posWS, color,0/* brdf_specular */,0.7 /* roughness */,0/* surface_specular */,mask.g,bakedGI,rDirWS,saturate(nDotv));
                float3 gi = bakedGI * color + UEIBL(rDirWS,i.posWS, 0.7,0,saturate(nDotv),1);
                
                color *= max(0, nDotl + _LightEnhance)*pow(mask.g,_ShadowInt*1.5) + caustic * 4 * _CausticIntensity;
                color += (matcap * _MatcapColor  ) + blinnPhong + gi ;
                // color *= lightColor ;
                
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}