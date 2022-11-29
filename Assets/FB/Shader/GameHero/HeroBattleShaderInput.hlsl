#ifndef HEROBATTLE_SHADERINPUT
	#define HEROBATTLE_SHADERINPUT


	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

	//PBR
	TEXTURE2D_X(_PBRBaseMap);
	SAMPLER(sampler_PBRBaseMap);
	TEXTURE2D_X(_MetallicGlossMap);
	SAMPLER(sampler_MetallicGlossMap);
	TEXTURE2D_X(_BumpMap);
	SAMPLER(sampler_BumpMap);
	TEXTURE2D_X(_EmissionMap);
	SAMPLER(sampler_EmissionMap);

	//
	TEXTURE2D_X(_BaseMap);
	SAMPLER(sampler_BaseMap);

	#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
		TEXTURE2D_X(_MaskMap);
		SAMPLER(sampler_MaskMap);
		TEXTURE2D_X(_LightTex);
		SAMPLER(sampler_LightTex);

		#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON)
			TEXTURE2D_X(_BaseMapMatCap);
			SAMPLER(sampler_BaseMapMatCap);
		#endif

		#if defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			TEXTURE2D_X(_BaseMapMatCapPBR);
			SAMPLER(sampler_BaseMapMatCapPBR);
			TEXTURE2D_X(_LightTexG);
			SAMPLER(sampler_LightTexG);
			TEXTURE2D_X(_LightTexB);
			SAMPLER(sampler_LightTexB);
			TEXTURE2D_X(_LightTexA);
			SAMPLER(sampler_LightTexA);
		#endif

		#if defined(_LIGHT_TEXNORMAL_ON) || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			TEXTURE2D_X(_MatCapNormal);
			SAMPLER(sampler_MatCapNormal);
		#endif

	#endif

	#if defined(_EFFECT_TEX_ON)
		TEXTURE2D_X(_EffectTex);
		SAMPLER(sampler_EffectTex);
	#endif

	#if defined(_DISSOLVE_ON) 
		TEXTURE2D_X(_DissolveTex);
		SAMPLER(sampler_DissolveTex);
		TEXTURE2D_X(_RinAlphaTex);
		SAMPLER(sampler_RinAlphaTex);
	#endif

	#if defined(_HURT_SHAKEEFFECT_ON) 
		TEXTURE2D_X(_ShakeNoiseMap);
		SAMPLER(sampler_ShakeNoiseMap);
	#endif

	UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	//PBR
	UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
	UNITY_DEFINE_INSTANCED_PROP(half, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(half, _NormalScale)
	UNITY_DEFINE_INSTANCED_PROP(float4, _PBRBaseMapOffset)
	UNITY_DEFINE_INSTANCED_PROP(half4, _PBRBaseColor)
	UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
	//阴影 
	UNITY_DEFINE_INSTANCED_PROP(half4, _ShadowColor)//阴影颜色
	UNITY_DEFINE_INSTANCED_PROP(half, _ShadowHeight)//阴影平面的高度
	UNITY_DEFINE_INSTANCED_PROP(half, _ShadowOffsetX)//XZ平面的偏移
	UNITY_DEFINE_INSTANCED_PROP(half, _ShadowOffsetZ)
	UNITY_DEFINE_INSTANCED_PROP(half, _MeshHight)//模型高度
	UNITY_DEFINE_INSTANCED_PROP(half4, _WorldPos)//模型位置
	//
	UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _AlphaVal)
	UNITY_DEFINE_INSTANCED_PROP(half3, _ProGameOutDir)

	//#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
	UNITY_DEFINE_INSTANCED_PROP(half, _LightScale)
	UNITY_DEFINE_INSTANCED_PROP(half4, _MainColor)
	//_LightWeight
	UNITY_DEFINE_INSTANCED_PROP(half, _LightWeight)
	//#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
	UNITY_DEFINE_INSTANCED_PROP(half, _MatCapNormalScale)
	//#endif
	//#endif

	//#if defined(_HURT_EFFECT_ON)
	UNITY_DEFINE_INSTANCED_PROP(half3, _HurtColor)
	//#endif

	//#if defined(_HURT_SHAKEEFFECT_ON)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeStrength)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeFrequency)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeVertexTwist)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeHorizontalStrength)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeHorizontalWeight)
	UNITY_DEFINE_INSTANCED_PROP(half, _ShakeVerticalStrength)
	//#endif

	//#if defined(_EFFECT_TEX_ON)
	UNITY_DEFINE_INSTANCED_PROP(half, _EffectFactor)
	UNITY_DEFINE_INSTANCED_PROP(half4, _EffectTexColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EffectTex_ST)
	//#endif

	//#if defined(_TRANSLUCENT) 
	UNITY_DEFINE_INSTANCED_PROP(half, _AlphaSet)
	//#endif

	//#if defined(_RIM_COLOR_ON)
	UNITY_DEFINE_INSTANCED_PROP(half4, _RimColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _RimColorSide)
	//#endif

	//#if defined(_DISSOLVE_ON) 
	UNITY_DEFINE_INSTANCED_PROP(half4, _ScrollSpeed)
	UNITY_DEFINE_INSTANCED_PROP(half, _Dissolve)
	UNITY_DEFINE_INSTANCED_PROP(half, _DissolveLV)
	UNITY_DEFINE_INSTANCED_PROP(half, _DissolveAlpha)
	UNITY_DEFINE_INSTANCED_PROP(float4, _DissolveTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveColor1)
	UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveColor2)
	//#endif

	//#if defined(_LIGHT_ON) 
	UNITY_DEFINE_INSTANCED_PROP(half, _MainLightStrength)
	UNITY_DEFINE_INSTANCED_PROP(half, _AddLightStrength)
	//#endif

	UNITY_DEFINE_INSTANCED_PROP(half4, _OutlineColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _Outline)

	UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

	#define GET_PROP(propName) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, propName)
	
	struct VertexInput {
		UNITY_VERTEX_INPUT_INSTANCE_ID
		float4 vertex : POSITION;
		half2 texcoord : TEXCOORD0;

		#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_DISSOLVE_ON) || defined(_LIGHT_ON) || defined(_RIM_COLOR_ON) || defined(_HURT_EFFECT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			float3 normal: NORMAL;
			#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
				float4 tangent:TANGENT;
			#endif
		#endif
	};

	struct v2f
	{
		float4 pos : SV_POSITION;

		#if defined(_DISSOLVE_ON) 
			half4 uv : TEXCOORD0;
		#else
			half2 uv : TEXCOORD0;
		#endif

		#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON)  || defined(_DISSOLVE_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			half2 uv2 : TEXCOORD1;
		#endif

		#if defined(_RIM_COLOR_ON) 
			half4 color : COLOR;
		#endif

		#if defined(_HURT_EFFECT_ON) 
			half hurtColor: TEXCOORD2;
		#endif

		#if defined(_EFFECT_TEX_ON) 
			half2 uv3 : TEXCOORD3;
		#endif
		
		#if defined(_HURT_SHAKEEFFECT_ON) || defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			//   #if defined(_LIGHT_ON)
			//	float3 posWS : TEXCOORD4;
			//#endif
			float3 posWS : TEXCOORD4;
			float3 normalWS : TEXCOORD5;
			#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
				float4	tangentWS : TEXCOORD6;
				float3  posVS : TEXCOORD7;
			#endif
		#endif
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	float2 UVTilingOffset(float2 uv, float4 st) {
		return (uv * st.xy + st.zw);
	}

	float3 ObjSpaceViewDir(in float4 v)
	{
		float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
		return objSpaceCameraPos - v.xyz;
	}

	float3 Shake(float3 wsPos){
		#if defined(_HURT_SHAKEEFFECT_ON) 
			float t=_Time.z*GET_PROP(_ShakeFrequency);
			float offsetU=sin(t);
			float offsetV=sin(t+offsetU);
			offsetU = offsetU.x*0.5+0.5;
			offsetV = offsetV.x*0.5+0.5;
			float3 fX = SAMPLE_TEXTURE2D_X_LOD(_ShakeNoiseMap,sampler_ShakeNoiseMap, float2(offsetU,-offsetV),0).rgb;
			fX.xy=(fX.xy-0.5)*2;
			float vertexU=frac(abs(wsPos.y*offsetV));
			float vertexOffset =SAMPLE_TEXTURE2D_X_LOD(_ShakeNoiseMap,sampler_ShakeNoiseMap, float2(vertexU,vertexU),0).r;
			vertexOffset=clamp(vertexOffset,0,1);
			vertexOffset =lerp(1,vertexOffset,GET_PROP(_ShakeVertexTwist));  
			float z =(0.5-GET_PROP(_ShakeHorizontalWeight))/0.5;
			fX.xy = float2(fX.x*(1-z) ,fX.y *(1+z));
			wsPos.xzy=wsPos.xzy+ float3(fX.xy*GET_PROP(_ShakeHorizontalStrength),fX.z*GET_PROP(_ShakeVerticalStrength))*vertexOffset*GET_PROP(_ShakeStrength);
			return wsPos;
		#else
			return wsPos;
		#endif
	}

	v2f vert(VertexInput v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, o);

		o.uv.xy = v.texcoord.xy;

		#if defined(_DISSOLVE_ON) 
			o.uv.zw = v.texcoord.xy + frac(GET_PROP(_ScrollSpeed).xy * _Time.x);
			o.uv.zw = UVTilingOffset(o.uv.zw,_DissolveTex_ST);
		#endif

		#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEX_HIFHT_ON) || defined(_DISSOLVE_ON) && !defined(_LIGHT_TEXNORMAL_ON) && !defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			//o.uv2.x = dot(UNITY_MATRIX_IT_MV[0].xyz, v.normal) * 0.5 + 0.5;
			//o.uv2.y = dot(UNITY_MATRIX_IT_MV[1].xyz, v.normal) * 0.5 + 0.5;


			float3 posWs=TransformObjectToWorld(v.vertex.xyz);
			float3 posVS = TransformWorldToView(posWs);

			half3 normalVS = normalize(mul((half3x3)UNITY_MATRIX_MV, v.normal));
			half3 r = normalize(reflect(posVS, normalVS));
			half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
			o.uv2.xy = r.xy / m + 0.5;
			o.uv2.xy -= half2(0.5,0.5);
			o.uv2.xy += half2(0.5, 0.5);

		#endif

		#if defined(_HURT_SHAKEEFFECT_ON) || defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			float3 wsPos=TransformObjectToWorld(v.vertex.xyz);
			#if defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
				o.normalWS =normalize(TransformObjectToWorldNormal(v.normal));
				#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
					real sign = v.tangent.w * GetOddNegativeScale();
					o.tangentWS = half4(TransformObjectToWorldDir(v.tangent.xyz), sign);
					o.posVS = TransformWorldToView(wsPos);
				#endif
			#endif
		#endif

		#if defined(_RIM_COLOR_ON) || defined(_HURT_EFFECT_ON)
			half3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			half dotProduct = 1-abs(dot(normalize(v.normal), viewDir));
			#if defined(_RIM_COLOR_ON)
				half4 rimColor = GET_PROP(_RimColor);
				o.color.rgb = (rimColor.rgb * pow(dotProduct, rimColor.w)).rgb;
				o.color.a=dotProduct;
			#endif
			#if defined(_HURT_EFFECT_ON)
				o.hurtColor=dotProduct*dotProduct*2;
			#endif
		#endif

		#if defined(_HURT_SHAKEEFFECT_ON)
			wsPos=Shake(wsPos);
		#endif

		#if defined(_EFFECT_TEX_ON) 
			o.uv3 = UVTilingOffset(v.texcoord.xy, GET_PROP(_EffectTex_ST));
		#endif
		#if defined(_HURT_SHAKEEFFECT_ON) || defined(_LIGHT_ON) || defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			o.pos = TransformWorldToHClip(wsPos);
			//#if defined(_LIGHT_ON)
			//	o.posWS = wsPos;
			//#endif
			o.posWS = wsPos;
		#else
			o.pos = TransformObjectToHClip(v.vertex.xyz);
		#endif

		return o;
	}

	half4 EffectFrag(half4 color,v2f i){
		UNITY_SETUP_INSTANCE_ID(i);

		color.rgb *= GET_PROP(_MainColor).rgb;

		//法线
		#if defined(_LIGHT_TEXNORMAL_ON)|| defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_MatCapNormal, sampler_MatCapNormal, i.uv.xy), GET_PROP(_MatCapNormalScale));
			float sgn = i.tangentWS.w;      // should be either +1 or -1
			float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
			float3 normalWS = TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
			normalWS = normalize(normalWS);
			i.normalWS=normalWS;
			//计算MatCapUV
			float3 normalVS = TransformWorldToViewDir(normalWS);
			half3 r = normalize(reflect(i.posVS, normalVS));
			half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
			i.uv2 = r.xy / m + 0.5;

			float3 viewWS = normalize(_WorldSpaceCameraPos.xyz-i.posWS);
			float vDotN=dot(normalWS,viewWS);
			vDotN=vDotN*0.5+0.5;
			color=color*vDotN;

		#endif

		//灯光处理
		#if defined(_LIGHT_ON)
			Light mainLight = GetMainLight();
			float nDotL=saturate(dot(i.normalWS,mainLight.direction)*0.5+0.5);
			nDotL=nDotL*nDotL;
			color.rgb = color.rgb+nDotL*mainLight.color*_MainLightStrength;
			uint pixelLightCount = GetAdditionalLightsCount();
			for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
			{
				Light light = GetAdditionalLight(lightIndex,i.posWS);
				nDotL=saturate(dot(i.normalWS,light.direction));
				color.rgb = color.rgb+nDotL*light.color*_AddLightStrength;
			}
		#endif

		#if defined(_LIGHT_TEX_ON) || defined(_LIGHT_TEXNORMAL_ON)
			half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy).r;
			half3 matCap = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv2);
			//color.rgb =lerp(color.rgb,color.rgb*GET_PROP(_MainColor).rgb,mask); //_LightWeight
			matCap = matCap.rgb * GET_PROP(_LightScale) * mask;
			color.rgb += matCap;
			color.rgb = lerp(color.rgb,matCap,_LightWeight);
		#endif

		#if defined(_LIGHT_TEX_HIFHT_ON)  || defined(_LIGHT_TEXNORMAL_HIFHT_ON)
			half4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy);
			half3 matCapR = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, i.uv2).rgb;
			half3 matCapG = SAMPLE_TEXTURE2D(_LightTexG, sampler_LightTexG, i.uv2).rgb;
			half3 matCapB = SAMPLE_TEXTURE2D(_LightTexB, sampler_LightTexB, i.uv2).rgb;
			half3 matCapA = SAMPLE_TEXTURE2D(_LightTexA, sampler_LightTexA, i.uv2).rgb;
			half3 matCap = matCapR*mask.r + matCapG*mask.g + matCapB*mask.b + matCapA*mask.a;
			matCap = matCap.rgb * GET_PROP(_LightScale);
			//color.rgb =lerp(color.rgb,color.rgb*GET_PROP(_MainColor).rgb,mask.r+mask.g+mask.b+mask.a);
			color.rgb +=matCap;
			color.rgb = lerp(color.rgb,matCap,_LightWeight);
		#endif

		#if defined(_TRANSLUCENT) 
			color.a = GET_PROP(_AlphaVal)*GET_PROP(_AlphaSet)*color.a;
		#else
			color.a = 1;
		#endif

		#if defined(_EFFECT_TEX_ON)
			half3 hc = SAMPLE_TEXTURE2D(_EffectTex, sampler_EffectTex, i.uv3);
			color.rgb = lerp(color.rgb, hc * GET_PROP(_EffectTexColor).rgb, GET_PROP(_EffectFactor));
		#elif defined(_RIM_COLOR_ON) 
			half rimColorSide = GET_PROP(_RimColorSide);
			float s = smoothstep(rimColorSide,rimColorSide+0.001,i.color.a);
			color.rgb += i.color.rgb*s;
		#elif defined(_OUTLINE_ON) 

		#elif defined(_DISSOLVE_ON) 
			half4 texDissolve = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.uv.zw);
			half  texDissloveA =texDissolve.a ;
			half rimDissolve = SAMPLE_TEXTURE2D(_RinAlphaTex, sampler_RinAlphaTex, i.uv2);
			half  dissolveMask = GET_PROP(_Dissolve) + texDissloveA;  
			dissolveMask = saturate ((dissolveMask-1)*4);  //控制透明通道的范围
			half  dissolveMask2 = saturate (1 - dissolveMask )*2 ; //控制2张贴图的混合
			float4 dissolveglow = GET_PROP(_DissolveLV)*texDissolve;
			float lerpV=dissolveMask * dissolveMask2;
			half4 lerpC=lerp(GET_PROP(_DissolveColor1),GET_PROP(_DissolveColor2),lerpV);
			dissolveglow = lerpV*lerpC*dissolveglow+ rimDissolve * dissolveMask2*lerpC;
			color = lerp (color+dissolveglow, color, dissolveMask) ;
			color.a = clamp((dissolveMask + rimDissolve*GET_PROP(_DissolveAlpha)), 0, 1)*color.a ;
			clip(color.a - 0.1);
		#endif

		#if defined(_HURT_EFFECT_ON) 
			color.rgb += GET_PROP(_HurtColor)*clamp(i.hurtColor,0,1);
		#endif

		return color;
	}

#endif

