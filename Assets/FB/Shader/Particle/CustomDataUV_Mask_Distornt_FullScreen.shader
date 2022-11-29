Shader "FB/Particle/U_Mask_Distornt_FullScreen"
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
        [MainTexture]_MainTex ("主贴图MainTex", 2D) = "white" { }
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

        _MaskTex ("遮罩贴图 MaskTex", 2D) = "white" { }
        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvMSpeedX ("遮罩uv流速X", int) = 0
        _uvMSpeedY ("遮罩uv流速Y", int) = 0
        [Space(25)] //Distort
        [MaterialToggle(DISTORTENABLE)]_DistortEnable ("是否启用扭曲", int) = 0
        _DistortTex ("扭曲贴图 DistortTex", 2D) = "white" { }
        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvDistortSpeedX ("扭曲uv流速X", int) = 0
        _uvDistortSpeedY ("扭曲uv流速Y", int) = 0
        _Distort ("扭曲强度", Range(0, 5)) = 0.8

        //溶解
        [Space(25)]
        [MaterialToggle(_DISSOLVE_ON)]DissolveOn("是否启用溶解", int) = 0
        _DissolveTex("溶解贴图 DissolveTex", 2D) = "white" { }
        _DissolveTex_BlendFilter("DissolveTex 通道过滤", Color) = (1, 0, 0, 1)
        _Dissolve("dissolveValue", Range(0, 3)) = 0
        _DissolveRange("Dissolve Range", Range(0, 10)) = 0
        [HDR]_DissolveColor1("dissolveColor1",color) = (1,0,0,1)
        [HDR]_DissolveColor2("dissolveColor2",color) = (0,0,0,1)
        [HideInInspector]_DissolveTexClamp("DissolveTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DissolveTexRepeatU("DissolveTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DissolveTexRepeatV("DissolveTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvDissolveSpeeyX("溶解贴图uv流速X", int) = 0
        _uvDissolveSpeeyY("溶解贴图uv流速Y", int) = 0

        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" }
        Blend [_SrcBlend] [_DestBlend]
        //Cull [_CullMode]
		Cull Off
        ZWrite Off
        ZTest [_ZAlways]
        
        Pass
        {
            //AlphaToMask On
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            //两种shader_feature写法 ,对应属性的 MaterialToggle
            #pragma multi_compile _ _MASKENABLE_ON _MASKENABLE_RGBNOTALPHA _MASKENABLE_RNOTALPHA _MASKENABLE_GNOTALPHA _MASKENABLE_BNOTALPHA
            #pragma multi_compile _ DISTORTENABLE
            #pragma multi_compile _ _DISSOLVE_ON
            
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
            
            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex); SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DistortTex); SAMPLER(sampler_DistortTex);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
            float4 _MainTex_ST, _MaskTex_ST, _DistortTex_ST, _DissolveTex_ST;
            half4 _Color;
            half _uvSpeeyX, _uvSpeeyY, _uvMSpeedX, _uvMSpeedY, _Intensity, _Distort, _uvDistortSpeedX, _uvDistortSpeedY, _DistortEnable, _MaskEnable,_Opacity;
            float _RotatorAngle, _RotatorToggle, _TextureScaleX, _TextureScaleY;
            half _MainTexClamp;
            half _MainTexRepeatU;
            half _MainTexRepeatV;
            half _MaskTexClamp;
            half _MaskTexRepeatU;
            half _MaskTexRepeatV;
            half _DistortTexClamp;
            half _DistortTexRepeatU;
            half _DistortTexRepeatV;
            half _DissolveTexClamp;
            half _DissolveTexRepeatU;
            half _DissolveTexRepeatV;
            half _uvDissolveSpeeyX;
            half _uvDissolveSpeeyY;
            half4 _DissolveTex_BlendFilter;
            half _Dissolve;
            half _DissolveRange;
            half4 _DissolveColor1;
            half4 _DissolveColor2;


            float _RotatorToggleMask, _RotatorAngleMask, _TextureScaleXMask, _TextureScaleYMask;

            CBUFFER_END

            
            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float4 vertexColor: COLOR;
                float4 customDataP: TEXCOORD1;
            };
            
            struct v2f
            {
#ifdef _DISSOLVE_ON
                float4 uv: TEXCOORD0;
#else
                float2 uv: TEXCOORD0;
#endif
                float4 positionCS: SV_POSITION;
                float4 uv2: TEXCOORD1;
                float4 vertexColor: COLOR;
                float dissolveCustomData : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertexColor = v.vertexColor;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                //o.positionCS = TransformWorldToHClip(positionWS);
o.positionCS = float4(v.vertex.xz*2,1, 1.0);
				
                //rotator
                float2 toggle = lerp(v.uv, UvRotatorAngle(v.uv.xy, _RotatorAngle, float2(_TextureScaleX, _TextureScaleY)), _RotatorToggle);
                o.dissolveCustomData = v.customDataP.z;
                o.uv.xy = TRANSFORM_TEX(toggle, _MainTex) + float2(_uvSpeeyX, _uvSpeeyY) * _Time.g;
                
                #if DISTORTENABLE
                    o.uv2.xy = TRANSFORM_TEX(v.uv, _DistortTex) + float2(_uvDistortSpeedX, _uvDistortSpeedY) * _Time.g;
                #endif
                #if _MASKENABLE_RGBNOTALPHA | _MASKENABLE_ON | _MASKENABLE_RNOTALPHA | _MASKENABLE_GNOTALPHA | _MASKENABLE_BNOTALPHA
                    float2 toggleMask = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngleMask, float2(_TextureScaleXMask, _TextureScaleYMask)), _RotatorToggleMask);
                    o.uv2.zw = TRANSFORM_TEX(toggleMask, _MaskTex) + float2(_uvMSpeedX, _uvMSpeedY) * _Time.g;
                #endif
                #ifdef _DISSOLVE_ON
                    o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex) + float2(_uvDissolveSpeeyX, _uvDissolveSpeeyY) * _Time.g;
                #endif
                
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 distort = i.uv.xy;

                //  distort
                #if DISTORTENABLE
                    float2 uvDistort = GetUV(i.uv2.xy, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV, _DistortTex_ST);
                    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, uvDistort);
                    //distortTex = GetTextColor(distortTex, uvDistort, _DistortTexRepeatU, _DistortTexRepeatV);
                    distort = (_Distort * 0.5 * distortTex.xy) + i.uv.xy;
                #endif

                //  main
                float2 uvMain = GetUV(distort, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                //maintex = GetTextColor(maintex,uvMain, _MainTexRepeatU, _MainTexRepeatV);
                half3 c = _Color.rgb * i.vertexColor.rgb * _Intensity * maintex.rgb  ;
                half alpha = _Color.a * i.vertexColor.a * maintex.a;

                //  mask
                //计算颜色
                half4 maskColor = half4(1, 1, 1, 1);
#ifdef _MASKENABLE_ON
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = mask;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_RGBNOTALPHA
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor.rgb = mask.rgb;
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1))/1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_RNOTALPHA
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.r, mask.r, mask.r, mask.r);
                maskColor.a= dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_GNOTALPHA
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.g, mask.g, mask.g, mask.g);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#elif _MASKENABLE_BNOTALPHA
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //mask = GetTextColor(mask, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);
                maskColor = half4(mask.b, mask.b, mask.b, mask.b);
                maskColor.a = dot(maskColor.rgb, half3(1, 1, 1)) / 1.732051;
                c *= maskColor.rgb;
                alpha *= maskColor.a;
