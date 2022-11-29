Shader "FB/Particle/CustomDataUV"
{
    Properties
    {

        [Header(Blend Mode)]
        [HideInInspector] _simpleUI("SimpleUI", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层1 ，one one 是ADD", int) = 6
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend", int) = 1
        [Header(Cull Mode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0
        [Header(ZTest Mode)]
        [Enum(LEqual, 4, Always, 8)]_ZAlways("层级显示：LEqual默认层级，Always永远在最上层", int) = 4
        //[Enum(UnityEngine.Rendering.CompareFunction)]_ZAlways ("层级显示：LEqual默认层级，Always永远在最上层", int) = 4
        [HideInInspector]_ZTest("ZTest", int) = 0
        [HideInInspector]_Blend("Blend", int) = 0
        [HideInInspector]_Cull("Cull", int) = 0
        [Space(25)]
        _Intensity("整体亮度Intensity", int) = 1
        [HDR]_Color("颜色Color", Color) = (1, 1, 1, 1)

         //Maintex
        [Space(15)]
        [MaterialToggle]_RotatorToggle("开启旋转缩放(主纹理)", int) = 0
        _RotatorAngle("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleX("缩 放", Range(0, 10)) = 1
        _TextureScaleY("缩 放", Range(0, 10)) = 1
        [NoScaleOffset][MainTexture]_MainTex("主贴图MainTex", 2D) = "white" {} //
        _MainTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0 //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        [MaterialToggle]_ToggleCustom("开启 Custom Data 开关", int) = 0

        //Mask
        [Space(25)]
        [KeywordEnum(Off,On,RgbNotAlpha,RNotAlpha,GNotAlpha,BNotAlpha)] _MaskEnable("遮罩WrapMode",Int) = 0
        [MaterialToggle]_RotatorToggleMask("开启旋转缩放(遮罩)", int) = 0
        _RotatorAngleMask("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleXMask("缩 放", Range(0, 10)) = 1
        _TextureScaleYMask("缩 放", Range(0, 10)) = 1
        [NoScaleOffset]_MaskTex("遮罩贴图 MaskTex", 2D) = "white" {}
        _MaskTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        [MaterialToggle(USINGPOLARMASK)]_PolarEnableMask("遮罩贴图是否启用极坐标", int) = 0
        _uvMSpeedX("遮罩uv流速X", int) = 0
        _uvMSpeedY("遮罩uv流速Y", int) = 0
        _MaskAngle("遮罩贴图旋转",Range(-180,180)) = 0


        //Distort
        [Space(25)]
        [MaterialToggle(DISTORTENABLE)]_DistortEnable("是否启用扭曲", int) = 0
        [NoScaleOffset]_DistortTex("扭曲贴图 DistortTex", 2D) = "white" { }
        _DistortTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        [MaterialToggle(USINGPOLARDISTORT)]_PolarEnableDistort("扭曲贴图是否启用极坐标", int) = 0
        _uvDistortSpeedX("扭曲uv流速X", float) = 0.1
        _uvDistortSpeedY("扭曲uv流速Y", float) = 0.1
        _DistortMapAngle("扭曲贴图旋转",Range(-180,180)) = 90
        _Distort("扭曲强度", Range(0, 5)) = 0.8

        //溶解
        [Space(25)]
        [MaterialToggle(_DISSOLVE_ON)]DissolveOn("是否启用溶解", int) = 0
        [NoScaleOffset]_DissolveTex("溶解贴图 DissolveTex", 2D) = "white" { }
        _DissolveTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _DissolveTex_BlendFilter("DissolveTex 通道过滤", Color) = (1, 0, 0, 1)
        [HDR]_DissolveColor1("dissolveColor1",color) = (1,0,0,1)
        [HDR]_DissolveColor2("dissolveColor2",color) = (0,0,0,1)
        [HideInInspector]_DissolveTexClamp("DissolveTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DissolveTexRepeatU("DissolveTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DissolveTexRepeatV("DissolveTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        [MaterialToggle(USINGPOLARDISSOLVE)]_PolarEnableDissolve("溶解贴图是否启用极坐标", int) = 0
        _DissolveMapAngle("扭曲贴图旋转角度",Range(0, 360)) = 0
        _uvDissolveSpeeyX("溶解贴图uv流速X", float) = 0.1
        _uvDissolveSpeeyY("溶解贴图uv流速Y", float) = 0.1
        _Dissolve("dissolveValue", Range(0, 1.2)) = 0
        _DissolveRange("Dissolve Range", Range(0, 10)) = 0
        [HideInInspector]_Opacity("Opacity", float) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" }
        Blend[_SrcBlend][_DestBlend]
        Cull[_CullMode]
        ZWrite Off
        ZTest[_ZAlways]

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest

            //两种shader_feature写法 ,对应属性的 MaterialToggle
            #pragma multi_compile _ _MASKENABLE_ON _MASKENABLE_RGBNOTALPHA _MASKENABLE_RNOTALPHA _MASKENABLE_GNOTALPHA _MASKENABLE_BNOTALPHA
            #pragma multi_compile _ DISTORTENABLE
            #pragma multi_compile _ USINGPOLARDISTORT
            #pragma multi_compile _ USINGPOLARDISSOLVE
            #pragma multi_compile _ USINGPOLARMASK
            #pragma multi_compile _ _DISSOLVE_ON
            #pragma multi_compile_instancing
            #pragma multi_compile_particles
            
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex); SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DistortTex); SAMPLER(sampler_DistortTex);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);

            CBUFFER_START(UnityPerMaterial)

            float4 _MainTex_ST, _MaskTex_ST, _DistortTex_ST, _DissolveTex_ST;
            half _DistortEnable, _MaskEnable;

            CBUFFER_END

            UNITY_INSTANCING_BUFFER_START(Props)

                UNITY_DEFINE_INSTANCED_PROP(half, _Intensity)
                UNITY_DEFINE_INSTANCED_PROP(half, _Opacity)

                UNITY_DEFINE_INSTANCED_PROP(float4, _MaskTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, _MaskTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _MaskTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _MaskTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorToggleMask)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorAngleMask)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleXMask)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleYMask)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvMSpeedX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvMSpeedY)

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorAngle)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorToggle)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleX)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleY)
                UNITY_DEFINE_INSTANCED_PROP(half, _MaskAngle)
                UNITY_DEFINE_INSTANCED_PROP(half, _PolarEnableMask)
                UNITY_DEFINE_INSTANCED_PROP(half, _ToggleCustom)

                
                //UNITY_DEFINE_INSTANCED_PROP(half, _uvSpeeyX)
                //UNITY_DEFINE_INSTANCED_PROP(half, _uvSpeeyY)

                UNITY_DEFINE_INSTANCED_PROP(float4, _DistortTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(half, _Distort)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDistortSpeedX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDistortSpeedY)
                UNITY_DEFINE_INSTANCED_PROP(half, _PolarEnableDistort)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortMapAngle)
                

                UNITY_DEFINE_INSTANCED_PROP(float4, _DissolveTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDissolveSpeeyX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDissolveSpeeyY)
                UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveTex_BlendFilter)
                UNITY_DEFINE_INSTANCED_PROP(half, _Dissolve)
                UNITY_DEFINE_INSTANCED_PROP(half, _DissolveRange)
                UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveColor1)
                UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveColor2)
                UNITY_DEFINE_INSTANCED_PROP(half,_DissolveMapAngle);
                UNITY_DEFINE_INSTANCED_PROP(half,_PolarEnableDissolve);
                

            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex: POSITION;
                float4 vertexColor: COLOR;
                float4 uv: TEXCOORD0;
                float4 customDataP: TEXCOORD1;
            };

            struct v2f
            {
                //#if defined(_DISSOLVE_ON)
                    float4 uv: TEXCOORD0;
                // #else
                //     float2 uv: TEXCOORD0;
                // #endif

                float4 positionCS: SV_POSITION;
                float4 uv2: TEXCOORD1;
                float4 vertexColor: COLOR;
                
                float dissolveCustomData : TEXCOORD2;
                float distortCustomData : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD3;
                    float3 normalWS : TEXCOORD4;
                #endif
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertexColor = v.vertexColor;
                float2 customData1 = v.uv.zw;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
               
                float _RotatorAngle_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorAngle);
                float _RotatorToggle_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorToggle);
                float _TextureScaleX_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleX);
                float _TextureScaleY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleY);
                float2 toggle = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngle_Value, float2(_TextureScaleX_Value, _TextureScaleY_Value)), _RotatorToggle_Value);
                half _ToggleCustom_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _ToggleCustom);

                float4 _MainTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MainTex_TilingOffset);
                o.uv.xy = UVTilingOffset(toggle, _MainTex_TilingOffset_Value) + lerp(0, customData1, _ToggleCustom_Value);
                o.dissolveCustomData = v.customDataP.z;
                o.distortCustomData  = v.customDataP.w;

                #if defined(DISTORTENABLE)
                    float4 _DistortTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTex_TilingOffset);
                    o.uv2.xy = UVTilingOffset(v.uv.xy, _DistortTex_TilingOffset_Value);
                #endif
                #if _MASKENABLE_RGBNOTALPHA | _MASKENABLE_ON | _MASKENABLE_RNOTALPHA | _MASKENABLE_GNOTALPHA | _MASKENABLE_BNOTALPHA
                    float _RotatorToggleMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorToggleMask);
                    float _RotatorAngleMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorAngleMask);
                    float _TextureScaleXMask_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleXMask);
                    float _TextureScaleYMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleYMask);
                    float2 toggleMask = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngleMask_Value, float2(_TextureScaleXMask_Value, _TextureScaleYMask_Value)), _RotatorToggleMask_Value);
                    
                    float4 _MaskTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTex_TilingOffset);
                    o.uv2.zw = UVTilingOffset(toggleMask, _MaskTex_TilingOffset_Value);
                #endif
                #if defined(_DISSOLVE_ON)
                    float4 _DissolveTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveTex_TilingOffset);
                    o.uv.zw = UVTilingOffset(v.uv.xy, _DissolveTex_TilingOffset_Value);
                #endif
                #if defined(UNITY_INSTANCING_ENABLED)
                    o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                #endif
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float2 distort = i.uv.xy;

                //  distort
                #if defined(DISTORTENABLE)
                    half _uvDistortSpeedX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvDistortSpeedX);
                    half _uvDistortSpeedY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvDistortSpeedY);

                    
                    half _DistortTexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexClamp);
                    half _DistortTexRepeatU_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexRepeatU);
                    half _DistortTexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexRepeatV);
                    half2 _uvDistortSpeedValue = half2(_uvDistortSpeedX_Value,_uvDistortSpeedY_Value);
                    float2 uvDistort = GetUV(i.uv2.xy, _DistortTexClamp_Value, _DistortTexRepeatU_Value, _DistortTexRepeatV_Value, _DistortTex_ST);
                    
                    float2 flowUV = toPolar(uvDistort,_uvDistortSpeedValue,_DistortMapAngle,_PolarEnableDistort);
                    //#endif
                    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, flowUV);
                    
                    half _Distort_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Distort);

                    distort = ((_Distort_Value + i.distortCustomData) * 0.5 * distortTex.xy) + i.uv.xy;
                #endif

                //  main
                half _MainTexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexClamp);
                half _MainTexRepeatU_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexRepeatU);
                half _MainTexRepeatV_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexRepeatV);
                float2 uvMain = GetUV(distort, _MainTexClamp_Value, _MainTexRepeatU_Value, _MainTexRepeatV_Value, _MainTex_ST);
                half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                maintex = GetTextColor(maintex, uvMain, _MainTexRepeatU_Value, _MainTexRepeatV_Value);
                half _Intensity_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Intensity);
                half4 _Color_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                half3 c = _Color_Value.rgb * i.vertexColor.rgb * _Intensity_Value * maintex.rgb;
                half alpha = _Color_Value.a * i.vertexColor.a * maintex.a;

                half _MaskTexClamp_Value   = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Value  = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Value, _MaskTex_ST);

                half _uvMSpeedX_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedX);
                half _uvMSpeedY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedY);
                half2 _uvMSpeed_Value = half2(_uvMSpeedX_Value,_uvMSpeedY_Value);
                float2 tempuvMask = toPolar(uvMask,_uvMSpeed_Value,_MaskAngle,_PolarEnableMask);
                //uvMask = tempuvMask;

                //  mask
                /*
                half _MaskTexClamp_Value   = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Value  = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);

                half _uvMSpeedX_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedX);
                half _uvMSpeedY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedY);
                half2 _uvMSpeed_Value = half2(_uvMSpeedX_Value,_uvMSpeedY_Value);

                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Value, _MaskTex_ST);
                float2 tempuvMask = toPolar(uvMask,_uvMSpeed_Value,_MaskAngle,_PolarEnableMask);*/

                //遮罩贴图采样
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, tempuvMask);

                //默认遮罩颜色
                half4 maskColor = half4(1,1,1,1);
                
                #if defined(_MASKENABLE_ON)
                    maskColor = mask;
                #elif _MASKENABLE_RGBNOTALPHA
                    maskColor.rgb = mask.rgb;
                    maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                #elif _MASKENABLE_RNOTALPHA
                    maskColor = half4(mask.r, mask.r, mask.r, mask.r);
                    maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                #elif _MASKENABLE_GNOTALPHA
                    maskColor = half4(mask.g, mask.g, mask.g, mask.g);
                    maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                #elif _MASKENABLE_BNOTALPHA
                    maskColor = half4(mask.b, mask.b, mask.b, mask.b);
                    maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                #endif
                    c *= maskColor.rgb;
                    alpha *= maskColor.a;
                
                    //溶解
                #if defined(_DISSOLVE_ON)
                    half _uvDissolveSpeedX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvDissolveSpeeyX);
                    half _uvDissolveSpeedY_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvDissolveSpeeyY);
                    half2 _UVDissSpeed_Value = half2(_uvDissolveSpeedX_Value,_uvDissolveSpeedY_Value);

                    half _DissolveTexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveTexClamp);
                    half _DissolveTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveTexRepeatU);
                    half _DissolveTexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveTexRepeatV);
                    float2 uvDissolve = GetUV(i.uv.zw, _DissolveTexClamp_Value, _DissolveTexRepeatU_Value, _DissolveTexRepeatV_Value, _DissolveTex_ST);
                    
                    float2 tempuvDissolve = toPolar(uvDissolve,_UVDissSpeed_Value,_DissolveMapAngle,_PolarEnableDissolve);

                    half4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, tempuvDissolve);
                    //dissolvetex = GetTextColor(dissolvetex, uvDissolve, _DissolveTexRepeatU, _DissolveTexRepeatV);
                    //
                    float4 _DissolveTex_BlendFilter_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveTex_BlendFilter);
                    half dissolveAlpha = dot(dissolvetex.rgb, _DissolveTex_BlendFilter_Value.rgb);
                    half _Dissolve_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Dissolve);

                    _Dissolve_Value = _Dissolve_Value + i.dissolveCustomData;

                    float clipValue = dissolveAlpha - _Dissolve_Value*1.8+0.1;
                    alpha *= smoothstep(0.001, 0.1, clipValue);
                    half _DissolveRange_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveRange);
                    clipValue = clamp(clipValue * _DissolveRange_Value, 0, 1);
                    half4 _DissolveColor1_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveColor1);
                    half4 _DissolveColor2_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveColor2);
                    half4 dissColor = lerp(_DissolveColor1_Value, _DissolveColor2_Value, smoothstep(0.15, 1, clipValue));
                    clipValue = clamp(clipValue + step(_Dissolve_Value, 0.001), 0, 1);
                    c.rgb = lerp(dissColor + c, c, clipValue).rgb;
                #endif
                half _Opacity_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Opacity);
                alpha = saturate(alpha) * _Opacity_Value;
                c *= alpha;

                return half4(c, alpha);
            }
            ENDHLSL
        }
    }

}
