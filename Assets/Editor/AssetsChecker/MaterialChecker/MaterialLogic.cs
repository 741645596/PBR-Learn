using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class MaterialLogic
{
    /// <summary>
    /// 判断材质球是否包含了空纹理
    /// </summary>
    /// <param name="matPath"> 材质球文件路径 </param>
    /// <returns></returns>
    public static bool HasEmptyTexture(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return false;
        }
        return HasEmptyTexture(material);
    }

    /// <summary>
    /// 判断材质球是否包含空纹理
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static bool HasEmptyTexture(Material material)
    {
        Debug.Assert(material != null, "错误提示：传入参数为null");

        var shader = material.shader;
        var count = shader.GetPropertyCount();
        for (var i = 0; i < count; i++)
        {
            if (shader.GetPropertyType(i) == ShaderPropertyType.Texture)
            {
                var name = shader.GetPropertyName(i);
                var texture = material.GetTexture(name);
                if (texture == null)
                {
                    return true;
                }
            }
        }
        return false;
    }

    /// <summary>
    /// 材质球共使用了几张纹理图片
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static int GetTextureCount(Material material)
    {
        var shader = material.shader;
        return ShaderKit.GetTextureCount(shader);
    }

    /// <summary>
    /// 获取材质球主纹理的尺寸大小
    /// </summary>
    /// <param name="matPath"></param>
    /// <returns></returns>
    public static Vector2 GetMainTextureSize(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return Vector2.zero;
        }
        return GetMainTextureSize(material);
    }

    /// <summary>
    /// 获取材质球主纹理的尺寸大小
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static Vector2 GetMainTextureSize(Material material)
    {
        Debug.Assert(material != null, "错误提示：传入参数为null");

        var shader = material.shader;
        var count = shader.GetPropertyCount();
        for (var i = 0; i < count; i++)
        {
            if (shader.GetPropertyType(i) == ShaderPropertyType.Texture)
            {
                var name = shader.GetPropertyName(i);
                var texture = material.GetTexture(name);
                if (texture != null)
                {
                    return new Vector2(texture.width, texture.height);
                }
            }
        }
        return Vector2.zero;
    }

    /// <summary>
    /// 查找材质球冗余Keywords，找不到返回空数组
    /// </summary>
    /// <param name="matPath"></param>
    /// <returns></returns>
    public static List<string> GetRedundanceKeywords(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return new List<string>();
        }

        return GetRedundanceKeywords(material);
    }

    /// <summary>
    /// 查找材质球冗余Keywords，找不到返回空数组
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static List<string> GetRedundanceKeywords(Material material)
    {
        List<string> notExistKeywords = new List<string>();

        // 对比shader的keywords和material的keywords
        var shaderKeywords = GetShaderKeywords(material.shader);
        var materialKeywords = new List<string>(material.shaderKeywords);
        foreach (var matKeyword in materialKeywords)
        {
            if (shaderKeywords.Contains(matKeyword) == false)
            {
                notExistKeywords.Add(matKeyword);
            }
        }

        return notExistKeywords;
    }

    /// <summary>
    /// 修复关键字冗余
    /// </summary>
    /// <param name="matPath"></param>
    public static void FixRedundanceKeywords(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return;
        }

        SerializedObject psSource = new SerializedObject(material);
        SerializedProperty property = psSource.FindProperty("m_ShaderKeywords");
        if (property == null)
        {
            return;
        }

        var needKeywords = GetNeedKeywords(material);
        var strKeyWords = string.Join(" ", needKeywords);
        property.stringValue = strKeyWords;
        psSource.ApplyModifiedProperties();
    }

    /// <summary>
    /// 获得所需Keywords（删除了冗余的keyword）
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static List<string> GetNeedKeywords(Material material)
    {
        List<string> needKeywords = new List<string>();

        // 对比shader的keywords和material的keywords，保留所需keywords
        var shaderKeywords = GetShaderKeywords(material.shader);
        var materialKeywords = new List<string>(material.shaderKeywords);
        foreach (var matKeyword in materialKeywords)
        {
            if (shaderKeywords.Contains(matKeyword))
            {
                needKeywords.Add(matKeyword);
            }
        }

        return needKeywords;
    }

    /// <summary>
    /// 获取冗余的其他资源
    /// </summary>
    /// <param name="matPath"></param>
    /// <returns></returns>
    public static List<string> GetRedunanceRes(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return new List<string>();
        }

        return GetRedunanceRes(material);
    }

    /// <summary>
    /// 获取冗余的其他资源
    /// </summary>
    /// <param name="material"></param>
    /// <returns></returns>
    public static List<string> GetRedunanceRes(Material material)
    {
        var res = new List<string>();

        SerializedObject psSource = new SerializedObject(material);
        SerializedProperty propertys = psSource.FindProperty("m_SavedProperties");
        SerializedProperty texEnvs = propertys.FindPropertyRelative("m_TexEnvs");
        for (int j = texEnvs.arraySize - 1; j >= 0; j--)
        {
            var element = texEnvs.GetArrayElementAtIndex(j);
            var propertyName = element.displayName;
            var isExist = material.HasProperty(propertyName);
            if (isExist == false)
            {
                res.Add(propertyName);
            }
        }

        return res;
    }

    /// <summary>
    /// 删除冗余的资源索引
    /// </summary>
    /// <param name="matPath"></param>
    public static void DeleteRedunanceRes(string matPath)
    {
        var material = _CheckMaterial(matPath);
        if (material == null)
        {
            return;
        }

        SerializedObject psSource = new SerializedObject(material);
        SerializedProperty propertys = psSource.FindProperty("m_SavedProperties");
        SerializedProperty texEnvs = propertys.FindPropertyRelative("m_TexEnvs");
        for (int j = texEnvs.arraySize - 1; j >= 0; j--)
        {
            var element = texEnvs.GetArrayElementAtIndex(j);
            var propertyName = element.displayName;
            var isExist = material.HasProperty(propertyName);
            if (isExist == false)
            {
                texEnvs.DeleteArrayElementAtIndex(j);
            }
        }
        psSource.ApplyModifiedProperties();
    }

    /// <summary>
    /// 获取shader包含哪些keywords
    /// </summary>
    /// <param name="shader"></param>
    /// <returns></returns>
    public static List<string> GetShaderKeywords(Shader shader)
    {
        List<string> shaderKeywordsLst = new List<string>();

        var getGlobalKeywords =
            typeof(ShaderUtil).GetMethod("GetShaderGlobalKeywords", BindingFlags.Static | BindingFlags.NonPublic);
        string[] keywords = (string[])getGlobalKeywords.Invoke(null, new object[] { shader });
        shaderKeywordsLst.AddRange(keywords);

        var getLocalKeywords =
            typeof(ShaderUtil).GetMethod("GetShaderLocalKeywords", BindingFlags.Static | BindingFlags.NonPublic);
        keywords = (string[])getLocalKeywords.Invoke(null, new object[] { shader });
        shaderKeywordsLst.AddRange(keywords);

        return shaderKeywordsLst;
    }

    /// <summary>
	/// 获取材质球的第一个纹理(备注：通过mat.mainTexture获取有可能为空)
	/// </summary>
	/// <param name="mat"></param>
	/// <returns></returns>
	public static Texture GetFirstTexture(Material mat)
    {
        foreach (var name in mat.GetTexturePropertyNames())
        {
            return mat.GetTexture(name);
        }
        return null;
    }

    /// <summary>
    /// 获取材质球的第一个纹理的路径地址，找不到返回null
    /// </summary>
    public static string GetFirstTexturePath(Material mat)
    {
        var txt = GetFirstTexture(mat);
        if (txt != null)
            return AssetDatabase.GetAssetPath(txt);
        return null;
    }

    private static Material _CheckMaterial(string matPath)
    {
        if (File.Exists(matPath) == false)
        {
            Debug.Log($"错误提示：{matPath}材质球不存在，请检查文件");
            return null;
        }

        if (matPath.EndsWith(".mat") == false)
        {
            Debug.Log($"错误提示：{matPath}材质球后缀不是.mat，请检查格式是否正确");
            return null;
        }

        var material = AssetDatabase.LoadAssetAtPath<Material>(matPath);
        if (material == null)
        {
            Debug.Log($"错误提示：{matPath}材质球读取失败，请检查材质球是否合法");
            return null;
        }

        return material;
    }
}
