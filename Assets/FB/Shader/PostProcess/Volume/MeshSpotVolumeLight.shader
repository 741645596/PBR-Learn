//此Shader是用于渲染聚光灯网格体积光的
//需要开启URP深度图
//由MeshSpotVolumeLight.cs自动指定
//需要避免SRP合批  需要使用MaterialPropertyBlock赋值属性
//适用场景：在没有屏幕体积光的场景中使用
//缺点：1.与光源同角度会穿帮 2.叠加会穿帮
Shader "FB/PostProcessing/MeshSpotVolumeLight"
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
            #pragma multi_compile _ _ENBLE_CULLPLANT //遮挡平面
            #pragma multi_compile _ _ENBLE_DEPTHPLANT //衰减平面

            #include "MeshSpotVolumeLight.hlsl"

            half4 Frag (Varyings i) : SV_Target
            {
                return FragSpotVolumeLight(i,0);
            }
            ENDHLSL
        }

        Pass //1
        {
            Tags { "LightMode" = "SrpDefaultUnlit" } 
            ZWrite Off
            Blend one one
            ColorMask RGBA
            Cull Back

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ _ENBLE_CULLPLANT //遮挡平面
            #pragma multi_compile _ _ENBLE_DEPTHPLANT //衰减平面

            #include "MeshSpotVolumeLight.hlsl"

            half4 Frag (Varyings i) : SV_Target
            {
                return FragSpotVolumeLight(i,1);
            }
            ENDHLSL
        }
    }
}

