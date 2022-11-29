//https://zhuanlan.zhihu.com/p/432361693
Shader "PBR/PBRSource"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BumpMap("BumpMap", 2D) = "bump" {}
        _BumpScale("Bump Scale",float) = 1

        [Header(PBR)]
        _Tint("Albedo Color",Color) = (1,1,1,1)
        _SMAE("R:Smoothness G:Metallic B:Occlusion",2D) = "white" {}
        _Metallic("Metallic",Range(0,1)) = 0
        _Smoothness("Smoothness",Range(0,1)) = 0
        //_LUT("LUT",2D) = "white"{} // Lut贴图
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                Tags {"LightMode" = "ForwardBase"}

                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "UnityStandardBRDF.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float4 TtoW0 : TEXCOORD1;
                    float4 TtoW1 : TEXCOORD2;
                    float4 TtoW2 : TEXCOORD3;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                half _BumpScale;

                half4 _Tint;
                sampler2D _SMAE;
                float4 _SMAE_ST;
                half _Metallic;
                half _Smoothness;

                sampler2D _LUT;

                //G (Geometry function)
                float GeometrySchlickGGX(float NdotV, float k)
                {
                    float nom = NdotV;
                    float denom = NdotV * (1.0 - k) + k;
                    return nom / denom;
                }

                float GeometrySmith(float NdotV,float NdotL, float Roughness)
                {
                    float squareRoughness = Roughness * Roughness;
                    float k = pow(squareRoughness + 1, 2) / 8;
                    float ggx1 = GeometrySchlickGGX(NdotV, k); // 视线方向的几何遮挡
                    float ggx2 = GeometrySchlickGGX(NdotL, k); // 光线方向的几何阴影
                    return ggx1 * ggx2;
                }

                //移动平台上使用的近似ENVBRDF
                //https://www.unrealengine.com/zh-CN/blog/physically-based-shading-on-mobile
                half3 EnvBRDFApprox(half3 SpecularColor, half Roughness, half NdotV)
                {
                    half4 c0 = { -1, -0.0275, -0.572, 0.022 };
                    half4 c1 = { 1, 0.0425, 1.04, -0.04 };
                    half4 r = Roughness * c0 + c1;
                    half a004 = min(r.x * r.x, exp2(-9.28 * NdotV)) * r.x + r.y;
                    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
                    return SpecularColor * AB.x + AB.y;
                }

                //立方体贴图的Mip等级计算
                half CubeMapMip(half perceptualRoughness)
                {
                    //基于粗糙度计算CubeMap的Mip等级
                    half mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);     //转换公式mip = r(1.7 - 0.7r),接近实际值的拟合曲线
                    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;     //得出mip层级。默认UNITY_SPECCUBE_LOD_STEPS=6（定义在UnityStandardConfig.cginc）
                    return mip;
                }

                //近似的菲涅尔函数
                float3 FresnelSchlick(float3 F0 , float VdotH)
                {
                    float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);
                    return F;
                }

                //间接光的菲涅尔系数
                float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
                {
                    return F0 + (max(float3(1 ,1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
                }

                // Cook-Torrance BRDF  
                half3 CookTorranceBRDF(half NdotH,half NdotL,half NdotV,half VdotH,half roughness,half3 F0)
                {
                    half D = GGXTerm(NdotH,roughness);      //法线分布函数
                    half G = GeometrySmith(NdotV,NdotL,roughness);          //微平面间相互遮蔽的比率  
                    half3 F = FresnelSchlick(F0,VdotH);       //近似的菲涅尔函数
                    half3 res = (D * G * F * 0.25) / (NdotV * NdotL);
                    return res;
                }

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                    o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                    o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                    o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                    float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                    float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    float3 halfDir = normalize(viewDir + lightDir);

                    float3 bump = UnpackScaleNormal(tex2D(_BumpMap, i.uv),_BumpScale);
                    bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                    //数据准备
                    float ndl_noclamp = dot(bump,lightDir);
                    float ndl = max(1e-5,saturate(dot(bump,lightDir)));   //防止除0
                    float ndv = max(1e-5,saturate(dot(bump,viewDir)));
                    float ndh = max(1e-5,saturate(dot(bump,halfDir)));
                    float vdh = max(1e-5,saturate(dot(viewDir, halfDir)));
                    float ldh = max(1e-5,saturate(dot(lightDir, halfDir)));

                    half4 albedo = tex2D(_MainTex, i.uv) * _Tint;
                    half4 PBRMask = tex2D(_SMAE, i.uv);
                    half metallic = _Metallic * PBRMask.g;
                    half perceptualRoughness = 1 - _Smoothness * PBRMask.r;
                    half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);     //粗糙度
                    roughness = max(roughness, 0.002);        //防止为0,保留一点点高光
                    half occlusion = PBRMask.b;

                    //直接光镜面反射
                    half3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
                    half3 specular = CookTorranceBRDF(ndh,ndl,ndv,vdh,roughness,F0);
                    half3 SpecularResult = specular;

                    //直接光漫反射     
                    //half3 kd = (1 - F)*(1 - metallic);     //漫反射系数,公式上更遵循物理，但效果上没有内置宏好
                    half3 kd = OneMinusReflectivityFromMetallic(metallic);   ////漫反射系数,内置宏
                    half3 DiffcuseResult = kd * albedo.rgb;

                    half3 DirectLightResult = (DiffcuseResult + SpecularResult * UNITY_PI) * _LightColor0 * ndl;

                    //间接光漫反射
                    half3 ambient_contrib = ShadeSH9(float4(bump, 1));   //球谐光照
                    half3 ambient = 0.03 * albedo.rgb;    //环境光,取很小的值即可,可省略      
                    half3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
                    half3 Flast = FresnelSchlickRoughness(ndv,F0, roughness);
                    half3 kdLast = (1 - Flast) * (1 - metallic);          //间接光漫反射系数
                    half3 iblDiffuseResult = iblDiffuse * kdLast * albedo.rgb;

                    //间接光镜面反射
                    half mip = CubeMapMip(perceptualRoughness);         //计算Mip等级
                    half3 reflectDir = reflect(-viewDir, bump);
                    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip);
                    half3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                    //half envBDRF = EnvBRDFApprox(F0,roughness,ndv); 
                    //float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99, ndv), lerp(0, 0.99, roughness))).rg; // LUT采样
                    float grazingTerm = saturate(1 - roughness + kd);
                    float surfaceReduction = 1 / (pow(roughness,2) + 1);
                    float3 iblSpecularResult = surfaceReduction * iblSpecular * FresnelLerp(float4(F0,1.0),grazingTerm,ndv);
                    //float3 iblSpecularResult =iblSpecular* (Flast * envBDRF.r + envBDRF.g);//最后通过使用采样得到的r值进行缩放和g值进行偏移得到结果

                    half3 IndirectResult = iblDiffuseResult + iblSpecularResult;

                    half3 finalResult = DirectLightResult + IndirectResult * occlusion;
                    return half4(finalResult,1);
                }
                ENDCG
            }
        }
}