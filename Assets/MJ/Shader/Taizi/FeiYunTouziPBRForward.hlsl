#ifndef SGAME_PBRFORWARD_INCLUDE
	#define SGAME_PBRFORWARD_INCLUDE

	#include "./FeiYunTouziPBRInput.hlsl"
	#include "Assets/Common/Standard/PBRFunction.hlsl"
	//带宽
	struct Attributes_PBR
	{
		float4 positionOS   : POSITION;
		float3 normalOS     : NORMAL;

		#if defined(_NORMAL_ON)
			float4 tangentOS    : TANGENT;
		#endif

		float2 uv     		: TEXCOORD0;
		float4 lightmapUV   : TEXCOORD1;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct Varyings_PBR
	{
		float4 positionCS   : SV_POSITION;
		float2 uv           : TEXCOORD0; 	

		#if defined(_NORMAL_ON)
			half4 normalWS      : TEXCOORD1;
			half4 tangentWS     : TEXCOORD2;
			half4 bitangentWS   : TEXCOORD3;
		#else
			half3 normalWS      : TEXCOORD1;
			half3 viewDirWS     : TEXCOORD2;
		#endif

		float3 positionWS   : TEXCOORD4;

		#ifdef _ADDITIONAL_LIGHTS_VERTEX
			half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
		#else
			half  fogFactor                 : TEXCOORD5;
		#endif

		// #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		float4 shadowCoord              : TEXCOORD6;
		// #endif
		
		DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct SurfaceData_PBR
	{
		half3 albedo;
		half3 specular;
		half  metallic;
		half  smoothness;
		half3 emission;
		half  occlusion;
		half  alpha;
		half  shadowStrenght;

		// #if defined(_CLEARCOAT_ON)
		half  clearCoatMask;
		half  clearCoatSmoothness;
		// #endif

		#if defined(_IRIDESCENCE_ON)
			// half2 iridescence;	//x : mask ; y : thickness
			half iridescence;
		#endif
	};

	struct InputData_PBR 
	{
		float3  positionWS;
		float4  positionCS;

		half3  normalWS;
		half3x3 TBN;  


		half3  viewDirWS;
		half3	bentNormalWS;

		half    fogCoord;
		half3   bakedGI;

		float4   shadowMask;

		#if defined(_CLEARCOAT_ON)
			half3 clearCoatNormalWS;
		#endif

		// #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
		half4  shadowCoord;
		// #endif

		#ifdef _ADDITIONAL_LIGHTS_VERTEX
			half3   vertexLighting;
		#endif
	};

	Varyings_PBR PBRVert(Attributes_PBR input)
	{
		Varyings_PBR output = (Varyings_PBR)0;

		// Instance
		UNITY_SETUP_INSTANCE_ID(input);
		UNITY_TRANSFER_INSTANCE_ID(input, output);

		// Vertex
		VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
		output.positionWS = vertexInput.positionWS;
		output.positionCS = vertexInput.positionCS;

		// UV

		float u = input.uv.x + 0.5 * _Col;
		float vm = input.uv.y - 0.333 * _Row;
		output.uv = float2(u,vm);

		//output.uv = input.uv;

		// Direction
		// VertexNormalInputs normalInput;
		// norma_CollInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
		// half sign = input.tangentOS.w * GetOddNegativeScale();
		// output.tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);

		//----------
		// View
		half3 viewDirWS = (GetCameraPositionWS() - vertexInput.positionWS);

		// Normal
		#if defined(_NORMAL_ON)
			VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
			half sign = input.tangentOS.w * GetOddNegativeScale();
			output.tangentWS = half4(normalInput.tangentWS.xyz, viewDirWS.x);
			output.bitangentWS = half4(sign * cross(normalInput.normalWS.xyz, normalInput.tangentWS.xyz), viewDirWS.y);
			output.normalWS = half4(normalInput.normalWS.xyz, viewDirWS.z);
		#else
			VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
			output.normalWS = normalInput.normalWS;
			output.viewDirWS = viewDirWS;
		#endif
		//---------

		// output.normalWS = normalInput.normalWS;
		// output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

		// Indirect light
		OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
		OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

		// VertexLight And Fog
		half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
		half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

		#ifdef _ADDITIONAL_LIGHTS_VERTEX
			vertexLight = VertexLighting(output.positionWS, output.normalWS);
			output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
		#else
			output.fogFactor = fogFactor;
		#endif

		// shadow
		#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
			#if !defined(ENABLE_HQ_SHADOW) && !defined(ENABLE_HQ_AND_UNITY_SHADOW)
				output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
			#endif
		#endif

		return output;
	}

	
	inline void InitSurfaceData(float2 uv,out SurfaceData_PBR outSurfaceData)
	{
		outSurfaceData = (SurfaceData_PBR)0;

		// base map
		half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_LinearRepeat, uv);

		//alpha
		outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;
		// outSurfaceData.shadowStrenght = outSurfaceData.alpha;
		outSurfaceData.shadowStrenght = 1;
		#if _ALPHATEST_ON
			clip(outSurfaceData.alpha- _Cutoff);
		#endif

		outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
		outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

		//specGloss
		half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_LinearRepeat, uv);
		outSurfaceData.metallic = specGloss.r * _Metallic;
		outSurfaceData.smoothness = specGloss.b * _Smoothness;

		//ao
		outSurfaceData.occlusion = LerpWhiteTo(specGloss.g, _OcclusionStrength);

		//emission
		#if defined(_EMISSION_ON)
			float4 emission_color = _EmissionColor;
			
			#if defined(_EMISSION_MAP)
				emission_color.rgb *= SAMPLE_TEXTURE2D(_EmissionMap, sampler_LinearRepeat, uv).rgb;
			#endif

			outSurfaceData.emission = emission_color.rgb;
		#endif

		//clearcloat
		#if defined(_CLEARCOAT_ON)
			half clearCoatMap = SAMPLE_TEXTURE2D(_ClearCoatMap,sampler_LinearRepeat,uv).r;
			outSurfaceData.clearCoatMask = _ClearCoatMask * clearCoatMap;
			outSurfaceData.clearCoatSmoothness = _ClearCoatSmoothness;
		#endif

		#if defined(_IRIDESCENCE_ON)
			// outSurfaceData.iridescence.x = _Iridescence;

			// #if defined(_IRIDESCENCE_MASK)
			// 	outSurfaceData.iridescence.x *= SAMPLE_TEXTURE2D(_IridescenceMask, sampler_LinearRepeat, uv).r;
			// #endif

			// outSurfaceData.iridescence.y = _IridescenceThickness;
			outSurfaceData.iridescence = SAMPLE_TEXTURE2D(_FilmStrengthMap, sampler_LinearRepeat, uv).r;
		#endif
	}

	void InitInputData(Varyings_PBR input,inout SurfaceData_PBR surfaceData, out InputData_PBR inputData)
	{
		inputData = (InputData_PBR)0;
		inputData.positionWS = input.positionWS;
		inputData.positionCS = input.positionCS;

		// Normal, View
		#if defined(_NORMAL_ON)
			inputData.viewDirWS = normalize(half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w));

			inputData.TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);

			half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_LinearRepeat, input.uv));

			#if defined(_CLEARCOAT_ON)	
				inputData.clearCoatNormalWS = normalize(mul(normalTS, inputData.TBN));
			#endif
			
			// Detail
			#if defined(_DETAILMAP_ON)
				DetailLayer_new(input.uv,surfaceData.albedo,normalTS,surfaceData.smoothness);
				// DetailLayer(input.uv,surfaceData.albedo,normalTS,surfaceData.smoothness);
			#endif

			inputData.normalWS = normalize(mul(normalTS,inputData.TBN));
			
			// Specular Occlusion
			#if defined(_SPECULAROCCLUSION_ON)
				half3 bent_normal_data = UnpackNormal(SAMPLE_TEXTURE2D(_BentNormalMap,sampler_LinearRepeat,input.uv));
				inputData.bentNormalWS = normalize(mul(bent_normal_data,inputData.TBN));
			#endif

		#else
			inputData.viewDirWS = normalize(input.viewDirWS);
			inputData.normalWS = normalize(input.normalWS);

			#if defined(_CLEARCOAT_ON)	
				inputData.clearCoatNormalWS = inputData.normalWS;
			#endif
		#endif	// _NORMAL_ON

		// Normal Filter
		#if defined(MODULATE_SMOOTHNESS)
			ModulateSmoothnessByNormal(surfaceData.smoothness, inputData.normalWS);
		#endif
		
		// Clear Coat
		#if defined(_CLEARCOAT_ON)	
			surfaceData.smoothness = lerp(surfaceData.smoothness,surfaceData.smoothness * _ClearCoatDownSmoothness,surfaceData.clearCoatMask);
			inputData.clearCoatNormalWS = lerp(inputData.clearCoatNormalWS,inputData.normalWS,_ClearCoat_Detail_Factor);
		#endif

		// Shadow
		#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
			#if defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW) 
				inputData.shadowCoord.x = HighQualityRealtimeShadow(input.positionWS);
			#else
				inputData.shadowCoord = input.shadowCoord;
			#endif
		#endif

		inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

		// Addisional Light Vertex
		#ifdef _ADDITIONAL_LIGHTS_VERTEX
			inputData.fogCoord = input.fogFactorAndVertexLight.x;
			inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
		#else
			inputData.fogCoord = input.fogFactor;
		#endif

		// Indirect Light
		inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

	}



#endif	//SGAME_PBRFORWARD_INCLUDE
