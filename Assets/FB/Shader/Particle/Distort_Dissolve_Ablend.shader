Shader "FB/Particle/DistortDissolveAblend" 
{
    Properties {
        [MainTexture] _MainTex ("Main Tex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        _Light ("Light", Float ) = 1
        _Alpha ("Alpha", Float ) = 1
        [HDR]_Color ("Color", Color) = (1,1,1,1)

        _Disstex ("Diss tex", 2D) = "white" {}

        [HideInInspector]_DissTexClamp("DissTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DissTexRepeatU("DissTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DissTexRepeatV("DissTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        [MaterialToggle] _DissSwitch ("Diss Switch", Float ) = 0.5148581
        _DissSlider ("Diss Slider", Range(-1, 2)) = 0.5148581

        _DistortTex ("Distort Tex", 2D) = "white" {}

        [HideInInspector]_DistortTexClamp("DistortTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        _DistortIntensity ("Distort  Intensity", Float ) = 0
        _USpeed ("U Speed", Float ) = 0
        _VSpeed ("V Speed", Float ) = 1
        [MaterialToggle] _DistortSwitch ("Distort Switch", Float ) = 0

        _MaskTex ("Mask Tex", 2D) = "white" {}

        [HideInInspector]_MaskTexClamp("MaskTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader {

        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
        
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_Disstex); SAMPLER(sampler_Disstex);
                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                TEXTURE2D_X(_DistortTex); SAMPLER(sampler_DistortTex);
                TEXTURE2D_X(_MaskTex); SAMPLER(sampler_MaskTex);

                uniform float4 _Disstex_ST;
                uniform float _DissSlider;
                uniform float4 _MainTex_ST;
                uniform half _DissSwitch;
                uniform float4 _Color;
                uniform float _Light;
                uniform float _USpeed;
                uniform float _VSpeed;
                uniform float4 _DistortTex_ST;
                uniform float4 _MaskTex_ST;
                uniform float _Alpha;
                uniform half _DistortSwitch;
                uniform float _DistortIntensity;
                half _Opacity;

                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
                float _DissTexClamp, _DissTexRepeatU, _DissTexRepeatV;
                float _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;

            CBUFFER_END

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 vertexColor : COLOR;
            };

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip( v.vertex.xyz );
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target{


                float2 GGG111 = float2(((_USpeed*_Time.g)+i.uv0.r),(i.uv0.g+(_Time.g*_VSpeed)));

                float2 distortTexUv = TRANSFORM_TEX(GGG111, _DistortTex);
                distortTexUv = GetUV(distortTexUv, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV, _DistortTex_ST);
                float4 _DistortTex_var = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, distortTexUv);
                //_DistortTex_var = GetTextColor(_DistortTex_var, distortTexUv, _DistortTexRepeatU, _DistortTexRepeatV);


                float2 FFF = (((lerp( i.uv1.g, _DistortIntensity, _DistortSwitch )*0.5+0.0)*_DistortTex_var.r)+i.uv0);

                float2 uvMain = TRANSFORM_TEX(FFF, _MainTex);
                uvMain = GetUV(uvMain, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                float4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                //_MainTex_var = GetTextColor(_MainTex_var, uvMain, _MainTexRepeatU, _MainTexRepeatV);

                float2 uvDisstex = TRANSFORM_TEX(FFF, _Disstex);
                uvDisstex = GetUV(uvDisstex, _DissTexClamp, _DissTexRepeatU, _DissTexRepeatV, _Disstex_ST);
                float4 _Disstex_var = SAMPLE_TEXTURE2D(_Disstex, sampler_Disstex, uvDisstex);
                //_Disstex_var = GetTextColor(_Disstex_var, uvDisstex, _DissTexRepeatU, _DissTexRepeatV);

                float DDD = step(lerp( i.uv1.r, _DissSlider, _DissSwitch ),(_Disstex_var.r*0.9+0.05));
                float3 emissive = (_MainTex_var.rgb*_Color.rgb*DDD*_Light*i.vertexColor.rgb);
                float3 finalColor = emissive;

                float2 uvMaskTex = TRANSFORM_TEX(i.uv0, _MaskTex);
                uvMaskTex = GetUV(uvMaskTex, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                float4 _MaskTex_var = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMaskTex);
                //_MaskTex_var = GetTextColor(_MaskTex_var, uvMaskTex, _MaskTexRepeatU, _MaskTexRepeatV);

                return half4(finalColor,(_MainTex_var.a*DDD*i.vertexColor.a*(_MaskTex_var.r*_MaskTex_var.a)*_Alpha*_Opacity));
            }

            ENDHLSL
        }
    }
}
