
CBUFFER_START(HeroURPGroups) 
	TEXTURE2D_X(_FogOfWar); SAMPLER(sampler_FogOfWar);
	float4 _InvSceneSize;
	half4 _FOWColor;
	half4 _FOWParams;
CBUFFER_END

half3 ComputeFow(half3 sceneColor, float3 worldPos)
{
	half2 fowUv = worldPos.xz * _InvSceneSize.xy + 0.5;
	half fowLum = SAMPLE_TEXTURE2D(_FogOfWar, sampler_FogOfWar, fowUv).r;
	
#ifdef _FOG_OF_WAR_ON_LOW
	half factor = 0.85;
#else
	float3 PointToEye = worldPos - _WorldSpaceCameraPos;
	half PointToEyeDist = length(PointToEye);
	half factor = saturate(PointToEyeDist * _FOWParams.x + _FOWParams.y);
	factor = factor * factor;
#endif
	
	half3 fowColor = sceneColor * sceneColor;
	fowColor += (_FOWColor.rgb - fowColor) * factor;
	fowColor *= _FOWParams.z; 
	half3 res = lerp(fowColor, sceneColor, fowLum);
	return res;
}


