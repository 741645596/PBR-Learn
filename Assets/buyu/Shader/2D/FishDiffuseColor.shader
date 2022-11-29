Shader "WB/FishDiffuseColor"
{
    Properties
    {
        _Color("diffuse",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

         Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            CBUFFER_END


            struct VertexInput
            {
                half4 vertex : POSITION;
                half3 ase_normal : NORMAL;
            };

            struct v2f
            {
                half4 clipPos:SV_POSITION;
                half3 worldNormal:NORMAL;
            };

            v2f vert(VertexInput v)
            {
                v2f o;
                o.clipPos = TransformObjectToHClip(v.vertex.xyz);
                o.worldNormal = TransformObjectToWorld(v.ase_normal);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                half3 worldLight = normalize(_MainLightPosition.xyz);
                half3 diffuse = _Color.rgb * _MainLightColor.rgb * saturate(dot(worldLight, i.worldNormal) * 0.5f + 0.5);
                return half4(diffuse + ambient, 1);
            }
            ENDHLSL
        }
    }
}


