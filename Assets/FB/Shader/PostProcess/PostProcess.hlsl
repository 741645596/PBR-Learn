#ifndef POSTPRO_INCLUDE
#define POSTPRO_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

//#if defined(USING_STEREO_MATRICES)
//    #define unity_eyeIndex unity_StereoEyeIndex
//#else
//    #define unity_eyeIndex 0
//#endif

//half4x4 _RenderPassCameraVP[2];
half4x4 _RenderPassCameraVP;

//计算世界坐标到屏幕uv
//需要先设置 RenderPassUtils.cs->SetShaderWorldToScreenPosition(CommandBuffer cmd,ScriptableRenderContext context, ref RenderingData renderingData);
half3 RenderPass_WorldToScreenPosition(half3 pnt)
{
    //half4x4 camVP = _RenderPassCameraVP[unity_eyeIndex];
    half4x4 camVP = _RenderPassCameraVP;

    half3 result;
    result.x = camVP._m00 * pnt.x + camVP._m01 * pnt.y + camVP._m02 * pnt.z + camVP._m03;
    result.y = camVP._m10 * pnt.x + camVP._m11 * pnt.y + camVP._m12 * pnt.z + camVP._m13;
    result.z = camVP._m20 * pnt.x + camVP._m21 * pnt.y + camVP._m22 * pnt.z + camVP._m23;
    half num = camVP._m30 * pnt.x + camVP._m31 * pnt.y + camVP._m32 * pnt.z + camVP._m33;
    num = 1.0 / num;
    result.x *= num;
    result.y *= num;
    result.z = num;

    result.x = result.x * 0.5 + 0.5;
    result.y = result.y * 0.5 + 0.5;

    return result;
}

float3 AntiACESToneMapping(float3 color) {
    float3 x = saturate(color);
    float3 a = -10127.0 * x * x + 13702.0 * x + 9.0;
    float3 b = 5.0 * pow(a, 0.5) + 295.0 * x - 15.0;
    float3 c = b / (2008.0 -1994.0*x);
    return c;
}

float3 ACESToneMapping(float3 color) {
    color = color * 0.8;
    float3 A = 2.51;
    float3 B = 0.03;
    float3 C = 2.43;
    float3 D = 0.59;
    float3 E = 0.14;

    return (color*(A*color+B)) / (color*(C*color+D)+E);
}

half2 WrapUv(half2 uv,half2 distortion){
    distortion = clamp(distortion,0, 1);
    half2 m = smoothstep(0,0.3,distortion)*smoothstep(1,0.7,distortion)*0.5;
    distortion=(distortion*2-1)*m;
    uv += distortion.xy;
    uv = clamp(uv, 0, 1);
    return uv;
}

//Mao Xing Yun
//故障特效

//RGB颜色分离故障（RGB Split Glitch） 水平
//indensity:强度
half3 RGBSplit_Horizontal(TEXTURE2D_PARAM(texMap, sampler_texMap),float2 uv, half frequency, half indensity) {
    float randomNoise = frac(sin(dot(float2(_Time.z * frequency, 2), float2(12.9898, 78.233))) * 43758.5453);
    //float randomNoise = frac(sin(_Time.z * frequency)* 437580.5453);
    float splitAmount = indensity * randomNoise;

    half4 colorR = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x + splitAmount, uv.y));
    half4 colorG = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv);
    half4 colorB = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x - splitAmount, uv.y));

    return half3(colorR.r, colorG.g, colorB.b);
}

//frequency: 频率 默认1
//amplitude: 间隔  默认2
//indensity: 强度  默认1
half3 RGBSplit_Horizontal(TEXTURE2D_PARAM(texMap, sampler_texMap), float2 uv, half frequency,half amplitude,half indensity) {

    float t = _Time.z * frequency;

    float splitAmout = (1.0 + sin(t * 6.0)) * 0.5;
    splitAmout *= 1.0 + sin(t * 16.0) * 0.5;
    splitAmout *= 1.0 + sin(t * 19.0) * 0.5;
    splitAmout *= 1.0 + sin(t * 27.0) * 0.5;
    splitAmout = pow(splitAmout, amplitude);
    splitAmout *= 0.05 * indensity;

    //float distance = length(uv - float2(0.5, 0.5));
    //splitAmout=splitAmout*distance;

    half3 finalColor;
    finalColor.r = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x + splitAmout, uv.y)).r;
    finalColor.g = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv).g;
    finalColor.b = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x - splitAmout, uv.y)).b;

    finalColor *= (1.0 - splitAmout * 0.5);

    return finalColor;
}

//RGB颜色分离故障（RGB Split Glitch） 垂直
//_indensity:强度
half3 RGBSplit_Vertical(TEXTURE2D_PARAM(texMap, sampler_texMap), float2 uv, half frequency, half _indensity) {
    float randomNoise = frac(sin(dot(float2(_Time.z * frequency, 2), float2(12.9898, 78.233))) * 43758.5453);
    //float randomNoise = frac(sin(_Time.z * frequency)* 43758.5453);
    float splitAmount = _indensity * randomNoise;

    half4 colorR = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x , uv.y + splitAmount));
    half4 colorG = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv);
    half4 colorB = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x , uv.y - splitAmount));

    return half3(colorR.r, colorG.g, colorB.b);
}

//frequency: 频率 默认1
//amplitude: 间隔  默认2
//indensity: 强度  默认1
half3 RGBSplit_Vertical(TEXTURE2D_PARAM(texMap, sampler_texMap), float2 uv, half frequency, half amplitude, half indensity) {

    float t = _Time.z * frequency;

    float splitAmout = (1.0 + sin(t * 6.0)) * 0.5;
    splitAmout *= 1.0 + sin(t * 16.0) * 0.5;
    splitAmout *= 1.0 + sin(t * 19.0) * 0.5;
    splitAmout *= 1.0 + sin(t * 27.0) * 0.5;
    splitAmout = pow(splitAmout, amplitude);
    splitAmout *= 0.05 * indensity;

    //float distance = length(uv - float2(0.5, 0.5));
    //splitAmout=splitAmout*distance;

    half3 finalColor;
    finalColor.r = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x, uv.y + splitAmout)).r;
    finalColor.g = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv).g;
    finalColor.b = SAMPLE_TEXTURE2D(texMap, sampler_texMap, float2(uv.x, uv.y - splitAmout)).b;

    finalColor *= (1.0 - splitAmout * 0.5);

    return finalColor;
}

//Image Block Glitch 错位图块故障

//frequency: 频率 默认 5
//blockCount: 错位块数量 默认30
half3 ImageBlockGlitch(TEXTURE2D_PARAM(texMap, sampler_texMap), float2 uv, half frequency,half blockCount) {

    float2 uv2 = floor(uv * blockCount) * floor(_Time.y * frequency);
    float dotUV = dot(uv2, float2(17.13, 3.71));
    float2 block = frac(sin(dotUV) * 43758.5453123);
    float displaceNoise = pow(block.x, 8.0) * pow(block.x, 3.0);

    half ColorR = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv).r;
    half ColorG = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv + float2(displaceNoise * 0.02 , 0.0)).g;
    half ColorB = SAMPLE_TEXTURE2D(texMap, sampler_texMap, uv - float2(displaceNoise * 0.02 , 0.0)).b;

    return half3(ColorR, ColorG, ColorB);
}


#endif
