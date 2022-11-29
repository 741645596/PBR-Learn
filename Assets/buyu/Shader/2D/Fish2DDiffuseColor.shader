Shader "WB/Fish2DDiffuseColor"
{
        Properties
        {
            [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
            _Color("Tint", Color) = (1,1,1,1)
            [HideInInspector] _RendererColor("RendererColor", Color) = (1,1,1,1)
            [HideInInspector] _Flip("Flip", Vector) = (1,1,1,1)
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
            }

            Cull Off
            Lighting Off
            ZWrite Off
            Blend One OneMinusSrcAlpha

            Pass
            {
            HLSLPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment SpriteFrag
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half2 _Flip;
                half4 _RendererColor;
                half4 _Color;
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

            half4 SpriteFrag(v2f IN) : SV_Target
            {
                half4 c = tex2D(_MainTex, IN.texcoord);
                c.rgb = half3(1, 1, 1);
                c = c * IN.color;
                c.rgb *= c.a;
                return c;
            }
            ENDHLSL
            }
        }
        CustomEditor "FoldoutShaderGUI"
}


