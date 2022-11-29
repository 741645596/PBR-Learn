Shader "FB/UI/UIAddAlphaBlend"
{
	Properties
	{
		[HideInInspector] _Blend("Blend",int) = 0
		[HideInInspector]_Cull("Cull",int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层 1 ，one one 是ADD",int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层 2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式 OFF 是双面显示",int) = 0
		
		[Enum(LEqual,4,Always,8)] _ZAlways("是否在层级最前面显示", int) = 4
		[HDR]_Color("Color", Color) = (1,1,1,0)
		_MainTex("MainTex", 2D) = "white" {}
		[HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
		[HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
		[HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

		_Intensity("Intensity", Float) = 1
		[HideInInspector]_Opacity("Opacity", float) = 1

		_StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

	}

	SubShader
	{

		Tags { "RenderPipeline" = "UniversalPipeline"
		 "RenderType" = "Transparent" 
		 "Queue" = "Transparent" 
		 }

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull[_CullMode]
		ZWrite Off
		ZTest[_ZAlways]
		Blend[_SrcBlend][_DestBlend]

		Pass
		{
				
			Name "Fx_Add_AlphaBlend"
			Tags {"LightMode"="Default UI RP"}

			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UI.hlsl" 
			
			TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)

				half4 _MainTex_ST;
				half4 _Color;
				half _Intensity;
				half _Opacity;
				float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
				half _SrcBlend;
				half _DestBlend;

			CBUFFER_END

			struct VertexInput
			{
				float4 vertex : POSITION;
				float4 ase_texcoord : TEXCOORD0;
				half4 ase_color : COLOR;
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
			};

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o = (VertexOutput)0;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;

				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
				float4 positionCS = TransformWorldToHClip(positionWS);
				o.clipPos = positionCS;
				return o;
			}

			half4 frag(VertexOutput IN) : SV_Target
			{
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				float2 uvMain = GetUV(uv_MainTex, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
				half4 tex2DNode5 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);

				float3 Color = (tex2DNode5 * _Color * IN.ase_color * _Intensity).rgb;
				float alpha = (tex2DNode5.a * IN.ase_color.a * _Intensity * _Color.a) * _Opacity;
				
				return half4(LinearToSRGB(Color)*alpha, alpha);
			}

			ENDHLSL
		}
	}
}
