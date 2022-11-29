//材质需要动态控制显示哪一个Pass
//使用方法
//1.URP管线配置 需要添加 RenderObjects,队列选择 BeforeRenderingTransparents,用于渲染平面阴影,此部分阴影是半透模式的阴影,Pass = "SGameShadowPassTrans", Queue = Transparent
//2.URP管线配置 需要添加 RenderObjects,队列选择 BeforeRendingPostProcessings,用于渲染平面阴影,此部分阴影是非透明阴影，当角色为半透的时候启用,Pass = "SGameShadowPass", Queue = Qpaque

//透明材质选择
//1.非透明模型(阴影开启) 开启Pass: "Opacity"或"PbrOpacity" "ShadowBeforeTrans"  关闭Pass:"TranslucentSrp" "Translucent" "BeforeRenderingTransparents"
//2.非透明模型(阴影关闭) 开启Pass: "Opacity"或"PbrOpacity"   关闭Pass:"TranslucentSrp" "Translucent" "BeforeRenderingTransparents" "ShadowBeforeTrans"

//3.透明模型(阴影开启) 开启Pass: "TranslucentSrp" "Translucent"或"PbrTranslucent" "BeforeRenderingTransparents"   关闭Pass: "Opacity"与"PbrOpacity" "ShadowBeforeTrans"
//4.透明模型(阴影关闭) 开启Pass: "TranslucentSrp" "Translucent"或"PbrTranslucent"   关闭Pass: "Opacity"与"PbrOpacity" "BeforeRenderingTransparents" "ShadowBeforeTrans"

//效果开启规则
//MatCap: 开启Key = _LIGHT_TEX_ON
//受击颜色: 开启Key = _HURT_EFFECT_ON
////特效图替换: 开启Key = _EFFECT_TEX_ON
//轮廓: 开启Key = _RIM_COLOR_ON
//溶解: 开启Key = _DISSOLVE_ON
////描边: 开启Key = _OUTLINE_ON

//低中高配

//低配
//1.关闭影子
//2.开启简易平面影子节点
//3.关闭PBR
//4.关闭MatCap

//中配
//1.开启影子
//2.关闭简易平面影子节点
//3.关闭PBR
//4.MatCap可开启

//高配
//1.开启影子
//2.关闭简易平面影子节点
//3.PBR可开启 ，MatCap可开启

