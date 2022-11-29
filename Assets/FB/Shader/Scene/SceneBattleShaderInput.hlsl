#ifndef SCENEBATTLE_SHADERINPUT
#define SCENEBATTLE_SHADERINPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Scene.hlsl"

//PBR
TEXTURE2D_X(_PBRBaseMap);
SAMPLER(sampler_PBRBaseMap);
TEXTURE2D_X(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D_X(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D_X(_EmissionMap);
SAMPLER(sampler_EmissionMap);

TEXTURE2D_X(_MainTex);
SAMPLER(sampler_MainTex);

//
TEXTURE2D_X(_BaseMap);
SAMPLER(sampler_BaseMap);

//
#if defined(_MATTYPE_RIVER)
	TEXTURE2D_X(_WaveNoiseTex);
	SAMPLER(sampler_WaveNoiseTex);
	TEXTURE2D_X(_WaveMaskTex);
	SAMPLER(sampler_WaveMaskTex);
#endif

#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
	TEXTURE2D_X(_MaskMap);
	SAMPLER(sampler_MaskMap);
	TEXTURE2D_X(_LightTex);
	SAMPLER(sampler_LightTex);
	TEXTURE2D_X(_LightTexG);
	SAMPLER(sampler_LightTexG);

	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON)
		TEXTURE2D_X(_BaseMapMatCap);
		SAMPLER(sampler_BaseMapMatCap);
	#endif

	#if defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		TEXTURE2D_X(_BaseMapMatCapPBR);
		SAMPLER(sampler_BaseMapMatCapPBR);
		TEXTURE2D_X(_LightTexB);
		SAMPLER(sampler_LightTexB);
		TEXTURE2D_X(_LightTexA);
		SAMPLER(sampler_LightTexA);
	#endif

	#if defined(_LIGHT_TEXNORMAL_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		TEXTURE2D_X(_MatCapNormal);
		SAMPLER(sampler_MatCapNormal);
	#endif

#endif

CBUFFER_START(UnityPerMaterial)
	//PBR
	half _OcclusionStrength;
	half _Smoothness;
	half _Metallic;
	half _NormalScale;
	float4 _PBRBaseMapOffset;
	half4 _PBRBaseColor;
	half4 _EmissionColor;
	//阴影 
	half4 _ShadowColor;//阴影颜色
	half _ShadowHeight;//阴影平面的高度
	half _ShadowOffsetX;//XZ平面的偏移
	half _ShadowOffsetZ;
	half _MeshHight;//模型高度
	half4 _WorldPos;//模型位置
	//
	half4 _BaseColor;
	half4 _BaseMap_ST;
	half _AlphaVal;
	half3 _ProGameOutDir;

	half _Cutoff;
	half4 _Color;

	half _LightScale;
	half4 _MainColor;
	half _MatCapNormalScale;
	half _LightWeight;
    half _AlphaSet;
	half _MainLightStrength;
	half _AddLightStrength;

	float _WindFreq;
	float _BendScale;
	float _BranchAmp;
	float _DetailFreq;
	float _DetailAmp;

	float4 _WaveSpeed;
	float4 _WaveNoiseTex_ST;
	float4 _WaveMaskTex_ST;
	float4 _WaveStrength;
	float4 _PlayerPos;

CBUFFER_END

//#define GET_PROP(propName) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, propName)
	
struct VertexInput {
	UNITY_VERTEX_INPUT_INSTANCE_ID
	float4 vertex : POSITION;
	half2 texcoord : TEXCOORD0;
	#if defined(_THISLIGHTMAP_ON) || defined(_MATTYPE_RIVER)
		LIGHTMAPSTRUCT_INPUT
	#endif	
	#if defined(_MATTYPE_GRASSANIM)
		float4 color : COLOR;
	#endif
	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON) || defined(_MATTYPE_GRASSANIM)
		float3 normal: NORMAL;
		#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			float4 tangent:TANGENT;
		#endif
	#endif
};

struct v2f
{
	float4 pos : SV_POSITION;

