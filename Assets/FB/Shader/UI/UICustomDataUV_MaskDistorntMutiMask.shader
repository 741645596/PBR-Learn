Shader "FB/UI/U_MaskDistorntMutiMask"
{
    Properties
    {
        [Header(Blend Mode)]
        [HideInInspector] _simpleUI ("SimpleUI", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("混合层1 ，one one 是ADD", int) = 6
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend ("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend", int) = 10
        [Header(Cull Mode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0
        [Header(ZTest Mode)]
        [Enum(LEqual, 4, Always, 8)]_ZAlways ("层级显示：LEqual默认层级，Always永远在最上层", int) = 4
        //[Enum(UnityEngine.Rendering.CompareFunction)]_ZAlways ("层级显示：LEqual默认层级，Always永远在最上层", int) = 4
        [HideInInspector]_ZTest ("ZTest", int) = 0
        [HideInInspector]_Blend ("Blend", int) = 0
        [HideInInspector]_Cull ("Cull", int) = 0

        [Space(25)]
        _Intensity ("整体亮度Intensity", int) = 1
        [HDR]_Color ("颜色Color", Color) = (1, 1, 1, 1) //
        [Space(15)] //Maintex
        [MaterialToggle]_RotatorToggle("开启旋转缩放(主纹理)", int) = 0
        _RotatorAngle("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleX("缩 放", Range(0, 10)) = 1
        _TextureScaleY("缩 放", Range(0, 10)) = 1
        [NoScaleOffset][MainTexture]_MainTex ("主贴图MainTex", 2D) = "white" { }
        _MainTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0 //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvSpeeyX ("主贴图uv流速X", int) = 0
        _uvSpeeyY ("主贴图uv流速Y", int) = 0
        
        [Space(25)]  //Mask
        //[Toggle]_MaskEnable ("是否启用Mask", int) = 0
        [KeywordEnum(Off,On,RgbNotAlpha,RNotAlpha,GNotAlpha,BNotAlpha)] _MaskEnable("遮罩WrapMode",Int) = 0

        [MaterialToggle]_RotatorToggleMask("开启旋转缩放(遮罩)", int) = 0
        _RotatorAngleMask("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleXMask("缩 放", Range(0, 10)) = 1
        _TextureScaleYMask("缩 放", Range(0, 10)) = 1

        [NoScaleOffset]_MaskTex ("遮罩贴图 MaskTex", 2D) = "white" { }
        _MaskTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvMSpeedX ("遮罩uv流速X", int) = 0
        _uvMSpeedY ("遮罩uv流速Y", int) = 0

        [Space(25)] //Mask2

        [MaterialToggle]_RotatorToggleMask2("2开启旋转缩放(遮罩)", int) = 0
        _RotatorAngleMask2("2旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleXMask2("2缩 放", Range(0, 10)) = 1
        _TextureScaleYMask2("2缩 放", Range(0, 10)) = 1

        [NoScaleOffset]_Mask2Tex("2遮罩贴图 MaskTex", 2D) = "white" { }
        _Mask2Tex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_Mask2TexClamp("2MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_Mask2TexRepeatU("2MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_Mask2TexRepeatV("2MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvM2SpeedX("2遮罩uv流速X", int) = 0
        _uvM2SpeedY("2遮罩uv流速Y", int) = 0

        [Space(25)] //Distort
        [MaterialToggle(DISTORTENABLE)]_DistortEnable ("是否启用扭曲", int) = 0
        [NoScaleOffset]_DistortTex ("扭曲贴图 DistortTex", 2D) = "white" { }
        _DistortTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvDistortSpeedX ("扭曲uv流速X", int) = 0
        _uvDistortSpeedY ("扭曲uv流速Y", int) = 0
        _Distort ("扭曲强度", Range(0, 5)) = 0.8

        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline"
         "Queue" = "Transparent" 
         "IgnoreProjector" = "True" 
         
         }
        Blend [_SrcBlend] [_DestBlend]
        Cull [_CullMode]
        ZWrite Off
        ZTest [_ZAlways]
        
        Pass
        {
            Tags {
            "LightMode" = "Default UI RP"
            }
            //AlphaToMask On
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            //两种shader_feature写法 ,对应属性的 MaterialToggle
            #pragma multi_compile _ _MASKENABLE_ON _MASKENABLE_RGBNOTALPHA _MASKENABLE_RNOTALPHA _MASKENABLE_GNOTALPHA _MASKENABLE_BNOTALPHA
            #pragma multi_compile _ DISTORTENABLE
            #pragma multi_compile_instancing 
            #pragma multi_compile_particles
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex); SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DistortTex); SAMPLER(sampler_DistortTex);
            TEXTURE2D(_Mask2Tex); SAMPLER(sampler_Mask2Tex);
            //TEXTURE2D(_Mask3Tex); SAMPLER(sampler_Mask3Tex);
            
            CBUFFER_START(UnityPerMaterial)

            //float4 _MainTex_ST, _MaskTex_ST, _DistortTex_ST, _Mask2Tex_ST;//_Mask3Tex_ST;
            half  _DistortEnable, _MaskEnable;

            CBUFFER_END

            UNITY_INSTANCING_BUFFER_START(Props)

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


                UNITY_DEFINE_INSTANCED_PROP(float4, _Mask2Tex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, _Mask2TexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _Mask2TexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _Mask2TexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvM2SpeedX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvM2SpeedY)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorToggleMask2)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorAngleMask2)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleXMask2)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleYMask2)

                UNITY_DEFINE_INSTANCED_PROP(int, _Intensity)
                UNITY_DEFINE_INSTANCED_PROP(half, _Opacity)

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorAngle)
                UNITY_DEFINE_INSTANCED_PROP(float, _RotatorToggle)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleX)
                UNITY_DEFINE_INSTANCED_PROP(float, _TextureScaleY)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _MainTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvSpeeyX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvSpeeyY)

                UNITY_DEFINE_INSTANCED_PROP(float4, _DistortTex_TilingOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexClamp)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexRepeatU)
                UNITY_DEFINE_INSTANCED_PROP(half, _DistortTexRepeatV)
                UNITY_DEFINE_INSTANCED_PROP(half, _Distort)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDistortSpeedX)
                UNITY_DEFINE_INSTANCED_PROP(half, _uvDistortSpeedY)


            UNITY_INSTANCING_BUFFER_END(Props)
            
            struct appdata
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float4 vertexColor: COLOR;
                float4 customDataP: TEXCOORD1;
            };
            
            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                float4 uv2: TEXCOORD1;
                float4 vertexColor: COLOR;

                float4 uvMutiMask: TEXCOORD3;

                UNITY_VERTEX_INPUT_INSTANCE_ID
