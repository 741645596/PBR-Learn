#ifndef SHADING_MOEDEL_INCLUDE
    #define SHADING_MOEDEL_INCLUDE
    
    #include "BRDF.hlsl"

    struct SurfaceData_SGame
    {
        half3 albedo;
        half3 specular;
        half  metallic;
        half  smoothness;
        half  occlusion;
        half  reflectance;
        half  alpha;

        half3 emission;

        #if defined(_CLEARCOAT_ON)
            half  clearCoatMask;
            half  clearCoatSmoothness;
        #endif

        #if defined(_IRIDENSCENE_ON)
            half  iridescence;
        #endif

        #if defined(_LASER_ON)
            half  laser;
        #endif

        #if defined(_ANISOTROPY_ON) || defined(_SILK_ON)
            half anisotropy;
        #endif
    };

    struct InputData_SGame 
    {
        float4  positionCS;
        float3  positionWS;

        half3   normalWS;
        half3x3 TBN;  

        half3   viewDirWS;

        half    fogCoord;

        half3   Irradiance;

        #if defined(_SPECULAROCCLUSION_ON)
            half3	bentNormalWS;
        #endif

        #if defined(_ADDITIONAL_LIGHTS_VERTEX)
            half3   vertexLighting;
        #endif

        #if defined(_CLEARCOAT_ON)
            half3 clearCoatNormalWS;
        #endif
    };

    struct BRDFData_PBR
    {
        half3 albedo;
        half3 diffuse;
        half3 specular;
        
        half perceptualRoughness;
        half roughness;
        half roughness2;
        
        half grazingTerm;
        half normalizationTerm;     // roughness * 4.0 + 2.0
        half roughness2MinusOne;    // roughness^2 - 1.0
        
        half2 envBRDF;

        #if defined(_CLEARCOAT_ON)
            half clearCoatPerceptualRoughness;
            half clearCoatRoughness;
            half clearCoatRoughness2;
            
            half clearCoatNormalizationTerm;     
            half clearCoatRoughness2MinusOne;   
        #endif
    };

    half UnitySpecular(half3 N, half3 L, half3 V,half roughness2MinusOne,half roughness2,half normalizationTerm)
    {
        float3 H = SafeNormalize(float3(L) + float3(V));

        half NoV = saturate(dot(N, V));
        half NoL = dot(N, L);
        float NoH = saturate(dot(N, H));
        float LoH = saturate(dot(L, H));
        float LoH2 = LoH * LoH;

        half specularTerm = GGX_Unity(NoH,LoH2,roughness2,roughness2MinusOne,normalizationTerm);
        
        // On platforms where half actually means something, the denominator has a risk of overflow
        // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
        // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - M_HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif

        // specularTerm = clamp(specularTerm, 0, 8);

        return specularTerm;
    }

    //SecondLobeRoughnessDerivation 0-1 
    //SpecularLobeInterpolation 0-1
    half UnitySpecularWithTwoLobes
    (
    half3 N, half3 L, half3 V,
    half SecondLobeRoughnessDerivation,half SpecularLobeInterpolation,
    half roughness,half roughness2MinusOne,half roughness2,half normalizationTerm
    )
    {
        float3 H = SafeNormalize(float3(L) + float3(V));

        float NoH = saturate(dot(N, H));
        float LoH = saturate(dot(L, H));

        // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
        // BRDFspec = (D * V * F) / 4.0
        // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
        // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
        // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
        // https://community.arm.com/events/1155

        // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
        // We further optimize a few light invariant terms
        // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.

        float secondRoughness = roughness * (1 + SecondLobeRoughnessDerivation);
        float secondRoughness2MinusOne = secondRoughness * secondRoughness - 1;

        float d = NoH * NoH * roughness2MinusOne + 1.00001f;
        float d2 = NoH * NoH * secondRoughness2MinusOne + 1.00001f;

        half normalizationTerm2 = secondRoughness * 4.0 + 2.0;

        half LoH2 = LoH * LoH;
        half specularTerm1 = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);
        half specularTerm2 = (secondRoughness * secondRoughness) / ((d2 * d2) * max(0.1h, LoH2) * normalizationTerm2);

        //half specularTerm = lerp(specularTerm1, specularTerm2, SpecularLobeInterpolation);
        half specularTerm = specularTerm2+ specularTerm1* SpecularLobeInterpolation;

        // On platforms where half actually means something, the denominator has a risk of overflow
        // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
        // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif

        specularTerm = clamp(specularTerm, 0, 8);

        return specularTerm;
    }

    float3 ClearCoatGGX( float ClearCoat,float Roughness, float3 N,float3 V, float3 L,out float3 EnergyLoss)
    {
        float3 H = normalize(L + V);
        float NoH = saturate(dot(N,H));
        float NoV = saturate(abs(dot(N,V)) + 1e-5);
        float NoL = saturate(dot(N,L));
        float VoH = saturate(dot(V,H));

        float a2 = Pow4( Roughness );
        
        // Generalized microfacet specular
        float D = D_GGX_UE4( a2, NoH );
        float Vis = Vis_SmithJointApprox( a2, NoV, NoL );
        float3 F = F_Schlick_UE4( float3(0.04,0.04,0.04), VoH ) * ClearCoat;
        EnergyLoss = F;

        return (D * Vis) * F;
    }

    // Subsurface Scatter
    half3 SubsurfaceScatter_Filament(half3 diffuse,half subsurfacePower,half subsurfaceThickness,float3 subsurfaceColor,float NoL,half3 L,half3 V) {
        // subsurface scattering
        // Use a spherical gaussian approximation of pow() for forwardScattering
        // We could include distortion by adding shading_normal * distortion to light.l
        float scatterVoH = saturate(dot(V, -L));
        float forwardScatter = exp2(scatterVoH * subsurfacePower - subsurfacePower);
        float backScatter = saturate(NoL * subsurfaceThickness + (1.0 - subsurfaceThickness)) * 0.5;
        float subsurface = lerp(backScatter, 1.0, forwardScatter) * (1.0 - subsurfaceThickness);
        // TODO: apply occlusion to the transmitted light
        return subsurfaceColor * (subsurface * diffuse/*Fd_Lambert()*/);
    }

    half3 SubsurfaceScatter_kShading(half NoL,half3 subsurfaceColor) {
        half3 NdotLWrap = saturate((NoL + subsurfaceColor) / ((1 + subsurfaceColor) * (1 + subsurfaceColor)));
        return lerp(NdotLWrap * subsurfaceColor, NdotLWrap, saturate(NoL));
    }

    float3 UE4_Aniso(half roughness,half roughness2,half Anisotropy,float3 N, float3 V, float3 L,float3 X,float3 Y,half3 SpecularColor)
    {
        float ax = max(roughness * (1.0 + Anisotropy), 0.001f);
        float ay = max(roughness * (1.0 - Anisotropy), 0.001f);

        float3 H  = normalize(L + V);
        float NoH = saturate(dot(N,H));
        float NoV = saturate(dot(N,V));
        float NoL = saturate(dot(N,L));
        float VoH = saturate(dot(V,H));

        float XoV = dot(X,V);
        float XoL = dot(X,L);
        float XoH = dot(X,H);
        float YoV = dot(Y,V);
        float YoL = dot(Y,L);
        float YoH = dot(Y,H);

        float D = D_GGXaniso(ax,ay,NoH,XoH,YoH);
        float Vis = Vis_SmithJointAniso(ax,ay,NoV,NoL,XoV,XoL,YoV,YoL);
        float3 F = F_Schlick_UE4( SpecularColor, VoH );
        return clamp((D * Vis) * F,0,100);
    }

    half3 Cloth_Specular(half NdotL,half clampedNdotV,half NdotH,half roughnessT,half3 fresnel0)
    {
        half D = D_Charlie_Unity(NdotH,roughnessT);

        // V_Charlie is expensive, use approx with V_Ashikhmin instead
        // float Vis = V_Charlie(NdotL, clampedNdotV, bsdfData.roughness);
        half Vis = V_Ashikhmin_Unity(NdotL, clampedNdotV);

        // Fabric are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
        // We don't use Fresnel term for CharlieD
        half3 F = fresnel0;

        return F * Vis * D;
    }

    half3 Silk_Specular(half TdotH,half TdotL,half BdotH,half BdotL,half NdotL,half LdotH,half NdotH,half clampedNdotV,half3 fresnel0,half roughnessT,half roughnessB,half partLambdaV)
    {
        // TODO: Do comparison between this correct version and the one from isotropic and see if there is any visual difference
        // We use abs(NdotL) to handle the none case of double sided
        half DV = DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, clampedNdotV, TdotL, BdotL, abs(NdotL),roughnessT,roughnessB, partLambdaV);

        // Fabric are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
        half3 F = F_Schlick(fresnel0, LdotH);

        return F * DV * PI;
    }

    float3 HightLightLaser(half3 V,half3 N,half3 tangent,half3 bitangent,half anisotropy,half universalLaser,half filmThickness,half laserSmoothstepValue_1,half laserSmoothstepValue_2,half filmBrdfIntensity,half filmIOR,half3 diffuse,half3 specular,half radiance,half3 laserColor,Light light)
    {
        half NoV = saturate(dot(N,V));
        half NoL = dot(N,light.direction);
        half half_NoL = NoL * 0.5 + 0.5;

        float BdotV = asin(dot(bitangent,V));
        float TdotV = asin(dot(-tangent, V));
        
        half BoV_lerp_ToV = lerp((lerp(BdotV,TdotV,anisotropy)),abs(BdotV + TdotV + (NoV)),universalLaser);
        
        half film = BoV_lerp_ToV * filmThickness - filmIOR;
        
        float3 laser_color = cos(film * float3(24.849998, 30.450001, 35.0));
        laser_color = laser_color * -0.5 + float3(0.5, 0.5, 0.5);
        laser_color = pow(laser_color, 2);
        laser_color = lerp( laser_color, smoothstep(laserSmoothstepValue_1, laserSmoothstepValue_2, laser_color), 1 - pow(NoV,6));
        laser_color = saturate(laser_color ) * light.color * half_NoL;

        laser_color += (diffuse + specular) * radiance * filmBrdfIntensity;
        
        return laser_color * laserColor * lerp(0.3,1,radiance);
    }


#endif // SHADING_MOEDEL_INCLUDE