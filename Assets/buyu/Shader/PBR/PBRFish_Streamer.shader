
Shader "WB/PBRFish_Streamer"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend("Source Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DestBlend("Dest Blend Mode", Float) = 10
		[Enum(Off, 0, On, 1)]_ZWriteMode("ZWriteMode", float) = 0

		[Foldout] _BaseName("Base控制面板",Range(0,1)) = 0
		[FoldoutItem] _BaseColor("BaseColor[ RGR : 主色]  [A : 透明]", Color) = (1, 1, 1, 1)
		[FoldoutItem] _ColorScale("_ColorScale", float) = 1
		[FoldoutItem] _ContrastScale("_ContrastScale", Float) = 1
		[FoldoutItem] _OverColor("OverlayColor", Color) = (1,1,1,1)
		[FoldoutItem] _OverMultiple("OverlayMultiple", Range(0,1)) = 1


		[Foldout] _PBRName("PBR控制面板",Range(0,1)) = 0
		[FoldoutItem] [NoScaleOffset]  _BaseMap("BaseMap( [ RGR : 主色]  [A : 透明] )", 2D) = "white" {}
		

		[FoldoutItem] [Normal][NoScaleOffset] _NormalMap("NormalMap", 2D) = "bump" {}
		[FoldoutItem] [NoScaleOffset] _MixMap("MixMap( [ R : 金属]  [G : AO]  [B : 用于mask标示眼球]  [A : 光滑] )", 2D) = "white" {}

		[FoldoutItem]  _MetallicRemapMin("MetallicRemapMin[金属度区间]", Range(0, 1)) = 0
		[FoldoutItem]  _MetallicRemapMax("MetallicRemapMax[金属度区间]", Range(0, 1)) = 1

		[FoldoutItem] _SmoothnessRemapMin("SmoothnessRemapMin[光滑度区间]", Range(0, 1)) = 0
		[FoldoutItem] _SmoothnessRemapMax("SmoothnessRemapMax[光滑度区间]", Range(0, 1)) = 1
		[FoldoutItem] _GlossMapScale("_GlossMapScale", float) = 0.75
		
		[FoldoutItem] _BumpStrength("_BumpStrength[法线强度]", Range(0, 10)) = 1
		[FoldoutItem] _OcclusionStrength("_OcclusionStrength[AO强度]", Range(0, 10)) = 1

		[Foldout] _RimColorName("边缘光控制面板",Range(0,1)) = 0
		[FoldoutItem] [HDR]_RimColor("RimColor[边缘光]", Color) = (0, 0, 0, 0)
		[FoldoutItem] _RimOffset("RimOffset", Vector) = (0, 0, 0, 0)
		[FoldoutItem] _RimSpread("RimSpread[边缘扩展参数]", Float) = 1
		[FoldoutItem] _RimPower("RimPower", Float) = 1

		[Foldout] _HSVName("明亮度控制面板",Range(0,1)) = 0
		[FoldoutItem] _HSVHue("色调", Float) = 1
		[FoldoutItem] _HSVSat("饱和度", Float) = 0.8
		[FoldoutItem] _HSVValue("亮度", Float) = 1

		[Foldout] _SpecularName("高光控制面板",Range(0,1)) = 0
		[FoldoutItem]  _SpecularStrength("高光强度", Range(0.95, 1)) = 1.0

        [Foldout] _NonMetalName("非金属度控制面板",Range(0,1)) = 0
		[FoldoutItem] _NonMetalThreshold("非金属阈值", Range(0, 0.2)) = 0.1
		[FoldoutItem] _NonMetalStrength("非金属强度", Range(0, 10)) = 1.0


        [Foldout] _HurtName("受击面板",Range(0,1)) = 0
		[FoldoutItem][KeywordEnum(Rim,Albedo,None)] _HitColorChannel("HitColorType", Float) = 1.0
		[FoldoutItem] _HitColor("HitColor[美术控制]", Color) = (1,1,1,1)
		[FoldoutItem] _HitMultiple("HitMultiple[美术控制]", Range(0,1)) = 1
		[FoldoutItem] _HitRimPower("HitRim Power[美术控制]", Range(0.01, 10)) = 0.01
		[FoldoutItem] _HitRimSpread("Hit Rim Spread[美术控制]", Range(-15, 4.99)) = 0.01
		[FoldoutItem] _OverlayColor("_OverlayColor[程序控制]", Color) = (1,1,1,1)
		[FoldoutItem] _OverlayMultiple("_OverlayMultiple[程序控制]", Range(0,1)) = 1

        [Foldout] _FadeName("淡入淡出控制面板[程序控制]",Range(0,1)) = 0
		[FoldoutItem] _Alpha("_Alpha", float) = 1


		[Foldout] _EmissionName("自发光控制面板",Range(0,1)) = 0
		[FoldoutItem][Toggle] _Emission("自发光控制开关开关", Float) = 0.0
		[FoldoutItem][HDR]_EmissionColor("Emission Color[自发光]", Color) = (0, 0, 0, 0)
		[FoldoutItem][NoScaleOffset] _EmissionMap("EmissionMap[自发光]", 2D) = "black" {}

		[Foldout] _StreamerName("流光控制面板",Range(0,1)) = 0
		[FoldoutItem][Toggle] _Streamer("流光控制开关开关", Float) = 0.0
		[FoldoutItem] _StreamerNoise("StreamerNoise", 2D) = "black" {}
		[FoldoutItem] _StreamerMask("StreamerMask[流光mask]", 2D) = "black" {}
		[FoldoutItem] _StreamerTex("StreamerTex[流光纹理]", 2D) = "black" {}
		[FoldoutItem] _StreamerAlpha("StreamerAlpha[流光Alpha]", Range(0, 1)) = 1
		[FoldoutItem] _StreamerNoiseSpeed("StreamerNoiseSpeed[流光速度]", Range(0, 10)) = 1
		[FoldoutItem] _StreamerScrollX("StreamerScrollX[流光方向]", Range(-10, 10)) = 1
		[FoldoutItem] _StreamerScrollY("StreamerScrollY[流光方向]", Range(-10, 10)) = 1
		[FoldoutItem][HDR]_StreamerColor("StreamerColor", Color) = (0, 0, 0, 0)

	    [Foldout] _LightDirName("灯光方向面板",Range(0,1)) = 0
		[FoldoutItem][Toggle] _LightDirControl("灯光方向控制开关", Float) = 0.0
		[FoldoutItem] _LightDir("LightDir", Vector) = (0, 0, 0, 0)
	}

	SubShader
	{
		Tags {  "RenderPipeline" = "UniversalPipeline"  "Queue" = "Transparent -300" }
		Cull[_CullMode]
		LOD 300

		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend[_SourceBlend][_DestBlend]
			ZWrite[_ZWriteMode]

		    ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			
			//模板测试总是通过，并写入模板缓存区值为1
			Stencil
			{
				Ref 9
				Comp always
				Pass replace
				Fail keep
				ZFail keep
			}

			HLSLPROGRAM
			#pragma multi_compile __ _EMISSION_ON
		    //#pragma multi_compile  _HITCOLORCHANNEL_RIM _HITCOLORCHANNEL_ALBEDO _HITCOLORCHANNEL_NONE
			#define _HITCOLORCHANNEL_RIM 1

			#pragma vertex vert
			#pragma fragment frag

			#include "ColorCore.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "HighLightingCore.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			struct VertexInput
			{
				half4 vertex : POSITION;
				half3 ase_normal : NORMAL;
				half4 ase_tangent : TANGENT;
				half4 texcoord : TEXCOORD0;
				
			};

			struct VertexOutput
			{
				half4 clipPos : SV_POSITION;
				half4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 tSpace0 : TEXCOORD1;
				half4 tSpace1 : TEXCOORD2;
				half4 tSpace2 : TEXCOORD3;
				half2 uv : TEXCOORD4;
				half4 streamerUv : TEXCOORD5;
			};

			CBUFFER_START(UnityPerMaterial)
#include "HitRed_dec.hlsl"

			half4 _BaseColor;
			half _ColorScale;
			half _ContrastScale;
			half3 _OverColor;
			half  _OverMultiple;

			half4 _BaseMap_ST;
			half4 _NormalMap_ST;
			half4 _MixMap_ST;

			half4 _RimColor;
			half _RimSpread;
			half4 _RimOffset;
			half _RimPower;

			half _MetallicRemapMin, _MetallicRemapMax;
			half _SmoothnessRemapMin, _SmoothnessRemapMax;
			half _GlossMapScale;
			half _OcclusionStrength;
			half _BumpStrength;
//#if			_EMISSION_ON
			half4 _EmissionColor;
//#endif

			half _HSVHue;
			half _HSVSat;
			half _HSVValue;
			half _SpecularStrength;

			half _NonMetalThreshold;
			half _NonMetalStrength;
			half _StreamerAlpha;
			half _StreamerNoiseSpeed;
			half _StreamerScrollX;
			half _StreamerScrollY;
			half4 _StreamerColor;
			half4 _StreamerTex_ST;
			half _Alpha;
			half _LightDirControl;
			half3 _LightDir;
			CBUFFER_END
			sampler2D _BaseMap;
			sampler2D _NormalMap;
			sampler2D _MixMap;
#if			_EMISSION_ON
			//float4 _EmissionColor;
			sampler2D _EmissionMap;
#endif

			sampler2D _StreamerNoise;
			sampler2D _StreamerTex;
			sampler2D _StreamerMask;
			

			VertexOutput vert ( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				o.uv.xy = v.texcoord.xy;
				half3 positionWS = TransformObjectToWorld(v.vertex.xyz);
				half3 positionVS = TransformWorldToView(positionWS);
				half4 positionCS = TransformWorldToHClip(positionWS);

				VertexNormalInputs normalInput = GetVertexNormalInputs(v.ase_normal, v.ase_tangent);

				o.tSpace0 = half4(normalInput.normalWS, positionWS.x);
				o.tSpace1 = half4(normalInput.tangentWS, positionWS.y);
				o.tSpace2 = half4(normalInput.bitangentWS, positionWS.z);

				OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);

#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
				half3 SH = SampleSH(normalInput.normalWS.xyz);
#else
				half3 SH = o.lightmapUVOrVertexSH.xyz;
#endif

				o.lightmapUVOrVertexSH.xyz = SAMPLE_GI(o.lightmapUVOrVertexSH.xy, SH, normalInput.normalWS);

				o.clipPos = positionCS;
				half4 offset = (_Time.xyyx * half4(_StreamerScrollX, _StreamerScrollY, _StreamerScrollY, _StreamerScrollX));
				offset = frac(offset);
				half4 streamerUv = v.texcoord.xyxy * _StreamerTex_ST.xyxy + _StreamerTex_ST.zwzw;
				o.streamerUv = streamerUv + offset;
				return o;
			}

            #include "HitRed_fun.hlsl"
			half4 frag(VertexOutput IN) : SV_Target
			{
				half3 WorldNormal = SafeNormalize( IN.tSpace0.xyz );
				half3 WorldTangent = IN.tSpace1.xyz;
				half3 WorldBiTangent = IN.tSpace2.xyz;

				half3 WorldPosition = half3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				half3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				//----------------------
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );


				half2 uv_BaseMap = IN.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				
				half2 uv_NormalMap = IN.uv.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				
				half2 uv_MixMap = IN.uv.xy * _MixMap_ST.xy + _MixMap_ST.zw;

				half4 tex2DNode11 = tex2D( _MixMap, uv_MixMap );

				half4 emission = half4(0, 0, 0, 0);