#if defined(UNITY_INSTANCING_ENABLED)
                float3 vertexSH : TEXCOORD4;
                float3  normalWS : TEXCOORD5;
#endif
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertexColor = v.vertexColor;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                //rotator
                float _RotatorAngle_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorAngle);
                float _RotatorToggle_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorToggle);
                float _TextureScaleX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleX);
                float _TextureScaleY_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleY);
                float2 toggle = lerp(v.uv, UvRotatorAngle(v.uv.xy, _RotatorAngle_Value, float2(_TextureScaleX_Value, _TextureScaleY_Value)), _RotatorToggle_Value);
                half _uvSpeeyX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvSpeeyX);
                half _uvSpeeyY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvSpeeyY);

                float4 _MainTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MainTex_TilingOffset);
                o.uv.xy = UVTilingOffset(toggle, _MainTex_TilingOffset_Value) + float2(_uvSpeeyX_Value, _uvSpeeyY_Value) * _Time.g;
                
                #if DISTORTENABLE
                    half _uvDistortSpeedX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvDistortSpeedX);
                    half _uvDistortSpeedY_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvDistortSpeedY);
                    float4 _DistortTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTex_TilingOffset);
                    o.uv2.xy = UVTilingOffset(v.uv, _DistortTex_TilingOffset_Value) + float2(_uvDistortSpeedX_Value, _uvDistortSpeedY_Value) * _Time.g;
                #endif
                #if _MASKENABLE_RGBNOTALPHA | _MASKENABLE_ON | _MASKENABLE_RNOTALPHA | _MASKENABLE_GNOTALPHA | _MASKENABLE_BNOTALPHA
                    float _RotatorToggleMask_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorToggleMask);
                    float _RotatorAngleMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorAngleMask);
                    float _TextureScaleXMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleXMask);
                    float _TextureScaleYMask_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleYMask);
                    float2 toggleMask = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngleMask_Value, float2(_TextureScaleXMask_Value, _TextureScaleYMask_Value)), _RotatorToggleMask_Value);
                    half _uvMSpeedX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedX);
                    half _uvMSpeedY_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvMSpeedY);
                    float4 _MaskTex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTex_TilingOffset);
                    o.uv2.zw = UVTilingOffset(toggleMask, _MaskTex_TilingOffset_Value) + float2(_uvMSpeedX_Value, _uvMSpeedY_Value) * _Time.g;
                    float _RotatorToggleMask2_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorToggleMask2);
                    float _RotatorAngleMask2_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _RotatorAngleMask2);
                    float _TextureScaleXMask2_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleXMask2);
                    float _TextureScaleYMask2_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureScaleYMask2);
                    float2 toggleMask2 = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngleMask2_Value, float2(_TextureScaleXMask2_Value, _TextureScaleYMask2_Value)), _RotatorToggleMask2_Value);
                    half _uvM2SpeedX_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _uvM2SpeedX);
                    half _uvM2SpeedY_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _uvM2SpeedY);
                    float4 _Mask2Tex_TilingOffset_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2Tex_TilingOffset);
                    o.uvMutiMask.xy = UVTilingOffset(toggleMask2, _Mask2Tex_TilingOffset_Value) + float2(_uvM2SpeedX_Value, _uvM2SpeedY_Value) * _Time.g;

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
                #if DISTORTENABLE
                    half _DistortTexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexClamp);
                    half _DistortTexRepeatU_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexRepeatU);
                    half _DistortTexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _DistortTexRepeatV);
                    float2 uvDistort = GetUV(i.uv2.xy, _DistortTexClamp_Value, _DistortTexRepeatU_Value, _DistortTexRepeatV_Value, _DistortTex_TilingOffset);
                    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, uvDistort);
                    half _Distort_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Distort);
                    //distortTex = GetTextColor(distortTex, uvDistort, _DistortTexRepeatU, _DistortTexRepeatV);
                    distort = (_Distort_Value * 0.5 * distortTex.xy) + i.uv.xy;
                #endif

                //  main
                half _MainTexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexClamp);
                half _MainTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexRepeatU);
                half _MainTexRepeatV_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MainTexRepeatV);
                float2 uvMain = GetUV(distort, _MainTexClamp_Value, _MainTexRepeatU_Value, _MainTexRepeatV_Value, _MainTex_TilingOffset);
                half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                //maintex = GetTextColor(maintex,uvMain, _MainTexRepeatU, _MainTexRepeatV);
                float4 _Color_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                int _Intensity_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Intensity);
                half3 c = _Color_Value.rgb * i.vertexColor.rgb * _Intensity_Value * maintex.rgb  ;
                half alpha = _Color_Value.a * i.vertexColor.a * maintex.a;

                //  mask
                //计算颜色
                half4 maskColor = half4(1, 1, 1, 1);
