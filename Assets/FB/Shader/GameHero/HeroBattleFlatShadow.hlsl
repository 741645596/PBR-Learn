#ifndef HEROBATTLE_FLATSHADOW
#define HEROBATTLE_FLATSHADOW

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
#include "HeroBattleShaderInput.hlsl" 

struct ShadowVertexInput {
	UNITY_VERTEX_INPUT_INSTANCE_ID
	float4 vertex : POSITION;
};

struct ShadowVertexOutput
{
	float4 pos : SV_POSITION;
	//剪裁值 小于0 剪裁
	float  ignore : TEXCOORD0;
	float shadowResoult : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//获得平面点的位置
//_zeroY:虚拟的水平0平面(脚底地面)
//_vertexWorldPosOld:顶点的原始世界坐标
//_shadowHeight:指定的阴影平面的高度 相对于(脚底地面)的偏移高度
//_xzPosOffset:XZ平面的偏移
float3 GetPlantPos(float3 _projDir,float _zeroY,float3 _vertexWorldPosOld,float _shadowHeight,float2 _xzPosOffset) {
	//此处计算阴影是按照 _zeroY Y轴0 的位置计算 XZ 的偏移 阴影顶点会压平在_ShadowHeight的高度处 处于 _zeroY Y轴0 的位置一下的点会被剔除
	//向量比例
	float dirScale = (_projDir.y - _zeroY) / _projDir.y;
	//高度比例
	float hightScale = (_vertexWorldPosOld.y - _zeroY) / (_projDir.y - _zeroY);
	//_zeroY平面的点坐标
	float3 vertexWorldPosZeroY = _vertexWorldPosOld - _projDir * dirScale * hightScale;
	vertexWorldPosZeroY.y = vertexWorldPosZeroY.y + _shadowHeight;
	vertexWorldPosZeroY.x = vertexWorldPosZeroY.x + _xzPosOffset.x;
	vertexWorldPosZeroY.z = vertexWorldPosZeroY.z + _xzPosOffset.y;
	return vertexWorldPosZeroY;
}

//获得一个最亮颜色
half3 ColorBrightet(half3 _color) {
	_color.r = max(0.001, _color.r);
	_color.g = max(0.001, _color.g);
	_color.b = max(0.001, _color.b);
	half maxValue = max(_color.r, _color.g);
	maxValue = max(maxValue, _color.b);
	half maxScale = 1/maxValue;
	_color = _color * maxScale;
	return _color;
}

//获得取值范围0中的值在取值范围1中的结果 按照比例缩放
half GetRange(half _value, half _min0, half _max0, half _min1, half _max1) {
	return _min1 + ((_value - _min0) * (_max1 - _min1)) / (_max0 - _min0);
}

ShadowVertexOutput vertGame(ShadowVertexInput v,ShadowVertexOutput o,float3 projDir){
	//此处为了处理距离原点过远 高度较低的阴影过浅
	half meshHight = GET_PROP(_MeshHight);
	float hightCoefficient = max(0, 4 - meshHight * 2.3);
	meshHight = meshHight + hightCoefficient;
	
	half4 worldPos;
	#ifdef _HERO_CENTER_WORLDPOS
		worldPos.xyz = TransformObjectToWorld(half3(0,0,0));
	#else
	    worldPos = GET_PROP(_WorldPos);
	#endif

	float3 vertexWorldPosOld = TransformObjectToWorld(v.vertex.xyz);
	float zeroY = 0;
	o.ignore = vertexWorldPosOld.y - zeroY + 0.001;
	//计算位于阴影平面的新的坐标
	half shadowHeight = GET_PROP(_ShadowHeight);
	half shadowOffsetX = GET_PROP(_ShadowOffsetX);
	half shadowOffsetZ = GET_PROP(_ShadowOffsetZ);
	float3 vertexWorldPosShadowPlant = GetPlantPos(projDir, zeroY, vertexWorldPosOld.xyz, shadowHeight,float2(shadowOffsetX, shadowOffsetZ));
	o.pos = mul(UNITY_MATRIX_VP, float4(vertexWorldPosShadowPlant, 1));
	//计算半径
	float radius = length(vertexWorldPosShadowPlant -float3(worldPos.x, vertexWorldPosShadowPlant.y, worldPos.z));
	//计算最高点的阴影平面世界坐标
	float3 highestWorldPosShadowPlant= GetPlantPos(projDir, zeroY, float3(worldPos.x, meshHight, worldPos.z), shadowHeight, float2(shadowOffsetX, shadowOffsetZ));
	//计算最大半径
	float maxRadius = length(highestWorldPosShadowPlant - float3(worldPos.x, highestWorldPosShadowPlant.y, worldPos.z));
	//计算半径比例
	float radiusScale = radius / maxRadius;
	//阴影半径可能存在的最大比例 用于GetRange()得到更加准确的值
	float powValue = 3;
	float maxRadiusScalePow = 3.375;
	//一阶段处理 让阴影的渐变更实
	float firstStep = pow(radiusScale, powValue);
	//二阶段进行范围限定
	float minShadow = 0.25;
	o.shadowResoult = GetRange(firstStep, 0, maxRadiusScalePow, minShadow, 0.85);
	return o;
}

ShadowVertexOutput vert(ShadowVertexInput v)
{
	ShadowVertexOutput o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	float3 projDir = normalize(float3(0.57, 1.9, 0.48));
	return vertGame(v,o,projDir);
}

ShadowVertexOutput vertGameOut(ShadowVertexInput v)
{
	ShadowVertexOutput o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	float3 projDir = normalize(GET_PROP(_ProGameOutDir));
	return vertGame(v,o,projDir);
}

half4 frag(ShadowVertexOutput i) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	//_DISSOLVE_ON
	#if defined(_DISSOLVE_ON)
		clip(-1);
	#endif
	half4 shadowColor = GET_PROP(_ShadowColor);
	half3 res = saturate(i.shadowResoult)  * ColorBrightet(shadowColor.rgb);
	#if defined(_TRANSLUCENT)
		res = lerp(half3(1,1,1),res, _AlphaVal);
	#endif
	return half4(res*lerp(2,1,shadowColor.a),1);
}

#endif


