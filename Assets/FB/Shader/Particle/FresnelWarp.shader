
Shader "FB/Particle/FresnelWarp"
{

    Properties {
        //当开启此选项的时候，粒子系统中的CustomData会控制shader中的VertexInput(TEXCOORD*)的参数,控制参数需要在粒子中的render中指定
        //如:CustomVertexStream->Custem1.xy(TEXCOORD0.xy)+Custem1.xyzw(TEXCOORD1.xyzw),同时需要在粒子系统中的CustomData中开启Custem1
        [Toggle(_Particle_Control)] _ParticleControl("粒子系统影响", Float) = 0
        _FresnelPow ("菲涅尔", float) = 5
        _NoiseIntensity ("扭曲程度", Range(0, 1)) = 0
        [MainColor]_MainColor("Color", Color) = (1,1,1,1)
    }

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }

        Pass {
            Tags {
                "LightMode" = "Wrap"
            }

            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual
            ColorMask RG
            
            HLSLPROGRAM

            #pragma multi_compile __ _Particle_Control

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            TEXTURE2D_X(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            CBUFFER_START(UnityPerMaterial)

                half _FresnelPow;
                half _NoiseIntensity;
                half4 _MainColor;

            CBUFFER_END

            struct VertexInput {
                half4 vertex : POSITION;
                half4 vertexColor : COLOR;
                half3 normal:NORMAL;
                float4 fresnelPowParticle:TEXCOORD1;
            };

            struct VertexOutput {
                half4 pos : SV_POSITION;
                half4 vertexColor : COLOR;
                float4 fresnelPowParticle:TEXCOORD0;
                float worldPos : TEXCOORD3;
                float3  worldNormal : TEXCOORD4;
                half4 projection:TEXCOORD1;
            };

            half3 GetViewDirWorld(float3 _worldPos){
                return normalize(_WorldSpaceCameraPos.xyz-_worldPos);
            }

            //计算菲涅尔
            //_normalWorld:世界法线
            //_viewDirWorld:视角
            //_fresnelPow:菲尼尔强度 >1
            half GetFresnel(half3 _normalWorld,half3 _viewDirWorld,half _fresnelPow){
                half d=1-saturate(dot(_normalWorld, _viewDirWorld));
                half res = pow(d, _fresnelPow);
                return res;
            }

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal=normalize(TransformObjectToWorldNormal(v.normal.xyz));
                float3 posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.projection = ComputeScreenPos(o.pos);
                o.projection.z = -TransformWorldToView(posWorld.xyz).z;
                return o;
            }

            half4 frag(VertexOutput i) : COLOR {

                float2 screenUV = i.projection.xy / i.projection.w;
                screenUV.y=-_ProjectionParams.x*screenUV.y+clamp(_ProjectionParams.x,0,1);
                float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(screenUV)).r;
                float  sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams) - _ProjectionParams.g;
                sceneZ = max(0, sceneZ);
                float partZ = max(0, i.projection.z - _ProjectionParams.g);
                float d = smoothstep(0,0.01, sceneZ - partZ);

                half3 viewDirWorld = GetViewDirWorld(i.worldPos);
                #ifdef _Particle_Control
                    _FresnelPow=_FresnelPow*i.fresnelPowParticle.x;
                #endif 

                half fresnelValue = GetFresnel(i.worldNormal,viewDirWorld,_FresnelPow)*_MainColor.a*_NoiseIntensity;


                return half4(fresnelValue,fresnelValue,0,0)*d*_MainColor.a;
            }

            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