	#if defined(_MATTYPE_RIVER)
		half4 uv : TEXCOORD0;
	#else
		half2 uv : TEXCOORD0;
	#endif

	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		half2 uv2 : TEXCOORD1;
	#endif
	#ifdef _THISLIGHTMAP_ON
		LIGHTMAPSTRUCT_OUTPUT(2)
	#endif

	#if defined(_MATTYPE_RIVER)
		float4 waveUV : TEXCOORD3;
	#endif

	#if defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON) || defined(_MATTYPE_GRASSANIM)
	    #if defined(_LIGHT_ON)
			float3 posWS : TEXCOORD4;
		#endif
		float3 normalWS : TEXCOORD5;
		#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			float4	tangentWS : TEXCOORD6;
			float3  posVS : TEXCOORD7;
		#endif
	#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

float2 UVTilingOffset(float2 uv, float4 st) {
    return (uv * st.xy + st.zw);
}

void GrassVertexApplyBlending(inout float3 vPos, float3 worldNormal, half4 maskColor, float2 time, float bendScale, float branchAmp, float detailFreq, float detailAmp) {
	float wind = sin(time * _WindFreq);
	float fLength = length(vPos);
	float fBF = vPos.y * bendScale + 1.0;
	fBF *= fBF;
	fBF = fBF * fBF - fBF;
	float3 vNewPos = vPos;
	vNewPos.z += wind * fBF;
	vPos.xyz = normalize(vNewPos.xyz) * fLength;

	float windStrength = abs(wind);
	float fVtxPhase = vPos.x + vPos.y + vPos.z;

	float2 vWavesIn = time + float2(fVtxPhase, 0.0);
	float4 vWaves = (frac(vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193)) * 2.0 - 1.0) * detailFreq;
	vWaves = abs(frac(vWaves + 0.5) * 2.0 - 1.0);
	vWaves = vWaves * vWaves * (3.0 - 2.0 * vWaves);
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	vPos.xyz += vWavesSum.x * float3(maskColor.r * detailAmp * windStrength * worldNormal.xyz);
	vPos.y += vWavesSum.y * (1.0 - maskColor.b) * branchAmp * windStrength;
}

v2f vert(VertexInput v)
{
	v2f o=(v2f)0;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	o.uv.xy = v.texcoord.xy;
	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON)
		o.uv2.x = dot(UNITY_MATRIX_IT_MV[0].xyz, v.normal) * 0.5 + 0.5;
		o.uv2.y = dot(UNITY_MATRIX_IT_MV[1].xyz, v.normal) * 0.5 + 0.5;
	#endif

	#if defined(_MATTYPE_RIVER)
	    o.uv.zw = TRANSFORM_TEX(v.lightmapUV.xy, _WaveMaskTex);
	    o.waveUV.xy = TRANSFORM_TEX(v.lightmapUV.xy, _WaveNoiseTex)+ frac(_WaveSpeed.xy * _Time.x);
		o.waveUV.zw = TRANSFORM_TEX(v.lightmapUV.xy, _WaveNoiseTex)+ frac(_WaveSpeed.zw * _Time.x);
	#endif

	#if defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON) || defined(_MATTYPE_GRASSANIM)
		float3 wsPos=TransformObjectToWorld(v.vertex.xyz);
		o.normalWS =normalize(TransformObjectToWorldNormal(v.normal));
		#if defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
				real sign = v.tangent.w * GetOddNegativeScale();
				o.tangentWS = half4(TransformObjectToWorldDir(v.tangent.xyz), sign);
				o.posVS = TransformWorldToView(wsPos);
			#endif
		#endif
		#if defined(_MATTYPE_GRASSANIM)
			float3 vPos = wsPos.xyz;
			float time = _Time.y * 0.5;
		    GrassVertexApplyBlending(vPos, o.normalWS.xyz, v.color, time, _BendScale, _BranchAmp, _DetailFreq, _DetailAmp);
			wsPos.xyz=vPos;
			//互动
			float3 dir = wsPos.xyz-_PlayerPos.xyz;
			float dis = length(dir)/_PlayerPos.w;
			dis=clamp(dis,0,1);
			dir=normalize(dir);
			float lerpY=(wsPos.y-_PlayerPos.y)/_PlayerPos.w;
			lerpY=clamp(lerpY,0,1)*2;
			dir.y=dir.y*0.5;
			wsPos.xyz=wsPos.xyz+dir*lerp(_PlayerPos.w,0,dis)*lerpY;

		#endif
	#endif

	#if defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)|| defined(_MATTYPE_GRASSANIM)
		o.pos = TransformWorldToHClip(wsPos);
		#if defined(_LIGHT_ON)
			o.posWS = wsPos;
		#endif
	#else

		o.pos = TransformObjectToHClip(v.vertex.xyz);
	#endif
	#ifdef _THISLIGHTMAP_ON
		LIGHTMAPVERTEX(o,v)
	#endif	

	return o;
}

