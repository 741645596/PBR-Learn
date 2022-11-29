Shader "FB/Particle/NphWrap"
{
    Properties
    {
        [MaterialToggle(USINGDISTORT)]_DistortEnable("是否启用扭曲贴图", int) = 1
        [MaterialToggle(_CUSTOMDATA_ON)]_CustomDataOn("开启 Custom Data 开关", int) = 0
        _DistortTex("_DistortTex(扭曲贴图)", 2D) = "black" {}
        _DistortTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _Distort("_Distort(扭曲强度)", Range(0, 1)) = 0.1
        //极坐标相关参数
        [Space(25)]
        [MaterialToggle(USINGPOLAR)]_PolarEnable("是否启用极坐标", int) = 0
        _uvDistortSpeed("流动速度",Vector) = (0.5,0.5,0,0)
        _DistortTexAngle("扭曲贴图旋转角度",Range(0, 360)) = 0
    }
    SubShader
    {
        Tags {  
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Tags {
                "LightMode" = "WrapPass"
            }
            
            BlendOp Add
            Blend One One
            ZWrite Off
            ZTest   LEqual
            ColorMask RG

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _CUSTOMDATA_ON

            #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _DistortTex_TilingOffset;
                float _Distort;
                half4 _uvDistortSpeed;
                half _PolarEnable;
                half _DistortEnable;
                half _DistortTexAngle;
            CBUFFER_END

            TEXTURE2D_X(_DistortTex);
            SAMPLER(sampler_DistortTex);
            
            TEXTURE2D_X(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;

                #ifdef _CUSTOMDATA_ON 
                    float3 uv               : TEXCOORD0; //xy : uv               ; z : customdata1.x
                #else
                    float2 uv               : TEXCOORD0;
                #endif
            };

            struct v2f
            {
                #ifdef _CUSTOMDATA_ON 
                    float3 uv               : TEXCOORD0; //xy : uv               ; z : customdata1.x
                #else
                    float2 uv               : TEXCOORD0;
                #endif

                float4 positionCS : SV_POSITION;

                half4 projection:TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = UVTilingOffset(v.uv.xy, _DistortTex_TilingOffset);

                #ifdef _CUSTOMDATA_ON 
                    o.uv.z = v.uv.z;
                #endif

                float3 posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.projection = ComputeScreenPos(o.positionCS);
                o.projection.z = -TransformWorldToView(posWorld.xyz).z;

                return o;
            }

            ////outBuffer0 - rg:扭曲 ba:色散
            ////outBuffer1 - 径向模糊参数
            ////outBuffer2 - r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊
            ////half4 frag(v2f i) : SV_Target
            //void frag(v2f i,out half4 outBuffer0 : SV_Target0,out half4 outBuffer1 : SV_Target1,out half4 outBuffer2 : SV_Target2)
            //{
                //    float2 polar = toPolar(i.uv,_uvDistortSpeed,_DistortTexAngle,_PolarEnable);
                //    half2 wrapXY = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, polar).rg*_Distort;

                //    //表示扭曲  xy:扭曲强度 zw:色散强度
                //    outBuffer0 = half4(wrapXY,0,0);
                //    //径向模糊
                //    outBuffer1=half4(0,0,0,0);
                //    //r>0 -- 开启了扭曲 g>0 -- 开启了色散 b>0 -- 开启了径向模糊
                //    outBuffer2=half4(1,0,0,0);
            //}

            //outBuffer0 - rg:扭曲 ba:色散
            //half4 frag(v2f i) : SV_Target
            void frag(v2f i,out half4 outBuffer0 : SV_Target0)
            {
                float2 polar = toPolar(i.uv,_uvDistortSpeed,_DistortTexAngle,_PolarEnable);

                half distortIntensity = _Distort;

                #ifdef _CUSTOMDATA_ON 
                    distortIntensity += i.uv.z;
                #endif

                half2 wrapXY = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, polar).rg * distortIntensity;

                //表示扭曲  xy:扭曲强度 zw:色散强度
                outBuffer0 = half4(wrapXY,0,0);

            }

            ENDHLSL
        }

    }
    //CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
