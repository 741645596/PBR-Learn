#ifndef SKIN_FUNCTION_INCLUDE
#define SKIN_FUNCTION_INCLUDE

#include "Assets/Common/ShaderLibrary/Surface/ShadingModel.hlsl"

float3 DualSpecularGGX_UE( float Lobe0Roughness,float Lobe1Roughness,float LobeMix, float3 SpecularColor,float NoH,float NoV, float NoL,float VoH)
{
    float Lobe0Alpha2 = Pow4( Lobe0Roughness );
    float Lobe1Alpha2 = Pow4( Lobe1Roughness );
    float AverageAlpha2 = Pow4( (Lobe0Roughness + Lobe1Roughness) * 0.5 );

    // Generalized microfacet specular
    float D = lerp(D_GGX_UE4( Lobe0Alpha2, NoH ),D_GGX_UE4( Lobe1Alpha2, NoH ),0.5);
    
    float Vis = Vis_SmithJointApprox( AverageAlpha2, NoV, NoL );
    float3 F = F_Schlick_UE4( SpecularColor, VoH );

    return (D * Vis * F);
}

float3 DualSpecularBeckmann( float Lobe0Roughness,float Lobe1Roughness,float LobeMix, float3 SpecularColor,float NoH,float NoV, float NoL,float VoH)
{
    float Lobe0Alpha2 = Pow4( Lobe0Roughness );
    float Lobe1Alpha2 = Pow4( Lobe1Roughness );
    float AverageAlpha2 = Pow4( (Lobe0Roughness + Lobe1Roughness) * 0.5 );

    // Generalized microfacet specular
    float D = lerp(D_Beckmann(Lobe0Alpha2, NoH ),D_Beckmann(Lobe1Alpha2, NoH ),0.5);    //LobeMix
    D = clamp(D,0,100);

    float Vis = Vis_SmithJointApprox( AverageAlpha2, NoV, NoL );
    float3 F = F_Schlick_UE4( SpecularColor, VoH );

    return (D * Vis * F);
}


// 3S Curve
half GetCurvature(float SSSRange,float SSSPower,float3 WorldNormal,float3 WorldPos)
{
    //ddx_fine
    float deltaWorldNormal = length( abs(ddx(WorldNormal)) + abs(ddy(WorldNormal)));
    float deltaWorldPosition = length( abs(ddx(WorldPos)) + abs(ddy(WorldPos)) ) / 0.001;
    return saturate(SSSRange + deltaWorldNormal / deltaWorldPosition * SSSPower);
}	

#endif  //SKIN_FUNCTION_INCLUDE