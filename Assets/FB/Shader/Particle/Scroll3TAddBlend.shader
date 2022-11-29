
Shader "FB/Particle/ScrollAddBlend3T" {
Properties {
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull Mode", Float) = 0
		[Enum(Off,0,On,1)]_ZWrite("ZWrite Mode", Float) = 0
		[Enum(One,1,OneMinusSrcAlpha,10)] _DestBlend ("Blend Mode", Float) = 1

	_BaseColor("Color", Color) = (1,1,1,1)
	_ColorFactor ("ColorFactor", Float ) = 1
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_DetailTex ("2nd layer (RGB)", 2D) = "white" {}
	_Fade("Fade (Alpha)", 2D) = "white"{}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
	_Scroll2X ("2nd layer Scroll speed X", Float) = 1.0
	_Scroll2Y ("2nd layer Scroll speed Y", Float) = 0.0
    _ScrollFadeX("Fade layer Scroll speed X", Float) = 1.0
    _ScrollFadeY("Fade layer Scroll speed Y", Float) = 0.0


	//_SineAmplX ("Base layer sine amplitude X",Float) = 0 
	//_SineAmplY ("Base layer sine amplitude Y",Float) = 0
	//_SineFreqX ("Base layer sine freq X",Float) = 0 
	//_SineFreqY ("Base layer sine freq Y",Float) = 0
	//_SineAmplX2 ("2nd layer sine amplitude X",Float) = 0 
	//_SineAmplY2 ("2nd layer sine amplitude Y",Float) = 0
	//_SineFreqX2 ("2nd layer sine freq X",Float) = 0 
	//_SineFreqY2 ("2nd layer sine freq Y",Float) = 0
	//_Color("Color", Color) = (1,1,1,1)
	
	
	_MMultiplier("Layer Multiplier", Float) = 2.0
	_Rotation("Rotation", vector) = (0,0,0,0)
}
	
SubShader {
	Tags {
	"Queue"="Transparent" 
	"IgnoreProjector"="True"
	"RenderType"="Transparent" 
	}

	//Blend SrcAlpha OneMinusSrcAlpha //混合模式
	//Blend One One
	Blend SrcAlpha [_DestBlend]
	//Cull Off  //双面
	Cull [_Cull]
	Lighting Off 
	//ZWrite Off Fog { Color (0,0,0,0) }
	ZWrite [_ZWrite]

	LOD 100
	
	CGINCLUDE
	//#pragma multi_compile LIGHTMAP_OFF
	//#pragma exclude_renderers molehill    
	#include "UnityCG.cginc"
	#define ang2rad (0.005555556*3.141592654)

	float4 _BaseColor;

	sampler2D _MainTex;
	sampler2D _DetailTex;
	sampler2D _Fade;

	float4 _MainTex_ST;
	float4 _DetailTex_ST;
	float4 _Fade_ST;
		
	float _ScrollX;
	float _ScrollY;
	float _Scroll2X;
	float _Scroll2Y;
    float _ScrollFadeX;
    float _ScrollFadeY;
	//float _MMultiplier;
	
	//float _SineAmplX;
	//float _SineAmplY;
	//float _SineFreqX;
	//float _SineFreqY;

	//float _SineAmplX2;
	//float _SineAmplY2;
	//float _SineFreqX2;
	//float _SineFreqY2;
	float4 _Color;
	half4 _Rotation;
	
	struct v2f {
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float2 uvfix : TEXCOORD1;
		fixed4 color : TEXCOORD2;
	};

	
	v2f vert (appdata_full v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		half4 cosRotation = cos(_Rotation * ang2rad);
		half4 sinRotation = sin(_Rotation * ang2rad);
		half2 texUV = v.texcoord - 0.5;
		half4 texcoordX = texUV.x * cosRotation + texUV.y * sinRotation + 0.5;
		half4 texcoordY = texUV.x * -sinRotation + texUV.y * cosRotation + 0.5;

		o.uv.xy = TRANSFORM_TEX(half2(texcoordX.x, texcoordY.x),_MainTex) + frac(float2(_ScrollX, _ScrollY) * _Time.x);
		o.uv.zw = TRANSFORM_TEX(half2(texcoordX.y, texcoordY.y),_DetailTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);

		//float4 sinTime = float4(_SineFreqX, _SineFreqY, _SineFreqX2, _SineFreqY2) * _Time.x;
		//float4 uvSineAmpl = float4(_SineAmplX, _SineAmplY, _SineAmplX2, _SineAmplY2);
		//o.uv += sin(sinTime) * uvSineAmpl;
		o.uvfix = TRANSFORM_TEX(half2(texcoordX.y, texcoordY.y), _Fade) + frac(float2(_ScrollFadeX, _ScrollFadeY) * _Time.x);

		o.color =  v.color;
		return o;
	}
	ENDCG


	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest		

		half _Lighten;

		uniform float _ColorFactor;

		fixed4 frag (v2f i) : COLOR
		{
			fixed4 o;
			fixed4 tex = tex2D (_MainTex, i.uv.xy) * _BaseColor;
			fixed4 alpha = tex.a;
			alpha *= tex2D (_DetailTex, i.uv.zw);
			fixed4 tex2 = tex2D (_DetailTex, i.uv.zw);
			fixed4 fade = tex2D(_Fade, i.uvfix);
			o = tex * tex2 * i.color * fade.r * fade.a * tex.a* _ColorFactor;
			return o;
		}
		ENDCG 
	}	
}
CustomEditor "CustomShaderGUI"
}
