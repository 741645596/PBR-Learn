
//#pragma fragmentoption ARB_precision_hint_fastest	
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
#ifdef _SEPERATE_ALPHA_TEX_ON
	TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
#endif

CBUFFER_START(UnityPerMaterial)

	half _CutOff;
	half4 _TintColor;
	half _FadeFactor;
	float4 _MainTex_ST;

CBUFFER_END

struct appdata_full {
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

v2f vert (appdata_full v)
{
	v2f o;
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.pos = TransformObjectToHClip(v.vertex.xyz);
	o.color = v.color;
	#ifdef _TINTCOLOR_ON
		o.color *= _TintColor * 2;
	#endif
	return o;
}

real3 LinearToSRGB2(real3 c)
{
	real3 sRGBLo = c * 12.92;
	real3 sRGBHi = (PositivePow(c, real3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
	real3 sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
	return sRGB;
}

half4 frag(v2f i) : SV_Target
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

	color.rgb = LinearToSRGB2(color.rgb);

	color.a *= _FadeFactor;
	return color;
}




