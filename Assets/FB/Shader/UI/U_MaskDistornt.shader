Shader "FB/UI/Fx/U_MaskDistort"
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
        [Space(15)]//Maintex
        [MaterialToggle]_RotatorToggle("开启旋转缩放(主纹理)", int) = 0
        _RotatorAngle("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleX("缩 放", Range(0, 10)) = 1
        _TextureScaleY("缩 放", Range(0, 10)) = 1
        [NoScaleOffset][MainTexture]_MainTex("主贴图MainTex", 2D) = "white" {} //
        _MainTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0 //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        _uvSpeeyX ("主贴图uv流速X", int) = 0
        _uvSpeeyY ("主贴图uv流速Y", int) = 0
        
        [Space(25)]  //Mask
        //[Toggle]_MaskEnable ("是否启用Mask", int) = 0
        //[KeywordEnum(Off,On,RgbNotAlpha,RNotAlpha,GNotAlpha,BNotAlpha)] _MaskEnable("遮罩WrapMode",Int) = 0
        [KeywordEnum(Off,On,RgbNotAlpha,RNotAlpha,GNotAlpha,BNotAlpha)] _MaskEnable("遮罩WrapMode",Int) = 0
        [MaterialToggle]_RotatorToggleMask("开启旋转缩放(遮罩)", int) = 0
        _RotatorAngleMask("旋 转 角 度", Range(-180, 180)) = 0
        _TextureScaleXMask("缩 放X", Range(0, 10)) = 1.0
        _TextureScaleYMask("缩 放y", Range(0, 10)) = 1.0
        [NoScaleOffset]_MaskTex("遮罩贴图 MaskTex", 2D) = "white" {}
        _MaskTex_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV
        [MaterialToggle(USINGPOLARMASK)]_PolarEnableMask("遮罩贴图是否启用极坐标", int) = 0
        _uvMSpeedX("遮罩uv流速X", int) = 0
        _uvMSpeedY("遮罩uv流速Y", int) = 0
        _MaskAngle("遮罩贴图旋转",Range(-180,180)) = 0
        [Space(30)]  //预乘
        _Premultply("预乘Alpha",float) = 1


        [Space(25)] //Distort
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
        Blend [_SrcBlend] [_DestBlend]
        Cull [_CullMode]
        ZWrite Off
        ZTest [_ZAlways]
        
        Pass
        {
            Tags {"LightMode"="Default UI RP"}
            //AlphaToMask On
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"  
            //#include "UIParticlesFun.hlsl"  
            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex); SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DistortTex); SAMPLER(sampler_DistortTex);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
            
            float4 _MainTex_ST, _MaskTex_ST, _DistortTex_ST, _DissolveTex_ST;
            half _DistortEnable,_MaskEnable;
            
            CBUFFER_START(UnityPerMaterial) 

                
                half _Intensity;
                half _Opacity;

                float4 _MaskTex_TilingOffset;
                half _MaskTexClamp;
                half _MaskTexRepeatU;
                half _MaskTexRepeatV;
                float _RotatorToggleMask;
                float _RotatorAngleMask;
                float _TextureScaleXMask;
                float _TextureScaleYMask;
                half _uvMSpeedX;
                half _uvMSpeedY;

                float4 _MainTex_TilingOffset;
                half4 _Color;
                half _MainTexClamp;
                half _MainTexRepeatU;
                half _MainTexRepeatV;
                float _RotatorAngle;
                float _RotatorToggle;
                float _TextureScaleX;
                float _TextureScaleY;
                half _MaskAngle;
                half _PolarEnableMask;
                half _ToggleCustom;


                float4 _DistortTex_TilingOffset;
                half _DistortTexClamp;
                half _DistortTexRepeatU;
                half _DistortTexRepeatV;
                half _Distort;
                half _uvDistortSpeedX;
                half _uvDistortSpeedY;
                half _PolarEnableDistort;
                half _DistortMapAngle;
                

                float4 _DissolveTex_TilingOffset;
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
                half _DissolveMapAngle;
                half _PolarEnableDissolve;

                half _uvSpeeyX;
                half _uvSpeeyY;
                half _Premultply;

            CBUFFER_END
            
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

                float4 uv: TEXCOORD0;
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
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                //rotator
                float _RotatorAngle_Value          = _RotatorAngle;
                float _RotatorToggle_Value         = _RotatorToggle;
                float _TextureScaleX_Value         = _TextureScaleX;
                float _TextureScaleY_Value         = _TextureScaleY;
                half _uvSpeeyX_Value               = _uvSpeeyX;
                half _uvSpeeyY_Value               = _uvSpeeyY;

               // float2 toggle = lerp(v.uv, UvRotatorAngle(v.uv.xy, _RotatorAngle_Value, float2(_TextureScaleX_Value, _TextureScaleY_Value)), _RotatorToggle_Value);
                
                float2 toggle = lerp(v.uv, UvRotatByQuaternion(v.uv.xy, _RotatorAngle_Value, float2(_TextureScaleX_Value, _TextureScaleY_Value)), _RotatorToggle_Value);
                
                o.uv.xy = UVTilingOffset(toggle, _MainTex_TilingOffset);
                o.dissolveCustomData = v.customDataP.z;
                o.distortCustomData  = v.customDataP.w;

                #if defined(DISTORTENABLE)
                   o.uv2.xy = UVTilingOffset(v.uv.xy, _DistortTex_TilingOffset);
                #endif

                #if _MASKENABLE_RGBNOTALPHA | _MASKENABLE_ON | _MASKENABLE_RNOTALPHA | _MASKENABLE_GNOTALPHA | _MASKENABLE_BNOTALPHA
                   float2 toggleMask = lerp(v.uv.xy, UvRotatByQuaternion(v.uv.xy, _RotatorAngleMask, float2(_TextureScaleXMask, _TextureScaleYMask)), _RotatorToggleMask);
                   o.uv2.zw = UVTilingOffset(toggleMask, _MaskTex_TilingOffset);
                #endif

                #if defined(_DISSOLVE_ON)
                   o.uv.zw = UVTilingOffset(v.uv.xy, _DissolveTex_TilingOffset);
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
                   half2 _uvDistortSpeedValue = half2(_uvDistortSpeedX,_uvDistortSpeedY);
                    
                   float2 uvDistort = GetUV(i.uv2.xy, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV, _DistortTex_ST);
                    
                   float2 flowUV = toPolar(uvDistort,_uvDistortSpeedValue,_DistortMapAngle,_PolarEnableDistort);
                    
                   half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, flowUV);

                   distort = ((_Distort + i.distortCustomData) * 0.5 * distortTex.xy) + i.uv.xy;
                
                #endif
                
                //  main
                float2 uvMain = GetUV(distort, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                half4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                maintex = GetTextColor(maintex, uvMain, _MainTexRepeatU, _MainTexRepeatV);
                //maintex = GetTextColor(maintex,uvMain, _MainTexRepeatU, _MainTexRepeatV);
                half4 _Color_Value = _Color;
                float _Intensity_Value= _Intensity;
                float3 c = _Color.rgb * i.vertexColor.rgb * _Intensity * maintex.rgb;
                half alpha = _Color.a * i.vertexColor.a * maintex.a;
                
                //  mask
                float2 uvMask = GetUV(i.uv2.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);

                float2 tempuvMask = toPolar(uvMask,half2(_uvMSpeedX,_uvMSpeedY),_MaskAngle,_PolarEnableMask);
                
                //遮罩贴图采样
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, tempuvMask);
                
                //默认遮罩颜色
                half4 maskColor = half4(1, 1, 1, 1);
                
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
                
                #if defined(_DISSOLVE_ON)

                   float2 uvDissolve = GetUV(i.uv.zw, _DissolveTexClamp, _DissolveTexRepeatU, _DissolveTexRepeatV, _DissolveTex_ST);
                    
                   float2 tempuvDissolve = toPolar(uvDissolve,half2(_uvDissolveSpeeyX,_uvDissolveSpeeyY),_DissolveMapAngle,_PolarEnableDissolve);
                    
                   half4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, tempuvDissolve);

                   half dissolveAlpha = dot(dissolvetex.rgb, _DissolveTex_BlendFilter.rgb);
                    
                   half _Dissolve_Value = _Dissolve + i.dissolveCustomData;

                   float clipValue = dissolveAlpha - _Dissolve_Value*1.8+0.1;
                   alpha *= smoothstep(0.001, 0.1, clipValue);

                   clipValue = clamp(clipValue * _DissolveRange, 0, 1);

                   half4 dissColor = lerp(_DissolveColor1, _DissolveColor2, smoothstep(0.15, 1, clipValue));
                   clipValue = clamp(clipValue + step(_Dissolve_Value, 0.001), 0, 1);
                   c.rgb = lerp(dissColor.rgb + c, c, clipValue).rgb;
                #endif
                alpha = saturate(alpha)* _Opacity;

                c.rgb = LinearToSRGB(c.rgb);

                return lerp(half4(c, alpha),half4(c*alpha, alpha),_Premultply);
            }
            ENDHLSL
            
        }
    }

}
