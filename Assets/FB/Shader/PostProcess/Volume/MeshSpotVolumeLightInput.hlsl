#ifndef VOLUMELIGHTINPUT_INCLUDE
#define VOLUMELIGHTINPUT_INCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    struct Attritubes
    {
        float4 positionOS : POSITION;
        float2 uv : TEXCOORD0;
        float3 normal:NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS   : SV_POSITION;
        float2 uv           : TEXCOORD0;
        float3 posWS   : TEXCOORD1;
        float lerpValue   : TEXCOORD2;
        half4 projection:TEXCOORD3;
        float3 normal:TEXCOORD4;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    TEXTURE2D_X(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D_X(_CameraDepthTexture);
    SAMPLER(sampler_CameraDepthTexture);

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float3, _ConeIntersectPA)
        UNITY_DEFINE_INSTANCED_PROP(float, _ConeIntersectRA)
        UNITY_DEFINE_INSTANCED_PROP(float3, _ConeIntersectPB)
        UNITY_DEFINE_INSTANCED_PROP(float, _ConeIntersectRB)
        UNITY_DEFINE_INSTANCED_PROP(float3, _LightWorldPos)
        UNITY_DEFINE_INSTANCED_PROP(float, _CosAnB)
        UNITY_DEFINE_INSTANCED_PROP(float, _OffsetY)
        UNITY_DEFINE_INSTANCED_PROP(float3, _LightForDir)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CamForDir)
        UNITY_DEFINE_INSTANCED_PROP(half, _Density)
        UNITY_DEFINE_INSTANCED_PROP(half4, _LightBlendColor)
        UNITY_DEFINE_INSTANCED_PROP(half4, _LightColor)
        UNITY_DEFINE_INSTANCED_PROP(half, _LightIntensity)
        UNITY_DEFINE_INSTANCED_PROP(half, _LengthScale)
        UNITY_DEFINE_INSTANCED_PROP(half, _DepthEdge)
        UNITY_DEFINE_INSTANCED_PROP(half, _Intensity)

        UNITY_DEFINE_INSTANCED_PROP(float3, _CullPlantPointA)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CullPlantPointB)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CullPlantPointC)
  
        UNITY_DEFINE_INSTANCED_PROP(float3, _DepthPlantPointA)
        UNITY_DEFINE_INSTANCED_PROP(float3, _DepthPlantPointB)
        UNITY_DEFINE_INSTANCED_PROP(float3, _DepthPlantPointC)

        UNITY_DEFINE_INSTANCED_PROP(float, _CosAngOut)
        UNITY_DEFINE_INSTANCED_PROP(float, _CosAngIn)

        UNITY_DEFINE_INSTANCED_PROP(float3, _CylinderPlantA)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CylinderPlantB)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CylinderPlantC)
        UNITY_DEFINE_INSTANCED_PROP(float, _CylinderRadius)
        UNITY_DEFINE_INSTANCED_PROP(float, _CylinderLength)
        UNITY_DEFINE_INSTANCED_PROP(float3, _CylinderForDir)
        UNITY_DEFINE_INSTANCED_PROP(float, _CylinderIntensity)

    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    #define GET_PROP(propName) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, propName)

#endif
