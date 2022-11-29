Shader "WB/OutGlow"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("CullMode", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend("Source Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DestBlend("Dest Blend Mode", Float) = 1
        [Enum(Off, 0, On, 1)]_ZWriteMode("ZWriteMode", float) = 0

        _MaskTex("_MaskTex", 2D) = "white" {}
        _StreamTex("_StreamTex", 2D) = "white" {}

        [HDR]_Color("_Color", Color) = (1, 1, 1, 1)
        _Alpha("_Alpha", Range(0, 1)) = 1
        
        [Foldout]EdgeColor("EdgeColor control",Range(0,1)) = 0
        [FoldoutItem] _EdgeColorFactor("EdgeColorFactor", Range(0, 1)) = 1
        [FoldoutItem] [HDR]_EdgeColor("EdgeColor", Color) = (1, 1, 1, 1)
        [FoldoutItem] _EdgeWidth("EdgeWidth", Range(0, 5)) = 1
        //
        [Foldout]SecondEdgeColor("SecondEdgeColor control",Range(0,1)) = 0
        [FoldoutItem] _SecondEdgeColorFactor("SecondEdgeColorFactor", Range(0, 1)) = 1
        [FoldoutItem] [HDR]_SecondEdgeColor("SecondEdgeColor", Color) = (1, 1, 1, 1)
        [FoldoutItem] _SecondEdgeWidth("SecondEdgeWidth", Range(0, 5)) = 1
        //
        [Foldout]StreamColor("StreamColor control",Range(0,1)) = 0
        [FoldoutItem] _StreamColorFactor("StreamColorFactor", Range(0, 1)) = 1
        [FoldoutItem] [HDR]_StreamColor("StreamColor", Color) = (1, 1, 1, 1)
        [FoldoutItem] _StreamWidth("StreamWidth", Range(-1, 1)) = 0
        [FoldoutItem] _StreamOffsetX("Stream OffsetX", Float) = 0
        [FoldoutItem] _StreamOffsetY("Stream OffsetY", Float) = 0
    }
    SubShader
    {
        LOD 300


        Name "Forward"
        Tags{"RenderPipeline" = "UniversalPipeline"  "Queue" = "Transparent-299"}
        Cull[_CullMode]
        Blend[_SourceBlend][_DestBlend]
        ZWrite[_ZWriteMode]
        ZTest LEqual
        Offset 0 , 0
        ColorMask RGBA

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float2 streamerUv : TEXCOORD0;
                float2 MaskUv : TEXCOORD1;
                float3 WorldViewDirection : TEXCOORD2;
                float3  worldNormal: TEXCOORD3;
            };
            //
            // 	vec4 _Time;
            CBUFFER_START(UnityPerMaterial)
            float _StreamOffsetX;
            float _StreamOffsetY;
            // 
            float _Alpha;
            float4 _Color;
            float _EdgeColorFactor;
            float4 _EdgeColor;
            float _EdgeWidth;
            float _SecondEdgeColorFactor;
            float4 _SecondEdgeColor;
            float _SecondEdgeWidth;
            float _StreamColorFactor;
            float4 _StreamColor;
            float _StreamWidth;

            float4 _StreamTex_ST;
            float4 _MaskTex_ST;

            CBUFFER_END
            sampler2D _MaskTex;
            sampler2D _StreamTex;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;;
                // 转到世界空间
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                // 计算view 方向
                float3 WorldViewDirection = _WorldSpaceCameraPos.xyz - positionWS;
                o.WorldViewDirection = normalize(WorldViewDirection);
                // streamer Uv
                float2 offset = _Time.y * float2(_StreamOffsetX, _StreamOffsetY);
                offset = frac(offset);
                float2 streamerUv = v.uv * _StreamTex_ST.xy + _StreamTex_ST.zw;
                o.streamerUv = streamerUv + offset;
                // mask Uv
                o.MaskUv = v.uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
                // 法线
                o.worldNormal = TransformObjectToWorld(v.ase_normal);
                float4 positionCS = TransformWorldToHClip(positionWS);
                o.clipPos = positionCS;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 WorldNormal = normalize(i.worldNormal);
                float3 WorldViewDirection = SafeNormalize(i.WorldViewDirection);
                float ndv = dot(WorldNormal, WorldViewDirection);
                
                float midResultValue = 1.0f - ndv;

                float3 resultEdgeColor = midResultValue * exp2(-_EdgeWidth) * _EdgeColor.rgb * _EdgeColorFactor;


                float3 resultSecondEdgeColor = midResultValue * exp2(-_SecondEdgeWidth) * _SecondEdgeColor.rgb * _SecondEdgeColorFactor;

                float3 ResultStreamColor = midResultValue * exp2(-_StreamWidth) * _StreamColor.rgb * _StreamColorFactor;


                float3 maskTexCol = tex2D(_MaskTex, i.MaskUv).rgb;
                float2 streamerUV = maskTexCol.rg + i.streamerUv;
                float alpha  = maskTexCol.b * _Color.a * _Alpha;
                float3 StreamTexCol = tex2D(_StreamTex, streamerUV).rgb;


                float3 resultCol = ResultStreamColor * StreamTexCol + resultEdgeColor + resultSecondEdgeColor;
                return alpha * float4(resultCol * _Color.xyz, 1.0f);
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}
