#ifndef SSR_SOLVE
#define SSR_SOLVE

	// Copyright 2021 Kronnect - All Rights Reserved.
    TEXTURE2D_X(_MainTex);
	float4 _MainTex_TexelSize;
    TEXTURE2D_X(_RayCastRT);
    float4 _SSRSettings2;
    #define ENERGY_CONSERVATION _SSRSettings2.y
    #define REFLECTIONS_MULTIPLIER _SSRSettings2.z
    float4 _SSRSettings4;
    #define REFLECTIONS_MIN_INTENSITY _SSRSettings4.y
    #define REFLECTIONS_MAX_INTENSITY _SSRSettings4.z
    #define VIGNETTE_SIZE _SSRSettings2.w

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

	half4 FragResolve (VaryingsSSR i) : SV_Target { 

        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.uv = SSRStereoTransformScreenSpaceTex(i.uv);

        half4 reflData = SAMPLE_TEXTURE2D_X(_RayCastRT, sampler_PointClamp, i.uv);
  		half4 reflection = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, reflData.xy);

        reflection.rgb = min(reflection.rgb, 1.0); // stop NAN pixels
        half vd = dot2( (reflData.xy - 0.5) * 2.0 );
        half vignette = saturate( VIGNETTE_SIZE - vd * vd );

        half reflectionIntensity = clamp(reflData.a * REFLECTIONS_MULTIPLIER, REFLECTIONS_MIN_INTENSITY, REFLECTIONS_MAX_INTENSITY) * vignette;
        reflection.rgb *= reflectionIntensity;

        reflection.rgb = min(reflection.rgb, 1.2); // clamp max brightness

        // conserve energy
        half4 pixel = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, i.uv);
        reflection.rgb -= pixel.rgb * reflectionIntensity;

        // keep blur factor in alpha channel
        reflection.a = reflData.z;
        return reflection;
	}



#endif // SSR_SOLVE