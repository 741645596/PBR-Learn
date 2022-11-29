#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

half4 _ShadowColor;
float _ShadowHeight;
half3 _ShadowProjDir;
float _ShadowOffsetX;
float _ShadowOffsetZ;

struct appdata
{
	float4 pos : POSITION;
};

struct v2f
{
	float4 vertex : SV_POSITION;
};

v2f vert(appdata v)
{
	v2f o;
    
	float3 projDir = normalize(_ShadowProjDir);
	
	half4 worldPos = mul(unity_ObjectToWorld, v.pos);
	
	float d1 = ( _ShadowHeight - worldPos.y ) / projDir.y;
	worldPos.xyz += d1 * projDir;
	worldPos.xz += float2(_ShadowOffsetX, _ShadowOffsetZ);
	o.vertex = mul(UNITY_MATRIX_VP, worldPos);
	return o;
}

half4 frag(v2f i) : SV_Target
{
	return _ShadowColor;
}