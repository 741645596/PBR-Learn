Shader "FB/Particle/DistortSHDissolveMaskAllTextureSpeed"
{
    Properties
    {
        [Header(CustomData  Distort  SoftHard Dissolve  Mask Shader)]
        [Space(15)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("混合层1 ，one one 是ADD", int) = 6
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend ("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend", int) = 11

        //主纹理
        [Space(25)]
        [MainTexture]_MainTex ("Main Tex", 2D) = "white" { }
        [MaterialToggle]_RotatorToggle("开启旋转缩放(主纹理)", int) = 0
        _RotatorAngle("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleX("缩 放", Range(0, 10)) = 1
        _TextureScaleY("缩 放", Range(0, 10)) = 1
        _Light ("Light", Float) = 1
        _Alpha ("Alpha", Float) = 1
        _MainTexUSpeed("MainTex U Speed", Float) = 0
        _MainTexVSpeed("MainTex V Speed", Float) = 0
        [HDR]_Color ("Color", Color) = (1, 1, 1, 1)

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        //溶解
        [Space(25)]
        _Disstex ("Diss tex", 2D) = "white" { }
        _DissUSpeed ("Diss U Speed", Float) = 0
        _DissVSpeed ("Diss V Speed", Float) = 0
        _DissFact ("溶解阈值 Dissolve Fact", Float) = 0.01
        _Tips ("！！！！！！tips ： 请用CustomData.x 控制整个溶解曲线 ！！！！！！", int) = 0

        [HideInInspector]_DissTexClamp("DissTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DissTexRepeatU("DissTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DissTexRepeatV("DissTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        //扭曲
        [Space(25)]
        _DistortTex ("Distort Tex", 2D) = "white" { }
        _DistortIntensity ("Distort  Intensity", Float) = 0
        _USpeed ("U Speed", Float) = 0
        _VSpeed ("V Speed", Float) = 1

        [HideInInspector]_DistortTexClamp("DistortTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_DistortTexRepeatU("DistortTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_DistortTexRepeatV("DistortTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        //遮罩
        [Space(25)]
        _MaskTex ("Mask Tex", 2D) = "white" { }
         [MaterialToggle]_RotatorToggleMask("开启旋转缩放(遮罩)", int) = 0
        _RotatorAngleMask("旋 转 角 度", Range(-1, 1)) = 0
        _TextureScaleXMask("缩 放", Range(0, 10)) = 1
        _TextureScaleYMask("缩 放", Range(0, 10)) = 1

        [HideInInspector]_MaskTexClamp("MaskTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MaskTexRepeatU("MaskTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MaskTexRepeatV("MaskTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Pass
        {
            Blend [_SrcBlend] [_DestBlend]
            Cull Off
            ZWrite Off
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
            //#pragma target 2.0

            CBUFFER_START(UnityPerMaterial)

                uniform float4 _Disstex_ST;
                uniform float _DissFact, _DissolvePower, _ToggleSwitch;
                uniform float4 _MainTex_ST;

                uniform float _MainTexUSpeed;
                uniform float _MainTexVSpeed;

                uniform half _DissSwitch;
                uniform float4 _Color;
                uniform float _Light;
                uniform float _DissUSpeed;
                uniform float _DissVSpeed;
                uniform float _USpeed;
                uniform float _VSpeed;
                uniform float4 _DistortTex_ST;
                uniform float4 _MaskTex_ST;
                uniform float _Alpha;
                uniform half _DistortSwitch;
                uniform float _DistortIntensity;
                half _Opacity;

                float _RotatorAngle, _RotatorToggle, _TextureScaleX, _TextureScaleY;
                float _RotatorToggleMask, _RotatorAngleMask, _TextureScaleXMask, _TextureScaleYMask;

                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;
                float _DissTexClamp, _DissTexRepeatU, _DissTexRepeatV;
                float _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;

            CBUFFER_END
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            TEXTURE2D(_DistortTex);SAMPLER(sampler_DistortTex);
            TEXTURE2D(_Disstex);SAMPLER(sampler_Disstex);
            
            struct VertexInput
            {
                float4 vertex: POSITION;
                float4 uv: TEXCOORD0;
                float4 vertexColor: COLOR;
            };
            
            struct VertexOutput
            {
                float4 pos: SV_POSITION;
                float4 uv0: TEXCOORD0;
                float4 vertexColor: COLOR;
                float customData: TEXCOORD1;
                float4 uv1: TEXCOORD2;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;

                float2 anim = float2(_MainTexUSpeed * _Time.g, _MainTexVSpeed * _Time.g);
                float2 anim1 = float2(_DissUSpeed * _Time.g, _DissVSpeed * _Time.g);
                float2 anim2 = float2(_USpeed * _Time.g, _VSpeed * _Time.g);

                float2 toggle = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngle, float2(_TextureScaleX, _TextureScaleY)), _RotatorToggle);
                o.uv0.zw = TRANSFORM_TEX(toggle, _MainTex) + anim;
                o.uv0.xy = TRANSFORM_TEX(v.uv.xy, _DistortTex) + anim2;
                o.uv1.xy = TRANSFORM_TEX(v.uv.xy, _Disstex)+ anim1;

                float2 toggleMask = lerp(v.uv.xy, UvRotatorAngle(v.uv.xy, _RotatorAngleMask, float2(_TextureScaleXMask, _TextureScaleYMask)), _RotatorToggleMask);
                o.uv1.zw = TRANSFORM_TEX(toggleMask, _MaskTex);

                o.customData = v.uv.z;
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            float4 frag(VertexOutput i): SV_Target
            {
                //扭曲
                float2 uvDistort = GetUV(i.uv0.xy, _DistortTexClamp, _DistortTexRepeatU, _DistortTexRepeatV,_DistortTex_ST);
                float4 _DistortTex_var = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, uvDistort);
                //_DistortTex_var = GetTextColor(_DistortTex_var, uvDistort, _DistortTexRepeatU, _DistortTexRepeatV);
                float2 distort = (_DistortIntensity * 0.5 * _DistortTex_var.xy) + i.uv0.zw;

                //主纹理
                float2 uvMain = GetUV(distort, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV, _MainTex_ST);
                float4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                //_MainTex_var = GetTextColor(_MainTex_var, uvMain, _MainTexRepeatU, _MainTexRepeatV);

                //溶解
                float2 uvDisstex = GetUV(i.uv1.xy, _DissTexClamp, _DissTexRepeatU, _DissTexRepeatV, _Disstex_ST);
                float4 _Disstex_var = SAMPLE_TEXTURE2D(_Disstex, sampler_Disstex, uvDisstex);
                //_Disstex_var = GetTextColor(_Disstex_var, uvDisstex, _DissTexRepeatU, _DissTexRepeatV);
                half toggle = saturate((_Disstex_var.r * _DissFact - lerp(_DissFact, -1.5, i.customData.x)));
                float3 finalColor = (_MainTex_var.rgb * _Color.rgb * toggle * _Light * i.vertexColor.rgb);

                //遮罩
                float2 uvMask = GetUV(i.uv1.zw, _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV, _MaskTex_ST);
                float4 _MaskTex_var = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uvMask);
                //_MaskTex_var = GetTextColor(_MaskTex_var, uvMask, _MaskTexRepeatU, _MaskTexRepeatV);

                half alpha = _MainTex_var.a * toggle * i.vertexColor.a * (_MaskTex_var.r * _MaskTex_var.a) * _Alpha*_Opacity;
                finalColor *= alpha;
                return half4(finalColor, alpha);

            }
            ENDHLSL
            
        }
    }
}
