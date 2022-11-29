#ifndef SCENEBATTLE_PBRFORWARD
#define SCENEBATTLE_PBRFORWARD

#include "CustomPBRInput.hlsl"

struct AttributesSSS
{
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
	float4 tangentOS    : TANGENT;
	float2 texcoord     : TEXCOORD0;
	float4 lightmapUV     : TEXCOORD1;
	float4 color     : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsPBR
{
	float4 positionCS               : SV_POSITION;
	float4 uv                       : TEXCOORD0; //xy:uv zw: sssNormalDetail uv
	float3 positionWS               : TEXCOORD1;
	half3 normalWS                 : TEXCOORD2;
	half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: sign
	float3 viewDirWS                : TEXCOORD4;
	float4 shadowCoord              : TEXCOORD5;
	half3 viewDirTS                : TEXCOORD7;
	#if defined(LIGHTMAP_ON)
		float2 lightmapUV : TEXCOORD8;
	#else
		half3 vertexSH : TEXCOORD8;
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct SurfaceDataPBR
{
	half3 albedo;
	half3 specular;
	half  metallic;
	half  smoothness;
	half3 normalTS;
	half3 emission;
	half  occlusion;
	half  alpha;
	half  clearCoatMask;
	half  clearCoatSmoothness;
	half shadowStrenght;
};

struct InputDataPBR {
	float3  positionWS;
	float4  positionCS;
	half3   normalWS;
	half3   viewDirectionWS;
	float4  shadowCoord;
	half    fogCoord;
	half3   bakedGI;
	half4   shadowMask;
};

//float2 UVTilingOffset(float2 uv, float4 st) {
//	return (uv * st.xy + st.zw);
//}

float3 NormalBlendReoriented(float3 A, float3 B)
{
	float3 t = A.xyz + float3(0.0, 0.0, 1.0);
	float3 u = B.xyz * float3(-1.0, -1.0, 1.0);
	return (t / t.z) * dot(t, u) - u;
}

half3 pow4(half3 color) {
	half3 c = color * color;
	return c * c;
}

half3 pow4(half p) {
	half c = p * p;
	return c * c;
}

//float3 ObjSpaceViewDir(in float4 v)
//{
//	float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
//	return objSpaceCameraPos - v.xyz;
//}

half3 PBRGetViewDirectionTangentSpace(half4 tangentWS, half3 normalWS, half3 viewDirWS)
{
    // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
    half3 unnormalizedNormalWS = normalWS;
    const half renormFactor = 1.0 / length(unnormalizedNormalWS);

    // use bitangent on the fly like in hdrp
    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
    half crossSign = (tangentWS.w > 0.0 ? 1.0 : -1.0); // we do not need to multiple GetOddNegativeScale() here, as it is done in vertex shader
    half3 bitang = crossSign * cross(normalWS.xyz, tangentWS.xyz);

    half3 WorldSpaceNormal = renormFactor * normalWS.xyz;       // we want a unit length Normal Vector node in shader graph

    // to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
    // This is explained in section 2.2 in "surface gradient based bump mapping framework"
    half3 WorldSpaceTangent = renormFactor * tangentWS.xyz;
    half3 WorldSpaceBiTangent = renormFactor * bitang;

    half3x3 tangentSpaceTransform = half3x3(WorldSpaceTangent, WorldSpaceBiTangent, WorldSpaceNormal);
    half3 viewDirTS = mul(tangentSpaceTransform, viewDirWS);

    return viewDirTS;
}

half3 PBRSampleSHVertex(half3 normalWS)
{
	#if defined(EVALUATE_SH_VERTEX)
		return SampleSH(normalWS);
	#elif defined(EVALUATE_SH_MIXED)
		// no max since this is only L2 contribution
		return SHEvalLinearL2(normalWS, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);
	#endif

    // Fully per-pixel. Nothing to compute.
    return half3(0.0, 0.0, 0.0);
}

VaryingsPBR PassVertexPBR(AttributesSSS input)
{
	VaryingsPBR output = (VaryingsPBR)0;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	//uv
	output.uv.xy = UVTilingOffset(input.texcoord.xy,_PBRBaseMapOffset);

	//
	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);

	output.positionCS = TransformWorldToHClip(output.positionWS);
	//tangent
	real sign = input.tangentOS.w * GetOddNegativeScale();
	half4 tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);
	output.tangentWS = tangentWS;
	//viewDir
	output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
	half3 viewDirTS = PBRGetViewDirectionTangentSpace(tangentWS, output.normalWS, output.viewDirWS);
	output.viewDirTS = viewDirTS;

	#if defined(LIGHTMAP_ON)
		output.lightmapUV.xy = input.lightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#else
		output.vertexSH.xyz = PBRSampleSHVertex(output.normalWS.xyz);
	#endif
	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		#if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
			output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
		#endif
	#endif
	return output;
}

real PBRLerpWhiteTo(real b, real t)
{
    real oneMinusT = 1.0 - t;
    return oneMinusT + b * t;
}

