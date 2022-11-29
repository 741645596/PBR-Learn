//吸收材质
Shader "FB/Particle/FlowMap_Sunction"
{
    
    Properties
    {
        //BaseMap相关
        _BaseMap("Albedo(底色)", 2D) = "white" {}
        [HDR][MainColor] _BaseColor("Color(底色)", Color) = (1,1,1,1)
        _AlphaControl("Alpha",Range(0,1)) = 0.9
        //FlowMap相关
        _FlowMap("FlowMap",2D) = "black"{}
        _Sunction("吸收率",Range(0,1)) = 0.5
        //溶解相关
        [Space(25)]
        [MaterialToggle(USINGDISSOLVE)]_DissolveEnable("是否启用溶解", int) = 0
        _DissolveMap("溶解贴图",2D) = "black"{}
        _DissolveMap_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _DissolveStrength("溶解强度",Range(0.0,1.0)) = 0.5
        _DissolveEdgeWidth("溶解边宽",Range(0.0,0.1)) = 0.03
        [HDR]_EdgeEmission("边界自发光颜色",Color) = (1,1,1,1)
        
        //扭曲相关
        [Space(25)]
        [MaterialToggle(USINGDISTORT)]_DistortEnable("是否启用扭曲贴图", int) = 1
        _DistortMap("_DistortTex(扭曲贴图)", 2D) = "black" {}
        _DistortMapMask("_DistortTex(扭曲贴图Mask)", 2D) = "black" {}
        _DistortMap_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _Distort("_Distort(扭曲强度)", Range(0, 1)) = 0.1
        _uvDistortSpeed("UV扭曲流动速度",Vector) = (0.1,0.1,0,0)
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags {  
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }
        Pass
        {
            BlendOp[_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            //Cull[_Cull]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ USINGDISSOLVE
            #pragma multi_compile _ USINGDISTORT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            TEXTURE2D_X(_DissolveMap);
            SAMPLER(sampler_DissolveMap);

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D_X(_FlowMap);
            SAMPLER(sampler_FlowMap);
            
            TEXTURE2D_X(_DistortMap);
            SAMPLER(sampler_DistortMap);

            TEXTURE2D_X(_DistortMapMask);
            SAMPLER(sampler_DistortMapMask);
            

            CBUFFER_START(UnityPerMaterial)
                half  _Sunction;
                half  _DissolveEnable;
                half _DistortEnable;
                half  _DissolveStrength;
                half  _DissolveEdgeWidth;
                half4 _EdgeEmission;
                half4 _DissolveMap_TilingOffset;
                half4 _BaseColor;
                half  _AlphaControl;
                half4 _uvDistortSpeed;
                half _Distort;
                half  _Opacity;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD4;
            };

            float2 UVTilingOffset(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            v2f vert(appdata v)
            {
                v2f o;

                o.uv = UVTilingOffset(v.uv, _DissolveMap_TilingOffset);
                o.vertex = TransformObjectToHClip(v.vertex);


                return o;
            }

            
            half4 frag (v2f i) : SV_Target
            {
                float2 distort = i.uv;
                #if defined(USINGDISTORT)
                {
                    half2 tempUVspeed  = _Time.g *_uvDistortSpeed;
                
                    float2 flowUV = i.uv + tempUVspeed;

                    half4 DistortMap = SAMPLE_TEXTURE2D(_DistortMap,sampler_DistortMap,flowUV);//全局扰动
                    half4 DistortMapMask = SAMPLE_TEXTURE2D(_DistortMapMask,sampler_DistortMapMask,i.uv);//主要扰动部分

                    distort += (DistortMap*DistortMapMask*_Distort).xy;
                }
                #endif
                
                half4 FlowMap = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,i.uv);
                half2 _BaseMapuv = lerp(distort,FlowMap.xy,_Sunction);
                half3 resultColor;
                half4 BaseMapCd = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,_BaseMapuv);

                #if defined(USINGDISSOLVE)
                    half4 DissolveColor = SAMPLE_TEXTURE2D(_DissolveMap,sampler_DissolveMap,i.uv);
                    //求溶解裁切Alpha
                    half DissolveAlpha = step(DissolveColor.x,_DissolveStrength);

                    //求溶解边宽
                    half EdgeWidth = step(DissolveColor.x,_DissolveStrength-_DissolveEdgeWidth);

                    //得到边界颜色
                    half4 emissionCd = (DissolveAlpha-EdgeWidth) * _EdgeEmission;
                    if(_DissolveStrength>0.98)
                    {
                        emissionCd = half4(0,0,0,0);
                    }
                    
                    resultColor = emissionCd.rgb + BaseMapCd.rgb;

                    return half4(resultColor,DissolveAlpha * BaseMapCd.a * _AlphaControl * _Opacity);
                #endif
                
                return BaseMapCd;
            }
            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
