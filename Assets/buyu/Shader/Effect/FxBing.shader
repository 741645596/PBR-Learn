
Shader "FX/Bing" {
    Properties {
		
       

        
		[HDR]_Color ("主贴图颜色", Color) = (1, 1, 1, 1)
        _MainTex ("主贴图", 2D) = "white" {}
        _MainTexRotate("主贴图旋转", Float) = 0

		_MainTexSpeed_U("主贴图UV流动速度U", Float) = 0

		_MainTexSpeed_V("主贴图UV流动速度U", Float) = 0

		
		
		
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
			"PreviewType" = "Plane"  "RenderPipeline" = "UniversalPipeline"
        }

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		
		ZWrite Off


        Pass {
            

			HLSLPROGRAM

			//Pragmas 
			#pragma vertex vert
			#pragma fragment frag 

			//Include
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
           
			
			TEXTURE2D(_MainTex);	
			SAMPLER(sampler_MainTex);
			

			CBUFFER_START(UnityPerMaterial)

			uniform float4 _MainTex_ST;
			
			uniform float4 _Color;

            uniform float _MainTexSpeed_U;
            uniform float _MainTexSpeed_V;
			uniform float _MainTexRotate;
	

			

			CBUFFER_END

		
			struct Attributes
			{
				float4 positionOS		:		POSITION;
				float3 normalOS 		:		NORMAL;
				float4 Color	 		: 		COLOR;
				float2 uv				:		TEXCOORD0;
				

			};
			struct Varyings
			{
				float4 positionCS		:		SV_POSITION;
				float4 Color			:		COLOR;
				float2 uv           	:       TEXCOORD0;
				float3 viewDirWS		:		TEXCOORD1;
				half3  normalWS			:		TEXCOORD2;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;

				//VertexPositionInputs posInput = GetVertexPositionInputs(IN.positionOS.xyz);
				VertexNormalInputs norInput = GetVertexNormalInputs(IN.normalOS);

				OUT.normalWS = norInput.normalWS;

				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);


				OUT.positionCS = TransformWorldToHClip(positionWS);

				OUT.uv = IN.uv;

				OUT.viewDirWS = GetCameraPositionWS() - positionWS;

				OUT.Color = IN.Color;

				

				return OUT;
			}

			

			half4 frag(Varyings IN, half facing : VFACE) : SV_Target{
                
				float3 normalWS =  (facing > 0) ? normalize(IN.normalWS) : normalize(-IN.normalWS) ;

				float2 uv = IN.uv;

			
				float2 uvMainLoop = TRANSFORM_TEX(uv, _MainTex) + float2(_MainTexSpeed_U, _MainTexSpeed_V) * _Time.g ;

				

				
				float4 finishColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMainLoop);
				
				
				finishColor *= _Color * IN.Color;

	
				return finishColor;

            }
			ENDHLSL
        }
    }
    //CustomEditor "ShaderForgeMaterialInspector"
}


/*
public enum BlendMode
{
	//
	// ժҪ:
	//     Blend factor is (0, 0, 0, 0).
	Zero = 0,
	//
	// ժҪ:
	//     Blend factor is (1, 1, 1, 1).
	One = 1,
	//
	// ժҪ:
	//     Blend factor is (Rd, Gd, Bd, Ad).
	DstColor = 2,
	//
	// ժҪ:
	//     Blend factor is (Rs, Gs, Bs, As).
	SrcColor = 3,
	//
	// ժҪ:
	//     Blend factor is (1 - Rd, 1 - Gd, 1 - Bd, 1 - Ad).
	OneMinusDstColor = 4,
	//
	// ժҪ:
	//     Blend factor is (As, As, As, As).
	SrcAlpha = 5,
	//
	// ժҪ:
	//     Blend factor is (1 - Rs, 1 - Gs, 1 - Bs, 1 - As).
	OneMinusSrcColor = 6,
	//
	// ժҪ:
	//     Blend factor is (Ad, Ad, Ad, Ad).
	DstAlpha = 7,
	//
	// ժҪ:
	//     Blend factor is (1 - Ad, 1 - Ad, 1 - Ad, 1 - Ad).
	OneMinusDstAlpha = 8,
	//
	// ժҪ:
	//     Blend factor is (f, f, f, 1); where f = min(As, 1 - Ad).
	SrcAlphaSaturate = 9,
	//
	// ժҪ:
	//     Blend factor is (1 - As, 1 - As, 1 - As, 1 - As).
	OneMinusSrcAlpha = 10
}


//     Backface culling mode.
public enum CullMode
{
	//
	// ժҪ:
	//     Disable culling.
	Off = 0,
	//
	// ժҪ:
	//     Cull front-facing geometry.
	Front = 1,
	//
	// ժҪ:
	//     Cull back-facing geometry.
	Back = 2
}


//     Depth or stencil comparison function.
public enum CompareFunction
{
	//
	// ժҪ:
	//     Depth or stencil test is disabled.
	Disabled = 0,
	//
	// ժҪ:
	//     Never pass depth or stencil test.
	Never = 1,
	//
	// ժҪ:
	//     Pass depth or stencil test when new value is less than old one.
	Less = 2,
	//
	// ժҪ:
	//     Pass depth or stencil test when values are equal.
	Equal = 3,
	//
	// ժҪ:
	//     Pass depth or stencil test when new value is less or equal than old one.
	LessEqual = 4,
	//
	// ժҪ:
	//     Pass depth or stencil test when new value is greater than old one.
	Greater = 5,
	//
	// ժҪ:
	//     Pass depth or stencil test when values are different.
	NotEqual = 6,
	//
	// ժҪ:
	//     Pass depth or stencil test when new value is greater or equal than old one.
	GreaterEqual = 7,
	//
	// ժҪ:
	//     Always pass depth or stencil test.
	Always = 8
}

*/