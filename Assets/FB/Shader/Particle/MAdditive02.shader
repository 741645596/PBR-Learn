
Shader "FB/Particle/MAdditive02"
{
	Properties
	{
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,1)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_Brightness ("Brightness", float) = 2.0
		_Opacity ("Opacity", float) = 1.0
	}
	
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		ColorMask RGB
		Blend One OneMinusSrcAlpha
		Cull Off
		Lighting Off
		ZWrite Off
		ZTest On
		Fog { Mode Off }
		
		LOD 100
		
		Pass
		{
			Tags {"LightMode"="UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest
			#include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl" 
			
			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half4 _TintColor;
				float4 _MainTex_ST;
				half _Brightness;
				half _Opacity;
			CBUFFER_END
			
			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				half4 color : COLOR;
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
				o.color = v.color;
				o.color *= _TintColor * 2;
				o.color.a *= _Opacity;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
				color *= i.color;
				color.rgb *= 2 * color.a * _Brightness;
				return color;
			}
			ENDHLSL
		}
	}
	Fallback Off
}

