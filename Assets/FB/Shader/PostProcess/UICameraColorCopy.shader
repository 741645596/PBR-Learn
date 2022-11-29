Shader "FB/PostProcessing/UICameraColorCopy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass //0
        {
            Tags { "LightMode" = "UI 3DBuffer SRGBToLiner" }
            ZTest Always 
            ZWrite Off
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            sampler2D _MainTex;

            Varyings SceneEffectVertex (Attritubes i)
            {
                Varyings o;
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 SceneEffectFrag (Varyings i) : SV_Target
            {
                half4 mainColor = half4(tex2D(_MainTex, i.uv));
                mainColor.rgb = SRGBToLinear(mainColor.rgb);
                return mainColor;
            }
            ENDHLSL
        }

        Pass //1
        {
            Tags { "LightMode" = "UI 3DBuffer LinerToSRGB" }
            ZTest Always 
            ZWrite Off
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Assets/Renders/Shaders/ShaderLibrary/Common/CommonFunction.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            sampler2D _MainTex;

            Varyings SceneEffectVertex (Attritubes i)
            {
                Varyings o;
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                // UV
                o.uv = i.uv;
                return o;
            }

            half4 SceneEffectFrag (Varyings i) : SV_Target
            {

                half4 mainColor = half4(tex2D(_MainTex, i.uv));

                mainColor.rgb = LinearToSRGB(mainColor.rgb);


                return mainColor;
            }
            ENDHLSL
        }

    }
}
