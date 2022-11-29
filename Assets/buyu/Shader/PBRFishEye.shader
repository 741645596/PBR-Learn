
Shader "WB/PBRFishEye"
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

		[Foldout] _FishEyeName("鱼眼径向透明度面板",Range(0,1)) = 0
		[FoldoutItem] _RadiusAlphaStrength("RadiusAlphaStrength[径向透明度强度]", Range(1, 3)) = 1
		[FoldoutItem] _RadiusAlphaMin("_RadiusAlphaMin[径向透明度区间]", Range(0, 0.5)) = 0.3
		[FoldoutItem] _RadiusAlphaMax("_RadiusAlphaMax[径向透明度区间]", Range(0.9, 1)) = 1
		[FoldoutItem] _LerpStrength("_LerpStrength[渐变过度强度区间]", Range(0.5, 20)) = 1

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
	}

	SubShader
	{
		Tags {  "RenderPipeline" = "UniversalPipeline"  "Queue" = "Transparent -300" }
		Cull[_CullMode]

		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend[_SourceBlend][_DestBlend]
			ZWrite[_ZWriteMode]

		    ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
            #define _HITCOLORCHANNEL_ALBEDO 1

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

			half _RadiusAlphaStrength;
			half _RadiusAlphaMin, _RadiusAlphaMax;
			half _LerpStrength;

			half _Alpha;
			CBUFFER_END
			sampler2D _BaseMap;
			sampler2D _NormalMap;
			sampler2D _MixMap;


			

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

				o.clipPos = positionCS;
				return o;
			}

            #include "HitRed_fun.hlsl"
			half4 frag(VertexOutput IN) : SV_Target
			{
				half3 WorldNormal = normalize( IN.tSpace0.xyz );
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

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = half4(0, 0, 0, 0);

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));

				half ndv = dot(normalize(inputData.normalWS), normalize(WorldViewDirection + _RimOffset.xyz));
				half3 rimColor = (pow((1.0 - saturate(ndv)), 5.0 - _RimSpread) * _RimColor).rgb * _RimPower;
				half3 Emission = emission.rgb + rimColor;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
				     half3 SH = SampleSH(inputData.normalWS.xyz);
				#else
				     half3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

			    inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				// 标识出金鱼眼圈。
				//half flag = step(0.3f, tex2DNode11.b);//step(a,b) b >= a ? 1:0
				half flag = saturate(exp((0.3f - tex2DNode11.b) * _LerpStrength));
				half cosAngel = saturate(ndv);
				half RadiusDistance = 1 - cosAngel * cosAngel;
				half RadiusAlpha = pow(RadiusDistance, _RadiusAlphaStrength);
				RadiusAlpha = lerp(_RadiusAlphaMin, _RadiusAlphaMax, RadiusAlpha);
				Alpha = lerp(RadiusAlpha, 1.0f, flag) * _Alpha;

				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo.rgb , 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					half3(0,0,0),
					Alpha,
					0,
					half3(0, 0, 0)
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

