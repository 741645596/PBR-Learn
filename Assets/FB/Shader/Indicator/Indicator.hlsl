
//#pragma fragmentoption ARB_precision_hint_fastest	
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);

CBUFFER_START(UnityPerMaterial)
	half _CutOff;
	half4 _TintColor;
	half _FadeFactor;
	float4 _MainTex_ST;
	half _BeCoveredAlpha;
CBUFFER_END

struct appdata {
	float4 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
	half4 color : COLOR0;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	half4 color : TEXCOORD1;
};

v2f vert (appdata v)
{
	v2f o;
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.pos = TransformObjectToHClip(v.vertex.xyz);
	o.color = v.color*_TintColor;
	return o;
}

half4 frag(v2f i) : SV_Target
{
	half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
	
	#if defined(_CUTOFF_ON)
		if (color.a < _CutOff)
			discard;
	#endif
	color *= i.color;
	color.a *= _FadeFactor;
	#if defined(_BE_COVERED)
		color.a *= _BeCoveredAlpha;
	#endif
	return color;
}




