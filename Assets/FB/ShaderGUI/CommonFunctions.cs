using UnityEngine;
using UnityEngine.Rendering;
public static class ShaderGUIExtensions
{
    public static void SetKeyword(this Material material, string keyword, bool value)
    {
        if (value)
        {
            material.EnableKeyword(keyword);
        }
        else
        {
            material.DisableKeyword(keyword);
        }
    }

    public static void SetPass(this Material material, string pass, bool value)
    {
        material.SetShaderPassEnabled(pass, value);
    }

    public static void SetTransparentStatus(this Material material, bool value)
    {
        if (value)
        {
            // General Transparent Material Settings
            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            material.SetOverrideTag("RenderType", "Transparent");
            material.SetInt("_ZWrite", 0);
            material.SetInt("_Surface", 1);
            material.renderQueue = (int)RenderQueue.Transparent;
            material.renderQueue += material.HasProperty("_QueueOffset") ? (int) material.GetFloat("_QueueOffset") : 0;
            // material.SetShaderPassEnabled("ShadowCaster", false);
            // material.SetShaderPassEnabled("DepthOnly", false);
        }
        else
        {
            // General Opaque Material Settings
            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
            material.SetOverrideTag("RenderType", "Opaque");
            material.SetInt("_ZWrite", 1);
            material.SetInt("_Surface", 0);
            material.renderQueue = (int)RenderQueue.Geometry;
            material.renderQueue += material.HasProperty("_QueueOffset") ? (int) material.GetFloat("_QueueOffset") : 0;
            // material.SetShaderPassEnabled("ShadowCaster", true);
            // material.SetShaderPassEnabled("DepthOnly", true);
        }
    }

    public static void SetTransparentValue(this Material material, float value)
    {
        Color color = material.GetColor("_BaseColor");
        if (color != null)
        {
            color.a = value;
            material.SetColor("_BaseColor", color);
        }
        else
        {
            Debug.LogError("Material is null");
        }
    }

    public static void SetTransparent(this Material material, bool value, float alpha )
    {
        SetTransparentStatus(material, value);
        SetTransparentValue(material, alpha);
    }
}
