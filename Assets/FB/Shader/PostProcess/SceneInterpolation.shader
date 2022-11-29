
Shader "FB/PostProcessing/SceneInterpolation" 
{
	Properties
	{
		[MainTexture] _Tex1 ("Tex1 (RGB)", 2D) = "" {}
		_Tex2 ("Tex2 (RGB)", 2D) = "" {}
		_Factor("Factor", float) = 0
	}
	
	Subshader 
	{ 
		Tags {"RenderPipeline" = "UniversalPipeline"}
		Pass 
		{
			Tags {"LightMode"="UniversalForward"}
			ZTest Off
			ZWrite Off 
			Cull Off 
			//Blend OneMinusDstColor Zero
			Fog { Mode Off }

			HLSLPROGRAM
			//#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
				
			CBUFFER_START(HeroURPGroups) 
				TEXTURE2D_X(_Tex1); SAMPLER(sampler_Tex1);
				TEXTURE2D_X(_Tex2); SAMPLER(sampler_Tex2);
				half _Factor;
			CBUFFER_END

			struct appdata_img {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : POSITION;
				half2 tex : TEXCOORD0;
			};

			v2f vert (appdata_img v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.tex = v.texcoord;
				return o;
			}

			half4 frag( v2f i ) : SV_Target
			{
				half4 c0 = SAMPLE_TEXTURE2D(_Tex1,sampler_Tex1,i.tex);
				half4 c1 = SAMPLE_TEXTURE2D(_Tex2, sampler_Tex2, i.tex);
				return lerp(c0, c1, _Factor);
			}
			ENDHLSL
		}
	}
	Fallback off
}