#endif

                //溶解
#ifdef _DISSOLVE_ON
                float2 uvDissolve = GetUV(i.uv.zw, _DissolveTexClamp, _DissolveTexRepeatU, _DissolveTexRepeatV, _DissolveTex_ST);
                half4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, uvDissolve);
                //dissolvetex = GetTextColor(dissolvetex, uvDissolve, _DissolveTexRepeatU, _DissolveTexRepeatV);
                //
                half dissolveAlpha = dot(dissolvetex.rgb, _DissolveTex_BlendFilter.rgb);
                _Dissolve = _Dissolve + i.dissolveCustomData;
                float clipValue = dissolveAlpha - _Dissolve * 1.2 + 0.1;
                alpha *= smoothstep(0.001, 0.1, clipValue);
                clipValue = clamp(clipValue * _DissolveRange, 0, 1);
                half4 dissColor = lerp(_DissolveColor1, _DissolveColor2, smoothstep(0.2, 0.3, clipValue));
                clipValue = clamp(clipValue + step(_Dissolve, 0.001), 0, 1);
                c.rgb = lerp(dissColor + c, c, clipValue).rgb;
#endif
                alpha = saturate(alpha)*_Opacity;
                c *= alpha;
                return half4(c, alpha);
            }
            ENDHLSL
            
        }
    }
    //CustomEditor "CustomShader_AddAB"
    //Fallback "Hidden/InternalErrorShader"
}
