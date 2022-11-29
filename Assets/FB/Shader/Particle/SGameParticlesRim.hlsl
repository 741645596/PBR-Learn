
//#pragma fragmentoption ARB_precision_hint_fastest	
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

CBUFFER_START(HeroURPGroups)

	TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
	half _CutOff;
	half4 _TintColor;
	half _FadeFactor;
	float4 _MainTex_ST;
	half4 _EdgeColor;
	half _EdgePower;
	half _EdgeScale;
	half _Brightness;
	#ifdef _SEPERATE_ALPHA_TEX_ON
		TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
	#endif

CBUFFER_END

struct appdata_full {
	float4 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
	half4 color : COLOR0;
	half3 normal : NORMAL;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	half4 color : TEXCOORD1;
	half4 rim : COLOR;
};

float3 ObjSpaceViewDir(in float4 v)
{
	float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
	return objSpaceCameraPos - v.xyz;
}

v2f vert (appdata_full v)
{
	v2f o;
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.pos = TransformObjectToHClip(v.vertex.xyz);
	float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
	float dotProduct = 1-max(0, dot(v.normal, viewDir));
	dotProduct = pow(dotProduct, _EdgePower) * _EdgeScale;
	half4 edgeColor = _EdgeColor * dotProduct;
	o.rim = edgeColor;
	o.color = v.color;
	#ifdef _TINTCOLOR_ON
		o.color *= _TintColor * 2;
	#endif
	return o;
}

half4 frag (v2f i) : SV_Target
{
	#ifdef _SEPERATE_ALPHA_TEX_ON
		half4 color = half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy).rgb,SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex,i.uv.xy).r);
	#else
		half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
	#endif
	#ifdef _CUTOFF_ON
		if (color.a < _CutOff)
			discard;
	#endif
	color *= i.color;
	color.rgb += i.rim.rgb;
	color.rgb *= _Brightness;
	color.a *= _FadeFactor;
	return color;
}




