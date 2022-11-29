
Shader "FB/PostProcessing/MeshSpotVolumeLightPlant"
{
    Properties
    {

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
            Cull Back

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile _ENBLE_ANGOUTCLOSE _ENBLE_ANGOUT _ENBLE_ANGIN _ENBLE_ANGOUTIN
            #pragma multi_compile_instancing
            #include "MeshSpotVolumeLight.hlsl"

            half4 Frag (Varyings i) : SV_Target
            {
                return FragSpotVolumeLightPlant(i);
            }
            ENDHLSL
        }
    }
}

