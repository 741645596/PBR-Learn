Shader "FB/Standard/SGameFur"
{
	Properties
	{	
		_BaseColor("颜色",Color) = (1.0 ,1.0 ,1.0 ,1.0)
		//_Color("ShadowColor",Color) = (1.0 ,0.85 ,0.7 ,1.0)
		_MainTex ("颜色贴图", 2D) = "white" {} 
		_FlowTex("毛发长度图",2D) = "white" {}
		//	_SubTex("SubTex",2D) = "white" {}   
		_SubTexUV("毛发缩放", Vector) = (4.0 ,8.0 ,1.0 ,1.0)

		[Space(10)]
		[Header(_______________________LIGHT______________________________________________)]
		[Space(10)]
		_EnvironmentLightInt("AO",  Range(0,1)) = 1
		_FresnelLV("边缘光强度", Range(1,10)) = 5

		[Space(10)]
		[Header(_______________________SHAPE______________________________________________)]
		[Space(10)]
		_FarSpacing("长度", Range(0,16)) = 1
		_FurTickness("浓密程度", Range(0,1)) = 1 
		_FurGravity("毛发重力", Range(0,1)) = 0.5

	}

	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 300
		Blend SrcAlpha OneMinusSrcAlpha//, One OneMinusSrcAlpha

		HLSLPROGRAM
		//#pragma multi_compile_fwdbase
		ENDHLSL

		//2
		Pass
		{
			Tags { "LightMode" = "MultiPass0" }
			ZWrite On

			HLSLPROGRAM
			#pragma vertex vertFirst
			#pragma fragment fragFirst
			#define FUROFFSETVX 0.0
		
		
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		//3
		Pass
		{
			Tags { "LightMode" = "MultiPass1" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.1
	
		
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		//4
		Pass
		{
			Tags { "LightMode" = "MultiPass2" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.2
	
		
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		//5
		Pass
		{
			Tags { "LightMode" = "MultiPass3" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.3
	
	
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		//6
		Pass
		{
			Tags { "LightMode" = "MultiPass4" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.4
	
		
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		//7
		Pass
		{
			Tags { "LightMode" = "MultiPass5" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.5
		
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		Pass
		{
			Tags { "LightMode" = "MultiPass6" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.6
		
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		Pass
		{
			Tags { "LightMode" = "MultiPass7" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.7
		
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		Pass
		{
			Tags { "LightMode" = "MultiPass8" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.8
			
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		Pass
		{
			Tags { "LightMode" = "MultiPass9" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 0.9
			
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}


		Pass
		{
			Tags { "LightMode" = "MultiPass10" }
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define FUROFFSETVX 1.0
			
			
			#include "MultiPassFurCore.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}

			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 4.5

			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment
			#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

			struct Attributes
			{
				float4 position     : POSITION;
				float2 uv0          : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
			};

			Varyings DepthOnlyVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				output.positionCS = TransformObjectToHClip(input.position.xyz);
				return output;
			}

			half4 DepthOnlyFragment(Varyings input) : SV_TARGET
			{
				return 0;
			}

			ENDHLSL
		}


		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			HLSLPROGRAM
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#pragma prefer_hlslcc gles

			#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

			struct appdata_s {
				float4 pos		: POSITION;
				float3 normal : NORMAL;
			};

			struct v2f_s {
				float4 pos		: SV_POSITION;
			};

			float3 _LightDirection;

			v2f_s vertShadowCaster(appdata_s v)
			{
				v2f_s o;
				float3 wPos = TransformObjectToWorld(v.pos);
				float3 wNormal = TransformObjectToWorldNormal(v.normal);
				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(wPos.xyz, wNormal, _LightDirection));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif
				o.pos = clipPos;

				return o;
			}

			float4 fragShadowCaster(v2f_s i) : SV_Target {
				return 0;
			}
			ENDHLSL
		}
	}

	
}
