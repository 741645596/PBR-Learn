//平面阴影制造

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
half4 _ShadowColor;
float4 _ShadowPlane;
float _ShadowHeight;
float _ShadowOffsetX;
float _ShadowOffsetZ;
float4 _ShadowProjDir;

struct appdata_base{
    float4 vertex:POSITION;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float  ignore : TEXCOORD0;
};

v2f vert(appdata_base v)
{
	float height = _ShadowHeight + _ShadowPlane.w;
#ifdef _SHADOW_PROJECT_DIR_ON
	float3 projDir = normalize(_ShadowProjDir);
#else
	float3 projDir = normalize(float3(0.57, 1.0, 0.48));
#endif
	
	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	
	float d1 = (worldPos.y - height) / projDir.y;
	float3 planePos = worldPos - d1 * projDir;
	
	planePos.xz += float2(_ShadowOffsetX, _ShadowOffsetZ);
	
	v2f o;
	o.pos = mul(UNITY_MATRIX_VP, float4(planePos, 1));
	if( worldPos.y - planePos.y <=0 ){
		o.ignore = 0;
	}
	else{
		o.ignore = 1;
	}
	return o;
}

half4 frag(v2f i) : COLOR0
{
	if(abs(i.ignore - 0) < 0.0001){
		clip(-1);
	}
	return _ShadowColor;
}