half4 EffectFrag(half4 color,v2f i){
	UNITY_SETUP_INSTANCE_ID(i);

	#ifdef _THISLIGHTMAP_ON
	    #if defined(_LIGHTMAP_ENCODE_ON)
			LIGHTMAPFRAG(i)
		#else
			LIGHTMAPFRAG_ENCODE(i,false)
		#endif
		color.rgb = color.rgb * lm;
	#endif

	//法线
	#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
	    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_MatCapNormal, sampler_MatCapNormal, i.uv.xy),_MatCapNormalScale);
		float sgn = i.tangentWS.w;      // should be either +1 or -1
		float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
		float3 normalWS = TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
		normalWS = normalize(normalWS);
		i.normalWS=normalWS;
		//计算MatCapUV
		float3 normalVS = TransformWorldToViewDir(normalWS);
		half3 r = normalize(reflect(i.posVS, normalVS));
		half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
        i.uv2 = r.xy / m + 0.5;
	#endif

	//灯光处理
	#if defined(_LIGHT_ON)
		Light mainLight = GetMainLight();
		float nDotL=saturate(dot(i.normalWS,mainLight.direction)*0.5+0.5);
		nDotL=nDotL*nDotL;
		color.rgb = color.rgb+nDotL*mainLight.color*_MainLightStrength;
		uint pixelLightCount = GetAdditionalLightsCount();
		for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
		{
			Light light = GetAdditionalLight(lightIndex,i.posWS);
			nDotL=saturate(dot(i.normalWS,light.direction));
			color.rgb = color.rgb+nDotL*light.color*_AddLightStrength;
		}
	#endif

	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON)
		half2 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy).rg;
		half3 matCapR = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv2).rgb;
		half3 matCapG = SAMPLE_TEXTURE2D(_LightTexG, sampler_LightTexG, i.uv2).rgb;
		half3 matCap = matCapR*mask.r + matCapG*mask.g;
		matCap = matCap.rgb * _LightScale;
		color.rgb += matCap;
		color.rgb = lerp(color.rgb,matCap,_LightWeight);
	#endif

	#if defined(_LIGHT_TEX_HIFHT_ON)  || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		half4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy);
		half3 matCapR = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv2).rgb;
		half3 matCapG = SAMPLE_TEXTURE2D(_LightTexG, sampler_LightTexG, i.uv2).rgb;
		half3 matCapB = SAMPLE_TEXTURE2D(_LightTexB, sampler_LightTexB, i.uv2).rgb;
		half3 matCapA = SAMPLE_TEXTURE2D(_LightTexA, sampler_LightTexA, i.uv2).rgb;
		half3 matCap = matCapR*mask.r + matCapG*mask.g + matCapB*mask.b + matCapA*mask.a;
		matCap = matCap.rgb *_LightScale;
		color.rgb +=matCap;
		color.rgb = lerp(color.rgb,matCap,_LightWeight);
	#endif

	#if defined(_TRANSLUCENT) 
		color.a = color.a*_AlphaVal*_AlphaSet;
		clip(color.a-0.5);
	#else
		color.a = 1;
	#endif

	return color;
}

#endif

