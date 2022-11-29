
#ifndef SGAME_SHADOWPLANT_INCLUDE
#define SGAME_SHADOWPLANT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
	//阴影颜色 目前由外部脚本设定 UpdateShadowPlane.cs
	half4 _ShadowColor;
	//阴影平面的高度 目前由外部脚本设定 UpdateShadowPlane.cs
	float _ShadowHeight;
	//XZ平面的偏移
	float _ShadowOffsetX;
	float _ShadowOffsetZ;

	//模型高度 由外部脚本设定 UpdateShadowPlane.cs
	float _MeshHight;
	//模型位置 由外部脚本设定 UpdateShadowPlane.cs
	float4 _WorldPos;
	//影子透明度
	half _AlphaVal;

	half3 _ProGameOutDir;
	half _ShadowStr=1;


	// meta 
	// x = use uv1 as raster position
	// y = use uv2 as raster position
	// bool4 unity_MetaVertexControl;

	// x = return albedo
	// y = return normal
	// bool4 unity_MetaFragmentControl;

	// Control which VisualizationMode we will
	// display in the editor
	// int unity_VisualizationMode;

CBUFFER_END

#endif
