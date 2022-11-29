//https://zhuanlan.zhihu.com/p/333613824
Shader "FB/PostProcessing/MeshCylinderVolumeLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Density("Density(密度)", range(0,1)) = 0.5
        _Intensity("Intensity(强度)", range(0,1)) = 0.5
        _LengthScale("LengthScale(长度)", range(0,2)) = 1.5
        _DepthEdge("DepthEdge(深度边缘)", range(0,1)) = 0.6
        [HDR]_LightBlendColor("LightBlendColor(混合颜色)", Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector"="true"}

        Pass //0
        {
            Tags { "LightMode" = "UniversalForward" }
            ZWrite Off
            Blend one one
            ColorMask RGBA
            Cull Front

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #include "MeshSpotVolumeLight.hlsl"

            half4 Frag (Varyings i) : SV_Target
            {
                return FragCylinderVolumeLightPlant(i);
            }

            ENDHLSL
        }

    }
}

