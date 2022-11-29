
Shader "FB/UI/UIScrollAddBlend3T" {
Properties {
	[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull Mode", Float) = 0
	[Enum(Off,0,On,1)]_ZWrite("ZWrite Mode", Float) = 0
	[Enum(One,1,OneMinusSrcAlpha,10)] _DestBlend ("Blend Mode", Float) = 1

	_BaseColor("Color", Color) = (1,1,1,1)
	_ColorFactor ("ColorFactor", Float ) = 1
	_MainTex ("Base layer (RGB)", 2D) = "white" {}
	_MainTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
	_DetailTex ("2nd layer (RGB)", 2D) = "white" {}
	_Fade("Fade (Alpha)", 2D) = "white"{}
	_ScrollX ("Base layer Scroll speed X", Float) = 1.0
	_ScrollY ("Base layer Scroll speed Y", Float) = 0.0
	_Scroll2X ("2nd layer Scroll speed X", Float) = 1.0
	_Scroll2Y ("2nd layer Scroll speed Y", Float) = 0.0
    _ScrollFadeX("Fade layer Scroll speed X", Float) = 1.0
    _ScrollFadeY("Fade layer Scroll speed Y", Float) = 0.0

	_MMultiplier("Layer Multiplier", Float) = 2.0
	_Rotation("Rotation", vector) = (0,0,0,0)
}
	
SubShader 
{
	Tags 
	{
	"Queue"="Transparent" 
	"IgnoreProjector"="True"
	"RenderType"="Transparent" 
	}
	Blend SrcAlpha [_DestBlend]
	//Cull Off  //双面
	Cull [_Cull]
	Lighting Off 
	//ZWrite Off Fog { Color (0,0,0,0) }
	ZWrite [_ZWrite]

	LOD 100
	pass 
	{
		Tags {"LightMode" = "Default UI RP"}
		HLSLPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		//#pragma fragmentoption ARB_precision_hint_fastest		
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
		TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
		TEXTURE2D_X(_DetailTex); SAMPLER(sampler_DetailTex);
		TEXTURE2D_X(_Fade); SAMPLER(sampler_Fade);
		half _Lighten;
		half4 _BaseColor;
		half _ColorFactor;
		half4 _MainTex_TilingOffset;
		half4 _MainTex_ST;
		half4 _DetailTex_ST;
		half4 _Fade_ST;
		half _ScrollX;
		half _ScrollY;
		half _Scroll2X;
		half _Scroll2Y;
		half _ScrollFadeX;
		half _ScrollFadeY;
		half4 _Color;
		half4 _Rotation;
		#define ang2rad (0.005555556*3.141592654)

		struct appdata{
			float4 vertex: POSITION;
			float4 uv: TEXCOORD0;
			float4 color : COLOR;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
			float2 uvfix : TEXCOORD1;
			float4 color : TEXCOORD2;
		};

		v2f vert (appdata v)
		{
			v2f o = (v2f)0;
			/*
			o.pos = UnityObjectToClipPos(v.vertex);*/
			float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
			o.pos = TransformWorldToHClip(positionWS);

			half4 cosRotation = cos(_Rotation * ang2rad);
			half4 sinRotation = sin(_Rotation * ang2rad);

			half2 texUV = v.uv - 0.5;

			half4 texcoordX = texUV.x * cosRotation + texUV.y * sinRotation + 0.5;
			half4 texcoordY = texUV.x * -sinRotation + texUV.y * cosRotation + 0.5;

			o.uv.xy = TRANSFORM_TEX(half2(texcoordX.x, texcoordY.x),_MainTex)+ frac(float2(_ScrollX, _ScrollY) * _Time.x);
			o.uv.zw = TRANSFORM_TEX(half2(texcoordX.y, texcoordY.y),_DetailTex) + frac(float2(_Scroll2X, _Scroll2Y) * _Time.x);
			o.uvfix =  TRANSFORM_TEX(half2(texcoordX.y, texcoordY.y),_Fade) + frac(float2(_ScrollFadeX, _ScrollFadeY) * _Time.x);
			
			o.color =  v.color;

			return o;
			
		}
		half4 frag (v2f i) : COLOR
		{
			half4 o;
			half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv.xy) * _BaseColor;
			half alpha = tex.a;
			alpha *= SAMPLE_TEXTURE2D(_DetailTex,sampler_DetailTex, i.uv.zw);
			half4 tex2 = SAMPLE_TEXTURE2D (_DetailTex,sampler_DetailTex, i.uv.zw);
			half4 fade = SAMPLE_TEXTURE2D(_Fade,sampler_Fade, i.uvfix);
			o = tex * tex2 * i.color * fade.r * fade.a * tex.a* _ColorFactor;
			return o;
		}
		ENDHLSL 
		}	
	}	
}