#ifndef MATCAP_FORWARD_PASS_INCLUDE
#define MATCAP_FORWARD_PASS_INCLUDE

#include "MatcapInput.hlsl"

struct Attritubes
{
    float4 positionOS : POSITION;
    float2 uv         : TEXCOORD0;
    #if ENABLE_MATCAP
        half3 normalOS    : NORMAL;
    #endif
    #if defined(ENABLE_MATCAP) && defined(ENABLE_NORMALMAP)
        half4 tangentOS   : TANGENT;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    #if ENABLE_MATCAP
        float4 uv         : TEXCOORD0;
    #else
        float2 uv         : TEXCOORD0;
    #endif
    #if defined(ENABLE_MATCAP) && defined(ENABLE_NORMALMAP)
        half3 normalWS    : TEXCOORD1;
        half4 tangentWS   : TEXCOORD2;
        half3 positionVS  : TEXCOORD3;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings MatcapVertex (Attritubes i)
{
    Varyings o;

    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_TRANSFER_INSTANCE_ID(i, o);
    
    // Position
    VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
    o.positionCS = vertexInput.positionCS;

    // Model uv
    o.uv.xy = i.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;

    // Matcap uv  Õ‚»¶ ’Àı ƒ⁄»¶¿©…¢
    #if defined(ENABLE_MATCAP) && !defined(ENABLE_NORMALMAP)
        half3 normalVS = normalize(mul((half3x3)UNITY_MATRIX_MV, i.normalOS));
        half3 r = normalize(reflect(vertexInput.positionVS, normalVS));
        #if defined(ENABLE_NORMALANIMTOGGLE)
            half radius = _NormalAnim.w * _Time.y;
            _NormalAnim.xyz = normalize(_NormalAnim.xyz);
            r = normalize(Rotate(r, _NormalAnim.xyz, radius));
        #endif
        half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
        o.uv.zw = r.xy / m + 0.5;

        o.uv.zw -= half2(0.5,0.5);
        o.uv.zw *= _UVScale;
        o.uv.zw += half2(0.5, 0.5);

    #endif

    #if defined(ENABLE_MATCAP) && defined(ENABLE_NORMALMAP)
        VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
        real sign = i.tangentOS.w * GetOddNegativeScale();
        o.tangentWS = half4(normalInput.tangentWS.xyz, sign);
        o.normalWS = normalInput.normalWS;
        o.positionVS = vertexInput.positionVS;
    #endif

    return o;
}

half4 MatcapFragment (Varyings i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);

    // sample the texture
    half4 base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy);
    #if defined(ENABLE_MATCAP) && defined(ENABLE_NORMALMAP)
        half sgn = i.tangentWS.w;      // should be either +1 or -1
        half3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
        half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, i.uv.xy);
        half3 normalTS = UnpackNormalScale(normalMap, _NormalScale);
        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
        half3 normalVS = normalize(mul((half3x3)UNITY_MATRIX_V, normalWS));
        half3 r = normalize(reflect(i.positionVS, normalVS));
        #if defined(ENABLE_NORMALANIMTOGGLE)
            half radius = _NormalAnim.w * _Time.y;
            _NormalAnim.xyz = normalize(_NormalAnim.xyz);
            r = normalize(Rotate(r, _NormalAnim.xyz, radius));
        #endif
        half m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
        i.uv.zw = r.xy / m + 0.5;

        i.uv.zw -= half2(0.5, 0.5);
        i.uv.zw *= _UVScale;
        i.uv.zw += half2(0.5, 0.5);
    #endif

    #if ENABLE_MATCAP
        half4 matcap = SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, i.uv.zw);
        #if MATCAP_OVERLAY
            half3 result1 = 1.0 - 2.0 * (1.0 - base.rgb) * (1.0 - matcap.rgb);
            half3 result2 = 2.0 * base.rgb * matcap.rgb;
            half3 zeroOrOne = step(base.rgb, 0.5);
            half3 final = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #elif MATCAP_MULTIPLY
            half3 final = base.rgb * matcap.rgb;
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #elif MATCAP_ADDITIVE
            base.rgb += matcap.rgb * _MatcapScale;

        #elif MATCAP_SOFTLIGHT
            half3 result1 = 2.0 * base.rgb * matcap.rgb + base.rgb * base.rgb * (1.0 - 2.0 * matcap.rgb);
            half3 result2 = sqrt(base.rgb) * (2.0 * matcap.rgb - 1.0) + 2.0 * base.rgb * (1.0 - matcap.rgb);
            half3 zeroOrOne = step(0.5, matcap.rgb);
            half3 final = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #elif MATCAP_PINLIGHT
            half3 check = step (0.5, matcap.rgb);
            half3 result1 = check * max(2.0 * (base.rgb - 0.5), matcap.rgb);
            half3 final = result1 + (1.0 - check) * min(2.0 * base.rgb, matcap.rgb);
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #elif MATCAP_LIGHTEN
            half3 final = max(matcap.rgb, base.rgb);
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #elif MATCAP_DARKEN
            half3 final = min(matcap.rgb, base.rgb);
            base.rgb = lerp(base.rgb, final, _MatcapScale);

        #endif
    #endif

    return base * _BaseColor;
}

#endif //MATCAP_FORWARD_PASS_INCLUDE