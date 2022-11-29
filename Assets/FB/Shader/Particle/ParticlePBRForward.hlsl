#ifndef PBR_FORWARD_INCLUDE
#define PBR_FORWARD_INCLUDE

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS      : NORMAL;
    float2 uv           : TEXCOORD0;
    #if ENABLE_NORMALMAP
        float4 tangentOS     : TANGENT;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    #if ENABLE_NORMALMAP
        half4 normalWS      : TEXCOORD1;
        half4 tangentWS     : TEXCOORD2;
        half4 bitangentWS   : TEXCOORD3;
    #else
        half3 normalWS      : TEXCOORD1;
        half3 viewDirWS     : TEXCOORD2;
    #endif
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
        float4 shadowCoord  : TEXCOORD4;
    #endif
    half3 vertexSH      : TEXCOORD5;
    float3 positionWS   : TEXCOORD6;
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings PBRVert (Attributes i)
{
    Varyings o;
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_TRANSFER_INSTANCE_ID(i, o);

    // Position
    VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
    o.positionCS = vertexInput.positionCS;
    o.positionWS = vertexInput.positionWS;
    // UV
    o.uv = TRANSFORM_TEX(i.uv, _BaseMap);
    // View
    half3 viewDirWS = (GetCameraPositionWS() - vertexInput.positionWS);

    // Normal
    #if ENABLE_NORMALMAP
        VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
        real sign = i.tangentOS.w * GetOddNegativeScale();
        o.tangentWS = half4(normalInput.tangentWS.xyz, viewDirWS.x);
        o.bitangentWS = half4(sign * cross(normalInput.normalWS.xyz, normalInput.tangentWS.xyz), viewDirWS.y);
        o.normalWS = half4(normalInput.normalWS.xyz, viewDirWS.z);
    #else
        VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS);
        o.normalWS = normalInput.normalWS;
        o.viewDirWS = viewDirWS;
    #endif

    // Shadow
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
        o.shadowCoord = GetShadowCoord(vertexInput);
    #endif

    // GI
    o.vertexSH = SampleSHVertex(o.normalWS.xyz);
    return o;
}

void EvaluatePixelData(inout PixelData pixel, Varyings i)
{
    // Base color
    half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
    #if _ALPHATEST_ON
        clip(baseColor.a - _Cutoff);
    #endif

    // Alpha
    pixel.alpha = baseColor.a;

    // Shadow
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF)
        pixel.shadowCoord = i.shadowCoord;
    #endif

    // Add light
    pixel.positionWS = i.positionWS;

    // Normal, View
    #if ENABLE_NORMALMAP
        half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BaseMap, i.uv));
        pixel.normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz)));
        pixel.viewDirWS = normalize(half3(i.tangentWS.w, i.bitangentWS.w, i.normalWS.w));
    #else
        pixel.normalWS = normalize(i.normalWS);
        pixel.viewDirWS = normalize(i.viewDirWS);
    #endif
    pixel.NoV = dot(pixel.normalWS, pixel.viewDirWS);

    // Roughness, Metallic, Occlusion
    half3 rmo = GetRMO(i.uv);
    #if ENABLE_MIXMAP
        half roughness = rmo.r *(1-_Smothness);
    #else
        half roughness=rmo.r;
    #endif
    half metallic = rmo.g * _Metallic;
    half occlusion = rmo.b * _Occlusion;
    pixel.diffuseColor          = baseColor.rgb * (1.0 - metallic);
    pixel.occlusion             = occlusion;
    pixel.perceptualRoughness   = clamp(roughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0f);    // User setup roughness
    pixel.roughness             = max(pixel.perceptualRoughness * pixel.perceptualRoughness, HALF_MIN_SQRT);        // perceptualRoughness ^ 2
    pixel.roughness2            = max(pixel.roughness * pixel.roughness, HALF_MIN);
    pixel.grazingTerm           = saturate((1 - roughness) + (1 - OneMinusReflectivityMetallic(metallic)));
    pixel.f0                    = lerp(kDielectricSpec.rgb, baseColor.rgb, metallic);
    pixel.NoV                   = ClampNdotV(pixel.NoV);
    
    // Emission
    pixel.emission = GetEmission(i.uv);

    // Bake GI
    pixel.bakedGI = SampleSHPixel(i.vertexSH, pixel.normalWS);

    //#if _CUSTOM_LIGHT_COLOR
    //    pixel.customLightColor = _CustomLightColor;
    //#endif
    //#if _CUSTOM_LIGHT_DIR
    //    pixel.customLightDir = normalize(_CustomLightDir.xyz);
    //#endif

     #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) && !defined(_RECEIVE_SHADOWS_OFF) && (defined(ENABLE_HQ_SHADOW) || defined(ENABLE_HQ_AND_UNITY_SHADOW))
         pixel.hqShasow = HighQualityRealtimeShadow(i.positionWS);
     #endif

}

half4 PBRFrag (Varyings i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);

    PixelData pixel;
    EvaluatePixelData(pixel, i);

    half3 color = 0;

    // Indirect
    CalculateIBL(pixel, color);

    // Direct
    CalculateDirectionalLight(pixel, color);

    // Additional 
    #if defined(_ADDITIONAL_LIGHTS)
        CalculateAdditionalLight(pixel, color);
    #endif

    // Emission
    #if ENABLE_EMISSION
        AddEmissive(pixel, color);
    #endif

    return half4(color, pixel.alpha);
}

#endif //PBR_FORWARD_INCLUDE 