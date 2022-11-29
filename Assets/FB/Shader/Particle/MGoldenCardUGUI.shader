
Shader "FB/Particle/MGoldenCardUGUI" 
{
	
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MaskTex ("Mask", 2D) = "white" {}
		_Fx1_Tex ("Layer1", 2D) = "black" {}
		_Fx2_Tex ("Layer2", 2D) = "black" {}
		_Fx3_Tex ("Layer3", 2D) = "black" {}
		_Fx4_Tex ("Layer4", 2D) = "black" {}
		_Fx1_FlowTex ("Layer1 Flow", 2D) = "black" {}
		_Fx3_FlowTex ("Layer3 Flow", 2D) = "black" {}
		
		_Seed ("Seed", float) = 0
		
		// Fx1 Begin
		
		_Fx1_Color("Layer1 Color", Color) = (1,1,1,1)
		_Fx1_Intensity("Layer1 Intensity", float) = 1
		_Fx1_Invert("Layer1 Invert", float) = 0
		_Fx1_Distortion("Layer1 Distortion", float) = 0
		
		_Fx1_PusleClip("Layer1 Pusle Clip", float) = 0
		_Fx1_PusleRate ("Layer1 Pusle Rate", float) = 20
		_Fx1_PusleIntensity("Layer1 Pusle Intensity", float) = 1
		_Fx1_PusleAmount("Layer1 Pusle Amount", float) = 0
		
			// _LAYER1_ROTATE
			_Fx1_RotSpeed ("Layer1 Rotate Speed", float) = 0
			_Fx1_RotationX ("Layer1 Rotation X", float) = 0
			_Fx1_RotationY ("Layer1 Rotation Y", float) = 0
			_Fx1_ScaleX ("Layer1 Scale X", float) = 1
			_Fx1_ScaleY ("Layer1 Scale Y", float) = 1
			
			// _LAYER1_SCROLL
			_Fx1_ScrollAngle ("Layer1 Scroll Angle", float) = 0
			_Fx1_ScrollX ("Layer1 Scroll X", float) = 0
			_Fx1_ScrollY ("Layer1 Scroll Y", float) = 0
			
			// _LAYER1_FLOW
			_Fx1_FlowAngle("Layer1 Flow Angle", float) = 0
			_Fx1_FlowOffsetX("Layer1 Flow Offset X", float) = 0
			_Fx1_FlowOffsetY("Layer1 Flow Offset Y", float) = 0
			_Fx1_FlowScaleX("Layer1 Flow Scale X", float) = 1
			_Fx1_FlowScaleY("Layer1 Flow Scale Y", float) = 1
			_Fx1_FlowScrollX("Layer1 Flow Scroll X", float) = 0
			_Fx1_FlowScrollY("Layer1 Flow Scroll Y", float) = 0
		// Fx1 End

		// Fx2 Begin
		
		_Fx2_Color("Layer2 Color", Color) = (1,1,1,1)
		_Fx2_Intensity("Layer2 Intensity", float) = 1
		_Fx2_Invert("Layer2 Invert", float) = 0
		_Fx2_Blend("Layer2 Blend", float) = 0
		_Fx2_Distortion("Layer2 Distortion", float) = 0
		
		_Fx2_PusleClip("Layer2 Pusle Clip", float) = 0
		_Fx2_PusleRate("Layer2 Pusle Rate", float) = 20
		_Fx2_PusleIntensity("Layer2 Pusle Intensity", float) = 1
		_Fx2_PusleAmount("Layer2 Pusle Amount", float) = 0
		
			// _LAYER2_ROTATE
			_Fx2_RotSpeed("Layer2 Rotate Speed", float) = 0
			_Fx2_RotationX("Layer2 Rotation X", float) = 0
			_Fx2_RotationY("Layer2 Rotation Y", float) = 0
			_Fx2_ScaleX("Layer2 Scale X", float) = 1
			_Fx2_ScaleY("Layer2 Scale Y", float) = 1
			
			// _LAYER2_SCROLL
			_Fx2_ScrollAngle("Layer2 Scroll Angle", float) = 0
			_Fx2_ScrollX("Layer2 Scroll X", float) = 0
			_Fx2_ScrollY("Layer2 Scroll Y", float) = 0
		// Fx2 End

		// Fx3 Begin
		
		_Fx3_Color("Layer3 Color", Color) = (1,1,1,1)
		_Fx3_Intensity("Layer3 Intensity", float) = 1
		_Fx3_Invert("Layer3 Invert", float) = 0
		_Fx3_Distortion("Layer3 Distortion", float) = 0
		//#if _LAYER3_BLEND_ON
			_Fx3_Blend("Layer3 Blend", float) = 0
		//#else
			_Fx3_ColorIntensity("Layer3 Color Intensity", float) = 1
		//#endif
		
		_Fx3_PusleClip("Layer3 Pusle Clip", float) = 0
		_Fx3_PusleRate("Layer3 Pusle Rate", float) = 20
		_Fx3_PusleIntensity("Layer3 Pusle Intensity", float) = 1
		_Fx3_PusleAmount("Layer3 Pusle Amount", float) = 0
		
			// _LAYER3_ROTATE
			_Fx3_RotSpeed("Layer3 Rotate Speed", float) = 0
			_Fx3_RotationX("Layer3 Rotation X", float) = 0
			_Fx3_RotationY("Layer3 Rotation Y", float) = 0
			_Fx3_ScaleX("Layer3 Scale X", float) = 1
			_Fx3_ScaleY("Layer3 Scale Y", float) = 1
			
			// _LAYER3_SCROLL
			_Fx3_ScrollAngle("Layer3 Scroll Angle", float) = 0
			_Fx3_ScrollX("Layer3 Scroll X", float) = 0
			_Fx3_ScrollY("Layer3 Scroll Y", float) = 0

			// _LAYER3_FLOW_ON
			_Fx3_FlowOffsetX("Layer3 Flow Offset X", float) = 0
			_Fx3_FlowOffsetY("Layer3 Flow Offset Y", float) = 0
			_Fx3_FlowScrollX("Layer3 Flow Scroll X", float) = 0
			_Fx3_FlowScrollY("Layer3 Flow Scroll Y", float) = 0
			_Fx3_FlowScaleX("Layer3 Flow Scale X", float) = 0
			_Fx3_FlowScaleY("Layer3 Flow Scale Y", float) = 0
		
		// Fx3 End

			// _LAYER4_ON
			_Fx4_Color("Layer4 Color", Color) = (1,1,1,1)
			_Fx4_Intensity("Layer4 Intensity", float) = 0
			_Fx4_ColorIntensity("Layer4 Color Intensity", float) = 1
			
			_Fx4_ScaleX("Layer4 Scale X", float) = 1
			_Fx4_ScaleY("Layer4 Scale Y", float) = 0
			_Fx4_ScrollAngle("Layer4 Scroll Angle", float) = 0
			_Fx4_ScrollX("Layer4 Scroll X", float) = 0
			_Fx4_ScrollY("Layer4 Scroll Y", float) = 0
			
			_Fx4_PusleClip("Layer4 Pusle Clip", float) = 0
			_Fx4_PusleRate("Layer4 Pusle Rate", float) = 20
			_Fx4_PusleIntensity("Layer4 Pusle Intensity", float) = 1
			_Fx4_PusleAmount("Layer4 Pusle Amount", float) = 0
		
		_FxBrightness("Brightness", float) = 0
		_FxIntensity("Intensity", float) = 1
		_DistortionVector("Distortion Vector", vector) = (1,1,1,1)
	}

	SubShader
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Opaque""RenderPipeline" = "UniversalPipeline"}
		LOD 100
		
        ZWrite off
		Cull Off
		
		Pass
		{
			Tags {"LightMode"="UniversalForward"}
			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				//#pragma fragmentoption ARB_precision_hint_fastest	
				#pragma target 3.0
				#include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"
				
				#define LAYER_MODE	1
				#define FX3_BLENDMODE	1
				
				#ifndef LAYER_MODE
				#define LAYER_MODE		0
				#endif

				// 0:	fx3 add blend
				// 1:	fx3 alpha blend
				#ifndef FX3_BLENDMODE
				#define FX3_BLENDMODE		0
				#endif
				
				#define PI	3.1415926
				
		CBUFFER_START(HeroURPGroups) 
				
				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
				TEXTURE2D_X(_Fx1_Tex); SAMPLER(sampler_Fx1_Tex);
				TEXTURE2D_X(_Fx2_Tex); SAMPLER(sampler_Fx2_Tex);
				TEXTURE2D_X(_Fx3_Tex); SAMPLER(sampler_Fx3_Tex);
				TEXTURE2D_X(_Fx4_Tex); SAMPLER(sampler_Fx4_Tex);
				TEXTURE2D_X(_Fx1_FlowTex); SAMPLER(sampler_Fx1_FlowTex);
				TEXTURE2D_X(_Fx3_FlowTex); SAMPLER(sampler_Fx3_FlowTex);

				float _Seed;

				// Fx1 Begin
				float4 _Fx1_Color;
				float _Fx1_Intensity;
				float _Fx1_Invert;
				float _Fx1_Distortion;
				float _Fx1_PusleClip;
				float _Fx1_PusleRate;
				float _Fx1_PusleIntensity;
				float _Fx1_PusleAmount;
				float _Fx1_RotSpeed;
				float _Fx1_RotationX;
				float _Fx1_RotationY;
				float _Fx1_ScaleX;
				float _Fx1_ScaleY;
				float _Fx1_ScrollAngle;
				float _Fx1_ScrollX;
				float _Fx1_ScrollY;
				float _Fx1_FlowAngle;
				float _Fx1_FlowOffsetX;
				float _Fx1_FlowOffsetY;
				float _Fx1_FlowScaleX;
				float _Fx1_FlowScaleY;
				float _Fx1_FlowScrollX;
				float _Fx1_FlowScrollY;
				// Fx1 End

				// Fx2 Begin
				float4 _Fx2_Color;
				float _Fx2_Intensity;
				float _Fx2_Invert;
				float _Fx2_Blend;
				float _Fx2_Distortion;
				float _Fx2_PusleClip;
				float _Fx2_PusleRate;
				float _Fx2_PusleIntensity;
				float _Fx2_PusleAmount;
				float _Fx2_RotSpeed;
				float _Fx2_RotationX;
				float _Fx2_RotationY;
				float _Fx2_ScaleX;
				float _Fx2_ScaleY;
				float _Fx2_ScrollAngle;
				float _Fx2_ScrollX;
				float _Fx2_ScrollY;
				// Fx2 End

				// Fx3 Begin
				float4 _Fx3_Color;
				float _Fx3_Intensity;
				float _Fx3_Invert;
				float _Fx3_Distortion;
				float _Fx3_Blend;
				float _Fx3_ColorIntensity;
				float _Fx3_PusleClip;
				float _Fx3_PusleRate;
				float _Fx3_PusleIntensity;
				float _Fx3_PusleAmount;
				float _Fx3_RotSpeed;
				float _Fx3_RotationX;
				float _Fx3_RotationY;
				float _Fx3_ScaleX;
				float _Fx3_ScaleY;
				float _Fx3_ScrollAngle;
				float _Fx3_ScrollX;
				float _Fx3_ScrollY;
				float _Fx3_FlowOffsetX;
				float _Fx3_FlowOffsetY;
				float _Fx3_FlowScrollX;
				float _Fx3_FlowScrollY;
				float _Fx3_FlowScaleX;
				float _Fx3_FlowScaleY;
				// Fx3 End

				// Fx4 Begin
				float _Fx4_Intensity;
				float _Fx4_ColorIntensity;
				float4 _Fx4_Color;
				float _Fx4_ScaleX;
				float _Fx4_ScaleY;
				float _Fx4_PusleAmount;
				float _Fx4_PusleRate;
				float _Fx4_PusleIntensity;
				float _Fx4_PusleClip;
				float _Fx4_ScrollAngle;
				float _Fx4_ScrollX;
				float _Fx4_ScrollY;
				// Fx3 End

				float _FxBrightness;
				float _FxIntensity;
				float2 _DistortionVector;

		CBUFFER_END

				struct appdata_full {
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
				};
				
				struct v2f
				{
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					float4 param0 : TEXCOORD1;
					float4 param1 : TEXCOORD2;
					float4 param2 : TEXCOORD3;
					float4 param3 : TEXCOORD4;
				};
				
				float2 CalcRotTex(float2 tex, float angle, float2 centerOffset, float2 offsetScale)
				{
					float rotAngle = frac(angle * 0.15915491 + 0.5);
					rotAngle = (rotAngle * 2.0 - 1.0) * PI;	
					
					float2 rotCenter = centerOffset + float2(0.5, 0.5);
					float2 offset = (tex - rotCenter) * offsetScale;
					
					float cosA = cos(rotAngle);
					float sinA = sin(rotAngle);
					
					// rotate texcoord
					float2 newTex = float2(
						offset.x * cosA + offset.y * sinA,
						offset.y * cosA - offset.x * sinA
					);
					
					newTex += float2(0.5, 0.5);
					
					return newTex;
				}

				float CalcPusle(float time, float pusleRate, float pusleClip, float pusleIntensity, float pusleAmount)
				{
					float angle = frac((time * pusleRate) * 0.15915491 + 0.5);
					angle = (angle * 2.0 - 1.0) * PI;

					float sinA = sin(angle);
					float pusle = saturate((sinA + pusleClip) * pusleIntensity);

					pusle += -1.0;
					pusle *= pusleAmount;
					pusle += 1.0;
					
					return pusle;
				}

				v2f vert (appdata_full v)
				{
					v2f o;
					o.pos = TransformObjectToHClip(v.vertex.xyz);
					o.uv = v.texcoord;
					
					float time = _Seed + _Time.y * 0.08;
						
					float2 tex0 = v.texcoord;
					float2 tex_layer1 = 0;
					float2 tex_layer2 = 0;
					float2 tex_layer3 = 0;
					float2 tex_layer4 = 0;
					float pusle_layer1 = 0;
					float pusle_layer2 = 0;
					float pusle_layer3 = 0;
					float pusle_layer4 = 0;
					float2 flow_layer1 = 0;
					float2 flow_layer3 = 0;
					
					tex_layer1 = CalcRotTex(
						tex0, 
						_Fx1_FlowAngle,							// angle
						float2(0, 0),							// center offset
						float2(1, 1)							// offset scale
					);
					
					tex_layer1 += float2(_Fx1_FlowOffsetX, _Fx1_FlowOffsetY);
					tex_layer1 *= float2(_Fx1_FlowScaleX, _Fx1_FlowScaleY);
					
					flow_layer1 = time * float2(_Fx1_FlowScrollX, _Fx1_FlowScrollY);
				
				// layer 2
					tex_layer2 = CalcRotTex(
						tex0, 
						_Fx2_ScrollAngle,	// angle
						float2(0, 0),			// center offset
						float2(1, 1)			// offset scale
					);
				
					tex_layer2 += time * float2(_Fx2_ScrollX, _Fx2_ScrollY);
					tex_layer2 *= float2(_Fx2_ScaleX, _Fx2_ScaleY);
				
				// layer 3
					tex_layer3 = CalcRotTex(
						tex0, 
						_Fx3_ScrollAngle,	// angle
						float2(0, 0),			// center offset
						float2(1, 1)			// offset scale
					);
					
					tex_layer3 += time * float2(_Fx3_ScrollX, _Fx3_ScrollY);
					tex_layer3 *= float2(_Fx3_ScaleX, _Fx3_ScaleY);
					
					pusle_layer1 = CalcPusle(time, _Fx1_PusleRate, _Fx1_PusleClip, _Fx1_PusleIntensity, _Fx1_PusleAmount);
					pusle_layer2 = CalcPusle(time, _Fx2_PusleRate, _Fx2_PusleClip, _Fx2_PusleIntensity, _Fx2_PusleAmount);
					pusle_layer3 = CalcPusle(time, _Fx3_PusleRate, _Fx3_PusleClip, _Fx3_PusleIntensity, _Fx3_PusleAmount);
					
				#ifdef _LAYER3_FLOW_ON
					tex_layer3 += float2(_Fx3_FlowOffsetX, _Fx3_FlowOffsetY);
					tex_layer3 *= float2(_Fx3_FlowScaleX, _Fx3_FlowScaleY);
					flow_layer3 = time * float2(_Fx3_FlowScrollX, _Fx3_FlowScrollY);
				#endif
					
				#ifdef _LAYER4_ON
					tex_layer4 = CalcRotTex(
						tex0, 
						_Fx4_ScrollAngle,	// angle
						float2(0, 0),			// center offset
						float2(1, 1)			// offset scale
					);
					
					tex_layer4 += time * float2(_Fx4_ScrollX, _Fx4_ScrollY);
					tex_layer4 *= float2(_Fx4_ScaleX, _Fx4_ScaleY);
					
					pusle_layer4 = CalcPusle(time, _Fx4_PusleRate, _Fx4_PusleClip, _Fx4_PusleIntensity, _Fx4_PusleAmount);
				#endif
					
					o.param0 = float4(tex_layer1.x, tex_layer1.y, tex_layer2.x, tex_layer2.y);
					o.param1 = float4(tex_layer3.x, tex_layer3.y, tex_layer4.x, tex_layer4.y);
					o.param2 = float4(pusle_layer1, pusle_layer2, pusle_layer3, pusle_layer4);
					o.param3 = float4(flow_layer1.x, flow_layer1.y, flow_layer3.x, flow_layer3.y);
					return o;;
				}

				half4 frag (v2f i) : SV_Target
				{
					float2 uv = i.uv;
					//uv.y = 1 - uv.y;
				
					float4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uv);

					float2 tex_layer1 = i.param0.xy;
					float2 tex_layer2 = i.param0.zw;
					float2 tex_layer3 = i.param1.xy;
					float2 tex_layer4 = i.param1.zw;
					float pusle_layer1 = i.param2.x;
					float pusle_layer2 = i.param2.y;
					float pusle_layer3 = i.param2.z;
					float pusle_layer4 = i.param2.w;
					float2 tex_flow_layer1 = i.param3.xy;
					float2 tex_flow_layer3 = i.param3.zw;
					
					float fx1_flow = 1.0;
					float fx3_flow = 1.0;
					
				// fx1
					float3 flow = SAMPLE_TEXTURE2D(_Fx1_FlowTex, sampler_Fx1_FlowTex, tex_layer1).xyz;
					tex_layer1 = flow.xy * float2(_Fx1_ScaleX, _Fx1_ScaleY) + tex_flow_layer1;
					//mov r0.w, r1.z
					fx1_flow = flow.z;

					float3 color_layer1 = SAMPLE_TEXTURE2D(_Fx1_Tex, sampler_Fx1_Tex, tex_layer1).xyz;
					color_layer1 = abs(float3(_Fx1_Invert, _Fx1_Invert, _Fx1_Invert) - color_layer1);
					float distortion_layer1 = color_layer1.x;
					float scale_layer1 = fx1_flow * _Fx1_Color.w * _Fx1_Intensity * mask.x * pusle_layer1;
					color_layer1 *= _Fx1_Color.xyz * scale_layer1;
					
					// fx2
					float3 color_layer2 = SAMPLE_TEXTURE2D(_Fx2_Tex, sampler_Fx2_Tex, tex_layer2).xyz;
					color_layer2 = abs(float3(_Fx2_Invert, _Fx2_Invert, _Fx2_Invert) - color_layer2);
					float distortion_layer2 = color_layer2.x;
					float scale_layer2 = _Fx2_Color.w * _Fx2_Intensity * mask.y * pusle_layer2;
					color_layer2 *= _Fx2_Color.xyz * scale_layer2;

					// fx3
				#ifdef _LAYER3_FLOW_ON
					float3 flow3 = SAMPLE_TEXTURE2D(_Fx3_FlowTex, sampler_Fx3_FlowTex, tex_layer3).xyz;
					tex_layer3 = flow3.xy * float2(_Fx3_ScaleX, _Fx3_ScaleY) + tex_flow_layer3;
					fx3_flow = flow3.z;
				#endif

				#ifdef _LAYER3_BLEND_ON
					float4 color_layer3 = SAMPLE_TEXTURE2D(_Fx3_Tex, sampler_Fx3_Tex, tex_layer3);
					color_layer3 = abs(float4(_Fx3_Invert, _Fx3_Invert, _Fx3_Invert, _Fx3_Invert) - color_layer3);
					float distortion_layer3 = color_layer3.x;
					color_layer3 *= _Fx3_Color;
					color_layer3.xyz *= _Fx3_ColorIntensity;
					color_layer3.w *= (_Fx3_Intensity * mask.z * pusle_layer3);
				#else
					float3 color_layer3 = SAMPLE_TEXTURE2D(_Fx3_Tex, sampler_Fx3_Tex, tex_layer3).xyz;
					color_layer3 = abs(float3(_Fx3_Invert, _Fx3_Invert, _Fx3_Invert) - color_layer3);
					float distortion_layer3 = color_layer3.x;
					 float scale_layer3 = _Fx3_Color.w * _Fx3_Intensity * mask.z * pusle_layer3;
					color_layer3 *= _Fx3_Color.xyz * scale_layer3;
				#endif
					
					// distortion
					distortion_layer1 = (distortion_layer1 - 0.5) * mask.x;
					distortion_layer2 = (distortion_layer2 - 0.5) * mask.y;
					distortion_layer3 = (distortion_layer3 - 0.5) * mask.z;
					float offset = distortion_layer1 * _Fx1_Distortion;
					offset += distortion_layer2 * _Fx2_Distortion;
					offset += distortion_layer3 * _Fx3_Distortion;
					float2 distortionUV = offset * _DistortionVector;
					
					// main color
					float2 mainUV = uv + distortionUV;
					float3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV).xyz;
					
					// blend
					float3 c1 = (color_layer1 + color_layer2) * 0.5;
					float3 c2 = color_layer1 * color_layer2 - c1;
					float3 color_layer_1_2 = lerp(c1, c2, _Fx2_Blend);
					
					// layer3 alpha blend
				#ifdef _LAYER3_BLEND_ON
					color_layer_1_2 += _FxIntensity * _FxBrightness;
					
					float mask_all = saturate(mask.x + mask.y);
					float3 color_1_2_m = mask_all * color_layer_1_2 + mainColor;
					float3 color_layer_all = lerp(color_1_2_m, color_layer3.xyz, color_layer3.w);
				#else	// layer3 additive
					float3 c3 = (color_layer_1_2 + color_layer3) * 0.5;
					float3 c4 = color_layer_1_2 * color_layer3;
					float3 color_layer_1_2_3 = lerp(c3, c4, _Fx3_Blend);
					
					color_layer_1_2_3 += _FxIntensity * _FxBrightness;
					
					float mask_all = saturate(mask.x + mask.y + mask.z);
					float3 color_layer_all = mask_all * color_layer_1_2_3 + mainColor;
				#endif

				#ifdef _LAYER4_ON
					// layer 4
					float4 color_layer4 = SAMPLE_TEXTURE2D(_Fx4_Tex, sampler_Fx4_Tex, tex_layer4);
					color_layer4 *= _Fx4_Color;
					color_layer4.xyz *= _Fx4_ColorIntensity;
					color_layer4.w *= (_Fx4_Intensity * mask.w * pusle_layer4);
					// blend
					color_layer_all = lerp(color_layer_all, color_layer4.xyz, color_layer4.w);
				#endif

				#ifdef _LAYER3_BLEND_ON
				#else
					color_layer_all = saturate(color_layer_all);
				#endif

					return float4(color_layer_all, 1);
				}
				
			ENDHLSL
		}
	}

	//CustomEditor "GoldenCardMaterialEditor"
}