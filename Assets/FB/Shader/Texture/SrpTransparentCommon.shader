
Shader "FB/Texture/SrpTransparentCommon" {

    Properties{
        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0

        [NoScaleOffset][MainTexture] _MainTex("MainTexture", 2D) = "white" {}
        [MainColor]_MainColor("MainColor", Color) = (1,1,1,1)
         _MainColorInst("MainColorInst", float) = 1
        _MainTexTilingOffset("MainTexTilingOffset", Vector) = (1,1,0,0)
    }

    SubShader{

        Tags {
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass{ //3

			Name "TranslucentSrp"
			Tags {"LightMode" = "SrpDefaultUnlit"}
			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            TEXTURE2D_X(_MainTex);
            SAMPLER(sampler_MainTex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _MainColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTexTilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(float, _MainColorInst)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			struct VertexInput {
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(VertexInput v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				return o;
			}

			half4 frag(v2f i) : SV_Target{
				return half4(0,0,0,0);
			}

			ENDHLSL
		}

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest On
            ZWrite Off

            Cull[_CullMode]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            TEXTURE2D_X(_MainTex);
            SAMPLER(sampler_MainTex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _MainColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTexTilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(float, _MainColorInst)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD2;
                    float3  normalWS : TEXCOORD3;
                #endif
            };

            float2 GetUv(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    float4 st= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTexTilingOffset);
                    o.uv0 = GetUv(v.texcoord0, st);
                    o.pos = TransformObjectToHClip(v.vertex.xyz);

                    #if defined(UNITY_INSTANCING_ENABLED)
                        o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                    #endif
                    

                    return o;
            }

            half4 frag(VertexOutput i) : SV_Target{
               UNITY_SETUP_INSTANCE_ID(i);

               half4 _Diffuse_var =  SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
               half4 c = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainColor);
               c.rgb= c.rgb* UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainColorInst);
               return _Diffuse_var * c;
            }

            ENDHLSL

        }
    }
    FallBack off
}
