#ifndef PBR_LIGHTING
#define PBR_LIGHTING
// https://zhuanlan.zhihu.com/p/432361693
// PBR 直接光 漫反射
half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter = (1 + (fd90 - 1) * Pow5(1 - NdotL));
    half viewScatter = (1 + (fd90 - 1) * Pow5(1 - NdotV));
    return lightScatter * viewScatter;
}
// PBR 直接光 高光
// Cook-Torrance BRDF  DFG/(4* l.n * v.n)
half3 CookTorranceBRDF(half NdotH, half NdotL, half NdotV, half VdotH, half roughness, half3 F0)
{
    half D = GGXTerm(NdotH, roughness);                       //法线分布函数
    half G = GeometrySmith(NdotV, NdotL, roughness);          //微平面间相互遮蔽的比率  
    half3 F = FresnelSchlick(F0, VdotH);                      //近似的菲涅尔函数
    half3 res = (D * G * F * 0.25) / (NdotV * NdotL);
    return res;
}
// 法线分布函数
// 公式：a2/{pi*[(n * h)2 *(a2 -1) +1]2} 
// a:为光滑度
inline float GGXTerm(float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
    return UNITY_INV_PI * a2 / (d * d + 1e-7f);
}

// 正态分布函数
float Distribution(float roughness, float nh)
{
    float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
    float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);
    return D;
}
// G(Geometry function)，微平面间相互遮蔽的比率
// G (Geometry function)
float GeometrySchlickGGX(float NdotV, float k)
{
    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return nom / denom;
}
float GeometrySmith(float NdotV, float NdotL, float Roughness)
{
    float squareRoughness = Roughness * Roughness;
    float k = pow(squareRoughness + 1, 2) / 8;
    float ggx1 = GeometrySchlickGGX(NdotV, k); // 视线方向的几何遮挡
    float ggx2 = GeometrySchlickGGX(NdotL, k); // 光线方向的几何阴影
    return ggx1 * ggx2;
}
// F(Fresnel equation)，菲涅尔方程，表示在不同观察方向上，表面上被反射的光除以被折射的光的比例
float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1 - F0) * pow(1.0 - cosTheta, 5.0);
}
//近似的菲涅尔函数
float3 FresnelSchlick(float3 F0, float VdotH)
{
    float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);
    return F;
}

// PBR 间接光 漫反射



// PBR 间接光 高光

























#endif