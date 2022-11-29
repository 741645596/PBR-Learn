#ifndef MATH_INCLUDE
#define MATH_INCLUDE

#ifndef PI
#define PI      3.14159265359
#endif

#ifndef PI
#define TWO_PI  6.28318530717958647693
#endif

#ifndef InvPI
#define InvPI   0.31830988618379067154
#endif

#ifndef HALF_PI
#define HALF_PI            1.570796327
#endif

//------------------------------------------------------------------------------
// Scalar operations
//------------------------------------------------------------------------------

/**
 * Computes x^5 using only multiply operations.
 *
 * @public-api
 */
float Pow5(float x) 
{
    float x2 = x * x;
    return x2 * x2 * x;
}

/**
 * Computes x^4 using only multiply operations.
 *
 * @public-api
 */
 
// half3 pow4(half3 color) {
// 	half3 c = color * color;
// 	return c * c;
// }

// half3 pow4(half p) {
// 	half c = p * p;
// 	return c * c;
// }


/**
 * Computes x^2 as a single multiplication.
 *
 * @public-api
 */
float Pow2(float x) 
{
    return x * x;
}

half SimpleSmoothStep(half low, half high, half value)
{
    return saturate((value - low) / (high - low));
}

half2 SimpleSmoothStep(half2 low, half2 high, half2 value)
{
    return saturate((value - low) / (high - low));
}

half3 SimpleSmoothStep(half3 low, half3 high, half3 value)
{
    return saturate((value - low) / (high - low));
}

half4 SimpleSmoothStep(half4 low, half4 high, half4 value)
{
    return saturate((value - low) / (high - low));
}

