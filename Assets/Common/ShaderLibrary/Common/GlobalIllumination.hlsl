#ifndef GLOBAL_ILLUMINATION_INCLUDE
    #define GLOBAL_ILLUMINATION_INCLUDE

    #include "CommonInput.hlsl"

    
    float3 AOMultiBounce( float3 BaseColor, float AO )
    {
        float3 a =  2.0404 * BaseColor - 0.3324;
        float3 b = -4.7951 * BaseColor + 0.6417;
        float3 c =  2.7552 * BaseColor + 0.6903;
        return max( AO, ( ( AO * a + b ) * AO + c ) * AO );
    }

    inline float GetSpecularOcclusion(float NoV, float RoughnessSq, float AO)
    {
        return saturate( pow( abs(NoV + AO), RoughnessSq ) - 1 + AO );
    }

    inline half3 RotateDirection(half3 R, half degrees)
    {
        float3 reflUVW = R;
        half theta = degrees * PI / 180.0f;
        half costha = cos(theta);
        half sintha = sin(theta);
        reflUVW = half3(reflUVW.x * costha - reflUVW.z * sintha, reflUVW.y, reflUVW.x * sintha + reflUVW.z * costha);
        return reflUVW;
    }

    // Specular Occlusion
    // http://media.steampowered.com/apps/valve/2015/Alex_Vlachos_Advanced_VR_Rendering_GDC2015.pdf
    void ModulateSmoothnessByNormal(inout float smoothness, float3 normal)
    {
        float3 normalWsDdx = ddx(normal);
        float3 normalWsDdy = ddy(normal);
        float geometricRoughnessFactor = pow(saturate(max(dot(normalWsDdx, normalWsDdx), dot(normalWsDdy, normalWsDdy))), 0.333f);
        smoothness = min(smoothness, 1.0f - geometricRoughnessFactor);
    }

    half GetReflectionOcclusion_float(float3 normalWS, float3 tangentWS, float3 bitangentWS, float3 viewDirectionWS, float3 normalTS,
    float3 bentNormalTS, float smoothness, float specularOcclusionStrength, float occlusion)
    {
        float3 bentNormalWS = TransformTangentToWorld(bentNormalTS, float3x3(tangentWS, bitangentWS, normalWS));
        float3 normal = TransformTangentToWorld(normalTS, float3x3(tangentWS, bitangentWS, normalWS));
        float3 reflectVector = reflect(-viewDirectionWS, normal);

        #ifdef MODULATE_SMOOTHNESS
            ModulateSmoothnessByNormal(smoothness, normalWS);
        #endif

        float perceptualRoughness = 1 - smoothness;

        // Base signal depends on occlusion and dot product between reflection and bent normal vector
        float occlusionAmount = max(0, dot(reflectVector, bentNormalWS));
        float reflOcclusion = occlusion - (1 - occlusionAmount);
        // Scale with roughness. This is what "sharpens" glossy reflections
        reflOcclusion = saturate(reflOcclusion / perceptualRoughness);
        // Fade between roughness-modulated occlusion and "regular" occlusion based on surface roughness
        // This is done because the roughness-modulated signal doesn't represent rough surfaces very well
        reflOcclusion = lerp(reflOcclusion, lerp(occlusionAmount, 1, occlusion), perceptualRoughness);
        // Scale by color and return
        return lerp(1, reflOcclusion, specularOcclusionStrength);
    }

    half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
    {
        // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
        // Adaptation to fit our G term.
        const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
        const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
        half4 r = Roughness * c0 + c1;
        half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
        half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

        // Anything less than 2% is physically impossible and is instead considered to be shadowing
        // Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
        AB.y *= saturate( 50.0 * SpecularColor.g );

        return SpecularColor * AB.x + AB.y;
    }

    half2 EnvBRDFApproxLazarov(half Roughness, half NoV )
    {
        // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
        // Adaptation to fit our G term.
        const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
        const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
        half4 r = Roughness * c0 + c1;
        half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
        half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

        // Anything less than 2% is physically impossible and is instead considered to be shadowing
        // Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0

        return AB;
    }

    // Same as EnvBRDFApprox( 0.04, Roughness, NoV )    
    half EnvBRDFApproxNonmetal(half roughness, half nv) 
    {               
        const half2 c0 = { -1, -0.0275 }; 
        const half2 c1 = { 1, 0.0425 }; 
        half2 r = roughness * c0 + c1; 
        return max(min( r.x * r.x, exp2( -9.28 * nv ) ) * r.x + r.y, 0);
    }

    half3 UEIBL(float3 R,float3 WorldPos,float Roughness,float3 SpecularColor,float NoV,half occlusion,half2 envBRDF)
    {	
        half3 SpeucularLD = GlossyEnvironmentReflection(R,WorldPos,Roughness,occlusion);
        half3 SpecularDFG = SpecularColor * envBRDF.x + envBRDF.y * saturate( 50.0 * SpecularColor.g);
        return SpeucularLD * SpecularDFG;
    }

    half3 UEIBL(float3 R,float3 WorldPos,float Roughness,float3 SpecularColor,float NoV,half occlusion)
    {	
        half3 SpeucularLD = GlossyEnvironmentReflection(R,WorldPos,Roughness,occlusion);
        half3 SpecularDFG = EnvBRDFApprox(SpecularColor,Roughness,NoV);
        return SpeucularLD * SpecularDFG;
    }

    half3 UnityIBL(half3 brdfSpecular,half grazingTerm,half perceptualRoughness,half roughness2, float3 positionWS,half NoV, half3 R,half occlusion)
    {
        half fresnelTerm = Pow4(1.0 - NoV);
        half3 indirectSpecular = GlossyEnvironmentReflection(R, positionWS,perceptualRoughness,occlusion);

        float surfaceReduction = 1.0 / (roughness2 + 1.0);
        half3 environmentSpecular = surfaceReduction * lerp(brdfSpecular, grazingTerm, fresnelTerm);
        half3 color = indirectSpecular * environmentSpecular;
        return color;
    }

    half3 ClothIBL(half3 specularFGD,half3 R,half iblPerceptualRoughness,half occlusion)
    {
        // Note: using influenceShapeType and projectionShapeType instead of (lightData|proxyData).shapeType allow to make compiler optimization in case the type is know (like for sky)
        half3 indirectSpecular = GlossyEnvironmentReflection(R, iblPerceptualRoughness, occlusion);
        return specularFGD * indirectSpecular;
    }

    ////////////////// Anisotropy /////////////////
    half3 AnisotropyIBL(float3 WorldPos,half Anisotropy,half3 N,half3 V,half3 T,half3 B,float Roughness,float3 SpecularColor,half Occlusion,float NoV)
    {
        float3 anisotropicDirection = Anisotropy >= 0.0 ? B : T;
        float3 anisotropicTangent = cross(anisotropicDirection, V);
        float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
        float3 bentNormal = normalize(lerp(N, anisotropicNormal, abs(Anisotropy)));

        half3 R = reflect(-V,bentNormal);
        half3 SpeucularLD = GlossyEnvironmentReflection(R,WorldPos,Roughness,Occlusion);
        half3 SpecularDFG = EnvBRDFApprox(SpecularColor,Roughness,NoV);
        float SpecularOcclusion = GetSpecularOcclusion(NoV,Pow2(Roughness),Occlusion);
        float3 SpecularAO = AOMultiBounce(SpecularColor,SpecularOcclusion);
        return SpeucularLD * SpecularDFG * SpecularAO;
    }

    void ClearCloatIllumination(
    TextureCube _ClearCoatCubeMap,float4 clearCoatCubeMap_HDR, half clearCoatPerceptualRoughness,half clearCoatMask,
    float3 positionWS,half NoVClearCoat,float3 RClearCoat,
    float3 SurfaceSpecular,float SurfaceOcclusion,
    inout float3 clearcloat_color)
    {
        float specularOcclusion = GetSpecularOcclusion(NoVClearCoat,Pow2(clearCoatPerceptualRoughness),SurfaceOcclusion) /* * inputData.shadowCoord*/;
        float3 specularAO = AOMultiBounce(SurfaceSpecular,specularOcclusion);

        float mip = clearCoatPerceptualRoughness * (1.7 - 0.7 * clearCoatPerceptualRoughness) * 6;

        // Custom Indirect Clear Coat Cube Map
        // #if defined(_CLEARCOATCUBEMAP_ON)
        float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(_ClearCoatCubeMap, sampler_LinearRepeat, RClearCoat, mip));
        float3 irradiance = DecodeHDREnvironment(encodedIrradiance, clearCoatCubeMap_HDR);
        // #else
        // float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, RClearCoat, mip));
        // float3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
        // #endif

        float3 clearCoatLobe = irradiance * EnvBRDFApprox(kDieletricSpec.xxx,clearCoatPerceptualRoughness,NoVClearCoat);
        float3 IndirectClearCoat = clearCoatLobe * clearCoatMask * specularAO;

        float coatFresnel = kDieletricSpec.x + kDieletricSpec.a * Pow4(1.0 - NoVClearCoat);
        clearcloat_color = clearcloat_color * (1.0 - coatFresnel * clearCoatMask) + IndirectClearCoat;
    }


    ////////////////  Anisotropic image based lighting //////////////////////
    // T is the fiber axis (hair strand direction, root to tip).
    float3 ComputeViewFacingNormal_SGame(float3 V, float3 T)
    {
        return Orthonormalize(V, T);
    }

    // Fake anisotropy by distorting the normal (non-negative anisotropy values only).
    // The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to N.
    // Anisotropic ratio (0->no isotropic; 1->full anisotropy in tangent direction)
    float3 GetAnisotropicModifiedNormal_SGame(float3 grainDir, float3 N, float3 V, float anisotropy)
    {
        float3 grainNormal = ComputeViewFacingNormal(V, grainDir);
        return normalize(lerp(N, grainNormal, anisotropy));
    }

    // For GGX aniso and IBL we have done an empirical (eye balled) approximation compare to the reference.
    // We use a single fetch, and we stretch the normal to use based on various criteria.
    // result are far away from the reference but better than nothing
    // Anisotropic ratio (0->no isotropic; 1->full anisotropy in tangent direction) - positive use bitangentWS - negative use tangentWS
    // Note: returned iblPerceptualRoughness shouldn't be use for sampling FGD texture in a pre-integration
    void GetGGXAnisotropicModifiedNormalAndRoughness_SGame(float3 bitangentWS, float3 tangentWS, float3 N, float3 V, float anisotropy, float perceptualRoughness, out float3 iblN, out float iblPerceptualRoughness)
    {
        // For positive anisotropy values: tangent = highlight stretch (anisotropy) direction, bitangent = grain (brush) direction.
        float3 grainDirWS = (anisotropy >= 0.0) ? bitangentWS : tangentWS;
        // Reduce stretching depends on the perceptual roughness
        float stretch = abs(anisotropy) * saturate(1.5 * sqrt(perceptualRoughness));
        // NOTE: If we follow the theory we should use the modified normal for the different calculation implying a normal (like NdotV)
        // However modified normal is just a hack. The goal is just to stretch a cubemap, no accuracy here. Let's save performance instead.
        iblN = GetAnisotropicModifiedNormal(grainDirWS, N, V, stretch);
        iblPerceptualRoughness = perceptualRoughness * saturate(1.2 - abs(anisotropy));
    }

    //////////// SH ////////////////
    // normal should be normalized, w=1.0
    half3 SHEvalLinearL0L1(half4 normal)
    {
        half3 x;

        // Linear (L1) + constant (L0) polynomial terms
        x.r = dot(unity_SHAr, normal);
        x.g = dot(unity_SHAg, normal);
        x.b = dot(unity_SHAb, normal);

        return x;
    }

    // normal should be normalized, w=1.0
    half3 SHEvalLinearL2(half3 normal)
    {
        half3 x1, x2;
        // 4 of the quadratic (L2) polynomials
        half4 vB = normal.xyzz * normal.yzzx;
        x1.r = dot(unity_SHBr, vB);
        x1.g = dot(unity_SHBg, vB);
        x1.b = dot(unity_SHBb, vB);

        // Final (5th) quadratic (L2) polynomial
        half vC = normal.x*normal.x - normal.y*normal.y;
        x2 = unity_SHC.rgb * vC;

        return x1 + x2;
    }

    half3 SGameSH9(half3 normal)
    {
        // Linear + constant polynomial terms
        half3 res = SHEvalLinearL0L1(half4(normal,1));

        res = lerp(max(res.x, max(res.y, res.z)), res, 0.25);

        // Quadratic polynomials
        res += SHEvalLinearL2(normal);

        return res;
    }


#endif  // GLOBAL_ILLUMINATION_INCLUDE