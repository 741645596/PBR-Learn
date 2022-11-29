#include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

struct VertexInput
{
    float4 in_POSITION0 : POSITION;
    float3 in_NORMAL0   : NORMAL;
    float2 in_TEXCOORD0 : TEXCOORD0;//UV
};

struct VertexOutput
{
    float4 gl_Position  : SV_POSITION;
    float4 vs_TEXCOORD0 : TEXCOORD0;//WorldPos
    float4 vs_TEXCOORD1 : TEXCOORD1;//Diffuse
};

CBUFFER_START(UnityPerMaterial)

    float4 _SubTexUV;
    half _EnvironmentLightInt;
    half _FresnelLV;
    half _FurGravity;
    float4 _BaseColor;
    float _FarSpacing;
    float _FurTickness;

    sampler2D _FlowTex;
  
    sampler2D _MainTex;
    float4  _MainTex_ST;

CBUFFER_END



//顶点着色
VertexOutput vert(VertexInput v)
{   
    VertexOutput o = (VertexOutput)0;

    float4 posWorld0 = mul(unity_ObjectToWorld, v.in_POSITION0);
    float len0 = length(posWorld0.xyz - _WorldSpaceCameraPos); 
    float spacing = _FarSpacing * 0.1;
    half4 positionLS;


    positionLS.xyz = normalize(mul(unity_WorldToObject, float3(0,-FUROFFSETVX*2*_FurGravity,0)) + v.in_NORMAL0.xyz) * FUROFFSETVX; //添加简单重力

    positionLS.xyz = positionLS.xyz * spacing * 0.1 + v.in_POSITION0.xyz;
    positionLS.w = 1.0;

    float4 posWorld = mul(unity_ObjectToWorld, positionLS);
    o.gl_Position = mul(UNITY_MATRIX_VP, posWorld);

    half2 uv = TRANSFORM_TEX(v.in_TEXCOORD0, _MainTex);
    o.vs_TEXCOORD0.xy = uv;
    o.vs_TEXCOORD0.zw = (v.in_TEXCOORD0 * _SubTexUV.xy);

    half3 normalWorld = TransformObjectToWorldNormal(v.in_NORMAL0); 
    float3 eyeVec = normalize(posWorld.xyz - _WorldSpaceCameraPos); 
    float nv = saturate(dot(normalWorld, -eyeVec));  

    float3 lightDir = _MainLightPosition.xyz;
    float3 nl = dot(normalWorld, lightDir);
    nl = nl + (FUROFFSETVX * 0.1 - 0.2)* (1 - _EnvironmentLightInt); 
    Light mainLight = GetMainLight();
    
    half3 sh = SampleSHVertex(normalWorld);

  
    half FurSSS = sh * pow(1 - nv,4) * (FUROFFSETVX * FUROFFSETVX * FUROFFSETVX * FUROFFSETVX) * 10 * _FresnelLV;
    half3 ambient =  sh  * lerp((FUROFFSETVX * 2 + 0.3), 1.3,  _EnvironmentLightInt);
    half shadowAtten = max(0.1, nl) * mainLight.color;

    o.vs_TEXCOORD1.xyz = shadowAtten  + (ambient + FurSSS);
    
    o.vs_TEXCOORD1.w = 1.0;

    return o;
}

half4 frag(VertexOutput v) : SV_Target
{
    half4 SV_Target0;
    half3 mainColor = (tex2D(_MainTex, v.vs_TEXCOORD0.xy).xyz) * _BaseColor.xyz;
    half3 finalColor = mainColor * v.vs_TEXCOORD1.xyz;
    half flowTex = tex2D(_FlowTex, v.vs_TEXCOORD0.zw).x;
    half furAlphaOffset = pow(FUROFFSETVX , 0.8 + _FurTickness); 
    finalColor.rgb = (finalColor.rgb);
    SV_Target0.xyz = finalColor;// / (finalColor + 0.155);
    SV_Target0.w = saturate(flowTex.x - pow(furAlphaOffset ,  1 + _FurTickness * 3)) ;
    SV_Target0.w *= _BaseColor.a;
    return SV_Target0;
}



//顶点着色
VertexOutput vertFirst(VertexInput v)
{   
    VertexOutput o = (VertexOutput)0;

    float4 posWorld = mul(unity_ObjectToWorld, v.in_POSITION0);
    o.gl_Position = mul(UNITY_MATRIX_VP, posWorld);
    half2 uv = TRANSFORM_TEX(v.in_TEXCOORD0, _MainTex);
    o.vs_TEXCOORD0.xy = uv;
    o.vs_TEXCOORD0.zw = v.in_TEXCOORD0 * _SubTexUV.xy;
    half3 normalWorld = TransformObjectToWorldNormal(v.in_NORMAL0);  //normalWorld
    float3 eyeVec = normalize(posWorld.xyz - _WorldSpaceCameraPos); //eyeVec
    float nv = saturate(dot(normalWorld, -eyeVec));  //nv
    float3 lightDir = _MainLightPosition.xyz;
    float3 nl = saturate(dot(normalWorld, lightDir));
    nl = nl  - 0.2 * (1 - _EnvironmentLightInt); //模拟光穿过毛发
    half3 sh = SampleSHVertex(normalWorld);
    Light mainLight = GetMainLight();
    half3 ambient =  sh  * lerp(0.3, 1.3, _EnvironmentLightInt);
    o.vs_TEXCOORD1.xyz = max(0, nl) * mainLight.color  + ambient;
    
    o.vs_TEXCOORD1.w = 1.0;

    return o;
}

half4 fragFirst(VertexOutput v) : SV_Target
{
    half4 SV_Target0;
    half3 mainColor = (tex2D(_MainTex, v.vs_TEXCOORD0.xy).xyz) * _BaseColor.xyz;
    half3 finalColor = mainColor * v.vs_TEXCOORD1.xyz;
    finalColor.rgb = (finalColor.rgb);

    SV_Target0.xyz = (finalColor.rgb);
    SV_Target0.w = 1;
    return SV_Target0;
}