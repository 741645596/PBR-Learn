Shader "FeiYun/Scene/Spec2"
{
	Properties
	{
		_BaseMap("BaseMap", 2D) = "white" {}

		_XTitles("X_Titles",  Range(0, 8)) = 0

		_YTitles("Y_Titles",  Range(0, 3)) = 0


		[Space(30)]

		_SpecColor ("Spec Color", Color) = (1, 1, 1, 1)	

		_SpecExp ("Exp", Range(0, 200)) = 50

		_SpecIntensity("SpecIntensity", Range(0, 2)) = 0.65

		_Offset("Offset", Vector) = (0, 0.4, 0.6, 1)	

		[Space(30)]

		_SpecColor2 ("Spec Color 2", Color) = (1, 1, 1, 1)	

		_SpecExp2 ("Exp2", Range(0, 200)) = 50

		_SpecIntensity2("SpecIntensity2", Range(0, 2)) = 0.65

		_Offset2("Offset2", Vector) = (0, 0.4, 0.6, 1)	

		[Space(30)]

		_DiffuseIntensity("DiffuseIntensity", Range(0, 2)) = 0.65

		_BaseColor ("Main Color", Color) = (1, 1, 1, 1)	

		[Space(30)]

		_FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)

		_FresnelPower("Fresnel Power", Float) = 15

		_FresnelStrenght("Fresnel Strenght", Float) = 0
		
		[HideInInspector] _Cutoff("Cutoff", Float) = 1

	}

	SubShader
	{
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"  }
		LOD 300
		Pass
		{
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			//Cull off
			
			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma multi_compile_instancing
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 

			CBUFFER_START(UnityPerMaterial)

			float4 _BaseMap_ST;

			half4  _BaseColor,  _SpecColor,_SpecColor2;
	
			float  _XTitles, _YTitles;

			float _DiffuseIntensity, _SpecExp, _SpecIntensity, _SpecExp2, _SpecIntensity2;

			float4 _Offset, _Offset2;

			float4 _FresnelColor;

			float _FresnelPower, _FresnelStrenght;
    		half _Cutoff;

			CBUFFER_END


			TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
				
			struct Attributes
			{
				float4 positionOS				: POSITION;
				float3 normalOS					: NORMAL;
				float4 tangentOS				: TANGENT;
				float2 texcoord					: TEXCOORD0;
				float2 lightmapUV				: TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct Varyings
			{
				float2 uv                       : TEXCOORD0;
				float3 normal                   : TEXCOORD1;
				float3 offset1					: TEXCOORD2;
				float3 offset2					: TEXCOORD3;
				float3 viewDirWS				: TEXCOORD4;
				float4 positionCS               : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 positionWS = TransformObjectToWorld(input.positionOS);
    			output.positionCS = TransformWorldToHClip(positionWS);
				output.viewDirWS = normalize(GetCameraPositionWS() - positionWS);//正负相反光源
				output.normal = TransformObjectToWorldNormal(input.normalOS);
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.offset1 = mul(_Offset, UNITY_MATRIX_V);
				output.offset2 = mul(_Offset2, UNITY_MATRIX_V);

				return output;
			}

			float4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float2 uv = input.uv;
				uv.x += floor(_XTitles) / 9.0;
				uv.y -= floor(_YTitles) / 6.0;

				float3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).rgb * _DiffuseIntensity;

				float3 normalWS = normalize(input.normal.xyz);
				float3 viewDirWS = normalize(input.viewDirWS.xyz);

				float ndvFresnel = 1 - saturate(dot(normalWS, viewDirWS));
				float3 fresnel = _FresnelColor.rgb * pow(ndvFresnel, _FresnelPower) * _FresnelStrenght;
				
				float3 customSpecView = normalize(input.offset1.xyz);
				float3 customSpecView2 = normalize(input.offset2.xyz);

				float ndv = saturate(dot(normalWS, customSpecView));
				float spec = pow(ndv, _SpecExp) * _SpecIntensity;

				float ndv2 = saturate(dot(normalWS, customSpecView2));
				float spec2 = pow(ndv2, _SpecExp2) * _SpecIntensity2;

				float4 finish = float4(albedo * _BaseColor + spec * _SpecColor + spec2 * _SpecColor2 + fresnel, 1);
				return finish;
			}
			ENDHLSL
		}
	}

}
