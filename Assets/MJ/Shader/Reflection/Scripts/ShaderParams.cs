/// <summary>
/// Shiny SSRR - Screen Space Reflections for URP - (c) 2021 Kronnect
/// </summary>

using UnityEngine;

namespace ShinySSRR {

    public static class ShaderParams {

        // input textures
        public static int MainTex = Shader.PropertyToID("_MainTex");
        public static int NoiseTex = Shader.PropertyToID("_NoiseTex");
        public static int BumpMap = Shader.PropertyToID("_BumpMap");
        public static int BumpMap_ST = Shader.PropertyToID("_BumpMap_ST");
        public static int BaseMap_ST = Shader.PropertyToID("_BaseMap_ST");

        // shader uniforms
        public static int Color = Shader.PropertyToID("_Color");
        public static int BaseColor = Shader.PropertyToID("_BaseColor");
        public static int Smoothness = Shader.PropertyToID("_Smoothness");
        public static int SmoothnessMap = Shader.PropertyToID("_SmoothnessMap");
        public static int MetallicGlossMap = Shader.PropertyToID("_MetallicGlossMap");
        public static int MaterialData = Shader.PropertyToID("_MaterialData");
        public static int SSRSettings = Shader.PropertyToID("_SSRSettings");
        public static int SSRSettings2 = Shader.PropertyToID("_SSRSettings2");
        public static int SSRSettings3 = Shader.PropertyToID("_SSRSettings3");
        public static int SSRSettings4 = Shader.PropertyToID("_SSRSettings4");
        public static int SSRSettings5 = Shader.PropertyToID("_SSRSettings5");
        public static int SSRBlurStrength = Shader.PropertyToID("_SSRBlurStrength");
        public static int WorldToViewDir = Shader.PropertyToID("_WorldToViewDir");
        public static int MinimumBlur = Shader.PropertyToID("_MinimumBlur");

        // targets
        public static int ColorTex = Shader.PropertyToID("_ColorTex");
        public static int RayCast = Shader.PropertyToID("_RayCastRT");
        public static int BlurRT = Shader.PropertyToID("_BlurRT");
        public static int ReflectionsTex = Shader.PropertyToID("_ReflectionsRT");
        public static int NaNBuffer = Shader.PropertyToID("_NaNBuffer");

        // shader keywords
        public const string SKW_JITTER = "SSR_JITTER";
        public const string SKW_NORMALMAP = "SSR_NORMALMAP";
        public const string SKW_DENOISE = "SSR_DENOISE";
        public const string SKW_SMOOTHNESSMAP = "SSR_SMOOTHNESSMAP";
        public const string SKW_REFINE_THICKNESS = "SSR_THICKNESS_FINE";
    }

}