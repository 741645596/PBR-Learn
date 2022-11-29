Shader "FB/Particle/2sideCustomData_MaskDistortDissolve"
{
    Properties
    {
        [Header(Render Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("混合层1 ，one one 是ADD",int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 10
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式 : Off是双面显示，否则一般用 Back",int) = 0
        [Enum(Off, 0, On, 1)]_ZWrite("深度写入 : 透明选off，否则选on",int) = 0

        
        [Space(25)]

        [MaterialToggle(_CUSTOMDATA_ON)]_CustomDataOn("开启 Custom Data 开关", int) = 0

        _Cutoff("剔除", range(-1,1)) = 0.2
        [HDR]_FrontColor("正面颜色", Color) = (1,1,1,1)
        _MainTex_Front("正面贴图(Custom1.xy : Offset)", 2D) = "white" {}
        _UVSpeed_Front("正面贴图UV速度(xy)", Vector) = (0,0,0,0)

        [HDR]_BackColor("背面颜色", Color) = (1,1,1,1)
        _MainTex_Back("背面贴图(Custom1.zw : Offset)", 2D) = "white" {}
        _UVSpeed_Back("背面贴图UV速度(xy)", Vector) = (0,0,0,0)

        _NoiseMap("扰动贴图", 2D) = "black" {}
        _NoiseIntensity("扰动强度(Custom2.x)", Float) = 0
        _UVSpeed_Noise("扰动贴图UV速度(xy)", Vector) = (0,0,0,0)

        _AlphaMask("透明度遮罩(Custom2.y)", 2D) = "white" {}
        _UVSpeed_Alpha("透明度遮罩UV速度(xy)", Vector) = (0,0,0,0)

        [MaterialToggle(_DISSOLVE_ON)]_DissolveOn("溶解开关", int) = 0
        _DissolveMap("溶解贴图", 2D) = "white" {}
        _UVSpeed_Dissolve("溶解UV速度(xy)", Vector) = (0,0,0,0)
        _DissolveAmmount("溶解程度(Custom2.z)", Range( 0 , 1)) = 0
        _Spread("溶解扩散", Range( 0 , 1)) = 0
        _EdgeWidth("溶解边宽", Range( 0 , 1)) = 0
        [HDR]_EdgeColor("溶解颜色(Custom2.w : Alpha)", Color) = (1,1,1,1)

        [HideInInspector]_MainTexClamp_Front("MainTexClamp_Front(纹理WrapMode)",float) = 0     // 0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU_Front("MainTexRepeatU_Front(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV_Front("MainTexRepeatV_Front(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_MainTexClamp_Back("MainTexClamp_Back(纹理WrapMode)",float) = 0     // 0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU_Back("MainTexRepeatU_Back(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV_Back("MainTexRepeatV_Back(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_NoiseTexClamp("_NoiseTexClamp(纹理WrapMode)",float) = 0     // 0:Clamp 1:RepeatUV
        [HideInInspector]_NoiseTexRepeatU("_NoiseTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_NoiseTexRepeatV("_NoiseTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_MaskTexClamp("_MaskTexClamp(纹理WrapMode)",float) = 0     // 0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("_MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("_MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_DissolveMapClamp("_DissolveMapClamp(纹理WrapMode)",float) = 0     // 0:Clamp 1:RepeatUV
        [HideInInspector]_DissolveMapRepeatU("_DissolveMapRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DissolveMapRepeatV("_DissolveMapRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
    }

    HLSLINCLUDE

    #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

    CBUFFER_START(UnityPerMaterial)
        float4 _FrontColor;
        float4 _MainTex_Front_ST;
        float2 _UVSpeed_Front;

        float4 _BackColor;
        float4 _MainTex_Back_ST;
        float2 _UVSpeed_Back;
        
        float4 _NoiseMap_ST;
        float _NoiseIntensity;
        float2 _UVSpeed_Noise;
        
        float4 _AlphaMask_ST;
        float2 _UVSpeed_Alpha;
        
        float4 _DissolveMap_ST;
        float2 _UVSpeed_Dissolve;
        float4 _EdgeColor;
        float _DissolveAmmount;
        float _Spread;
        float _EdgeWidth;

        //面板支持
        float _MainTexClamp_Front, _MainTexRepeatU_Front, _MainTexRepeatV_Front;
        float _MainTexClamp_Back, _MainTexRepeatU_Back, _MainTexRepeatV_Back;
        float _NoiseTexClamp, _NoiseTexRepeatU, _NoiseTexRepeatV;
        float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;
        float _DissolveMapClamp, _DissolveMapRepeatU, _DissolveMapRepeatV;

        float _Cutoff;
    CBUFFER_END

    sampler2D _MainTex_Front;
    sampler2D _MainTex_Back;
    sampler2D _NoiseMap;
    sampler2D _AlphaMask;
    sampler2D _DissolveMap;
    ENDHLSL
    

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            Blend [_SrcFactor] [_DstFactor]
            Cull [_Cull]
            // ZWrite Off
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _CUSTOMDATA_ON
            #pragma multi_compile _ _DISSOLVE_ON
            
            struct Attributes
            {
                float4 vertex           : POSITION;
                #ifdef _CUSTOMDATA_ON 
                    float4 uv               : TEXCOORD0; //xy : uv               ; zw : customdata1.xy
                    float4 uv2              : TEXCOORD1; //xy : customdata1.zw   ; zw : customdata2.xy
                    float2 uv3              : TEXCOORD2; //xy : customdata2.zw
                #else
                    float2 uv               : TEXCOORD0;
                #endif
                float4 vertexColor      : COLOR;
            };
            
            struct Varyings
            {
                float4 vertex               : SV_POSITION;
                float4 uv_main              : TEXCOORD0;
                #ifdef _DISSOLVE_ON
                    float4 uv_alpha_dissolve    : TEXCOORD1;
                #else
                    float2 uv_alpha_dissolve    : TEXCOORD1;
                #endif

                #ifdef _CUSTOMDATA_ON 
                    float3 custom_data          : TEXCOORD2;
                #endif
                float4 vertexColor          : TEXCOORD3;
            };

            Varyings vert( Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);

                //sample noise
                half noise_intensity = _NoiseIntensity;
                #ifdef _CUSTOMDATA_ON 
                    noise_intensity += v.uv2.z;
                #endif
                half2 noise = tex2Dlod(_NoiseMap,half4(GetUV(TRANSFORM_TEX(v.uv.xy ,_NoiseMap), _NoiseTexClamp, _NoiseTexRepeatU, _NoiseTexRepeatV, _NoiseMap_ST)+ _UVSpeed_Noise * _Time.y , 1,1)).rg * noise_intensity;
                
                //handle uv
                o.uv_main.xy = TRANSFORM_TEX(v.uv.xy ,_MainTex_Front) + frac(_UVSpeed_Front * _Time.y) + noise;
                o.uv_main.zw = TRANSFORM_TEX(v.uv.xy ,_MainTex_Back)  + frac(_UVSpeed_Back  * _Time.y) + noise;

                o.uv_alpha_dissolve.xy = TRANSFORM_TEX(v.uv.xy ,_AlphaMask) + _UVSpeed_Alpha * _Time.y;
                #ifdef _DISSOLVE_ON
                    o.uv_alpha_dissolve.zw = TRANSFORM_TEX(v.uv.xy ,_DissolveMap) + _UVSpeed_Dissolve * _Time.y;
                #endif

                #ifdef _CUSTOMDATA_ON 
                    //if custom data
                    o.uv_main.xy += v.uv.zw;
                    o.uv_main.zw += v.uv2.xy;
                    o.custom_data = half3(v.uv2.w, v.uv3);
                #endif

                o.vertexColor = v.vertexColor;
                return o;
            }

            float4 frag(Varyings i,half facing : VFACE):SV_TARGET
            {
                // sample tex
                half4 maintex_front = tex2D(_MainTex_Front, GetUV(i.uv_main.xy, _MainTexClamp_Front, _MainTexRepeatU_Front, _MainTexRepeatV_Front, _MainTex_Front_ST)) * _FrontColor ;
                half4 maintex_back  = tex2D(_MainTex_Back , GetUV(i.uv_main.zw, _MainTexClamp_Back , _MainTexRepeatU_Back , _MainTexRepeatV_Back , _MainTex_Back_ST))  * _BackColor  ;

                half4 final_color = (max(facing,0) > 0 ? maintex_front: maintex_back) * i.vertexColor;
                
                half dissolve_ammount = 1;
                #ifdef _DISSOLVE_ON
                    // dissolve
                    half dissolve_map = tex2D(_DissolveMap, GetUV(i.uv_alpha_dissolve.zw, _DissolveMapClamp, _DissolveMapRepeatU, _DissolveMapRepeatV, _DissolveMap_ST)).r;
                    dissolve_ammount = _DissolveAmmount;
                    #ifdef _CUSTOMDATA_ON 
                        dissolve_ammount = saturate(dissolve_ammount + i.custom_data.y);
                    #endif            
                    dissolve_ammount = ( (dissolve_ammount) * ( 1.0 + _Spread ) - _Spread );
                    dissolve_ammount = saturate( (dissolve_map - dissolve_ammount) / max(_Spread * 2,0.001f) );

                    half edge_factor = saturate(1.0 - (distance(dissolve_ammount , 0.5) / _EdgeWidth));

                    // combine base color and dissolve edge color
                    final_color =lerp(final_color,_EdgeColor,edge_factor);
                #endif

                //alpha
                half alpha = final_color.a * tex2D(_AlphaMask, GetUV(i.uv_alpha_dissolve.xy, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _AlphaMask_ST)).r * dissolve_ammount * _FrontColor.a * _BackColor.a;
                #ifdef _CUSTOMDATA_ON 
                    alpha = saturate(alpha * (_EdgeColor.a - i.custom_data.z) - i.custom_data.x);
                #else
                    alpha = saturate(alpha * _EdgeColor.a);
                #endif

                clip(final_color.a - _Cutoff);
                
                return half4(final_color.rgb,alpha);
            }
            ENDHLSL 
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
