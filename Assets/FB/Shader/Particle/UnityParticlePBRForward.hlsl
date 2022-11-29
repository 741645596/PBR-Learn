#ifndef SKINMUTIPAR_FORWARD_INCLUDE
#define SKINMUTIPAR_FORWARD_INCLUDE

#include "UnityParticlePBRInput.hlsl"

struct AttributesSSS
{
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
	float4 tangentOS    : TANGENT;
	float2 texcoord     : TEXCOORD0;
	float4 lightmapUV     : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsSSS
{
	float4 positionCS               : SV_POSITION;
	float4 uv                       : TEXCOORD0; //xy:uv zw: sssNormalDetail uv
	float3 positionWS               : TEXCOORD1;
	half3 normalWS                 : TEXCOORD2;
	half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: sign
	float3 viewDirWS                : TEXCOORD4;
	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
	#else
		half  fogFactor                 : TEXCOORD5;
	#endif

	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		float4 shadowCoord              : TEXCOORD6;
	#endif
	
	//float4 shadowCoord              : TEXCOORD6;

	half3 viewDirTS                : TEXCOORD7;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 8);
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct SurfaceDataSSS
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

struct InputDataSSS {
	float3  positionWS;
	float4  positionCS;
	half3   normalWS;
	half3   viewDirectionWS;
	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		float4  shadowCoord;
	#endif
	//float4  shadowCoord;
	half    fogCoord;
	half3   bakedGI;
	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		half3   vertexLighting;
	#endif
	half4   shadowMask;
};



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

//颜色饱和度处理
//_color:颜色值
//_saturation:饱和度 >=0
half3 ColorSaturation(half3 _color, half _saturation) {
	half luminance = 0.2125 * _color.r + 0.7154 * _color.g + 0.0721 * _color.b;
	half3 luminanceColor = half3(luminance, luminance, luminance);
	return lerp(luminanceColor, _color, _saturation);
}

VaryingsSSS SSSPassVertex(AttributesSSS input)
{
	VaryingsSSS output = (VaryingsSSS)0;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	//uv
	output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
	//
	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);

	//fog
	//#if defined(_FOG_FRAGMENT)
	//	half fogFactor = 0;
	//#else
	//	half fogFactor = ComputeFogFactor(output.positionCS.z);
	//#endif
	half fogFactor = ComputeFogFactor(output.positionCS.z);

	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		half3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
		output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
	#else
		output.fogFactor = fogFactor;
	#endif

	//tangent
	real sign = input.tangentOS.w * GetOddNegativeScale();
	half4 tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);
	output.tangentWS = tangentWS;
	//viewDir
	output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
	half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, output.viewDirWS);
	output.viewDirTS = viewDirTS;
	//lightmap
	OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
	OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		//shadow
		//output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
		#if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
			output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
		#endif
	#endif

	////shadow
	//output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);

	return output;
}

//类型=SSS区域区分

inline void InitSurfaceDataSSSRange(VaryingsSSS input, out SurfaceDataSSS outSurfaceData)
{
	//_BaseMap
	half4 albedoAlpha = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));

	//alpha
	outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;
	#if _ALPHATEST_ON
		clip(outSurfaceData.alpha- _Cutoff);
	#endif

	outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
	outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

	//specGloss
	half4  specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv.xy);
	outSurfaceData.smoothness = specGloss.a * _Smoothness;
	outSurfaceData.metallic = specGloss.r * _Metallic;

	//normalTS
	outSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy), _BumpScale);

	//ao
	outSurfaceData.occlusion = LerpWhiteTo(specGloss.g, _OcclusionStrength);

	//emission
	half4 emissionTex = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv.xy) * _EmissionColor;
	outSurfaceData.emission = emissionTex.rgb;
	outSurfaceData.shadowStrenght = emissionTex.a;

	outSurfaceData.clearCoatMask = 0.0h;
	outSurfaceData.clearCoatSmoothness = 0.0h;

}

void InitInputDataSSS(VaryingsSSS input, half3 normalTS, out InputDataSSS inputData)
{
	inputData = (InputDataSSS)0;
	inputData.positionWS = input.positionWS;
	inputData.positionCS = input.positionCS;

	float sgn = input.tangentWS.w;      // should be either +1 or -1
	float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
	inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
	inputData.normalWS = normalize(inputData.normalWS);
	inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);

	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		#if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
			inputData.shadowCoord.x = HighQualityRealtimeShadow(input.positionWS);
		#else
			inputData.shadowCoord = input.shadowCoord;
		#endif
	#endif

	//inputData.shadowCoord = input.shadowCoord;

	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		inputData.fogCoord = input.fogFactorAndVertexLight.x;
		inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	#else
		inputData.fogCoord = input.fogFactor;
	#endif

	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

	inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

#endif