half Remap(half In, half2 InMinMax, half2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

float Square( float x )
{
	return x*x;
}

float2 Square( float2 x )
{
	return x*x;
}

float3 Square( float3 x )
{
	return x*x;
}

float4 Square( float4 x )
{
	return x*x;
}

half4 EncodeHDR(half3 color)
{
    #if _USE_RGBM
        half4 outColor = EncodeRGBM(color);
    #else
        half4 outColor = half4(color, 1.0);
    #endif

    #if UNITY_COLORSPACE_GAMMA
        return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
    #else
        return outColor;
    #endif
}

half3 DecodeHDR(half4 color)
{
    #if UNITY_COLORSPACE_GAMMA
        color.xyz *= color.xyz; // γ to linear
    #endif

    #if _USE_RGBM
        return DecodeRGBM(color);
    #else
        return color.xyz;
    #endif
}

half3 Contrast(half3 color, half c)
{
    half midpoint = pow(0.5, 2.2);
    return (color - midpoint) * c + midpoint;
}

half3 Saturation(half3 color, half s)
{
    half luma = dot(color, half3(0.2126729, 0.7151522, 0.0721750));
    return luma.xxx + s.xxx * (color - luma.xxx);
}


half SinusoidsWave(float2 pos, half amplitude, half length, half speed, float time, half2 direction, out half3 normal, out half3 tangent)
{
    half frequency = 1.0 / length;
    half phase = speed * frequency;
    half f = dot(direction, pos) * frequency - phase * time;
    
    half sinf, cosf;
    sincos(f, sinf, cosf);
    half height = amplitude * sinf;
    half2 derivative = direction * ((1 / speed) * amplitude * cos(f));
    normal = half3(derivative.x, derivative.y, -1);
    tangent = half3(0, -1, -derivative.y);
    return height;
}

// wave.xy: direction;  wave.z: steepness;  wave.w: wavelength;
half3 GerstnerWave(half4 wave, half3 p, inout half3 tangent, inout half3 bitangent) 
{
    half steepness = wave.z;
    half wavelength = wave.w;
    half k = 2 * PI / wavelength;
    half c = sqrt(9.8 / k);
    half2 d = normalize(wave.xy);
    half f = k * (dot(d, p.xz) - c * _Time.y);
    half a = steepness / k;
    half sinf = 0;
    half cosf = 0;
    sincos(f, sinf, cosf);
    
    tangent += float3(
        -d.x * d.x * (steepness * sinf),
        d.x * (steepness * cosf),
        -d.x * d.y * (steepness * sinf)
    );
    bitangent += float3(
        -d.x * d.y * (steepness * sinf),
        d.y * (steepness * cosf),
        -d.y * d.y * (steepness * sinf)
    );
    return float3(
        d.x * (a * cosf),
        a * sinf,
        d.y * (a * cosf)
    );
}

#define POW_CLAMP 0.000001f

// Clamp the base, so it's never <= 0.0f (INF/NaN).
float ClampedPow(float X,float Y)
{
	return pow(max(abs(X),POW_CLAMP),Y);
}
float2 ClampedPow(float2 X,float2 Y)
{
	return pow(max(abs(X),float2(POW_CLAMP,POW_CLAMP)),Y);
}
float3 ClampedPow(float3 X,float3 Y)
{
	return pow(max(abs(X),float3(POW_CLAMP,POW_CLAMP,POW_CLAMP)),Y);
}  
float4 ClampedPow(float4 X,float4 Y)
{
	return pow(max(abs(X),float4(POW_CLAMP,POW_CLAMP,POW_CLAMP,POW_CLAMP)),Y);
} 
/** 
 * Use this function to compute the pow() in the specular computation.
 * This allows to change the implementation depending on platform or it easily can be replaced by some approxmation.
 */
float PhongShadingPow(float X, float Y)
{
	// The following clamping is done to prevent NaN being the result of the specular power computation.
	// Clamping has a minor performance cost.

	// In HLSL pow(a, b) is implemented as exp2(log2(a) * b).

	// For a=0 this becomes exp2(-inf * 0) = exp2(NaN) = NaN.

	// As seen in #TTP 160394 "QA Regression: PS3: Some maps have black pixelated artifacting."
	// this can cause severe image artifacts (problem was caused by specular power of 0, lightshafts propagated this to other pixels).
	// The problem appeared on PlayStation 3 but can also happen on similar PC NVidia hardware.

	// In order to avoid platform differences and rarely occuring image atrifacts we clamp the base.

	// Note: Clamping the exponent seemed to fix the issue mentioned TTP but we decided to fix the root and accept the
	// minor performance cost.

	return ClampedPow(X, Y);
}


float Sigmoid(float x, float center, float sharp) 
{
    float s;
    s = 1 / (1 + pow(100000, (-3 * sharp * (x - center))));
    return s;
}

half3 AntiACESToneMapping(half3 color)
{
    half3 x = saturate(color);
    half3 a = -10127.0 * x * x + 13702.0 * x + 9.0;
    half3 b = 5.0 * pow(a, 0.5) + 295.0 * x - 15.0;
    half3 c = b / (2008.0 - 1994.0 * x);
    return c;
}

//====
//note: normalized random, float=[0;1[
float PDnrand( float2 n ) {
	return frac( sin(dot(n.xy, float2(12.9898f, 78.233f)))* 43758.5453f );
}
float2 PDnrand2( float2 n ) {
	return frac( sin(dot(n.xy, float2(12.9898f, 78.233f)))* float2(43758.5453f, 28001.8384f) );
}
float3 PDnrand3( float2 n ) {
	return frac( sin(dot(n.xy, float2(12.9898f, 78.233f)))* float3(43758.5453f, 28001.8384f, 50849.4141f ) );
}
float4 PDnrand4( float2 n ) {
	return frac( sin(dot(n.xy, float2(12.9898f, 78.233f)))* float4(43758.5453f, 28001.8384f, 50849.4141f, 12996.89f) );
}

//====
//note: signed random, float=[-1;1[
float PDsrand( float2 n ) {
	return PDnrand( n ) * 2 - 1;
}
float2 PDsrand2( float2 n ) {
	return PDnrand2( n ) * 2 - 1;
}
float3 PDsrand3( float2 n ) {
	return PDnrand3( n ) * 2 - 1;
}
float4 PDsrand4( float2 n ) {
	return PDnrand4( n ) * 2 - 1;
}

float Unity_Dither_float(float In, float2 ScreenPosition)
{

    float2 uv = ScreenPosition * _ScreenParams.xy;

    float DITHER_THRESHOLDS[16] =
    {

        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,

        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,

        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,

        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };

    uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;

    return In - DITHER_THRESHOLDS[index];
}

half Dither8x8Bayer( int x, int y )
{
    const half dither[ 64 ] = {
        1, 49, 13, 61,  4, 52, 16, 64,
        33, 17, 45, 29, 36, 20, 48, 32,
        9, 57,  5, 53, 12, 60,  8, 56,
        41, 25, 37, 21, 44, 28, 40, 24,
        3, 51, 15, 63,  2, 50, 14, 62,
        35, 19, 47, 31, 34, 18, 46, 30,
        11, 59,  7, 55, 10, 58,  6, 54,
        43, 27, 39, 23, 42, 26, 38, 22};
    int r = y * 8 + x;
    return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
}

half Dither4x4Bayer(int x, int y)
{
    const half dither[16] = {
        1.0,    9.0,    3.0,    11.0,
        13.0,   5.0,    15.0,   7.0,
        4.0,    12.0,   2.0,    10.0,
        16.0,   8.0,    14.0,   6.0
    };
    int r = y * 4 + x;
    return dither[r] / 16;
}

half4 Quaternion(half3 v, half theta)
{
    half sin, cos;
    sincos(theta / 2, sin, cos);

    half4 q = half4(0, 0, 0, cos);
    q.x = v.x * sin;
    q.y = v.y * sin;
    q.z = v.z * sin;

    return q;
}

half3 Rotate(half3 p, half3 v, half theta)
{
    half4 q = Quaternion(v, theta);

    half3 t = cross(q.xyz, p) + q.w * p;
    return p + 2 * cross(q.xyz, t);
}

#endif // MATH_INCLUDE