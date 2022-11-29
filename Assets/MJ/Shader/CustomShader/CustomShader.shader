
Shader "FeiYun/Custom/CustomShader"
{	
	Properties
	{

		//[KeywordEnum(Normal, GrassAnim,River)] _MatType ("材质类型", Float) = 0

		//主纹理
		_BaseMap ("BaseMap (RGB)", 2D) = "grey" {} //低配 主纹理
		[HDR]_BaseColor("BaseColor", Color) = (1,1,1,1)
		_BaseMapMatCap ("BaseMap (RGB)", 2D) = "grey" {} //中配 MatCap 主纹理
		_BaseMapMatCapPBR ("BaseMap (RGB)", 2D) = "grey" {} //高配 MatCap 主纹理

		[Space(25)]
		//平面阴影
		_ShadowColor("Shadow Color", Color) = (0.83,0.89,0.97,1)
		_ShadowHeight("Shadow Height", float) = 0
		_MeshHight("Mesh Hight", float) = 0
		_ShadowOffsetX("Shadow Offset X", float) = 0.0
		_ShadowOffsetZ("Shadow Offset Y", float) = 0.0
		_AlphaSet("AlphaSet(美术用)", range(0,1)) = 1

		[HideInInspector]_AlphaSetSave_Low("AlphaSet(美术用)", range(0,1)) = 1
		[HideInInspector]_AlphaSetSave_Mid("AlphaSet(美术用)", range(0,1)) = 1
		[HideInInspector]_AlphaSetSave_Hight("AlphaSet(美术用)", range(0,1)) = 1
		[HideInInspector]_AlphaVal("AlphaVal(程序用)", range(0,1)) = 1
		[HideInInspector]_AlphaValClientTag("AlphaValClientTag(程序用控制标记)", range(0,1)) = 0

		[Space(25)]
		//MatCap _LIGHT_TEX_ON
		[MaterialToggle]_LightTexOn("开启MatCap", int) = 0
		_MainColor("BaseColor", Color) = (1,1,1,1)
		_LightTex("LightTex (MatCap)", 2D) = "gray" {}
		_LightTexG("LightTex (MatCap)", 2D) = "black" {}
		_LightTexB("LightTex (MatCap)", 2D) = "black" {}
		_LightTexA("LightTex (MatCap)", 2D) = "black" {}
		_MaskMap ("Mask: R(MatCap区域)", 2D) = "black" {}
		_MatCapNormal ("Normal", 2D) = "bump" {}
		_MatCapNormalScale("NormalScale", Range(-2,2)) = 1
		_LightScale("LightScale(MatCap强度)", range(0,10)) = 1
		_LightWeight("LightWeight(MatCap权重)", range(0,1)) = 0

		//非PBR灯光反应
		[MaterialToggle]_LightOn("开启灯光反应", int) = 0
		_MainLightStrength("MainLightStrength(主灯光反应程度)", range(0,1)) = 0.2
		_AddLightStrength("AddLightStrength(辅助灯光反应程度)", range(0,1)) = 0.2

		//PBR
		[Space(25)]
		_PBRBaseMap("Albedo(底色)", 2D) = "white" {}
		_PBRBaseMapOffset("TillingOffset", vector) = (1,1,0,0)
		_PBRBaseColor("Color(底色)", Color) = (1,1,1,1)
		[Space(25)]
		_NormalScale("NormalScale(法线)", Float) = 1.0
		[NoScaleOffset]_BumpMap("Normal Map(法线)", 2D) = "bump" {}
		[Space(25)]
		[NoScaleOffset]_MetallicGlossMap("Metallic(R:金属度 G:AO B:皮肤范围 A:光滑度)", 2D) = "white" {}
		_Smoothness("Smoothness(光滑度)", Range(0.0, 1.0)) = 0.85
		_Metallic("Metallic(金属度)", Range(0.0, 1.0)) = 1
		_OcclusionStrength("AOStrength(ao强度)", Range(0.0, 1.0)) = 1.0
		[Space(25)]
		[HDR] _EmissionColor("自发光颜色", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("自发光Mask", 2D) = "black" {}

		[Space(25)]
		[HideInInspector]_PlantShadowType("0:开启影子 1:关闭影子", int) = 0
		[HideInInspector]_QualityType("0:低配 1:中配 2:高配", int) = 2
		[HideInInspector]_MatType_Low("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //低配
		[HideInInspector]_MatType_Mid("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //中配
		[HideInInspector]_MatType_Hight("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //高配
		[HideInInspector]_MatCap_Mid("0:中配MatCap关 1:中配MatCap开 2:中配MatCap开法线开", int) = 0 //中配
		[HideInInspector]_MatCap_Hight("0:高配MatCap关 1:高配MatCap开 2:高配MatCap开法线开", int) = 0 //高配

		[HideInInspector] _ShadowType("ShadowType",Int) = 0 // 0:Unity 1:HQ

	}
	
	SubShader
	{

		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest-178" "IgnoreProjector"="True" "RenderPipeline" = "UniversalPipeline"}
		LOD 200
		Fog { Mode Off }

		Cull off

		//非透明模型
		Pass //0
		{
			Name "Opacity"
			Tags {"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#ifdef _THISLIGHTMAP_ON
				#define LIGHTMAP_ON
			#endif
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _TRANSLUCENT
			#pragma multi_compile _ _THISLIGHTMAP_ON
			#pragma multi_compile _ _LIGHTMAP_ENCODE_ON
			#pragma multi_compile _ _LIGHT_TEX_ON _LIGHT_TEX_HIFHT_ON _LIGHT_TEXNORMAL_ON _LIGHT_TEXNORMAL_HIFHT_ON//MatCap 对应 中配 高配 中配法线 高配法线
			#pragma multi_compile _ _LIGHT_ON//灯光

			#include "CustomShader.hlsl"
			#include "Scene.hlsl"
			ENDHLSL
		}

		Pass //1
		{
			Name "PbrOpacity"
			Tags {"LightMode" = "UniversalForwardPbrOpacity"}
			HLSLPROGRAM
			#ifdef _THISLIGHTMAP_ON
				#define LIGHTMAP_ON
			#endif
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex PassVertexPBR
			#pragma fragment Fragment
			#pragma multi_compile _ _TRANSLUCENT
			#pragma multi_compile _ _THISLIGHTMAP_ON
			#pragma shader_feature _RECEIVE_SHADOWS_OFF
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma shader_feature _ ENABLE_HQ_SHADOW ENABLE_HQ_AND_UNITY_SHADOW

			#include "CustomPBRLighting.hlsl"
			#include "Scene.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}

			ZWrite On
			ZTest LEqual
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature _ALPHATEST_ON

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			#include "CustomShaderInput.hlsl"
			#include "CustomPBRForward.hlsl"

			float3 _LightDirection;
			float3 _LightPosition;
			
			float4 GetShadowPositionHClip(AttributesSSS input)
			{
				float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				return positionCS;
			}

			half Alpha(half albedoAlpha, half4 color, half cutoff)
			{
				#if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
					half alpha = albedoAlpha * color.a;
				#else
					half alpha = color.a;
				#endif

				#if defined(_ALPHATEST_ON)
					clip(alpha - cutoff);
				#endif

				return alpha;
			}

			VaryingsPBR ShadowPassVertex(AttributesSSS input)
			{
				VaryingsPBR output;
				UNITY_SETUP_INSTANCE_ID(input);
				output.uv.xy = UVTilingOffset(input.texcoord.xy,_PBRBaseMapOffset);
				output.positionCS = GetShadowPositionHClip(input);
				return output;
			}

			half4 ShadowPassFragment(VaryingsPBR input) : SV_TARGET
			{
				Alpha(SAMPLE_TEXTURE2D(_PBRBaseMap, sampler_PBRBaseMap, input.uv.xy).a, _PBRBaseColor, _Cutoff);
				return 0;
			}

			ENDHLSL
		}
	}
	
	CustomEditor "Yun_FBShaderGUI.Yun_CustomShaderGUI"
}
