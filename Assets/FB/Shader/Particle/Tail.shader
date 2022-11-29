Shader "FB/Particle/Tail"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_Src("Src", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_Dst("Dst", Float) = 10
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("ZTest Mode", Float) = 2
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 2
        
        [Space(20)]
        [HDR]_TintColor("Color", Color) = (1,1,1,1)
        _MainTex("主贴图", 2D) = "white" {}
        [Toggle]_Desaturate("主贴图去色", Float) = 1
        _MainUVPanner("主贴图流动", Vector) = (0,0,0,0)

        [Space(20)]
        [Toggle(_ALPHARED_ON)] _AlphaRed("A/R通道", Float) = 0
        [Toggle(_ONEMINUS_DISSOLVE_ON)] _OneMinus_Dissolve("Distort取反", Float) = 0
        _Dissolvew("Distort", 2D) = "white" {}
        _Strength1("Distort强度", Float) = 0
        _Length("Length", Float) = 0

        [Space(20)]
        _Mask("Mask", 2D) = "white" {}
        _UV_speed("UVPanner(Distort/Mask)", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "Queue"="Transparent" 
            "RenderType"="Transparent"
        }
        
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            Blend [_Src] [_Dst]
            ZTest [_ZTestMode]
            ZWrite Off
            Cull [_CullMode]
            HLSLPROGRAM

            #pragma shader_feature _ONEMINUS_DISSOLVE_ON
            #pragma shader_feature _ALPHARED_ON

            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            struct appdata
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 uv       : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD1;
                float4 vertexColor  : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _TintColor;
                half4 _MainTex_ST;
                half _Length;
                half _Strength1;
                half4 _UV_speed;
                half4 _Dissolvew_ST;
                half _Desaturate;
                half4 _Mask_ST;
                half2 _MainUVPanner;

                half _Src;
                half _Dst;
            CBUFFER_END
            
            sampler2D _MainTex;
            SamplerState sampler_MainTex;
            sampler2D _Dissolvew;
            SamplerState sampler_Dissolvew;
            sampler2D _Mask;
            SamplerState sampler_Mask;

            
            v2f vert ( appdata v )
            {
                v2f o;
                o.uv = v.uv;
                o.vertexColor = v.color;
                
                o.vertex = TransformObjectToHClip(v.vertex.xyz);

                return o;
            }
            half4 frag (v2f i ) : SV_Target
            {
                float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                half temp1 = _Length * uv_MainTex.x;
                half temp2 = temp1 * _Strength1;

                float2 uv_Dissolvew = i.uv.xy * _Dissolvew_ST.xy + _Dissolvew_ST.zw + _Time.y * _UV_speed.xy;
                half4 dissolveMap = tex2D( _Dissolvew, uv_Dissolvew );
                dissolveMap = pow(dissolveMap,0.416);
                half dissolveVar = ( dissolveMap.r * dissolveMap.a );

                #if !defined(_ONEMINUS_DISSOLVE_ON)
                    dissolveVar = 1.0 - dissolveVar;
                #endif

                half4 mainTex = tex2D( _MainTex, ( ( uv_MainTex + ( temp2 * dissolveVar ) ) - (temp2 * 0.5).xx ) + _Time.y * _MainUVPanner );

                half desaturateDot = dot( mainTex.rgb, float3( 0.299, 0.587, 0.114 ));
                half3 desaturateVar = lerp( mainTex.rgb, desaturateDot.xxx, _Desaturate);

                #ifdef _ALPHARED_ON
                    half finalDissolve = desaturateVar.x;
                #else
                    half finalDissolve = mainTex.a;
                #endif

                float2 uv_Mask = i.uv.xy * _Mask_ST.xy + _Mask_ST.zw + _Time.y * _UV_speed.zw;
                half4 mask = tex2D( _Mask, uv_Mask );
                float clampDissolveVar = saturate( 1.0 - ( temp1 * dissolveVar ) );

                half finalAlpha = _TintColor.a * finalDissolve * i.vertexColor.a * mask.a * mask.r * clampDissolveVar ;
                half3 finalColor = ( _TintColor * half4( desaturateVar , 0.0 ) * i.vertexColor ).rgb;

                half isOneOne = _Src == 1.0 && _Dst == 1.0;
                finalColor.rgb *= isOneOne ? finalAlpha : 1;
                finalAlpha = isOneOne ? 1 : saturate(finalAlpha);

                return float4(finalColor,finalAlpha);
            }
            ENDHLSL 
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
