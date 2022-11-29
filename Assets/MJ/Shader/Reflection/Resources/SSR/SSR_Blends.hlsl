#ifndef SSR_BLENDS
#define SSR_BLENDS

	// Copyright 2021 Kronnect - All Rights Reserved.

    TEXTURE2D_X(_MainTex);
    float4 _MainTex_TexelSize;
    float4 _SSRSettings4;
    #define SEPARATION_POS _SSRSettings4.x
    float  _MinimumBlur;

    TEXTURE2D_X(_RayCastRT);
    TEXTURE2D_X(_ReflectionsRT);
    TEXTURE2D_X(_BlurRTMip0);
    TEXTURE2D_X(_BlurRTMip1);
    TEXTURE2D_X(_BlurRTMip2);
    TEXTURE2D_X(_BlurRTMip3);
    TEXTURE2D_X(_BlurRTMip4);

	struct AttributesFS {
		float4 positionHCS : POSITION;
		float2 uv          : TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

 	struct VaryingsSSR {
    	float4 positionCS : SV_POSITION;
    	float2 uv  : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
	};


	VaryingsSSR VertSSR(AttributesFS input) {
	    VaryingsSSR output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = float4(input.positionHCS.xyz, 1.0);

		#if UNITY_UV_STARTS_AT_TOP
		output.positionCS.y *= -1;
		#endif

        output.uv = input.uv;
    	return output;
	}


	half4 FragCopy (VaryingsSSR i) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.uv     = SSRStereoTransformScreenSpaceTex(i.uv);
   		half4 pixel = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, i.uv);
        return pixel;
	}

	half4 FragCopyExact (VaryingsSSR i) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.uv     = SSRStereoTransformScreenSpaceTex(i.uv);
   		half4 pixel = SAMPLE_TEXTURE2D_X(_MainTex, sampler_PointClamp, i.uv);
        pixel = max(pixel, 0.0);
        return pixel;
	}

    half4 Combine(VaryingsSSR i) {

        // exclude skybox from blur bleed
        float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, i.uv).r;
        #if UNITY_REVERSED_Z
            depth = 1.0 - depth;
        #endif
        if (depth >= 1.0) return float4(0,0,0,0);

    	half4 mip0  = SAMPLE_TEXTURE2D_X(_ReflectionsRT, sampler_LinearClamp, i.uv);
        half4 mip1  = SAMPLE_TEXTURE2D_X(_BlurRTMip0, sampler_LinearClamp, i.uv);
        half4 mip2  = SAMPLE_TEXTURE2D_X(_BlurRTMip1, sampler_LinearClamp, i.uv);
        half4 mip3  = SAMPLE_TEXTURE2D_X(_BlurRTMip2, sampler_LinearClamp, i.uv);
        half4 mip4  = SAMPLE_TEXTURE2D_X(_BlurRTMip3, sampler_LinearClamp, i.uv);
        half4 mip5  = SAMPLE_TEXTURE2D_X(_BlurRTMip4, sampler_LinearClamp, i.uv);

        half r = mip5.a;
        half4 reflData = SAMPLE_TEXTURE2D_X(_RayCastRT, sampler_PointClamp, i.uv);
        if (reflData.z > 0) {
            r = min(reflData.z, r);
        }

        half roughness = clamp(r + _MinimumBlur, 0, 5);

        half w0 = max(0, 1.0 - roughness);
        half w1 = max(0, 1.0 - abs(roughness - 1.0));
        half w2 = max(0, 1.0 - abs(roughness - 2.0));
        half w3 = max(0, 1.0 - abs(roughness - 3.0));
        half w4 = max(0, 1.0 - abs(roughness - 4.0));
        half w5 = max(0, 1.0 - abs(roughness - 5.0));

        half4 refl = mip0 * w0 + mip1 * w1 + mip2 * w2 + mip3 * w3 + mip4 * w4 + mip5 * w5;
        return refl;
	}

	half4 FragCombine (VaryingsSSR i) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.uv     = SSRStereoTransformScreenSpaceTex(i.uv);
        return Combine(i);
    }


	half4 FragCombineWithCompare (VaryingsSSR i) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.uv     = SSRStereoTransformScreenSpaceTex(i.uv);
        if (i.uv.x < SEPARATION_POS - _MainTex_TexelSize.x * 3) {
            return 0;
        } else if (i.uv.x < SEPARATION_POS + _MainTex_TexelSize.x * 3) {
            return 1.0;
        } else {
            return Combine(i);
        }
	}

#endif // SSR_BLENDS