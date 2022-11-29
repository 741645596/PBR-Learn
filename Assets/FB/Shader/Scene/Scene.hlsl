#ifndef SCENEBATTLE
#define SCENEBATTLE

//此库为局内场景函数库

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define UNITY_PI     3.14159265359f
#define UNITY_TWO_PI     6.28318530718f
#define UNITY_FOUR_PI    12.56637061436f

//获得取值范围0中的值在取值范围1中的结果 按照比例缩放
half GetRange(half _value,half _min0,half _max0,half _min1,half _max1){
	_value=clamp(_value,_min0,_max0);
    return _min1+((_value-_min0)*(_max1-_min1))/(_max0-_min0);
}


half3 SampleLightmap(float2 lightmapUV)
{
	//是否需要对光照图中的数据进行解码
	#ifdef UNITY_LIGHTMAP_FULL_HDR
		bool encodedLightmap = false;
	
	#else
		bool encodedLightmap = true;
	#endif

	//解码指令，以将照明带入正确的范围
	half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
	half4 transformCoords = half4(1, 1, 0, 0);
	half3 res = SampleSingleLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME), lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
	return res;
}

half3 SampleLightmap(float2 lightmapUV,bool encodedLightmap)
{
	//解码指令，以将照明带入正确的范围
	half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
	half4 transformCoords = half4(1, 1, 0, 0);
	half3 res = SampleSingleLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME), lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
	return res;
}

//放在Vertex输入结构
#define LIGHTMAPSTRUCT_INPUT float2 lightmapUV : TEXCOORD1;

//放在Vertex输出结构
#define LIGHTMAPSTRUCT_OUTPUT(index) float2 lightmapUV : TEXCOORD##index;

//放在Vertex函数
#define LIGHTMAPVERTEX(outPutData,inPutData) outPutData.lightmapUV.xy = inPutData.lightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;

//放在Frag函数
#define LIGHTMAPFRAG(outPutData) half3 lm = SampleLightmap(outPutData.lightmapUV);

#define LIGHTMAPFRAG_ENCODE(outPutData,encodedLightmap) half3 lm = SampleLightmap(outPutData.lightmapUV,encodedLightmap);

half3 LinearToGammaSpace(half3 linRGB)
{
	linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
	return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);
}

half3 GammaToLinearSpace(half3 sRGB)
{
	return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);
}

#define SCALED_NORMAL v.normal

float3 UnityWorldSpaceViewDir(in float3 worldPos)
{
	return _WorldSpaceCameraPos.xyz - worldPos;
}

float3 WorldSpaceViewDir(in float4 localPos)
{
	float3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
	return UnityWorldSpaceViewDir(worldPos);
}

float3 ObjSpaceViewDir(in float4 v)
{
	float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
	return objSpaceCameraPos - v.xyz;
}

#define TANGENT_SPACE_ROTATION \
	float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w; \
	float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal )

float3 ObjSpaceLightDir(in float4 v)
{
	float3 objSpaceLightPos = mul(unity_WorldToObject, _MainLightPosition).xyz;
	#ifndef USING_LIGHT_MULTI_COMPILE
		return objSpaceLightPos.xyz - v.xyz * _MainLightPosition.w;
	#else
		#ifndef USING_DIRECTIONAL_LIGHT
			return objSpaceLightPos.xyz - v.xyz;
		#else
			return objSpaceLightPos.xyz;
		#endif
	#endif
}

#endif




