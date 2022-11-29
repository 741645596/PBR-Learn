// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "FB/UI/Default"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask [_ColorMask]
        
        Pass
        {
            Name "Default"
            Tags {"LightMode"="Default UI RP"}
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma prefer_hlslcc gles
			    #pragma exclude_renderers d3d11_9x
			    #pragma target 2.0
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

                #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
                #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

                struct appdata_t
                {
                    float4 vertex   : POSITION;
                    float4 color    : COLOR;
                    float2 texcoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f
                {
                    float4 vertex   : SV_POSITION;
                    half4 color    : COLOR;
                    float2 texcoord  : TEXCOORD0;
                    float4 worldPosition : TEXCOORD1;
                    float4  mask : TEXCOORD2;
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                TEXTURE2D_X(_MainTex);
                SAMPLER(sampler_MainTex);
                float _UIMaskSoftnessX;
                float _UIMaskSoftnessY;
                float4 _ClipRect;
                half4 _TextureSampleAdd;

                CBUFFER_START(UnityPerMaterial)
                    half4 _Color;
                    float4 _MainTex_ST;
                CBUFFER_END

                v2f vert(appdata_t v)
                {
                    v2f OUT;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                    float4 vPosition = TransformObjectToHClip(v.vertex.xyz);
                    OUT.worldPosition = v.vertex;
                    OUT.vertex = vPosition;
                    float2 pixelSize = vPosition.w;
                    pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));
                    float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                    float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                    OUT.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                    OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));
                    OUT.color = v.color * _Color;
                    return OUT;
                }

                half4 frag(v2f IN) : SV_Target
                {
                    //Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
                    //The incoming alpha could have numerical instability, which makes it very sensible to
                    //HDR color transparency blend, when it blends with the world's texture.
                    const half alphaPrecision = half(0xff);
                    const half invAlphaPrecision = half(1.0/alphaPrecision);
                    IN.color.a = round(IN.color.a * alphaPrecision)*invAlphaPrecision;

                    half4 color = IN.color * ( SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.texcoord) + _TextureSampleAdd);

                    #ifdef UNITY_UI_CLIP_RECT
                    half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                    color.a *= m.x * m.y;
                    #endif

                    #ifdef UNITY_UI_ALPHACLIP
                    clip (color.a - 0.001);
                    #endif

                    color.rgb = LinearToSRGB(color.rgb);

                    color.rgb *= color.a;

                    return color;
                }

            ENDHLSL
        }
    }
}
