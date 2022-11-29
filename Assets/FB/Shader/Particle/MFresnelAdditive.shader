
Shader "FB/Particle/MFresnelAdditive" {
	Properties {
		_Color("Main Color", Color) = (1,1,1,1)
		_Power ("Fresnel Power", float) = 2.0
		_MainTex ("FX Map (RGB)", 2D) = "white" {}
		_Level ("FX Map Level", float) = 0.5
		_FXPower ("FX Map Power", float) = 2.0
		_HurtColor("HurtColor", vector) = (0,0,0,0)
		_Brightness ("Brightness", float) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True""RenderPipeline" = "UniversalPipeline"}
		LOD 100
		Pass {
			ZWrite On
			ColorMask 0
		}
		
		Pass {
			Tags {"LightMode"="UniversalForward"}
			Fog {Mode Off}
	        ZWrite Off
	        ColorMask RGB
	        Blend SrcAlpha One
	        
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest
			#include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl" 
	
			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half4 _Color;
				float _Power;
				float4 _MainTex_ST;
				half _Level;
				half _FXPower;
				half _Brightness;
				half3 _HurtColor;
			CBUFFER_END
			
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				half4 color : COLOR0;
			};

			float3 UnityWorldSpaceViewDir(in float3 worldPos)
			{
				return _WorldSpaceCameraPos.xyz - worldPos;
			}

			float3 WorldSpaceViewDir(in float4 localPos)
			{
				float3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
				return UnityWorldSpaceViewDir(worldPos);
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
				float3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
				float rimCoe = 1.0 - saturate(dot(viewDir, worldNormal));
				rimCoe = pow(rimCoe, _Power);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color.rgb = _Color.rgb * rimCoe;
				o.color.a = _Color.a;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half3 texcol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).rgb;
				half gray = dot(texcol, half3(0.3,0.6,0.1));
				half4 ret = i.color;
				ret.rgb += _Color.rgb * pow(gray, _FXPower) * _Level;
				ret.rgb *= _Brightness;
				ret.rgb += _HurtColor;
				return ret;
			}
			ENDHLSL
	    }
	}
	FallBack Off
}
