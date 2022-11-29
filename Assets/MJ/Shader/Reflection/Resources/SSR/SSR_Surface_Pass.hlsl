#ifndef SSR_SURF_FX
#define SSR_SURF_FX

	// Copyright 2021 Kronnect - All Rights Reserved.
    TEXTURE2D(_NoiseTex);
    TEXTURE2D(_BumpMap);
    TEXTURE2D(_SmoothnessMap);
    float4 _BumpMap_ST;
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

    struct AttributesSurf {
        float4 positionOS   : POSITION;
        float2 texcoord     : TEXCOORD0;
        float3 normalOS     : NORMAL;
        float4 tangentOS    : TANGENT;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

 	struct VaryingsSSRSurf {
    	float4 positionCS : SV_POSITION;
    	float2 uv : TEXCOORD0;
        float4 scrPos : TEXCOORD1;
        float3 positionVS : TEXCOORD2;
        #if SSR_NORMALMAP
            float4 normal    : TEXCOORD3;    // xyz: normal, w: viewDir.x
            float4 tangent   : TEXCOORD4;    // xyz: tangent, w: viewDir.y
            float4 bitangent : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
        #else
            float3 normal    : TEXCOORD3;
        #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
	};

	VaryingsSSRSurf VertSSRSurf(AttributesSurf input) {

	    VaryingsSSRSurf output = (VaryingsSSRSurf)0;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        VertexPositionInputs positions = GetVertexPositionInputs(input.positionOS.xyz);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

        output.positionCS = positions.positionCS;
        output.positionVS = positions.positionVS * float3(1,1,-1);
        output.scrPos     = ComputeScreenPos(positions.positionCS);
        output.uv         = TRANSFORM_TEX(input.texcoord, _BumpMap);

        #if SSR_NORMALMAP
            half3 viewDirWS = GetCameraPositionWS() - positions.positionWS;
            output.normal = half4(normalInput.normalWS, viewDirWS.x);
            output.tangent = half4(normalInput.tangentWS, viewDirWS.y);
            output.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
        #else
            output.normal = TransformWorldToViewDir(normalInput.normalWS) * float3(1,1,-1);
        #endif

        #if UNITY_REVERSED_Z
            output.positionCS.z += 0.001;
        #else
            output.positionCS.z -= 0.001;
        #endif

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

        // depth clip check
        float sceneDepth = GetLinearDepth(p.xy);
        float pz = p.z / p.w;
        if (sceneDepth < pz - DEPTH_BIAS) return 0;

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
            //pincr *= 1.0 + jitter * JITTER;
            p += pincr * (jitter * JITTER);
        #endif

        float collision = 0;
        float dist = 0;
        float zdist = 0;

        UNITY_LOOP
        for (int k = 0; k < sampleCount; k++) {
            p += pincr;
            if (any(floor(p.xy)!=0)) return 0.0.xxxx; // exit if out of screen space
            sceneDepth = GetLinearDepth(p.xy);
            pz = p.z / p.w;
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
                {
#endif
                    float hitAccuracy = 1.0 - abs(depthDiff) / THICKNESS_FINE;
                zdist = (pz - rayStart.z) / (rayEnd.z - rayStart.z);
                float rayFade = 1.0 - saturate(zdist);
                collision = hitAccuracy * rayFade;
                break;
#if SSR_THICKNESS_FINE
                }
                pincr = origPincr;
                p += pincr;
#endif
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


	float4 FragSSRSurf (VaryingsSSRSurf input) : SV_Target {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        input.scrPos.xy /= input.scrPos.w;
        //input.scrPos = SSRStereoTransformScreenSpaceTex(input.scrPos);
        #if SSR_NORMALMAP
            float4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_PointRepeat, input.uv);
            float3 normalTS = UnpackNormal(packedNormal);
            half3 viewDirWS = half3(input.normal.w, input.tangent.w, input.bitangent.w);
            float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangent.xyz, input.bitangent.xyz, input.normal.xyz));
            float3 normalVS = TransformWorldToViewDir(normalWS);
            normalVS.z *= -1;
        #else
            float3 normalVS = input.normal;
        #endif

        #if SSR_SMOOTHNESSMAP
            float smoothness = SMOOTHNESS * SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_PointRepeat, input.uv).a;
        #else
            float smoothness = SMOOTHNESS;
        #endif

   	    float4 reflection = SSR_Pass(input.scrPos.xy, normalVS, input.positionVS, smoothness);

        return reflection;
	}


#endif // SSR_SURF_FX