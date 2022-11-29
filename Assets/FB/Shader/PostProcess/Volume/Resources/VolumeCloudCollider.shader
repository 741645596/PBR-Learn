
Shader "FB/PostProcessing/RayVolumeCloud/VolumeCloudCollider" {

    Properties{
         _MainColor("MainColor", Color) = (1,1,1,1)
         _MainColorInst("MainColorInst", float) = 1
         _CenterDis("CenterDis", float) = 1
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
            #pragma multi_compile _ ENBLE_SP_VDOTN
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _MainColor;
                float _MainColorInst;
                float _CenterDis;
            CBUFFER_END

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float3  normalWS : TEXCOORD0;
                float3 posLocal : TEXCOORD1;
                float3 centerLocal: TEXCOORD2;
                float3 viewDirWS: TEXCOORD3;
            };

            VertexOutput vert(VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.posLocal = v.vertex.xyz;
                o.normalWS =TransformObjectToWorldDir(v.normal);
                o.centerLocal = float3(0,0,0);

                o.viewDirWS = normalize(_WorldSpaceCameraPos-TransformObjectToWorld(v.vertex.xyz));

                return o;
            }

            half4 frag(VertexOutput i) : SV_Target{


               float sinY =sin(_Time.y*1.4);
               sinY=(sinY+1.0f)*0.5f;
               sinY=0.8+0.3*sinY;

               float dx=abs(ddx(i.posLocal));
               float dy=abs(ddy(i.posLocal));
               float d=max(dx,dy)*5;
               d=pow(d,2);
               d=clamp(d,0,1);

               float dis = length(i.posLocal-i.centerLocal)*_CenterDis;
               dis=pow(dis,2)*3.0;

               float oneMinVDotN =1.0 - dot(i.viewDirWS,normalize(i.normalWS));

               #if defined(ENBLE_SP_VDOTN)
                    _MainColorInst=_MainColorInst+d+oneMinVDotN;
               #else
                    _MainColorInst=_MainColorInst+d;
               #endif

               half4 resColor= _MainColor*dis*_MainColorInst;

               resColor.a=resColor.a*sinY;
               return resColor;


            }

            ENDHLSL

        }
    }
    FallBack off
}
