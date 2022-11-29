Shader "FB/Particle/SGameEffectUber"
{
    Properties
    {
        _Opacity("Opacity", range(0,1)) = 1

        _MainTex("主贴图", 2D) = "white" {}
        [HDR]_Color("主颜色", Color) = (1,1,1,1)
        _AlphaEnhance("透明度增强", Range(0,99)) = 1
        _MainUVPanner("主贴图UV", Vector) = (0,0,0,0)
        [Toggle]_MainUVDistort("主贴图UV扭曲", range(0,1)) = 1
        [Toggle]_MainUVXClamp("Main Clamp X", range(0,1)) = 0
        [Toggle]_MainUVYClamp("Main Clamp Y", range(0,1)) = 0
        [Enum(UV0,0,UV1,1)]_MainUV("MainUV", Float) = 0

        [Toggle]_MainTexSamplerState("MainTexSamplerState", range(0,1)) = 0

        [Toggle(_SECONDLAYER_ON)] _SecondLayer("SecondLayer", Float) = 0
        [Enum(Blend,0,Add,1,Mul,2)]_SecondColorBlend("SecondColorBlend", Float) = 2
        _SecondTex("第二贴图", 2D) = "white" {}
        [HDR]_SecondColor("SecondColor", Color) = (1,1,1,1)
        _SecondUVPanner("副贴图UV", Vector) = (0,0,0,0)
        [Toggle]_SecondDistort("SecondDistort", range(0,1)) = 0
        [Toggle]_SecondUVXClamp("Second Clamp X", range(0,1)) = 0
        [Toggle]_SecondUVYClamp("Second Clamp Y", range(0,1)) = 0
        [Enum(UV0,0,UV1,1)]_SecondUV("SecondUV", Float) = 0

        // Custom Data
        [Toggle] _CustomData("CustomData", Float) = 0

        // Rim
        [Toggle] _Rim("Rim", Float) = 0
        _RimPower("RimPower", Float) = 3
        [HDR]_RimColor("RimColor", Color) = (1,0.5,0,1)
        _RimPower2("RimPower2", Float) = 1
        [HDR]_RimColor2("RimColor2", Color) = (0,0,0,1)

        // Distort
        [Toggle(_DISTORT_ON)] _Distort("Distort", Float) = 0
        _DistortionTex("扭曲贴图", 2D) = "white" {}
        _DistortionIntensity("UV扭曲强度", Float) = 0
        _DistortUVPanner("扭曲UV", Vector) = (0,0,0,0)
        [Enum(UV0,0,UV1,1)]_DistortUV("DistortUV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)]_DistortChannel("DistortChannel", Float) = 0

        // Alpha
        [Toggle(_ALPHA_ON)] _Alpha("Alpha", Float) = 0
        _AlphaTex("Alpha贴图", 2D) = "white" {}
        _AlphaUVPanner("AlphaUV速度", Vector) = (0,0,0,0)
        [Toggle]_AlphaDistort("Alpha Distort", range(0,1)) = 1
        [Toggle]_AlphaUVXClamp("Alpha Clamp X", range(0,1)) = 0
        [Toggle]_AlphaUVYClamp("Alpha Clamp Y", range(0,1)) = 0
        [Enum(UV0,0,UV1,1)]_AlphaUV("AlphaUV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)]_AlphaChannel("AlphaUV", Float) = 3

        // Dissolve
        [Toggle(_DISSOLVE_ON)] _Dissolve("溶解开关", Float) = 0
        _DissolveTex("软溶解贴图", 2D) = "white" {}
        _DissolveIntensity("软溶解强度", Range( 0 , 2)) = 0
        _DissolveSoft("软溶解软度", Range( 0 , 2)) = 0
        _DissolveEdgeWidth("溶解描宽度", Range( 0 , 1)) = 0
        [HDR]_DissolveEdgeColor("溶解描边颜色", Color) = (1,1,1,1)
        _DissolveUVPanner("软溶解UV速度", Vector) = (0,0,0,0)
        [Enum(UV0,0,UV1,1)]_DissolveUV("DissolveUV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)]_DissolveChannel("DissolveChannel", Float) = 0

        // Gradient Dissolve
        [Toggle(_GRADIENTDISSOLVE_ON)] _GradientDissolve("GradientDissolve", Float) = 0
        _DissolveDirAndSphere("DissolveDirAndSphere", Vector) = (0,1,0,0)
        [Toggle] _InverseSphere("InverseSphere", range(0,1)) = 0
        _ObjectScale("ObjectScale", Float) = 1
        _NoiseIntensity("NoiseIntensity", Range( 0 , 1)) = 0
        _VertexOrigin("Vertex Origin", Vector) = (0,0,0,0)
        [Toggle]_DissolveDistort("DissolveDistort", range(0,1)) = 0

        // Stencil
        [Toggle]_StencilOn("StencilOn", Float) = 0
        _StencilRef("Stencil Ref", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass("Stencil Pass", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comp", Float) = 4

        // Stencil Easy
        [Toggle]_StencilEasy("StencilEasy", Float) = 0
        [Enum(Plane,0,Obj,1,Sky Box,2,Through,3,Cull,4)]_StencilMode("StencilMode", Float) = 0

        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式", Float) = 2
        
        // Depth
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("深度测试", Float) = 4
        [Enum(Off,0,On,1)]_ZWrite("深度写入", Float) = 0
        [Toggle]_PreZ("预写入深度", Float) = 0


        [Enum(UnityEngine.Rendering.ColorWriteMask)]_ColorMask("ColorMask", Float) = 15
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc("Blend Src", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDes("Blend Des", Float) = 10
        [Enum(Alpha Blend,0 ,Additive,1 ,Additive2,2 ,Soft Additive,3,Particle Additive,4,Premultiplied,5,2x Multiplicative,6)]_BlendMode("BlendMode", Float) = 0
        [Enum(Transparent,0,AlphaTest,1)]_SurfaceType("SurfaceType", Float) = 0

        [IntRange]_QueueID("QueueID", Range( -25 , 25)) = 0
        _CutOff("CutOff", Range( 0 , 1)) = 0.5

        [Toggle]_HideButtom("HideButtom", Float) = 0

        [HideInInspector]_AlphaClip("AlphaClip",Range(0,1)) = 0.5
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0
    }

    HLSLINCLUDE

    #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
    #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

    #pragma multi_compile _ _SECONDLAYER_ON

    #pragma multi_compile _ _ALPHA_ON

    #pragma multi_compile _ _DISTORT_ON

    #pragma multi_compile _ _DISSOLVE_ON _GRADIENTDISSOLVE_ON

    #pragma multi_compile _ _EFFECT_CLIP

    // #pragma fragmentoption ARB_precision_hint_fastest

    // #pragma multi_compile_particles
    #pragma exclude_renderers  d3d11_9x xbox360 xboxone ps3 ps4 psp2 
    #pragma target 3.0

    CBUFFER_START(UnityPerMaterial)
        half _Opacity;

        half _MainTexSamplerState;

        half _MainUV;
        half _SecondUV;
        half _DistortUV;
        half _GradientUV;
        half _AlphaUV;
        half _DissolveUV;

        float4 _Color;
        half4 _MainUVPanner;
        float4 _MainTex_ST;
        half   _MainUVDistort;
        half   _MainUVXClamp;
        half   _MainUVYClamp;

        float4 _SecondTex_ST;
        float4 _SecondColor;
        half   _SecondColorBlend;
        half4 _SecondUVPanner;
        half   _SecondDistort;
        half   _SecondUVXClamp;
        half   _SecondUVYClamp;

        half   _Rim;
        half   _RimPower;
        float4 _RimColor;
        half   _RimPower2;
        float4 _RimColor2;

        half   _CustomData;

        float4 _DistortionTex_ST;
        half2  _DistortUVPanner;
        half   _DistortionIntensity;
        half   _DistortChannel;

        float4 _GradientColor;
        float4 _GradientTex_ST;
        half2  _GradientUVPanner;
        half   _GradientDistort;
        half   _GradientUVXClamp;
        half   _GradientUVYClamp;

        float4 _AlphaTex_ST;
        half4  _AlphaUVPanner;
        half   _AlphaDistort;
        half   _AlphaUVXClamp;
        half   _AlphaUVYClamp;
        half  _AlphaChannel;

        float4 _DissolveTex_ST;
        float4 _DissolveEdgeColor;
        half2  _DissolveUVPanner;
        half4  _DissolveDirAndSphere;
        half   _DissolveEdgeWidth;
        half   _DissolveSoft;
        half   _DissolveIntensity;
        half _DissolveChannel;

        half   _DissolveDistort;

        half3  _VertexOrigin;
        half   _ObjectScale;
        half   _NoiseIntensity;
        half   _InverseSphere;

        half _CutOff;

        half _StencilRef;
        half _StencilPass;
        half _StencilComp;

        half _BlendSrc;
        half _BlendDes;

        half _ZTest;
        half _ZWrite;
        
        half _Cull;

        half _ColorMask;
        half _AlphaEnhance;
    CBUFFER_END
    
    TEXTURE2D(_MainTex);
    TEXTURE2D(_SecondTex);
    TEXTURE2D(_DistortionTex);
    TEXTURE2D(_DissolveTex);
    TEXTURE2D(_AlphaTex);

    struct Attributes
    {
        float4 positionOS       : POSITION;
        float4 vertexColor      : COLOR;
        float3 normalCS         : NORMAL;
        
        float4 uv0              : TEXCOORD0;    // uv0;custom data1 xy
        float4 uv1              : TEXCOORD1;    // uv1;custom data1 xy
        float4 customdata1      : TEXCOORD2;    // custom data1 zw;custom data2 xy
        float2 customdata2      : TEXCOORD3;    // custom data2 zw
    };
    
    struct Varyings
    {
        float4 positionCS           : SV_POSITION;
        float4 vertexColor          : TEXCOORD0;

        float4 positionWS           : TEXCOORD1;
        float4 normalWS             : TEXCOORD2;
        float3 customdata           : TEXCOORD3; //customData2.y/z/w

        #if defined(_SECONDLAYER_ON)
            float4 uv               : TEXCOORD4;
        #else
            float2 uv               : TEXCOORD4;
        #endif

        #if defined(_DISTORT_ON) || defined(_DISSOLVE_ON) || defined(_GRADIENTDISSOLVE_ON)
            float4 uv1              : TEXCOORD5;
        #endif

        #if defined(_ALPHA_ON)
            float2 uv2              : TEXCOORD6;
        #endif
    };

    #if defined(_DISSOLVE_ON) || defined(_GRADIENTDISSOLVE_ON)
        void Dissolve(Varyings i,float2 uv,inout float3 color,inout half alpha)
        {
            half4 dissolve_tex = SAMPLE_TEXTURE2D(_DissolveTex,sampler_LinearRepeat,uv);

            half dissolve_map = 0;
            if(_DissolveChannel > 1.5)
            dissolve_map = lerp(dissolve_tex.b,dissolve_tex.a,_DissolveChannel - 2);
            else
            dissolve_map = lerp(dissolve_tex.r,dissolve_tex.g,_DissolveChannel);

            half dissolveIntensity = _DissolveIntensity + i.customdata.y * _CustomData;

            #if defined(_GRADIENTDISSOLVE_ON)
                float3 worldPos_pivol = float3(i.positionWS.w,i.normalWS.w,i.customdata.z);
                DissolveGradientSphere(
                dissolve_map,dissolveIntensity,_DissolveSoft,_DissolveEdgeWidth,_DissolveEdgeColor.rgb,
                _DissolveDirAndSphere,i.positionWS.xyz,worldPos_pivol,_VertexOrigin,_NoiseIntensity,_ObjectScale,_InverseSphere,color,alpha);
            #else 
                DissolveSimple(dissolve_map,dissolveIntensity,_DissolveSoft,_DissolveEdgeWidth,_DissolveEdgeColor.rgb,color,alpha);
            #endif
        }
    #endif 

    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalRenderPipline"
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "IgnoreProjector"="True"
        }

        Pass
        {
            Name "Effect PrePass"
            Tags { "LightMode"="SGameShadowPassTrans" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert_preZ
            #pragma fragment frag_preZ

            Varyings vert_preZ( Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half frag_preZ(Varyings i):SV_TARGET
            {
                return 1;
            }

            ENDHLSL
        }

        Pass
        {
            Name "Effect Forward"
            Tags { "LightMode"="UniversalForward" }
            
            Cull  [_Cull]

            Blend [_BlendSrc] [_BlendDes], One OneMinusSrcAlpha

            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Fog   { Mode Off }

            Offset  -1, 1

            // Stencil
            // {
                //     Ref [_StencilRef]
                //     Comp [_StencilComp]
                //     Pass [_StencilPass]
                //     Fail Keep
                //     ZFail Keep
            // }

            ColorMask [_ColorMask]
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            Varyings vert( Attributes v)
            {
                Varyings o = (Varyings)0;

                o.normalWS.xyz = TransformObjectToWorldNormal(v.normalCS);
                o.vertexColor = v.vertexColor * _Color;
                o.vertexColor.a *= _AlphaEnhance;

                o.customdata.xy = v.customdata2.xy;
                
                o.positionWS.xyz = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS     = TransformWorldToHClip(o.positionWS.xyz);

                float2 uv0 = v.uv0.xy;
                float2 uv1 = v.uv1.xy;

                // Main Tex UV
                {
                    float2 main_uv = TRANSFORM_TEX(lerp(uv0,uv1,_MainUV),_MainTex) + frac(_MainUVPanner.xy * _Time.y) + v.uv1.zw * _CustomData;  
                    o.uv.xy = RotateUV(main_uv, _MainUVPanner.z + _MainUVPanner.w * _Time.y);
                }
                
                // Second Tex UV
                #if defined(_SECONDLAYER_ON)
                    float2 second_uv = TRANSFORM_TEX(lerp(uv0,uv1,_SecondUV),_SecondTex) + frac(_SecondUVPanner.xy * _Time.y) + v.customdata1.xy * _CustomData;         
                    o.uv.zw = RotateUV(second_uv,_SecondUVPanner.z + _SecondUVPanner.w * _Time.y);
                #endif
                
                // Distort UV
                #if defined(_DISTORT_ON)
                    o.uv1.xy = TRANSFORM_TEX(lerp(uv0,uv1,_DistortUV),_DistortionTex) + frac(_DistortUVPanner.xy * _Time.y);
                #endif

                // Dissolve UV
                #if defined(_DISSOLVE_ON) || defined(_GRADIENTDISSOLVE_ON)
                    o.uv1.zw = TRANSFORM_TEX(lerp(uv0,uv1,_DissolveUV),_DissolveTex) + frac(_DissolveUVPanner.xy * _Time.y);
                    float3 worldPos_pivol = TransformObjectToWorld(float3(0,0,0));
                    o.positionWS.w = worldPos_pivol.x;
                    o.normalWS.w   = worldPos_pivol.y;
                    o.customdata.z = worldPos_pivol.z;
                #endif

                // Alpha UV
                #if defined(_ALPHA_ON)
                    float2 alpha_uv = TRANSFORM_TEX(lerp(uv0,uv1,_AlphaUV),_AlphaTex) + frac(_AlphaUVPanner.xy * _Time.y) + v.customdata1.zw * _CustomData;
                    o.uv2.xy = RotateUV(alpha_uv, _AlphaUVPanner.z + _AlphaUVPanner.w * _Time.y);
                #endif

                return o;
            }

            float4 frag(Varyings i,half facing : VFACE):SV_TARGET
            {
                // Distort
                #if defined(_DISTORT_ON)
                    half4 distort_tex = SAMPLE_TEXTURE2D(_DistortionTex,sampler_LinearRepeat,i.uv1.xy);
                    half distort = 0;
                    if(_DistortChannel > 1.5)
                    distort = lerp(distort_tex.b,distort_tex.a,_DistortChannel - 2) * (_DistortionIntensity + i.customdata.x * _CustomData);
                    else
                    distort = lerp(distort_tex.r,distort_tex.g,_DistortChannel) * (_DistortionIntensity + i.customdata.x * _CustomData);
                #endif 

                // Main Layer
                float2 main_uv = i.uv.xy;
                #if defined(_DISTORT_ON)
                    main_uv += distort * _MainUVDistort;                                        // Distort
                #endif 
                main_uv = lerp(main_uv,ClampUV(main_uv),half2(_MainUVXClamp,_MainUVYClamp));    // Clamp

                float4 final_color = SAMPLE_TEXTURE2D(_MainTex,sampler_LinearRepeat,main_uv) * i.vertexColor;

                half alpha = final_color.a * _Opacity;

                // Alpha
                #if defined(_ALPHA_ON)
                    float2 alpha_uv = i.uv2.xy;
                    #if defined(_DISTORT_ON)
                        alpha_uv += distort * _AlphaDistort;
                    #endif 
                    alpha_uv = lerp(alpha_uv,ClampUV(alpha_uv),half2(_AlphaUVXClamp,_AlphaUVYClamp));

                    half4 alpha_map = SAMPLE_TEXTURE2D(_AlphaTex,sampler_LinearRepeat,alpha_uv);
                    half final_alpha_map = 0;
                    if(_AlphaChannel > 1.5)
                    final_alpha_map = lerp(alpha_map.b,alpha_map.a,_AlphaChannel - 2);
                    else
                    final_alpha_map = lerp(alpha_map.r,alpha_map.g,_AlphaChannel);

                    alpha *= final_alpha_map;
                #endif

                // Second Layer
                #if defined(_SECONDLAYER_ON)
                    float2 second_uv = i.uv.zw;
                    #if defined(_DISTORT_ON)
                        second_uv += distort * _SecondDistort;
                    #endif 
                    second_uv = lerp(second_uv,ClampUV(second_uv),half2(_SecondUVXClamp,_SecondUVYClamp));
                    float4 second_color = SAMPLE_TEXTURE2D(_SecondTex,sampler_LinearRepeat,second_uv) * _SecondColor;
                    final_color = BlendColor(_SecondColorBlend,final_color,second_color);
                #endif

                // Dissolve
                #if defined(_DISSOLVE_ON) || defined(_GRADIENTDISSOLVE_ON)
                    float2 dissolve_uv = i.uv1.zw;
                    #if defined(_DISTORT_ON)
                        dissolve_uv += distort * _DissolveDistort;
                    #endif 
                    Dissolve(i,dissolve_uv,final_color.rgb,alpha);
                #endif

                // Rim
                if(_Rim > 0.5)
                {
                    half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                    half3 N = normalize(i.normalWS.xyz);

                    // float4 rim_color = FresnelSimple(N,V,_RimColor,_RimPower,facing,_Cull);
                    float4 rim_color = DoubleFresnel(N,V,_RimPower,_RimColor,_RimPower2,_RimColor2,facing,_Cull);
                    final_color.rgb += rim_color.rgb * rim_color.a;
                }

                // Alpha Clip
                #if defined(_EFFECT_CLIP)
                    clip(alpha - _CutOff);
                #endif

                // Handle Blend One One
                half isOneOne = _BlendSrc == 1.0 && _BlendDes == 1.0;
                final_color.rgb *= isOneOne ? alpha : 1;
                alpha = isOneOne ? 1 : saturate(alpha);

                return float4(final_color.rgb,alpha);
            }
            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.SGameUberEffectGUI"
}