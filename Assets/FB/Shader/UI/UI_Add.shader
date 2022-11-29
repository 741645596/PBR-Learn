
Shader "FB/UI/UI_Add" {
    Properties {
        [Enum(LEqual, 4, Always, 8)] _ZAlways("层级显示：LEqual默认层级，Always永远在最上层", int) = 4

        [MainTexture] _MainTex ("MainTex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HDR]_TintColor ("颜色_Color", Color) = (0.5,0.5,0.5,1)
        _Intensity ("强度_Intensity", Float ) = 1
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader {
        Tags {"Queue"="Transparent"
            "IgnoreProjector"="True" 
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "Default UI RP"
         }
        ZTest[_ZAlways]

        Pass {

            Blend One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"

            TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial) 
                float4 _MainTex_ST;
                half4 _TintColor;
                float _Intensity;
                half _Opacity;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
            CBUFFER_END
            
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip( v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target{
                float2 uvMain = GetUV(i.uv0, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV,_MainTex_ST);
                half4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uvMain);
                float3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*_Intensity);
                float3 finalColor =_Opacity* emissive*(_MainTex_var.a*i.vertexColor.a*_TintColor.a);
                return half4 (LinearToSRGB(finalColor),1);
            }

            ENDHLSL
        }
    }
}
