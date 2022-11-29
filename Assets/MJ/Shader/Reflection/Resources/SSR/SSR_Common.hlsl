#ifndef SSR_COMMON
#define SSR_COMMON

	// XR is not supported but we leave this macro for future uses
	#define SSRStereoTransformScreenSpaceTex(x) UnityStereoTransformScreenSpaceTex(x)
	//#define SSRStereoTransformScreenSpaceTex(x) x

    #define dot2(x) dot(x, x)

	inline half getLuma(float3 rgb) { 
		const half3 lum = float3(0.299, 0.587, 0.114);
		return dot(rgb, lum);
	}



#endif // SSR_BLUR