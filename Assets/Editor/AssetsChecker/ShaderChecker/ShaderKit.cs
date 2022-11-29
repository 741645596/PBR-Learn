using UnityEngine;
using UnityEditor;
using System.IO;
using System.Reflection;


public static class ShaderKit
{
    public class ShaderKitData
    {
        public bool isSupportSRP;   // 是否支持SRP
        public int textureCount;    // 纹理数量
        public int variantCount;    // 变体数量
    }

    /// <summary>
    /// 获得shader基本信息
    /// </summary>
    /// <param name="shaderPath"> shader文件路径 </param>
    /// <returns></returns>
    public static ShaderKitData GetData(string shaderPath)
    {
        if (File.Exists(shaderPath) == false)
        {
            Debug.LogWarning($"错误提示：{shaderPath}文件不存在");
            return null;
        }

        var data = new ShaderKitData();
        var shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
        if (shader == null)
        {
            Debug.LogWarning($"错误提示：{shaderPath}文件读取失败");
            return null;
        }

        data.textureCount = GetTextureCount(shader);

        // 获得变体数量
        System.Type t2 = typeof(ShaderUtil);
        MethodInfo method = t2.GetMethod("GetVariantCount", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var variantCount = method.Invoke(null, new System.Object[] { shader, true });
        data.variantCount = int.Parse(variantCount.ToString());

        // 是否支持SRP
        MethodInfo method2 = t2.GetMethod("GetSRPBatcherCompatibilityCode", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        var code = method2.Invoke(null, new System.Object[] { shader, 0 });
        data.isSupportSRP = int.Parse(code.ToString()) == 0;

        return data;
    }

    /// <summary>
    /// 获得这个shader包含了几个纹理贴图
    /// </summary>
    /// <param name="shader"></param>
    /// <returns></returns>
    public static int GetTextureCount(Shader shader)
    {
        int res = 0;
        int count = shader.GetPropertyCount();
        for (int i = 0; i < count; i++)
        {
            var t = shader.GetPropertyType(i);
            if (t == UnityEngine.Rendering.ShaderPropertyType.Texture)
            {
                res++;
            }
        }
        return res;
    }
}
