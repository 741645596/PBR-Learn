Shader "WB/fish2d"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("CullMode", float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend("Source Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DestBlend("Dest Blend Mode", Float) = 10
        [Enum(Off, 0, On, 1)]_ZWriteMode("ZWriteMode", float) = 0

        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
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

        Lighting Off
        Cull[_CullMode]
        Blend[_SourceBlend][_DestBlend]
        ZWrite[_ZWriteMode]


        Pass
        {
        HLSLPROGRAM
        #pragma vertex SpriteVert
        #pragma fragment SpriteFrag
        #pragma target 2.0
        #include "ColorCore.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


    CBUFFER_START(UnityPerMaterial)
        half2 _Flip;
        half4 _Color;
        half4 _RendererColor;
    CBUFFER_END
        sampler2D _MainTex;
        

        struct appdata_t
        {
            half4 vertex   : POSITION;
            half4 color    : COLOR;
            half2 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            half4 vertex   : SV_POSITION;
            half4 color : COLOR;
            half2 texcoord : TEXCOORD0;
        };

        inline half4 UnityFlipSprite(in half3 pos, in half2 flip)
        {
            return half4(pos.xy * flip, pos.z, 1.0);
        }

        v2f SpriteVert(appdata_t IN)
        {
            v2f OUT;
            OUT.vertex = UnityFlipSprite(IN.vertex.xyz, _Flip);
            OUT.vertex = TransformObjectToHClip(OUT.vertex.xyz);
            OUT.texcoord = IN.texcoord;
            OUT.color = IN.color * _Color * _RendererColor;
            return OUT;
        }

        half4 SampleSpriteTexture(half2 uv)
        {
            half4 color = tex2D(_MainTex, uv);
            return color;
        }

        half4 SpriteFrag(v2f IN) : SV_Target
        {
            half4 c = SampleSpriteTexture(IN.texcoord) * IN.color;
            c.rgb *= c.a;
            return c;
        }
        ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}
