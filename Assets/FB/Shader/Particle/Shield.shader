Shader "FB/Particle/Shield"
{
    Properties
    {
        [Header(Setting)]
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc("混合因子1", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDes("混合因子2", Float) = 10
        [Enum(Off,0,On,1)]_ZWrite("深度写入", Float) = 0

        [Header(Main)]
        [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" {}

        _LineTex ("LineTex", 2D) = "white" {}
        [Enum(UV1,0,UV2,1,UV3,2)]_LineUV("LineUV模式", Float) = 0
        _LineUVPanner("LineUV流动(xy)",vector) = (0,0,0,1)

        [Header(Back)]
        [HDR]_FrontFrameColor("背面线框颜色", Color) = (1,1,1,1)
        [HDR]_FrontColor("背面颜色", Color) = (1,1,1,1)

        [Header(Front)]
        [HDR]_BackFrameColor("正面线框颜色", Color) = (1,1,1,1)
        [HDR]_BackColor("正面颜色", Color) = (1,1,1,1)

        [Header(Fresnel)]
        _RimPower("边缘光Power", Range(0.01,10)) = 1
        [HDR]_RimColor("边缘光颜色", Color) = (1,1,1,1)

        [Header(Vertex1)]
        [Toggle(_CUSTOMDATA)] _CustomData("CustomData开关", Float) = 0
        _OffsetDir("偏移方向(w整体)",vector) = (0,0,0,1)
        _OffsetOffset1("偏移波长",float) = 0
        _OffsetOffset2("偏移差距",float) = 0
        _OffsetFrequence("偏移频率",float) = 0
        [Toggle]_UseTime("偏移sin时间",float) = 0

        [Header(Vertex2)]
        
        [Toggle(_VERTEX2_ON)] _UseVertex2("UseVertex2", Float) = 0
        HitOffset("整体偏移强度",float) = 0
        [NoScaleOffset]_Ramp ("Ramp", 2D) = "white" {}
        HitNoise("Ramp强度",float) = 0
        HitSize("Ramp负强度",float) = 0
        _Ramp_Panner("Tilling(xy) | UVPanner(zw)",vector) = (0,0,0,0)
        HitSpread("偏移柔和程度1",float) = 0
        HitFadeDistance("偏移柔和程度2",float) = 0
        HitPosition("HitPosition",vector) = (0,0,0,0)

        // Dissolve
        [Toggle(_DISSOLVE_ON)] _Dissolve("溶解开关", Float) = 0
        _DissolveTex("软溶解贴图", 2D) = "white" {}
        _DissolveIntensity("软溶解强度", Range( 0 , 2)) = 0
        _DissolveSoft("软溶解软度", Range( 0 , 2)) = 0
        _DissolveEdgeWidth("溶解描宽度", Range( 0 , 1)) = 0
        [HDR]_DissolveEdgeColor("溶解描边颜色", Color) = (1,1,1,1)
        _DissolveUVPanner("软溶解UV速度", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "Queue" = "Transparent" 
        }
        
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            Cull [_Cull]
            Blend [_BlendSrc] [_BlendDes]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _CUSTOMDATA
            #pragma multi_compile _ _DISSOLVE_ON
            #pragma multi_compile _ _VERTEX2_ON
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_particles

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _FrontColor;
                float4 _BackColor;

                float4 _FrontFrameColor;
                float4 _BackFrameColor;

                half   _RimPower;
                float4 _RimColor;

                half _Cull;

                half4 _OffsetDir;
                half _OffsetOffset1;
                half _OffsetOffset2;
                half _OffsetFrequence;

                half _UseTime;

                half2 _MainUVPanner;
                half2 _LineUVPanner;

                half4 _LineTex_ST;
                half4 _Ramp_Panner;

                half3 HitPosition;
                half HitSize;
                half HitSpread;
                half HitFadeDistance;
                half HitOffset;
                half HitNoise;

                float4 _RampTex_ST;

                half _LineUV;

                float4 _DissolveTex_ST;
                float4 _DissolveEdgeColor;
                half2  _DissolveUVPanner;
                half   _DissolveEdgeWidth;
                half   _DissolveSoft;
                half   _DissolveIntensity;

            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_LineTex);
            SAMPLER(sampler_LineTex);
            
            TEXTURE2D(_DissolveTex);

            sampler2D _Ramp;

            struct Attributes
            {
                float4 vertex           : POSITION;
                float3 normal           : NORMAL;
                float4 vertexColor      : COLOR;
                #if defined(_CUSTOMDATA)
                    float4 uv01         : TEXCOORD0;
                    float4 uv23         : TEXCOORD1;
                    half4 customData    : TEXCOORD2;
                    half4 customData2   : TEXCOORD3;
                #else
                    float2 uv0          : TEXCOORD0;
                    float2 uv1          : TEXCOORD1;
                    float2 uv2          : TEXCOORD2;
                    float2 uv3          : TEXCOORD3;
                #endif
            };
            
            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float4 uv               : TEXCOORD0;
                #if defined(_DISSOLVE_ON)
                    float4 world_pos        : TEXCOORD1;
                    float4 world_normal     : TEXCOORD2;
                #else
                    float3 world_pos        : TEXCOORD1;
                    float3 world_normal     : TEXCOORD2;
                #endif
                float4 vertexColor      : TEXCOORD3;
                #if defined(_CUSTOMDATA)
                    half4 customData    : TEXCOORD4;
                #endif
            };

            float Hit(float3 HitPosition,float3 WorldPos,float HitSize,half HitNoise,half HitSpread,sampler2D _RampTex,half HitFadeDistance)
            {
                float hit_result;

                float distance_mask = distance(HitPosition,WorldPos);
                float hit_range = -clamp((distance_mask - HitSize + HitNoise) / HitSpread , -1 ,0);
                float2 ramp_uv = float2(hit_range,0.5) * _Ramp_Panner.xy + _Ramp_Panner.zw * _Time.y;
                half hit_wave = tex2Dlod(_RampTex,float4(ramp_uv,0,0)).r;

                half hit_fade = saturate((1- distance_mask/HitFadeDistance));
                
                hit_result = hit_fade + hit_wave;

                return hit_result;
            }

            Varyings vert( Attributes v)
            {
                Varyings o = (Varyings)0;
                o.world_pos.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.world_normal.xyz = TransformObjectToWorldNormal(v.normal);
                

                #if defined(_DISSOLVE_ON)
                    #if defined(_CUSTOMDATA)
                        o.world_pos.w = v.uv23.x;
                        o.world_normal.w = v.uv23.y;
                    #else
                        o.world_pos.w = v.uv2.x;
                        o.world_normal.w = v.uv2.y;
                    #endif
                #endif

                // float3 origin = float3(0,0,0);
                // origin = TransformObjectToWorld(origin);
                // half3 pointToCenter = -Rejection(o.world_pos - origin,o.world_normal);
                // half3 offsetCenter = o.world_pos + pointToCenter;

                #if defined(_CUSTOMDATA)
                    o.customData = v.customData2;
                    float hitNoisePattern = v.uv23.y;
                #else
                    float hitNoisePattern = v.uv2.y;
                #endif

                half time = sin(lerp(1,_Time.y,_UseTime) * _OffsetFrequence + _OffsetOffset1) + _OffsetOffset2;

                half4 offsetDir = _OffsetDir;
                #if defined(_CUSTOMDATA)
                    offsetDir += v.customData;
                #endif

                float3 vertexOffset = v.vertex.xyz + offsetDir.xyz * offsetDir.w * time * v.normal;

                #if defined(_UseVertex2)
                    float3 hit = Hit(HitPosition,v.vertex.xyz,HitSize,hitNoisePattern * HitNoise,HitSpread,_Ramp,HitFadeDistance) * v.normal * 0.01;
                    vertexOffset += hit * HitOffset;
                #endif
                
                o.vertex = TransformObjectToHClip(vertexOffset) ;

                #if defined(_CUSTOMDATA)
                    o.uv.xy = v.uv01.xy;

                    if (_LineUV < 0.5)
                    o.uv.zw = v.uv01.zw;
                    else if (_LineUV < 1.5)
                    o.uv.zw = v.uv23.xy;
                    else
                    o.uv.zw = v.uv23.zw;
                #else
                    o.uv.xy = v.uv0;

                    if (_LineUV < 0.5)
                    o.uv.zw = v.uv1;
                    else if (_LineUV < 1.5)
                    o.uv.zw = v.uv2;
                    else
                    o.uv.zw = v.uv3;

                #endif
                o.uv.zw = o.uv.zw * _LineTex_ST.xy + _LineTex_ST.zw + _LineUVPanner * _Time.y;
                
                o.vertexColor = v.vertexColor;

                return o;
            }

            #if defined(_DISSOLVE_ON)
                void Dissolve(Varyings i,inout float3 color,inout half alpha)
                {
                    float2 uv = float2(i.world_pos.w,i.world_normal.w);
                    half dissolve_map = SAMPLE_TEXTURE2D(_DissolveTex,sampler_LinearRepeat,uv * _DissolveTex_ST.xy + _DissolveTex_ST.zw  + frac(_DissolveUVPanner.xy * _Time.y)).r;
                    half intensity = _DissolveIntensity;

                    #if defined(_CUSTOMDATA)
                        intensity += i.customData.x;
                    #endif

                    DissolveSimple(dissolve_map,intensity,_DissolveSoft,_DissolveEdgeWidth,_DissolveEdgeColor.rgb,color,alpha);
                }
            #endif 

            float4 frag(Varyings i, half facing : VFACE) :SV_TARGET
            {

                // uv2.zw gradient 扫光
                // uv1.zw line     个体扫光
                half line_mask = SAMPLE_TEXTURE2D(_LineTex,sampler_LineTex,i.uv.zw ).a;
                float4 base_color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy).a * line_mask;

                float4 front_color = base_color * _FrontFrameColor + _FrontColor;
                float4 back_color = base_color * _BackFrameColor + _BackColor;

                float4 color = lerp(front_color,back_color,saturate(facing)) * i.vertexColor; 

                // Dissolve
                #if defined(_DISSOLVE_ON)
                    Dissolve(i,color.rgb,color.a);
                #endif

                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.world_pos.xyz);
                half3 N = normalize(i.world_normal.xyz);

                float4 rim_color = FresnelSimple(N,V,_RimColor,_RimPower,facing,_Cull);
                color.rgb += rim_color.rgb * rim_color.a;

                return float4(color.rgb,color.a);
                
            }

            ENDHLSL 
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
