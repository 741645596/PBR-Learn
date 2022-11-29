#ifndef SSR_GBUF_PASS
#define SSR_GBUF_PASS

	// Copyright 2021 Kronnect - All Rights Reserved.
    TEXTURE2D(_NoiseTex);
    float4 _NoiseTex_TexelSize;

    float4 _MaterialData;
    #define SMOOTHNESS _MaterialData.x
    #define FRESNEL _MaterialData.y
    #define FUZZYNESS _MaterialData.z
    #define DECAY _MaterialData.w

    float4 _SSRSettings;
    #define THICKNESS _SSRSettings.x
    #define SAMPLES _SSRSettings.y
    #define BINARY_SEARCH_ITERATIONS _SSRSettings.z
    #define MAX_RAY_LENGTH _SSRSettings.w

#if SSR_THICKNESS_FINE
    float _SSRSettings5;
    #define THICKNESS_FINE _SSRSettings5
#else
    #define THICKNESS_FINE THICKNESS
#endif

    float4 _SSRSettings2;
    #define JITTER _SSRSettings2.x
    #define CONTACT_HARDENING _SSRSettings2.y

    float4 _SSRSettings3;
    #define INPUT_SIZE _SSRSettings3.xy
    #define GOLDEN_RATIO_ACUM _SSRSettings3.z
    #define DEPTH_BIAS _SSRSettings3.w

    float4x4 _WorldToViewDir;

    TEXTURE2D_X(_GBuffer2);
    


	struct AttributesFS {
		float4 positionHCS : POSITION;
		float4 uv          : TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

 	struct VaryingsSSR {
    	float4 positionCS : SV_POSITION;
    	float4 uv  : TEXCOORD0;
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
        float4 projPos = output.positionCS * 0.5;
        projPos.xy = projPos.xy + projPos.w;
        output.uv.zw = projPos.xy;
    	return output;
	}
  
    inline float GetLinearDepth(float2 uv) {
        float rawDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, SSRStereoTransformScreenSpaceTex(uv), 0).r;
        return LinearEyeDepth(rawDepth, _ZBufferParams);
    }


	float4 SSR_Pass(float2 uv, float3 normalVS, float3 rayStart, float smoothness) {

        float3 viewDirVS = normalize(rayStart);
        float3 rayDir = reflect( viewDirVS, normalVS );

        // if ray is toward the camera, early exit (optional)
        //if (rayDir.z < 0) return 0.0.xxxx;

        float  rayLength = MAX_RAY_LENGTH;

        float3 rayEnd = rayStart + rayDir * rayLength;
        if (rayEnd.z < _ProjectionParams.y) {
            rayLength = (rayStart.z - _ProjectionParams.y) / rayDir.z;
        }
        rayEnd = rayStart + rayDir * rayLength;

        float4 sposStart = mul(unity_CameraProjection, float4(rayStart, 1.0));
        float4 sposEnd = mul(unity_CameraProjection, float4(rayEnd, 1.0));
        float k0 = rcp(sposStart.w);
        float q0 = rayStart.z * k0;
        float k1 = rcp(sposEnd.w);
        float q1 = rayEnd.z * k1;
        float4 p = float4(uv, q0, k0);

        // length in pixels
        float2 uv1 = (sposEnd.xy * rcp(rayEnd.z) + 1.0) * 0.5;
        float2 duv = uv1 - uv;
        float2 duvPixel = abs(duv * INPUT_SIZE);
        float pixelDistance = max(duvPixel.x, duvPixel.y);
        pixelDistance = max(1, pixelDistance);
        int sampleCount = (int)SAMPLES;
        float scale = max(1, SAMPLES * rcp(pixelDistance));
        sampleCount = (int)(sampleCount * rcp(scale));
        float4 pincr = float4(duv, q1-q0, k1-k0) * rcp(sampleCount);

        #if SSR_JITTER
            float jitter = SAMPLE_TEXTURE2D(_NoiseTex, sampler_PointRepeat, uv * INPUT_SIZE * _NoiseTex_TexelSize.xy + GOLDEN_RATIO_ACUM).r;
            pincr *= 1.0 + jitter * JITTER;
            p += pincr * (jitter * JITTER);
        #endif

        float collision = 0;
        float dist = 0;
        float zdist = 0;

        UNITY_LOOP
        for (int k = 0; k < sampleCount; k++) {
            p += pincr;
            if (any(floor(p.xy)!=0)) return 0.0.xxxx; // exit if out of screen space
            float sceneDepth = GetLinearDepth(p.xy);
            float pz = p.z / p.w;
            float depthDiff = pz - sceneDepth;
            if (depthDiff > 0 && depthDiff < THICKNESS) {
                float4 origPincr = pincr;
                p -= pincr;
                float reduction = 1.0;
                UNITY_LOOP
                for (int j = 0; j < BINARY_SEARCH_ITERATIONS; j++) {
                    reduction *= 0.5;
                    p += pincr * reduction;
                    sceneDepth = GetLinearDepth(p.xy);
                    pz = p.z / p.w;
                    depthDiff = sceneDepth - pz;
                    pincr = sign(depthDiff) * origPincr;
                }
#if SSR_THICKNESS_FINE
                if (abs(depthDiff) < THICKNESS_FINE)
#endif
                {
                    float hitAccuracy = 1.0 - abs(depthDiff) / THICKNESS_FINE;
                zdist = (pz - rayStart.z) / (rayEnd.z - rayStart.z);
                float rayFade = 1.0 - saturate(zdist);
                collision = hitAccuracy * rayFade;
                break;
                }
                pincr = origPincr;
                p += pincr;
            }
        }

        if (collision > 0) {

            // intersection found
            float reflectionIntensity = smoothness * pow(collision, DECAY);

            // compute fresnel
            float fresnel = 1.0 - FRESNEL * abs(dot(normalVS, viewDirVS));
            float reflectionAmount = reflectionIntensity * fresnel; 

            // compute blur amount
            float wdist = rayLength * zdist;
            float blurAmount = max(0, wdist - CONTACT_HARDENING) * FUZZYNESS * (1 - smoothness);
            
            // return hit pixel
            return float4(p.xy, blurAmount + 0.001, reflectionAmount);
        }

        return float4(0,0,0,0);
	}


	float4 FragSSR (VaryingsSSR input) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.uv.xy).r;
        #if UNITY_REVERSED_Z
            depth = 1.0 - depth;
        #endif
        if (depth >= 1.0) return float4(0,0,0,0);

        depth = 2.0 * depth - 1.0;
        float2 zw = SSRStereoTransformScreenSpaceTex(input.uv.zw);
        float3 positionVS = ComputeViewSpacePosition(zw, depth, unity_CameraInvProjection);

        float4 normals = SAMPLE_TEXTURE2D_X(_GBuffer2, sampler_PointClamp, SSRStereoTransformScreenSpaceTex(input.uv.xy));
        #if defined(_GBUFFER_NORMALS_OCT)
            half2 remappedOctNormalWS = Unpack888ToFloat2(normals.xyz); // values between [ 0,  1]
            half2 octNormalWS = remappedOctNormalWS.xy * 2.0h - 1.0h;    // values between [-1, +1]
            float3 normalWS = UnpackNormalOctQuadEncode(octNormalWS);
        #else
            float3 normalWS = normals.xyz;
        #endif
        float3 normalVS = mul((float3x3)_WorldToViewDir, normalWS);
        normalVS.z *= -1.0;

        float smoothness = normals.w;

   		float4 reflection = SSR_Pass(input.uv.xy, normalVS, positionVS, smoothness);

        return reflection;
	}


#endif // SSR_GBUF_PASS