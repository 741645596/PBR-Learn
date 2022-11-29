float4 PBRDissolve(half4 Color,float2 uv)
{
    
    //极坐标UV
    float2 polar = toPolar(uv,_UVDissolveSpeed,_DissolveTexAngle,_PolarEnable);
    //溶解贴图
    half4 DissolveColor = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, polar);
    
    //求溶解裁切Alpha
    half DissolveAlpha  = step(DissolveColor.x, _DissolveStrength);

    //求溶解边宽
    half EdgeWidth      = step(DissolveColor.x, _DissolveStrength - _DissolveEdgeWidth);
   
    //得到边界颜色
    half4 emissionCd = (DissolveAlpha - EdgeWidth) * _EdgeEmission;
    //如遇图片灰度问题可开启这里
    /*
    if (_DissolveStrength > 0.999)
    {
        emissionCd = half4(0, 0, 0, 0);
    }*/
    
    return half4(emissionCd.rgb + Color.rgb,DissolveAlpha);

}
