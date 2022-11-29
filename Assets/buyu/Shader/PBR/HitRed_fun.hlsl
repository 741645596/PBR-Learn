#ifndef HITRED_FUN
#define HITRED_FUN


half3 HitRed(half3 baseColor, half3 RimColor, half3 normalWS, half3 viewDirWS)
{
    half3 ResultColor = baseColor + RimColor;
#if _HITCOLORCHANNEL_RIM
    half ndv = dot(SafeNormalize(normalWS), SafeNormalize(viewDirWS));
    half Fresnel = pow(1.0 - saturate(ndv), 5.0 - _HitRimSpread) * _HitRimPower;
    half hitColorScale = 0;
    hitColorScale = saturate(Fresnel) * _OverlayMultiple;
    half3 hitColorAdd = _HitColor.rgb * _OverlayMultiple - RimColor;
    ResultColor += saturate(hitColorScale * hitColorAdd);

#elif _HITCOLORCHANNEL_ALBEDO
    half3 mulColor = saturate(_OverlayColor * _OverlayMultiple);
    ResultColor = mulColor * ResultColor;
#endif
    return ResultColor;
}

#endif // HITRED_FUN