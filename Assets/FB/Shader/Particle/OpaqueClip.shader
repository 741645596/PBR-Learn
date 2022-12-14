
Shader "FB/Particle/Opaque (Clip)"
{
    Properties
    {
        [MainTexture] _MainTex ("Particle Texture", 2D) = "white" {}
        _ClipRange("Clip Range", vector) = (-1.0, 1.0, -1.0, 1.0)
    }
    
    SubShader
    {
        Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Opaque""RenderPipeline" = "UniversalPipeline" }
        ColorMask RGB
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        Lighting Off 
        Fog { Mode Off }
    
        LOD 100
    
        Pass
        {
            Tags {"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            CBUFFER_START(HeroURPGroups) 

                TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);
                float4 _MainTex_ST;
                float4 _ClipRange;

            CBUFFER_END

            struct appdata_full {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                half4 color : COLOR0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                half4 color : TEXCOORD1;
                float2 screenpos : TEXCOORD2;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.color = v.color;
                o.screenpos = o.pos.xy;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                color *= i.color;
                float factor1 = step(_ClipRange.x, i.screenpos.x);
                float factor2 = step(i.screenpos.x, _ClipRange.y);
                float factor3 = step(_ClipRange.z, i.screenpos.y);
                float factor4 = step(i.screenpos.y, _ClipRange.w);
                color.a = color.a * factor1 * factor2 * factor3 * factor4;

                return color;
            }            
            ENDHLSL
        }
	}
    FallBack Off
}