Shader "FB/GameHero/HeroBattle"
{	
	Properties
	{
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


		[Space(25)]
		//受击颜色 _HURT_EFFECT_ON
		[MaterialToggle]_HurtEffectOn("开启受击闪烁", int) = 0
		_HurtColor("HurtColor", Color) = (0,0,0,0)

		[Space(25)]
		//受击振动 _HURT_SHAKEEFFECT_ON
		[MaterialToggle]_HurtShakeEffectOn("开启受击振动", int) = 0
		_ShakeNoiseMap("ShakeNoiseMap", 2D) = "white" {}
		_ShakeStrength("ShakeStrength(强度)", range(0,1)) = 1
		_ShakeFrequency("ShakeFrequency(频率)", range(0.1,10)) = 6
		_ShakeVertexTwist("ShakeVertexTwist(顶点扭动)", range(0,1)) = 0
		_ShakeHorizontalStrength("ShakeHorizontalStrength(水平强度)", range(0,1)) = 0.15
		_ShakeVerticalStrength("ShakeVerticalStrength(垂直强度)", range(0,1)) = 0.05
		_ShakeHorizontalWeight("ShakeHorizontalWeight(水平权重)", range(0,1)) = 0.5
		
		//效果相关
		//0:无 1:轮廓边缘 2:溶解 3:特效 4;描边
		_EffectType("效果类型", int) = 0

		[Space(25)]
		//特效  _EFFECT_TEX_ON
		_EffectTex("EffectTex (RGB)", 2D) = "white" {}
		_EffectFactor("EffectFactor(占比)", range(0,1)) = 0.85
		[HDR]_EffectTexColor("EffectTexColor", Color) = (1,1,1,1)

		[Space(25)]
		//轮廓 _RIM_COLOR_ON
		[HDR]_RimColor("RimColor(轮廓颜色) A:pow", Color) = (0,0,0,1)
		_RimColorSide("RimColorSide", range(0,1)) = 0.25

		[Space(25)]
		//溶解 _DISSOLVE_ON
		_DissolveTex("DissolveTex(RGBA)", 2D) = "black" {}
		_RinAlphaTex("RinAlphaTex(MatCap 保留区域)", 2D) = "white" {}
		_DissolveAlpha("DissolveAlpha(溶解保留区域透明度)", float) = 0.02
		_ScrollSpeed("Scroll Speed(xy:流速)", vector) = (0,0,0,0)
		_Dissolve("Dissolve", range(0,1)) = 1
		_DissolveLV("DissolveLV(亮度)", float) = 20
		_DissolveColor1("Dissolve Color1", Color) = (1,0,0,1)
		_DissolveColor2("Dissolve Color2", Color) = (0,1,0,1)

		//[Space(25)]
		////描边 _OUTLINE_ON
		//_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		//_Outline ("Outline width", Float) = 0.0015	

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
		[HDR] _EmissionColor("Color(自发光,A通道阴影强度)", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("Emission(自发光,A通道阴影强度)", 2D) = "white" {}

		[Space(25)]
		[HideInInspector]_PlantShadowType("0:开启影子 1:关闭影子", int) = 0
		[HideInInspector]_QualityType("0:低配 1:中配 3:高配", int) = 0
		[HideInInspector]_MatType_Low("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //低配
		[HideInInspector]_MatType_Mid("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //中配
		[HideInInspector]_MatType_Hight("0:非PBR,不透明 1:非PBR,透明 2:PBR,不透明 3:PBR,透明", int) = 0 //高配
		[HideInInspector]_MatCap_Mid("0:中配MatCap关 1:中配MatCap开 2:中配MatCap开法线开", int) = 0 //中配
		[HideInInspector]_MatCap_Hight("0:高配MatCap关 1:高配MatCap开 2:高配MatCap开法线开", int) = 0 //高配

		[MaterialToggle]_OutlineOpen("开启描边",float) = 0
		_Outline("描边宽度", float) = 0
		_OutlineColor("描边颜色", color) = (1,1,1,1)


	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="AlphaTest-178" "IgnoreProjector"="True" "RenderPipeline" = "UniversalPipeline"}
		LOD 200
		Fog { Mode Off }

		Pass 
		{
			Name "Outline"
			Tags {"LightMode" = "OutlinePass"}
			Cull Front
			Stencil
			{
				Ref 27
				Comp NotEqual
			}

			HLSLPROGRAM

			#pragma vertex vert_outline
			#pragma fragment frag_outline
			#include "HeroBattleShader.hlsl"
			
			struct a2v_outline
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			}; 

			struct v2f_outline
			{
				float4 pos : SV_POSITION;
			};

			v2f_outline vert_outline (a2v_outline v) 
			{
				v2f_outline o;

				float4 pos = mul(UNITY_MATRIX_MV, v.vertex); 
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);  
				normal.z = -0.5;
				pos = pos + float4(normalize(normal), 0) * _Outline / v.vertex.w * 0.01;
				o.pos = mul(UNITY_MATRIX_P, pos);

				return o;
			}

			float4 frag_outline(v2f_outline i) : SV_Target 
			{ 
				return float4(_OutlineColor.rgb, 1);               
			}

			ENDHLSL
		}

		//非透明模型
		Pass //0
		{
			Name "Opacity"
			Tags {"LightMode" = "UniversalForward"}

			Stencil
			{
				Ref 27
				Comp Always
				Pass Replace
			}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _LIGHT_TEX_ON _LIGHT_TEX_HIFHT_ON _LIGHT_TEXNORMAL_ON _LIGHT_TEXNORMAL_HIFHT_ON//MatCap 对应 中配 高配 中配法线 高配法线
			#pragma multi_compile _ _HURT_EFFECT_ON //受击颜色
			#pragma multi_compile _ _HURT_SHAKEEFFECT_ON //受击振动
			//轮廓:_RIM_COLOR_ON 溶解:_DISSOLVE_ON 特效:_EFFECT_TEX_ON 描边:_OUTLINE_ON
			#pragma multi_compile _ _RIM_COLOR_ON _DISSOLVE_ON //_EFFECT_TEX_ON _OUTLINE_ON
			#pragma multi_compile _ _LIGHT_ON//灯光

			#include "HeroBattleShader.hlsl"
			ENDHLSL
		}

		Pass //1
		{
			Name "PbrOpacity"
			Tags {"LightMode" = "UniversalForwardPbrOpacity"}

			Stencil
			{
				Ref 27
				Comp Always
				Pass Replace
			}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex PassVertexPBR
			#pragma fragment Fragment
			#pragma multi_compile _ _HURT_EFFECT_ON //受击颜色
			#pragma multi_compile _ _HURT_SHAKEEFFECT_ON //受击振动
			//轮廓:_RIM_COLOR_ON 溶解:_DISSOLVE_ON 特效:_EFFECT_TEX_ON 描边:_OUTLINE_ON
			#pragma multi_compile _ _RIM_COLOR_ON _DISSOLVE_ON //_EFFECT_TEX_ON _OUTLINE_ON

			//#include "HeroBattlePBRInput.hlsl"
			//#include "HeroBattlePBRForward.hlsl"
			#include "HeroBattlePBRLighting.hlsl"
			ENDHLSL
		}

		Pass //2
		{
			Name "ShadowBeforeTrans"
			Tags {"LightMode"="SGameShadowPass"}
			Stencil
			{
				Ref 0
				Comp equal
				Pass incrWrap
				Fail keep
				ZFail keep
			}
			
			Blend DstColor Zero
			ColorMask RGB
			ZWrite off
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _DISSOLVE_ON
			#define _HERO_CENTER_WORLDPOS
			#include "HeroBattleFlatShadow.hlsl"
			ENDHLSL
		}

		//透明模型

		Pass{ //3

			Name "TranslucentSrp"
			Tags {"LightMode" = "SrpDefaultUnlit"}
			
			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			struct VertexInput {
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(VertexInput v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				return o;
			}

			half4 frag(v2f i) : SV_Target{
				return half4(0,0,0,0);
			}

			ENDHLSL
		}

		Pass //4
		{
			Name "Translucent"
			Tags {"LightMode"="UniversalForwardTranslucent"}
			ZWrite Off
			Stencil
			{
				Ref 27
				Comp Always
				Pass Replace
			}
			Blend SrcAlpha OneMinusSrcAlpha
			//Blend One One
			ColorMask RGB
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _LIGHT_TEX_ON _LIGHT_TEX_HIFHT_ON _LIGHT_TEXNORMAL_ON _LIGHT_TEXNORMAL_HIFHT_ON//MatCap 对应 中配 高配 中配法线 高配法线
			#pragma multi_compile _ _HURT_EFFECT_ON //受击颜色
			#pragma multi_compile _ _HURT_SHAKEEFFECT_ON //受击振动
			//轮廓:_RIM_COLOR_ON 溶解:_DISSOLVE_ON 特效:_EFFECT_TEX_ON 描边:_OUTLINE_ON
			#pragma multi_compile _ _RIM_COLOR_ON _DISSOLVE_ON //_EFFECT_TEX_ON _OUTLINE_ON
			#pragma multi_compile _ _LIGHT_ON//灯光
			#define _TRANSLUCENT

			#include "HeroBattleTranslucent.hlsl"
			ENDHLSL
		}

		Pass //5
		{
			Name "PbrTranslucent"
			Tags {"LightMode"="UniversalForwardPbrTranslucent"}
			ZWrite Off
			Stencil
			{
				Ref 27
				Comp Always
				Pass Replace
			}
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex PassVertexPBR
			#pragma fragment Fragment
			#pragma multi_compile _ _HURT_EFFECT_ON //受击颜色
			#pragma multi_compile _ _HURT_SHAKEEFFECT_ON //受击振动
			//轮廓:_RIM_COLOR_ON 溶解:_DISSOLVE_ON 特效:_EFFECT_TEX_ON 描边:_OUTLINE_ON
			#pragma multi_compile _ _RIM_COLOR_ON _DISSOLVE_ON //_EFFECT_TEX_ON _OUTLINE_ON
			#define _TRANSLUCENT

			//#include "HeroBattlePBRInput.hlsl"
			//#include "HeroBattlePBRForward.hlsl"
			#include "HeroBattlePBRLighting.hlsl"
			ENDHLSL
		}

		Pass //6
		{
			Name "BeforeRenderingTransparents"
			Tags {"LightMode"="SGameShadowPassTrans"}
			Blend DstColor Zero
			ColorMask RGB
			ZWrite off
			Stencil
			{
				Ref 0
				Comp equal
				Pass incrWrap
				Fail keep
				ZFail keep
			}
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#define _TRANSLUCENT
			#define _HERO_CENTER_WORLDPOS
			#pragma multi_compile _ _DISSOLVE_ON
			#include "HeroBattleFlatShadow.hlsl"

			ENDHLSL
		}

	}
	
	CustomEditor "FBShaderGUI.GameHeroShaderGUI"
}
