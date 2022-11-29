Shader "WB/Mask"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendRGB("BlendSrcRGB", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendRGB("BlendDstRGB", Float) = 1
        [Enum(Off,0, On,1)] _ZWriteMode("ZWrite Mode", Int) = 0
        [Enum(Always,0,Less,2,LessEqual,4)] _ZTest("ZTest Mode", Int) = 4
        _BaseColor("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend[_SrcBlendRGB][_DstBlendRGB]
        ZWrite[_ZWriteMode]
        ZTest[_ZTest]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
         

            struct appdata
            {
                half4 vertex : POSITION;
            };

            struct v2f
            {
                half4 vertex : SV_POSITION;
            };
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            CBUFFER_END
            v2f vert (appdata v)
            {
                v2f o; 
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                return _BaseColor;
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}
