Shader "FB/PostProcessing/LutBuilderHdr"
{
    HLSLINCLUDE

        #pragma multi_compile TONEMAPPING_UNITY TONEMAPPING_GT TONEMAPPING_UNREAL

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "PostProcess.hlsl"
        #include "Tonemapping.hlsl"

        float4 _Lut_Params;         // x: lut_height, y: 0.5 / lut_width, z: 0.5 / lut_height, w: lut_height / lut_height - 1
        float4 _ColorBalance;       // xyz: LMS coeffs, w: unused
        float4 _ColorFilter;        // xyz: color, w: unused
        float4 _HueSatCon;          // x: hue shift, y: saturation, z: contrast, w: unused
        float4 _Lift;               // xyz: color, w: unused
        float4 _Gamma;              // xyz: color, w: unused
        float4 _Gain;               // xyz: color, w: unused
        float4 _Shadows;            // xyz: color, w: unused
        float4 _Midtones;           // xyz: color, w: unused
        float4 _Highlights;         // xyz: color, w: unused
        float4 _ShaHiLimits;        // xy: shadows min/max, zw: highlight min/max
        float4 _SplitShadows;       // xyz: color, w: balance
        float4 _SplitHighlights;    // xyz: color, w: unused
        TEXTURE2D(_ColorLutNotACES);               SAMPLER(sampler_ColorLutNotACES);

        float Tonemap_FilmSlope;

        float Tonemap_FilmToe;

        float Tonemap_FilmShoulder;

        float Tonemap_FilmBlackClip;

        float Tonemap_FilmWhiteClip;

        // Note: when the ACES tonemapper is selected the grading steps will be done using ACES spaces
        float3 ColorGrade_ACES(float3 colorLutSpace)
        {
            // Switch back to linear
            float3 colorLinear = LogCToLinear(colorLutSpace);
            // White balance in LMS space
            float3 colorLMS = LinearToLMS(colorLinear);
            colorLMS *= _ColorBalance.xyz;
            colorLinear = LMSToLinear(colorLMS);

            // Do contrast in log after white balance
            float3 colorLog = ACES_to_ACEScc(unity_to_ACES(colorLinear));
            //float3 colorLog = LinearToLogC(colorLinear);

            colorLog = (colorLog - ACEScc_MIDGRAY) * _HueSatCon.z + ACEScc_MIDGRAY;

            colorLinear = ACES_to_ACEScg(ACEScc_to_ACES(colorLog));
            //colorLinear = LogCToLinear(colorLog);

            // Color filter is just an unclipped multiplier
            colorLinear *= _ColorFilter.xyz;

            // Do NOT feed negative values to the following color ops
            colorLinear = max(0.0, colorLinear);

            // Split toning
            // As counter-intuitive as it is, to make split-toning work the same way it does in Adobe
            // products we have to do all the maths in gamma-space...
            float balance = _SplitShadows.w;
            float3 colorGamma = PositivePow(colorLinear, 1.0 / 2.2);
            float luma = saturate(GetLuminance(saturate(colorGamma)) + balance);
            float3 splitShadows = lerp((0.5).xxx, _SplitShadows.xyz, 1.0 - luma);
            float3 splitHighlights = lerp((0.5).xxx, _SplitHighlights.xyz, luma);
            colorGamma = SoftLight(colorGamma, splitShadows);
            colorGamma = SoftLight(colorGamma, splitHighlights);
            colorLinear = PositivePow(colorGamma, 2.2);

            // Shadows, midtones, highlights
            luma = GetLuminance(colorLinear);
            float shadowsFactor = 1.0 - smoothstep(_ShaHiLimits.x, _ShaHiLimits.y, luma);
            float highlightsFactor = smoothstep(_ShaHiLimits.z, _ShaHiLimits.w, luma);
            float midtonesFactor = 1.0 - shadowsFactor - highlightsFactor;
            colorLinear = colorLinear * _Shadows.xyz * shadowsFactor
                        + colorLinear * _Midtones.xyz * midtonesFactor
                        + colorLinear * _Highlights.xyz * highlightsFactor;

            // Hue Shift & Hue Vs Hue
            float3 hsv = RgbToHsv(colorLinear);
            float hue = hsv.x + _HueSatCon.x;
            hsv.x = RotateHue(hue, 0.0, 1.0);
            colorLinear = HsvToRgb(hsv);

            // Lift, gamma, gain
            colorLinear = colorLinear * _Gain.xyz + _Lift.xyz;
            colorLinear = sign(colorLinear) * pow(abs(colorLinear), _Gamma.xyz);

            // Global saturation
            luma = GetLuminance(colorLinear);
            colorLinear =  luma.xxx + _HueSatCon.yyy * (colorLinear - luma.xxx);

            return max(0.0, colorLinear);
        }

        // Note: when the ACES tonemapper is selected the grading steps will be done using ACES spaces
        float3 ColorGrade_NOTACES(float3 colorLutSpace)
        {
            // Switch back to linear
            float3 colorLinear = LogCToLinear(colorLutSpace);
            // White balance in LMS space
            float3 colorLMS = LinearToLMS(colorLinear);
            colorLMS *= _ColorBalance.xyz;
            colorLinear = LMSToLinear(colorLMS);

            // Do contrast in log after white balance
            //float3 colorLog = ACES_to_ACEScc(unity_to_ACES(colorLinear));
            float3 colorLog = LinearToLogC(colorLinear);

            colorLog = (colorLog - ACEScc_MIDGRAY) * _HueSatCon.z + ACEScc_MIDGRAY;

            //colorLinear = ACES_to_ACEScg(ACEScc_to_ACES(colorLog));
            colorLinear = LogCToLinear(colorLog);

            // Color filter is just an unclipped multiplier
            colorLinear *= _ColorFilter.xyz;

            // Do NOT feed negative values to the following color ops
            colorLinear = max(0.0, colorLinear);

            // Split toning
            // As counter-intuitive as it is, to make split-toning work the same way it does in Adobe
            // products we have to do all the maths in gamma-space...
            float balance = _SplitShadows.w;
            float3 colorGamma = PositivePow(colorLinear, 1.0 / 2.2);
            float luma = saturate(GetLuminance(saturate(colorGamma)) + balance);
            float3 splitShadows = lerp((0.5).xxx, _SplitShadows.xyz, 1.0 - luma);
            float3 splitHighlights = lerp((0.5).xxx, _SplitHighlights.xyz, luma);
            colorGamma = SoftLight(colorGamma, splitShadows);
            colorGamma = SoftLight(colorGamma, splitHighlights);
            colorLinear = PositivePow(colorGamma, 2.2);

            // Shadows, midtones, highlights
            luma = GetLuminance(colorLinear);
            float shadowsFactor = 1.0 - smoothstep(_ShaHiLimits.x, _ShaHiLimits.y, luma);
            float highlightsFactor = smoothstep(_ShaHiLimits.z, _ShaHiLimits.w, luma);
            float midtonesFactor = 1.0 - shadowsFactor - highlightsFactor;
            colorLinear = colorLinear * _Shadows.xyz * shadowsFactor
                        + colorLinear * _Midtones.xyz * midtonesFactor
                        + colorLinear * _Highlights.xyz * highlightsFactor;

            // Hue Shift & Hue Vs Hue
            float3 hsv = RgbToHsv(colorLinear);
            float hue = hsv.x + _HueSatCon.x;
            hsv.x = RotateHue(hue, 0.0, 1.0);
            colorLinear = HsvToRgb(hsv);

            // Lift, gamma, gain
            colorLinear = colorLinear * _Gain.xyz + _Lift.xyz;
            colorLinear = sign(colorLinear) * pow(abs(colorLinear), _Gamma.xyz);

            // Global saturation
            luma = GetLuminance(colorLinear);

            colorLinear =  luma.xxx + _HueSatCon.yyy * (colorLinear - luma.xxx);
   
            return max(0.0, colorLinear);
        }

        //具备    ACES
        float4 FragACES(Varyings input) : SV_Target
        {
            // Lut space
            // We use Alexa LogC (El 1000) to store the LUT as it provides a good enough range
            // (~58.85666) and is good enough to be stored in fp16 without losing precision in the
            // darks
            float3 colorLutSpace = GetLutStripValue(input.uv, _Lut_Params);

            // Color grade & tonemap
            float3 gradedColor = ColorGrade_ACES(colorLutSpace);

            #if defined(TONEMAPPING_UNITY)
                gradedColor=Tonemapping_Unity(gradedColor);
            #elif defined(TONEMAPPING_GT)
                gradedColor=Tonemapping_GT(gradedColor);
            #elif defined(TONEMAPPING_UNREAL)
                gradedColor=Tonemapping_Unreal(gradedColor,Tonemap_FilmSlope,Tonemap_FilmToe,Tonemap_FilmShoulder,Tonemap_FilmBlackClip,Tonemap_FilmWhiteClip);
            #endif

            return float4(gradedColor, 1.0);
        }

        //具备    ACES
        float4 FragACESTexture(Varyings input) : SV_Target{
           float3  gradedColor = SAMPLE_TEXTURE2D_X(_ColorLutNotACES, sampler_ColorLutNotACES, input.uv.xy).rgb;

            #if defined(TONEMAPPING_UNITY)
                gradedColor=Tonemapping_Unity(gradedColor);
            #elif defined(TONEMAPPING_GT)
                gradedColor=Tonemapping_GT(gradedColor);
            #elif defined(TONEMAPPING_UNREAL)
                gradedColor=Tonemapping_Unreal(gradedColor,Tonemap_FilmSlope,Tonemap_FilmToe,Tonemap_FilmShoulder,Tonemap_FilmBlackClip,Tonemap_FilmWhiteClip);
            #endif

           return float4(gradedColor, 1.0);
        }

        //不具备    ACES
        float4 FragNotACES(Varyings input) : SV_Target
        {
            // Lut space
            // We use Alexa LogC (El 1000) to store the LUT as it provides a good enough range
            // (~58.85666) and is good enough to be stored in fp16 without losing precision in the
            // darks
            float3 colorLutSpace = GetLutStripValue(input.uv, _Lut_Params);
            // Color grade & tonemap
            float3 gradedColor = ColorGrade_NOTACES(colorLutSpace);

            return float4(gradedColor, 1.0);
        }


    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "LutBuilderHdrACES"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragACES
            ENDHLSL
        }

        Pass
        {
            Name "LutBuilderHdrACESTexture"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragACESTexture
            ENDHLSL
        }

        Pass
        {
            Name "LutBuilderHdrNotACES"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNotACES
            ENDHLSL
        }
    }
}
