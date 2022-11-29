Shader "FB/Particle/AddAlphaBlend"
{
	Properties
	{
		[HideInInspector]_Blend("Blend",int) = 0
		[HideInInspector]_Cull("Cull",int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层 1 ，one one 是ADD",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层 2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式 OFF 是双面显示",int ) = 0
		//[Enum(UnityEngine.Rendering.ZTestMode)]_Ztest("深度测试选项",int ) = 0
		//[KeywordEnum(LEqual,3,Always,7)]_ZAlways("是否在层级最前面显示",float) = 3
		//[Toggle(_)] _Is_LightColor_Base ("Is_LightColor_Base", Float ) = 1
		
		[Enum(LEqual,4,Always,8)] _ZAlways("是否在层级最前面显示", int) = 4
		[HDR]_Color("Color", Color) = (1,1,1,0)
		_MainTex("MainTex", 2D) = "white" {}
		[HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
		[HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
		[HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

		_Intensity("Intensity", Float) = 1
		[HideInInspector]_Opacity ("Opacity", float) = 1

	}

	SubShader
	{

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull [_CullMode]
		ZWrite Off
		ZTest [_ZAlways]
		Blend [_SrcBlend] [_DestBlend]
		//AlphaToMask ON

		Pass
		{
			Name "Fx_Add_AlphaBlend"
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			//#pragma prefer_hlslcc gles
			//#pragma exclude_renderers d3d11_9x
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

			CBUFFER_START(HeroURPGroups) 

				TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
				half4 _MainTex_ST;
				half4 _Color;
				half _Intensity;
				half _Opacity;
				float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;

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

			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz);
				float4 positionCS = TransformWorldToHClip( positionWS );
				o.clipPos = positionCS;
				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{

				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				float2 uvMain = GetUV(uv_MainTex, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
				half4 tex2DNode5 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
	
				//tex2DNode5 = GetTextColor(tex2DNode5, uvMain, _MainTexRepeatU, _MainTexRepeatV);

				float3 Color = ( tex2DNode5 * _Color * IN.ase_color * _Intensity ).rgb;
				float alpha = ( tex2DNode5.a * IN.ase_color.a * _Intensity * _Color.a )*_Opacity;

				return half4(Color*alpha,alpha);
				/*
				alpha = saturate(alpha);
				half3 final = Color.rgb*alpha;
				return half4( final, alpha);*/
			}

			ENDHLSL
		}
	}
}
