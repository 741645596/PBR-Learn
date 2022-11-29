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
	//����ֵ С��0 ����
	float  ignore : TEXCOORD0;
	float shadowResoult : TEXCOORD1;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//���ƽ����λ��
//_zeroY:�����ˮƽ0ƽ��(�ŵ׵���)
//_vertexWorldPosOld:�����ԭʼ��������
//_shadowHeight:ָ������Ӱƽ��ĸ߶� �����(�ŵ׵���)��ƫ�Ƹ߶�
//_xzPosOffset:XZƽ���ƫ��
float3 GetPlantPos(float3 _projDir,float _zeroY,float3 _vertexWorldPosOld,float _shadowHeight,float2 _xzPosOffset) {
	//�˴�������Ӱ�ǰ��� _zeroY Y��0 ��λ�ü��� XZ ��ƫ�� ��Ӱ�����ѹƽ��_ShadowHeight�ĸ߶ȴ� ���� _zeroY Y��0 ��λ��һ�µĵ�ᱻ�޳�
	//��������
	float dirScale = (_projDir.y - _zeroY) / _projDir.y;
	//�߶ȱ���
	float hightScale = (_vertexWorldPosOld.y - _zeroY) / (_projDir.y - _zeroY);
	//_zeroYƽ��ĵ�����
	float3 vertexWorldPosZeroY = _vertexWorldPosOld - _projDir * dirScale * hightScale;
	vertexWorldPosZeroY.y = vertexWorldPosZeroY.y + _shadowHeight;
	vertexWorldPosZeroY.x = vertexWorldPosZeroY.x + _xzPosOffset.x;
	vertexWorldPosZeroY.z = vertexWorldPosZeroY.z + _xzPosOffset.y;
	return vertexWorldPosZeroY;
}

//���һ��������ɫ
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

//���ȡֵ��Χ0�е�ֵ��ȡֵ��Χ1�еĽ�� ���ձ�������
half GetRange(half _value, half _min0, half _max0, half _min1, half _max1) {
	return _min1 + ((_value - _min0) * (_max1 - _min1)) / (_max0 - _min0);
}

ShadowVertexOutput vertGame(ShadowVertexInput v,ShadowVertexOutput o,float3 projDir){
	//�˴�Ϊ�˴������ԭ���Զ �߶Ƚϵ͵���Ӱ��ǳ
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
	//����λ����Ӱƽ����µ�����
	half shadowHeight = GET_PROP(_ShadowHeight);
	half shadowOffsetX = GET_PROP(_ShadowOffsetX);
	half shadowOffsetZ = GET_PROP(_ShadowOffsetZ);
	float3 vertexWorldPosShadowPlant = GetPlantPos(projDir, zeroY, vertexWorldPosOld.xyz, shadowHeight,float2(shadowOffsetX, shadowOffsetZ));
	o.pos = mul(UNITY_MATRIX_VP, float4(vertexWorldPosShadowPlant, 1));
	//����뾶
	float radius = length(vertexWorldPosShadowPlant -float3(worldPos.x, vertexWorldPosShadowPlant.y, worldPos.z));
	//������ߵ����Ӱƽ����������
	float3 highestWorldPosShadowPlant= GetPlantPos(projDir, zeroY, float3(worldPos.x, meshHight, worldPos.z), shadowHeight, float2(shadowOffsetX, shadowOffsetZ));
	//�������뾶
	float maxRadius = length(highestWorldPosShadowPlant - float3(worldPos.x, highestWorldPosShadowPlant.y, worldPos.z));
	//����뾶����
	float radiusScale = radius / maxRadius;
	//��Ӱ�뾶���ܴ��ڵ������� ����GetRange()�õ�����׼ȷ��ֵ
	float powValue = 3;
	float maxRadiusScalePow = 3.375;
	//һ�׶δ��� ����Ӱ�Ľ����ʵ
	float firstStep = pow(radiusScale, powValue);
	//���׶ν��з�Χ�޶�
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


