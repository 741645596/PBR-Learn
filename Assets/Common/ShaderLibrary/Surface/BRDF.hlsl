#ifndef BRDF_INCLUDE
#define BRDF_INCLUDE

#define MEDIUMP_FLT_MAX    65504.0
#define MEDIUMP_FLT_MIN    0.00006103515625
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

#ifndef kDieletricSpec
    #define kDieletricSpec  half4(0.04, 0.04, 0.04, 1.0 - 0.04)
#endif
#ifndef kSkinSpec
    #define kSkinSpec       half4(0.028, 0.028, 0.028, 1.0 - 0.028)
#endif
#ifndef kHairSpec
    #define kHairSpec       half4(0.046, 0.046, 0.046, 1.0 - 0.028)
#endif

#define M_HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define M_HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    // min roughness such that (MIN_PERCEPTUAL_ROUGHNESS^4) > 0 in fp16 (i.e. 2^(-14/4), rounded up)
    #define MIN_PERCEPTUAL_ROUGHNESS 0.089
    #define MIN_ROUGHNESS            0.007921
#else
    #define MIN_PERCEPTUAL_ROUGHNESS 0.045
    #define MIN_ROUGHNESS            0.002025
#endif

#include "../Math/Math.hlsl"

//------------------------------------------------------------------------------
// Specular BRDF
//------------------------------------------------------------------------------

///////////////// Isotropy ///////////////////
half GGX_Unity(float NoH, half LoH2, half roughness2, half roughness2MinusOne, half normalizationTerm)
{    
    // Normal Distribution & Fersnel
    float d = NoH * NoH * roughness2MinusOne + 1.00001f;
    half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);

    return specularTerm;
}

