#ifndef PBR_INPUTDISSOLVE_INCLUDE
#define PBR_INPUTDISSOLVE_INCLUDE
//_Dissolve
    //TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
    // half4 _DissolveTex_TilingOffset;
    // half _DissolveTexClamp;
    // half _DissolveTexRepeatU;
    // half _DissolveTexRepeatV;
    // half4 _uvDissSpeed;
    // half4 _DissolveTex_BlendFilter;
    // half _Dissolve;
    // half _DissolveRange;
    // half4 _DissolveColor1;
    // half4 _DissolveColor2;
    // half _DissolveTexRotAngle, _DissolveTexRotateToggle;
    //极坐标相关
	half _PolarEnable;
	half2 _UVDissolveSpeed;
	half _DissolveTexAngle;

	//溶解相关
	TEXTURE2D_X(_DissolveMap);
	SAMPLER(sampler_DissolveMap);

	half _DissolveStrength;
	half _DissolveEdgeWidth;
	half4 _EdgeEmission;
#endif