inline void InitSurfaceDataPBR(VaryingsPBR input, out SurfaceDataPBR outSurfaceData)
{
	//_PBRBaseMap
	half4 albedoAlpha = half4(SAMPLE_TEXTURE2D(_PBRBaseMap, sampler_PBRBaseMap, input.uv.xy));

	half4 pbrBaseColor = _PBRBaseColor;
	//alpha
	outSurfaceData.alpha = albedoAlpha.a * pbrBaseColor.a;
	#if _ALPHATEST_ON
		clip(outSurfaceData.alpha- _Cutoff);
	#endif

	outSurfaceData.albedo = albedoAlpha.rgb * pbrBaseColor.rgb;
	outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

	//specGloss
	half4  specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv.xy);
	outSurfaceData.smoothness = specGloss.a *_Smoothness;
	outSurfaceData.metallic = specGloss.r * _Metallic;

	//normalTS
	outSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy), _NormalScale);

	//ao
	outSurfaceData.occlusion = PBRLerpWhiteTo(specGloss.g, _OcclusionStrength);

	//emission
	half4 emissionTex = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv.xy) *_EmissionColor;
	outSurfaceData.emission = emissionTex.rgb;
	outSurfaceData.shadowStrenght = emissionTex.a;

	outSurfaceData.clearCoatMask = 0.0h;
	outSurfaceData.clearCoatSmoothness = 0.0h;
}

real3 PBRSHEvalLinearL0L1(real3 N, real4 shAr, real4 shAg, real4 shAb)
{
    real4 vA = real4(N, 1.0);

    real3 x1;
    // Linear (L1) + constant (L0) polynomial terms
    x1.r = dot(shAr, vA);
    x1.g = dot(shAg, vA);
    x1.b = dot(shAb, vA);

    return x1;
}

real3 PBRSHEvalLinearL2(real3 N, real4 shBr, real4 shBg, real4 shBb, real4 shC)
{
    real3 x2;
    // 4 of the quadratic (L2) polynomials
    real4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    real vC = N.x * N.x - N.y * N.y;
    real3 x3 = shC.rgb * vC;

    return x2 + x3;
}

#if HAS_HALF
half3 PBRSampleSH9(half4 SHCoefficients[7], half3 N)
{
    half4 shAr = SHCoefficients[0];
    half4 shAg = SHCoefficients[1];
    half4 shAb = SHCoefficients[2];
    half4 shBr = SHCoefficients[3];
    half4 shBg = SHCoefficients[4];
    half4 shBb = SHCoefficients[5];
    half4 shCr = SHCoefficients[6];

    // Linear + constant polynomial terms
    half3 res = PBRSHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += PBRSHEvalLinearL2(N, shBr, shBg, shBb, shCr);

#ifdef UNITY_COLORSPACE_GAMMA
    res = LinearToSRGB(res);
#endif

    return res;
}
#endif

float3 PBRSampleSH9(float4 SHCoefficients[7], float3 N)
{
    float4 shAr = SHCoefficients[0];
    float4 shAg = SHCoefficients[1];
    float4 shAb = SHCoefficients[2];
    float4 shBr = SHCoefficients[3];
    float4 shBg = SHCoefficients[4];
    float4 shBb = SHCoefficients[5];
    float4 shCr = SHCoefficients[6];

    // Linear + constant polynomial terms
    float3 res = PBRSHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += PBRSHEvalLinearL2(N, shBr, shBg, shBb, shCr);

#ifdef UNITY_COLORSPACE_GAMMA
    res = LinearToSRGB(res);
#endif

    return res;
}

half3 PBRSampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), PBRSampleSH9(SHCoefficients, normalWS));
}

half3 PBRSampleSHPixel(half3 L2Term, half3 normalWS)
{
	#if defined(EVALUATE_SH_VERTEX)
		return L2Term;
	#elif defined(EVALUATE_SH_MIXED)
		half3 res = SHEvalLinearL0L1(normalWS, unity_SHAr, unity_SHAg, unity_SHAb);
	#ifdef UNITY_COLORSPACE_GAMMA
		res = LinearToSRGB(res);
	#endif
		return max(half3(0, 0, 0), res);
	#endif

    // Default: Evaluate SH fully per-pixel
    return PBRSampleSH(normalWS);
}

void InitInputData(VaryingsPBR input, half3 normalTS, out InputDataPBR inputData)
{
	inputData = (InputDataPBR)0;
	inputData.positionWS = input.positionWS;
	inputData.positionCS = input.positionCS;

	float sgn = input.tangentWS.w;      // should be either +1 or -1
	float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
	inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
	inputData.normalWS = normalize(inputData.normalWS);
	inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);
	#if defined(LIGHTMAP_ON)
		inputData.bakedGI = SampleLightmap(input.lightmapUV, 0, inputData.normalWS);
	#else
		inputData.bakedGI = PBRSampleSHPixel(input.vertexSH, inputData.normalWS);
	#endif

	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		#if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
			inputData.shadowCoord.x = HighQualityRealtimeShadow(input.positionWS);
		#else
			inputData.shadowCoord = input.shadowCoord;
		#endif
	#endif

	#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
		inputData.shadowMask = SAMPLE_TEXTURE2D_LIGHTMAP(SHADOWMASK_NAME, SHADOWMASK_SAMPLER_NAME, input.lightmapUV SHADOWMASK_SAMPLE_EXTRA_ARGS);
	#elif !defined (LIGHTMAP_ON)
		inputData.shadowMask = unity_ProbesOcclusion;
	#else
		inputData.shadowMask = half4(1, 1, 1, 1);
	#endif

}



#endif