half D_GGX_Mobile(half Roughness, float NoH)
{
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
	float OneMinusNoHSqr = 1.0 - NoH * NoH; 
	half a = Roughness * Roughness;
	half n = NoH * a;
	half p = a / (OneMinusNoHSqr + n * n);
	half d = p * p;
	// clamp to avoid overlfow in a bright env
	return min(d, MEDIUMP_FLT_MAX);
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float D_GGX_UE4( float a2, float NoH )
{
    float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
    return a2 / ( PI * d * d );					// 4 mul, 1 rcp
}

// Input roughness = percepturalRoughness ^ 2
half D_GGX_Fast(half roughness, half NoH, half3 N, half3 H) 
{
    half3 NxH = cross(N, H);
    half oneMinusNoHSquared = dot(NxH, NxH);
    half a = NoH * roughness;
    half k = roughness / (oneMinusNoHSquared + a * a);
    half d = k * k * (1.0 / PI);
    // return clamp(d, 0, 10);
    return saturateMediump(d);
}

// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
float D_Beckmann( float a2, float NoH )
{
	float NoH2 = NoH * NoH;
	return exp( (NoH2 - 1) / (a2 * NoH2) ) / ( PI * a2 * NoH2 * NoH2 );
}


//////////////////////// Anisotropy //////////////////////
float D_InvGGX( float a2, float NoH )
{
	float A = 4;
	float d = ( NoH - a2 * NoH ) * NoH + a2;
	return rcp( PI * (1 + A*a2) ) * ( 1 + 4 * a2*a2 / ( d*d ) );
}

// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
float D_GGXaniso( float ax, float ay, float NoH, float XoH, float YoH )
{
	float a2 = ax * ay;
	float3 V = float3(ay * XoH, ax * YoH, a2 * NoH);
	float S = dot(V, V);

	return (1.0f / PI) * a2 * Pow2(a2 / S);
}

//////////////////////// Fabric /////////////////////////
float D_Charlie_Unity(float NdotH, float roughness)
{
    float invR = rcp(roughness);
    float cos2h = NdotH * NdotH;
    float sin2h = 1.0 - cos2h;
    // Note: We have sin^2 so multiply by 0.5 to cancel it
    return (2.0 + invR) * PositivePow(sin2h, invR * 0.5) / 2.0 / PI;
}


// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointApprox( float a2, float NoV, float NoL )
{
    float a = sqrt(a2);
    float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
    float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
    return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
}

half V_SmithGGXCorrelated_Fast(half roughness, half NoV, half NoL) 
{
    // Hammon 2017, "PBR Diffuse Lighting for GGX+Smith Microsurfaces"
    half v = 0.5 / lerp(2.0 * NoL * NoV, NoL + NoV, roughness);
    return saturateMediump(v);
}

// We use V_Ashikhmin instead of V_Charlie in practice for game due to the cost of V_Charlie
half V_Ashikhmin_Unity(half NdotL, half NdotV)
{
    // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
    return 1.0 / (4.0 * (NdotL + NdotV - NdotL * NdotV));
}

// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL)
{
	float Vis_SmithV = NoL * length(float3(ax * XoV, ay * YoV, NoV));
	float Vis_SmithL = NoV * length(float3(ax * XoL, ay * YoL, NoL));
	return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
}

half3 F_Schlick_Fast(half3 f0, half VoH) 
{
    half f = Pow5(1.0 - VoH);
    return f + f0 * (1.0 - f);
}

half3 F_SchlickRoughness(half cosTheta, half3 F0, half roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}  

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
float3 F_Schlick_UE4( float3 SpecularColor, float VoH )
{
    float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
    //return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
                
    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
                
}

float Fresnel_Dielectric(float3 Incoming, float3 Normal, float eta)
{
    // compute fresnel reflectance without explicitly computing
    // the refracted direction
    float c = abs(dot(Incoming, Normal));
    float g = eta * eta - 1.0 + c * c;

    if(g > 0.0)
    {
        g = sqrt(g);
        float A = (g - c) / (g + c);
        float B = (c * (g + c) - 1.0) / (c * (g - c) + 1.0);
        
        return 0.5 * A * A * (1.0 + B * B);
    }
    
    return 1.0; // TIR (no refracted component)
}


//------------------------------------------------------------------------------
// Diffuse BRDF
//------------------------------------------------------------------------------

half Fd_Lambert() {
    return 1.0 / PI;
}

float Fd_Burley(float roughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    //float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    //float lightScatter = F_Schlick(1.0, f90, NoL);
    //float viewScatter  = F_Schlick(1.0, f90, NoV);
    //return lightScatter * viewScatter * (1.0 / PI);
    return 1;
}

half Fd_Fabric(half roughness)
{
    return lerp(1.0, 0.5, roughness) / PI;
}

//-------------------------------------------------------------------------------
// Iridescence
//------------------------------------------------------------------------------

// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
float3 Iri_Sensitivity(float opd, float shift)
{
    // Use Gaussian fits, given by 3 parameters: val, pos and var
    float phase = 2.0 * PI * opd * 1e-6;
    float3 val = float3(5.4856e-13, 4.4201e-13, 5.2481e-13);
    float3 pos = float3(1.6810e+06, 1.7953e+06, 2.2084e+06);
    float3 var = float3(4.3278e+09, 9.3046e+09, 6.6121e+09);
    float3 xyz = val * sqrt(2.0 * PI * var) * cos(pos * phase + shift) * exp(-var * phase * phase);
    xyz.x += 9.7470e-14 * sqrt(2.0 * PI * 4.5282e+09) * cos(2.2399e+06 * phase + shift) * exp(-4.5282e+09 * phase * phase);
    xyz /= 1.0685e-7;

    // Convert to linear sRGb color space here.
    // EvalIridescence works in linear sRGB color space and does not switch...
    float3 srgb = mul(XYZ_2_REC709_MAT, xyz);
    return srgb;
}

// Evaluate the reflectance for a thin-film layer on top of a dielectric medum.
half3 F_Iridescence(half eta_1, half cosTheta1, half iridescenceThickness, half3 baseLayerFresnel0, half iorOverBaseLayer = 0.0)
{
    half3 I;

    // iridescenceThickness unit is micrometer for this equation here. Mean 0.5 is 500nm.
    half Dinc = 3.0 * iridescenceThickness;

    // Note: Unlike the code provide with the paper, here we use schlick approximation
    // Schlick is a very poor approximation when dealing with iridescence to the Fresnel
    // term and there is no "neutral" value in this unlike in the original paper.
    // We use Iridescence mask here to allow to have neutral value

    // Hack: In order to use only one parameter (DInc), we deduced the ior of iridescence from current Dinc iridescenceThickness
    // and we use mask instead to fade out the effect
    half eta_2 = lerp(2.0, 1.0, iridescenceThickness);
    // Following line from original code is not needed for us, it create a discontinuity
    // Force eta_2 -> eta_1 when Dinc -> 0.0
    // float eta_2 = lerp(eta_1, eta_2, smoothstep(0.0, 0.03, Dinc));
    // Evaluate the cosTheta on the base layer (Snell law)
    half sinTheta2Sq = Sq(eta_1 / eta_2) * (1.0 - Sq(cosTheta1));

    // Handle TIR:
    // (Also note that with just testing sinTheta2Sq > 1.0, (1.0 - sinTheta2Sq) can be negative, as emitted instructions
    // can eg be a mad giving a small negative for (1.0 - sinTheta2Sq), while sinTheta2Sq still testing equal to 1.0), so we actually
    // test the operand [cosTheta2Sq := (1.0 - sinTheta2Sq)] < 0 directly:)
    half cosTheta2Sq = (1.0 - sinTheta2Sq);
    // Or use this "artistic hack" to get more continuity even though wrong (no TIR, continue the effect by mirroring it):
    //   if( cosTheta2Sq < 0.0 ) => { sinTheta2Sq = 2 - sinTheta2Sq; => so cosTheta2Sq = sinTheta2Sq - 1 }
    // ie don't test and simply do
    //   float cosTheta2Sq = abs(1.0 - sinTheta2Sq);
    if (cosTheta2Sq < 0.0)
        I = half3(1.0, 1.0, 1.0);
    else
    {
        half cosTheta2 = sqrt(cosTheta2Sq);

        // First interface
        half R0 = IorToFresnel0(eta_2, eta_1);
        half R12 = F_Schlick(R0, cosTheta1);
        half R21 = R12;
        half T121 = 1.0 - R12;
        half phi12 = 0.0;
        half phi21 = PI - phi12;

        // Second interface
        // The f0 or the base should account for the new computed eta_2 on top.
        // This is optionally done if we are given the needed current ior over the base layer that is accounted for
        // in the baseLayerFresnel0 parameter:
        if (iorOverBaseLayer > 0.0)
        {
            // Fresnel0ToIor will give us a ratio of baseIor/topIor, hence we * iorOverBaseLayer to get the baseIor
            half3 baseIor = iorOverBaseLayer * Fresnel0ToIor(baseLayerFresnel0 + 0.0001); // guard against 1.0
            baseLayerFresnel0 = IorToFresnel0(baseIor, eta_2);
        }

        half3 R23 = F_Schlick(baseLayerFresnel0, cosTheta2);
        half  phi23 = 0.0;

        // Phase shift
        half OPD = Dinc * cosTheta2;
        half phi = phi21 + phi23;

        // Compound terms
        half3 R123 = clamp(R12 * R23, 1e-5, 0.9999);
        half3 r123 = sqrt(R123);
        half3 Rs = Sq(T121) * R23 / (half3(1.0, 1.0, 1.0) - R123);

        // Reflectance term for m = 0 (DC term amplitude)
        half3 C0 = R12 + Rs;
        I = C0;

        // Reflectance term for m > 0 (pairs of diracs)
        half3 Cm = Rs - T121;
        for (int m = 1; m <= 2; ++m)
        {
            Cm *= r123;
            float3 Sm = 2.0 * Iri_Sensitivity(m * OPD, m * phi);
            //vec3 SmP = 2.0 * evalSensitivity(m*OPD, m*phi2.y);
            I += Cm * Sm;
        }

        // Since out of gamut colors might be produced, negative color values are clamped to 0.
        I = max(I, half3(0.0, 0.0, 0.0));
    }

    return I;
}


//------------------------------------------------------------------------------
// Other BRDF
//------------------------------------------------------------------------------

half3 LightRim2(half3 N, half3 V, half4 rimColor)
{
    half NoV = saturate(dot(N, V));
    return pow(1.0 - NoV, 0.5) * rimColor.rgb * rimColor.a;
}


float3 EnvDFGLazarov( float3 specularColor, float gloss, float ndotv )
{
    float4 p0 = float4( 0.5745, 1.548, -0.02397, 1.301 );
    float4 p1 = float4( 0.5753, -0.2511, -0.02066, 0.4755 );
    float4 t = gloss * p0 + p1;
    float bias = saturate( t.x * min( t.y, exp2( -7.672 * ndotv ) ) + t.z );
    float delta = saturate( t.w );
    float scale = delta - bias;
    bias *= saturate( 50.0 * specularColor.y );
    return specularColor * scale + bias;
}

float2 Hammersley(uint i, float numSamples) 
{
    uint bits = i;
    bits = (bits << 16) | (bits >> 16);
    bits = ((bits & 0x55555555) << 1) | ((bits & 0xAAAAAAAA) >> 1);
    bits = ((bits & 0x33333333) << 2) | ((bits & 0xCCCCCCCC) >> 2);
    bits = ((bits & 0x0F0F0F0F) << 4) | ((bits & 0xF0F0F0F0) >> 4);
    bits = ((bits & 0x00FF00FF) << 8) | ((bits & 0xFF00FF00) >> 8);
    return float2(i / numSamples, bits / exp2(32));
}

float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
{
    float a = roughness*roughness;

    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    // from spherical coordinates to cartesian coordinates
    float3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;

    // from tangent-space floattor to world-space sample floattor
    float3 up        = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
    float3 tangent   = normalize(cross(up, N));
    float3 bitangent = cross(N, tangent);

    float3 samplefloat = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(samplefloat);
}

#endif // BRDF_INCLUDE