#ifdef _MASKENABLE_ON
                half _MaskTexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Vlue= UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Vlue, _MaskTex_TilingOffset);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = mask;
                c *= maskColor.rgb;
                alpha *= maskColor.a;

                half _Mask2TexClamp_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexClamp);
                half _Mask2TexRepeatU_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatU);
                half _Mask2TexRepeatV_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatV);
                float2 uvMask2 = GetUV(i.uvMutiMask.xy, _Mask2TexClamp_Value, _Mask2TexRepeatU_Value, _Mask2TexRepeatV_Value, _Mask2Tex_TilingOffset);
                half4 mask2 = SAMPLE_TEXTURE2D(_Mask2Tex, sampler_Mask2Tex, uvMask2);
                maskColor = mask2;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_RGBNOTALPHA
                half _MaskTexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Vlue = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Vlue, _MaskTex_TilingOffset);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor.rgb = mask.rgb;
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1))/1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;

                half _Mask2TexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexClamp);
                half _Mask2TexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatU);
                half _Mask2TexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatV);
                float2 uvMask2 = GetUV(i.uvMutiMask.xy, _Mask2TexClamp_Value, _Mask2TexRepeatU_Value, _Mask2TexRepeatV_Value, _Mask2Tex_TilingOffset);
                half4 mask2 = SAMPLE_TEXTURE2D(_Mask2Tex, sampler_Mask2Tex, uvMask2);
                maskColor.rgb = mask2.rgb;
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_RNOTALPHA
                half _MaskTexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Vlue = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Vlue, _MaskTex_TilingOffset);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.r, mask.r, mask.r, mask.r);
                maskColor.a= dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;

                half _Mask2TexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexClamp);
                half _Mask2TexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatU);
                half _Mask2TexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatV);
                float2 uvMask2 = GetUV(i.uvMutiMask.xy, _Mask2TexClamp_Value, _Mask2TexRepeatU_Value, _Mask2TexRepeatV_Value, _Mask2Tex_TilingOffset);
                half4 mask2 = SAMPLE_TEXTURE2D(_Mask2Tex, sampler_Mask2Tex, uvMask2);
                maskColor = half4(mask2.r, mask2.r, mask2.r, mask2.r);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_GNOTALPHA
                half _MaskTexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Vlue = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Vlue, _MaskTex_TilingOffset);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.g, mask.g, mask.g, mask.g);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;

                half _Mask2TexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexClamp);
                half _Mask2TexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatU);
                half _Mask2TexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatV);
                float2 uvMask2 = GetUV(i.uvMutiMask.xy, _Mask2TexClamp_Value, _Mask2TexRepeatU_Value, _Mask2TexRepeatV_Value, _Mask2Tex_TilingOffset);
                half4 mask2 = SAMPLE_TEXTURE2D(_Mask2Tex, sampler_Mask2Tex, uvMask2);
                maskColor = half4(mask2.g, mask2.g, mask2.g, mask2.g);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_BNOTALPHA
                half _MaskTexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexClamp);
                half _MaskTexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatU);
                half _MaskTexRepeatV_Vlue = UNITY_ACCESS_INSTANCED_PROP(Props, _MaskTexRepeatV);
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp_Value, _MaskTexRepeatU_Value, _MaskTexRepeatV_Vlue, _MaskTex_TilingOffset);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.b, mask.b, mask.b, mask.b);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;

                half _Mask2TexClamp_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexClamp);
                half _Mask2TexRepeatU_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatU);
                half _Mask2TexRepeatV_Value = UNITY_ACCESS_INSTANCED_PROP(Props, _Mask2TexRepeatV);
                float2 uvMask2 = GetUV(i.uvMutiMask.xy, _Mask2TexClamp_Value, _Mask2TexRepeatU_Value, _Mask2TexRepeatV_Value, _Mask2Tex_TilingOffset);
                half4 mask2 = SAMPLE_TEXTURE2D(_Mask2Tex, sampler_Mask2Tex, uvMask2);
                maskColor = half4(mask2.b, mask2.b, mask2.b, mask2.b);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#endif
                half _Opacity_Value= UNITY_ACCESS_INSTANCED_PROP(Props, _Opacity);
                alpha = saturate(alpha)* _Opacity_Value;
                c *= alpha;
                return half4(c, alpha);
            }
            ENDHLSL
            
        }
    }
    //CustomEditor "CustomShader_AddAB"
    //Fallback "Hidden/InternalErrorShader"
}
