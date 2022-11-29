#ifndef COMMON_INPUT_INCLUDE
    #define COMMON_INPUT_INCLUDE

    // Unity Include
    // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

    // SGame Include
    #include "Assets/Common/ShaderLibrary/Math/Math.hlsl"
    #include "Color.hlsl"

    struct Attributes_SGame
	{
		float4 positionOS   : POSITION;
		float3 normalOS     : NORMAL;

		float4 tangentOS    : TANGENT;

		float2 uv     		: TEXCOORD0;
		#if defined(LIGHTMAP_ON)
			float2 lightmapUV   : TEXCOORD1;
		#endif
	};

    struct Varyings_SGame
	{
		float4 positionCS   : SV_POSITION;

		#if defined(LIGHTMAP_ON)
			float4 uv           : TEXCOORD0; 
		#else
			float2 uv           : TEXCOORD0; 
		#endif

		half4 normalWS      : TEXCOORD1;
		half4 tangentWS     : TEXCOORD2;
		half4 bitangentWS   : TEXCOORD3;

		float3 positionWS   : TEXCOORD4;

		half3 vertexSH      : TEXCOORD5;

		#if defined(_ADDITIONAL_LIGHTS_VERTEX)
			half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
		#else
			half  fogFactor                 : TEXCOORD6;
		#endif

		// #if defined(_MAIN_LIGHT_SHADOWS)
		float4 shadowCoord  : TEXCOORD7;
		// #endif
	};

    Varyings_SGame Vert_SGame(Attributes_SGame input)
    {
        Varyings_SGame output = (Varyings_SGame)0;

        // Vertex
        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        output.positionWS = vertexInput.positionWS;
        output.positionCS = vertexInput.positionCS;

        // UV
        #if defined(LIGHTMAP_ON)
            output.uv.xy = input.uv;
            output.uv.zw = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
        #else
            output.uv = input.uv;
        #endif

        // View
        half3 viewDirWS = (GetCameraPositionWS() - vertexInput.positionWS);

        // Normal
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        half sign = input.tangentOS.w * GetOddNegativeScale();
        output.tangentWS = half4(normalInput.tangentWS.xyz, viewDirWS.x);
        output.bitangentWS = half4(sign * cross(normalInput.normalWS.xyz, normalInput.tangentWS.xyz), viewDirWS.y);
        output.normalWS = half4(normalInput.normalWS.xyz, viewDirWS.z);
        
        // Indirect light
        output.vertexSH = SampleSHVertex(output.normalWS.xyz);
        // output.vertexSH = SGameSH9(output.normalWS.xyz);

        // VertexLight And Fog
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
        #if defined(_ADDITIONAL_LIGHTS_VERTEX)
            half3 vertexLight = VertexLighting(output.positionWS, output.normalWS.xyz);
            output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        #else
            output.fogFactor = fogFactor;
        #endif

        // Shadow
        output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);

        return output;
    }

    SamplerState sampler_LinearClamp;
    SamplerState sampler_LinearRepeat;

    half Alpha(half albedoAlpha, half4 color, half cutoff)
    {
        #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
            half alpha = albedoAlpha * color.a;
        #else
            half alpha = color.a;
        #endif

        #if defined(_ALPHATEST_ON)
            clip(alpha - cutoff);
        #endif
        return alpha;
    }

    half4 SampleAlbedoAlpha(half2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
    {
        #ifdef _AMD_FSR
            return SAMPLE_TEXTURE2D_BIAS(albedoAlphaMap, sampler_albedoAlphaMap, uv, amd_fsr_mipmap_bias);
        #else
            return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
        #endif
    }

    half3 SampleNormal(half2 uv, half scale, TEXTURE2D_PARAM(normalMap, sampler_NormalMap))
    {
        #ifdef ENABLE_NORMALMAP
            half4 n = SAMPLE_TEXTURE2D(normalMap, sampler_LinearClamp, uv);
            return UnpackNormalScale(n, scale);
        #else
            return half3(0.0h, 0.0h, 1.0h);
        #endif
    }


#endif // COMMON_INPUT_INCLUDE