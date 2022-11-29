Shader "WB/UVFlow"
{
	// 主贴图+uv
	Properties
	{
		[Foldout] _BlendName("混合控制",Range(0,1)) = 0
		[FoldoutItem] [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("BlendSource", Float) = 5
		[FoldoutItem] [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("BlendDestination", Float) = 1
		[FoldoutItem] [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
		[FoldoutItem] [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
		[FoldoutItem] [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 4
		[FoldoutItem] _OffsetFactor("Offset Factor", Float) = 0
		[FoldoutItem] _OffsetUnits("Offset Units", Float) = 0

        _BaseMap("Base Map", 2D) = "white" {}
        [HDR] _BaseColor("Base Color", Color) = (1,1,1,1)
		_GlowScale("Glow Scale", float) = 1
        _AlphaScale("Alpha Scale", float) = 1

		_FlowMap("Flow Map", 2D) = "white" {}
		[HDR] _FlowColor("Flow Color", Color) = (1,1,1,1)
		_FlowSpeed("Flow Speed", Vector) = (0,0,0,0)
	}

	SubShader
	{
		Tags 
		{
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "PerformanceChecks" = "False"
            "RenderPipeline" = "UniversalPipeline"
        }

		Pass
		{
			Name "UVFlow"
			Blend[_SrcBlend][_DstBlend]
            Cull[_Cull]
            ZWrite[_ZWriteMode]
            Lighting Off
            ZTest [_ZTest]
			Offset[_OffsetFactor],[_OffsetUnits]
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag



			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

			CBUFFER_START(UnityPerMaterial)

			float4 _BaseMap_ST;
		    float4 _BaseColor;
		    float _GlowScale;
		    float _AlphaScale;

			
		    float4 _FlowMap_ST;
		    float4 _FlowColor;
			float2 _FlowSpeed;

			CBUFFER_END
			sampler2D _FlowMap;
			TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);

			struct Attributes
			{
				float3 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord :TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float4 color : COLOR;
				float2 texcoord :TEXCOORD0;
				float2 texcoordMask: TEXCOORD1;
			};


			Varyings vert(Attributes input)
			{
				Varyings output;
				output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.texcoordMask = TRANSFORM_TEX(input.texcoord, _FlowMap);
				output.positionCS = TransformObjectToHClip(input.vertex);
				output.color = input.color;
				return output;
			}


			float4 frag(Varyings in_f) : SV_TARGET
			{
				float t = abs(frac(_Time.y * 0.01));
				float calcTime = t * 100;
				float2 uv = in_f.texcoord;
				float4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				float4 col = in_f.color * baseCol * _BaseColor;
				col.rgb *= _GlowScale;

				float2 uvMask = in_f.texcoordMask + calcTime * _FlowSpeed;
				float4 uvCol = tex2D(_FlowMap, uvMask);
				float node_5670 = (dot(uvCol.rgb, float3(0.3, 0.59, 0.11))*uvCol.a);
				float3 emissive = (_FlowColor.rgb * saturate((node_5670 - 0.25)) * in_f.color.rgb);

				col.rgb += emissive;
				col.a = saturate(col.a * in_f.color.a * _BaseColor.a * _AlphaScale);
				return col;
			}

			ENDHLSL
		}
	}
    CustomEditor "FoldoutShaderGUI"
}