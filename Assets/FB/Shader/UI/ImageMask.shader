
Shader "FB/UI/ImageMask"
{
    Properties
    {
        [PerRendererData] [MainTexture] _MainTex("Sprite Texture", 2D) = "white" {}
        _MaskTex("Mask Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
        _ColorMask("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
        Fog{ Mode Off }
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Tags {"LightMode"="Default UI RP"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 

            TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);
            #ifdef _SEPERATE_ALPHA_TEX_ON
                TEXTURE2D_X(_AlphaTex); SAMPLER(sampler_AlphaTex);
            #endif

            CBUFFER_START(UnityPerMaterial) 
                half4 _Color;
            CBUFFER_END

            struct vtx
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                half4 color : COLOR;
                half4 texcoord  : TEXCOORD0;
            };

            v2f vert(vtx IN)
            {
                v2f OUT;
                OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
                OUT.texcoord.xy = IN.texcoord0;
                OUT.texcoord.zw = IN.texcoord1;
                #ifdef UNITY_HALF_TEXEL_OFFSET
                    OUT.vertex.xy += (_ScreenParams.zw - 1.0) * float2(-1.0, 1.0);
                #endif
                OUT.color = IN.color * _Color;
                return OUT;
            }

            half4 frag(v2f IN) : SV_Target
            {
                half4 color;
                color.rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.texcoord.xy).rgb * IN.color.rgb;
                #ifdef _SEPERATE_ALPHA_TEX_ON
                    color.a = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, IN.texcoord.xy).r * SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, IN.texcoord.zw).r;
                #else
                    color.a = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, IN.texcoord.xy).a;
                #endif
                color *= IN.color;
                color.rgb = LinearToSRGB(color.rgb);
                clip(color.a - 0.01);
                return color;
            }

            ENDHLSL
        }
    }
}