#if			_EMISSION_ON
				half4 emissionMapColor = tex2D(_EmissionMap, IN.uv.xy);
			    emission = emissionMapColor * _EmissionColor ; 
#else
                emission = _EmissionColor * tex2DNode11.b;
#endif
				half4 Albedo = tex2D(_BaseMap, uv_BaseMap).rgba;
				// hsv 处理
				half3 hvs = rgb2hsv(Albedo.rgb);
				hvs.x = fmod(_HSVHue * 0.00277777785 + hvs.x, 1);
				hvs.yz *= half2(_HSVSat, _HSVValue);
				Albedo.rgb = hsv2rgb(hvs);
				Albedo = Albedo.rgba * _BaseColor.rgba;
				Albedo.rgb = Albedo.rgb * _ColorScale;
				half Alpha = Albedo.a;
				
				half3 Normal = UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), _BumpStrength );
				half Metallic = lerp(_MetallicRemapMin, _MetallicRemapMax, tex2DNode11.r);
				half Smoothness = lerp(_SmoothnessRemapMin, _SmoothnessRemapMax, tex2DNode11.a) * _GlossMapScale;
				half3 Specular = _SpecularStrength;
				half Occlusion = tex2DNode11.g * _OcclusionStrength;

				half flag = step(_NonMetalThreshold, tex2DNode11.r);
				Occlusion = Occlusion * lerp(_NonMetalStrength, 1.0f, flag);

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = half4(0, 0, 0, 0);

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));

				half ndv = dot(SafeNormalize(inputData.normalWS), SafeNormalize(WorldViewDirection + _RimOffset.xyz));
				half3 rimColor = (pow((1.0 - saturate(ndv)), 5.0 - _RimSpread) * _RimColor).rgb * _RimPower;
				half3 Emission = emission.rgb + rimColor;

				half streamNoiseX = tex2D(_StreamerNoise, IN.streamerUv.yx).x;
				half streamNoiseY = tex2D(_StreamerNoise, IN.streamerUv.zw).y;
				half streamNoise = streamNoiseX * streamNoiseY;
				half2 streamerUvNew = streamNoise.xx * _StreamerNoiseSpeed + IN.streamerUv.xy;
				half3 streamer = tex2D(_StreamerTex, streamerUvNew.xy).xyz;
				half3 streamerMask = tex2D(_StreamerMask, IN.uv.xy).xyz;
				streamer *= _StreamerColor.rgb;
				streamer *= streamerMask;
				streamer *= _StreamerAlpha;
				Emission += streamer;


			    inputData.bakedGI = IN.lightmapUVOrVertexSH.xyz;

				Alpha = Alpha * _Alpha;
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo.rgb , 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					half3(0,0,0),
					Alpha,
					_LightDirControl,
					_LightDir
				    );

				color.rgb = HitRed(color.rgb, Emission.rgb, inputData.normalWS, WorldViewDirection);
				color.rgb = CalcFinalColor(color.rgb, _OverColor, _OverMultiple, _ContrastScale);
				return color;
			}
			ENDHLSL
		}
	}
	SubShader
	{
		Tags {  "RenderPipeline" = "UniversalPipeline"  "Queue" = "Transparent -300" }
		Cull[_CullMode]
		LOD 150

		Pass
		{

			Name "Forward"
			Tags { "LightMode" = "UniversalForward" }

			Blend[_SourceBlend][_DestBlend]
			ZWrite[_ZWriteMode]

			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

		//模板测试总是通过，并写入模板缓存区值为1
		Stencil
		{
			Ref 9
			Comp always
			Pass replace
			Fail keep
			ZFail keep
		}

		HLSLPROGRAM
		//#pragma multi_compile __ _EMISSION_ON
		//#pragma multi_compile  _HITCOLORCHANNEL_RIM _HITCOLORCHANNEL_ALBEDO _HITCOLORCHANNEL_NONE
        #define _HITCOLORCHANNEL_RIM 1

		#pragma vertex vert
		#pragma fragment frag

		#include "ColorCore.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "SimpleLightingCore.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

		struct VertexInput
		{
			half4 vertex : POSITION;
			half3 ase_normal : NORMAL;
			half4 ase_tangent : TANGENT;
			half4 texcoord : TEXCOORD0;

		};

		struct VertexOutput
		{
			half4 clipPos : SV_POSITION;
			half4 lightmapUVOrVertexSH : TEXCOORD0;
			half4 tSpace0 : TEXCOORD1;
			half4 tSpace1 : TEXCOORD2;
			half4 tSpace2 : TEXCOORD3;
			half2 uv : TEXCOORD4;
			};

			CBUFFER_START(UnityPerMaterial)
#include "HitRed_dec.hlsl"

			half4 _BaseColor;
			half _ColorScale;
			half _ContrastScale;
			half3 _OverColor;
			half  _OverMultiple;

			half4 _BaseMap_ST;
			half4 _NormalMap_ST;
			half4 _MixMap_ST;

			half4 _RimColor;
			half _RimSpread;
			half4 _RimOffset;
			half _RimPower;

			half _MetallicRemapMin, _MetallicRemapMax;
			half _SmoothnessRemapMin, _SmoothnessRemapMax;
			half _GlossMapScale;
			half _OcclusionStrength;
			half _BumpStrength;

			half _HSVHue;
			half _HSVSat;
			half _HSVValue;
			half _SpecularStrength;

			half _NonMetalThreshold;
			half _NonMetalStrength;
			half _Alpha;
			half _LightDirControl;
			half3 _LightDir;
			CBUFFER_END
			sampler2D _BaseMap;
			sampler2D _NormalMap;
			sampler2D _MixMap;

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o = (VertexOutput)0;
				o.uv.xy = v.texcoord.xy;
				half3 positionWS = TransformObjectToWorld(v.vertex.xyz);
				half3 positionVS = TransformWorldToView(positionWS);
				half4 positionCS = TransformWorldToHClip(positionWS);

				VertexNormalInputs normalInput = GetVertexNormalInputs(v.ase_normal, v.ase_tangent);

				o.tSpace0 = half4(normalInput.normalWS, positionWS.x);
				o.tSpace1 = half4(normalInput.tangentWS, positionWS.y);
				o.tSpace2 = half4(normalInput.bitangentWS, positionWS.z);

				OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);

				o.clipPos = positionCS;
				return o;
			}

			#include "HitRed_fun.hlsl"
			half4 frag(VertexOutput IN) : SV_Target
			{
				half3 WorldNormal = SafeNormalize(IN.tSpace0.xyz);
				half3 WorldTangent = IN.tSpace1.xyz;
				half3 WorldBiTangent = IN.tSpace2.xyz;

				half3 WorldPosition = half3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				half3 WorldViewDirection = _WorldSpaceCameraPos.xyz - WorldPosition;
				//----------------------

				WorldViewDirection = SafeNormalize(WorldViewDirection);


				half2 uv_BaseMap = IN.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;

				half2 uv_NormalMap = IN.uv.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;

				half2 uv_MixMap = IN.uv.xy * _MixMap_ST.xy + _MixMap_ST.zw;

				half4 tex2DNode11 = tex2D(_MixMap, uv_MixMap);

				half4 emission = half4(0, 0, 0, 0);
/*#if			_EMISSION_ON
				half4 emissionMapColor = tex2D(_EmissionMap, IN.uv.xy);
				emission = emissionMapColor * _EmissionColor;
#else
				emission = _EmissionColor * tex2DNode11.b;
#endif
*/				half4 Albedo = tex2D(_BaseMap, uv_BaseMap).rgba;
				// hsv 处理
				half3 hvs = rgb2hsv(Albedo.rgb);
				hvs.x = fmod(_HSVHue * 0.00277777785 + hvs.x, 1);
				hvs.yz *= half2(_HSVSat, _HSVValue);
				Albedo.rgb = hsv2rgb(hvs);
				Albedo = Albedo.rgba * _BaseColor.rgba;
				Albedo.rgb = Albedo.rgb * _ColorScale;
				half Alpha = Albedo.a;

				half3 Normal = UnpackNormalScale(tex2D(_NormalMap, uv_NormalMap), _BumpStrength);
				half Metallic = lerp(_MetallicRemapMin, _MetallicRemapMax, tex2DNode11.r);
				half Smoothness = lerp(_SmoothnessRemapMin, _SmoothnessRemapMax, tex2DNode11.a) * _GlossMapScale;
				half3 Specular = _SpecularStrength;
				half Occlusion = tex2DNode11.g * _OcclusionStrength;

				half flag = step(_NonMetalThreshold, tex2DNode11.r);
				Occlusion = Occlusion * lerp(_NonMetalStrength, 1.0f, flag);

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = half4(0, 0, 0, 0);

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));

				half ndv = dot(SafeNormalize(inputData.normalWS), SafeNormalize(WorldViewDirection + _RimOffset.xyz));
				half3 rimColor = (pow((1.0 - saturate(ndv)), 5.0 - _RimSpread) * _RimColor).rgb * _RimPower;
				half3 Emission = emission.rgb + rimColor;

				//half3 SH = IN.lightmapUVOrVertexSH.xyz;
				inputData.bakedGI = IN.lightmapUVOrVertexSH.xyz;

				Alpha = Alpha * _Alpha;
				half4 color = UniversalFragmentPBR(
					inputData,
					Albedo.rgb ,
					Metallic,
					Specular,
					Smoothness,
					Occlusion,
					half3(0,0,0),
					Alpha,
					_LightDirControl,
					_LightDir
					);

				color.rgb = HitRed(color.rgb, Emission.rgb, inputData.normalWS, WorldViewDirection);
				color.rgb = CalcFinalColor(color.rgb, _OverColor, _OverMultiple, _ContrastScale);
				return color;
			}
		    ENDHLSL
		}
	}
CustomEditor "FoldoutShaderGUI"
}

