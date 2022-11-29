Shader "FB/Particle/AlphaBlendAlways" {
    Properties {
	    [Header(ZTest Mode)]
        [Enum(LEqual, 4, Always, 8)]_ZAlways ("�㼶��ʾ��LEqualĬ�ϲ㼶��Always��Զ�����ϲ�", int) = 8
		
        [MainTexture] _MainTex ("MainTex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

        [HDR]_TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        _Light ("Light", Float ) = 2
        _MaskR ("Mask(R)", 2D) = "white" {}

        [HideInInspector]_MaskRClamp("MaskRClamp(����WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskRRepeatU("MaskRRepeatU(����WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskRRepeatV("MaskRRepeatV(����WrapMode)",float) = 0 // 1:RepeatV

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
            //ZTest Always
			ZTest [_ZAlways]
            ZWrite Off
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                TEXTURE2D_X(_MaskR); SAMPLER(sampler_MaskR);
                uniform float4 _MainTex_ST;
                uniform float4 _TintColor;
                uniform float _Light;
                uniform float4 _MaskR_ST;
                half _Opacity;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
                float _MaskRClamp, _MaskRRepeatU, _MaskRRepeatV;

            CBUFFER_END

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            v2f vert (VertexInput v) {
                v2f o = (v2f)0;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip( v.vertex.xyz);
                o.uv0.xy = TRANSFORM_TEX(v.texcoord0, _MainTex);
                o.uv0.zw = TRANSFORM_TEX(v.texcoord0, _MaskR);
                return o;
            }

            half4 frag(v2f i) : SV_Target{

                float2 uvMain = GetUV(i.uv0.xy, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV,_MainTex_ST);
                half4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, uvMain);
                //_MainTex_var = GetTextColor(_MainTex_var, uvMain, _MainTexRepeatU, _MainTexRepeatV);

                half3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*_Light);
                half3 finalColor = emissive;

                float2 uvMask = GetUV(i.uv0.zw, _MaskRClamp, _MaskRRepeatU, _MaskRRepeatV, _MaskR_ST);
                half4 _MaskR_var = SAMPLE_TEXTURE2D(_MaskR, sampler_MaskR, i.uv0.zw);
                //_MaskR_var = GetTextColor(_MaskR_var, uvMask, _MaskRRepeatU, _MaskRRepeatV);

                return half4(finalColor,(_MainTex_var.a*i.vertexColor.a*_TintColor.a*(_MaskR_var.r*_MaskR_var.a))*_Opacity);
            }

            ENDHLSL
        }
    }
}
