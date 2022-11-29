
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float3 UILinearToSRGB(float3 c, half _IsInUICamera) {
    return lerp(c, LinearToSRGB(c), _IsInUICamera);
}

float2 ClampUV(float2 uv) {
    uv.x = max(uv.x, 0.001);
    uv.x = min(uv.x, 1);
    uv.y = max(uv.y, 0.001);
    uv.y = min(uv.y, 1);
    return uv;
}

//此函数根据传入参数重新计算纹理新的WrapMode的UV坐标 纹理原来的WrapMode将不在起作用
//uv:原来的uv
//clampValue (0 or 1):表明 纹理的WrapMode 当repeatU和repeatV任意一个为1 则clampValue=1 否则 clampValue=0
//repeatU (0 or 1): 1:U方向的WrapMode=Repeat
//repeatV (0 or 1): 1:V方向的WrapMode=Repeat
half2 GetUV(float2 uv,float clampValue,float repeatU, float repeatV,float4 _Texture_ST) {
    float2 uvDistortClamp = ClampUV(uv);
    //float2 uvDistortRepeat = uvDistortClamp - ceil(uvDistortClamp) + 1;

    //float2 uvDistortRepeat = fmod(uv, abs(_Texture_ST.xy*_Time.g) + abs(_Texture_ST.zw + float2(1,1)));
    float2 uvDistortRepeat = frac(uv);
    

    uvDistortRepeat.x = lerp(uvDistortClamp.x, uvDistortRepeat.x, repeatU);
    uvDistortRepeat.y = lerp(uvDistortClamp.y, uvDistortRepeat.y, repeatV);
    return lerp(uvDistortClamp, uvDistortRepeat, clampValue);
}




