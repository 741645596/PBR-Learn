
Shader "FB/FlowMap/FlowMap" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "black" {}
		_FlowMap ("FlowMap (RG)", 2D) = "black" {}
		_FlowMapSpeed ("FlowMapSpeed", Range(0,20)) = 1
		_FlowMapDirection("FlowMapDirection", Range(-1,1)) = 1
		[Enum(Off,0,On,1)]_ZWrite("深度写入", Float) = 0
	}

	SubShader {
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline"}
		
		Pass {
			Tags {"LightMode"="Default UI RP"}
			Blend SrcAlpha OneminusSrcAlpha
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
			TEXTURE2D(_FlowMap); SAMPLER(sampler_FlowMap);

			CBUFFER_START(UnityPerMaterial) 

				half4 _MainTex_ST;
				half4 _FlowMap_ST;
				float _FlowMapSpeed;
				float _FlowMapDirection;

			CBUFFER_END

			struct appdata_full {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4	uv : TEXCOORD0;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _FlowMap);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				float2 flowMap = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,i.uv.zw).xy *2.0-1.0;

				float flowTime = _Time.y * _FlowMapSpeed;
				float2 phase0 =  i.uv.xy + frac(flowTime) * flowMap * _FlowMapDirection;
				float2 phase1 =  i.uv.xy + frac(flowTime - 0.5) * flowMap * _FlowMapDirection;

				half4 tex0 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, phase0);//采样两张主贴图
				half4 tex1 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, phase1); 
				float flowLerp = abs(frac(flowTime) - 0.5) * 2;
				half4 color = lerp(tex0,tex1,flowLerp);

				return color;
			}
			
			ENDHLSL
		}
	}
	Fallback Off
}
