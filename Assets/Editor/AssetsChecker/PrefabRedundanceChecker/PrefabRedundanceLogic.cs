using UnityEngine;
using UnityEditor;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using EditerUtils;

public static class PrefabRedundanceLogic
{
    /// <summary>
    /// 获取预设打成ab包，有可能引用外部的资源路径集合
    /// </summary>
    /// <param name="prefabPath"></param>
    /// <returns> 冗余文件集合路径 </returns>
    public static List<string> GetPaths(string prefabPath)
    {
        if (File.Exists(prefabPath) == false)
        {
            Debug.LogError($"错误提示：{prefabPath}文件不存在，请检查路径");
            return new List<string>();
        }

        if (prefabPath.EndsWith(".prefab") == false)
        {
            Debug.LogError($"错误提示：{prefabPath}文件格式不是prefab，请检查资源");
            return new List<string>();
        }

        var res = new List<string>();
        var paths = AssetDatabase.GetDependencies(prefabPath);
        foreach (var path in paths)
        {
            if (IsRedundanceFile(path))
            {
                res.Add(path);
            }
        }
        return res;
    }

    /// <summary>
    /// 是否是冗余的文件
    /// </summary>
    /// <param name="path"></param>
    /// <returns></returns>
    public static bool IsRedundanceFile(string path)
    {
        if (path.EndsWith(".cs"))
        {
            return false;
        }

        // 这个是我们的游戏目录，不做判断
        if (path.StartsWith(PathHelper.Game_Assets_Unity_Path))
        {
            return false;
        }

        // 指定目录不做判断
        if (path.StartsWith(AssetsCheckEditorWindow.Asset_Search_Path))
        {
            return false;
        }

        // 判断ab包名是否存在，不存在则表示会冗余
        AssetImporter assetImporter = AssetImporter.GetAtPath(path);
        if (null == assetImporter)
        {
            return false;
        }
        if (string.IsNullOrEmpty(assetImporter.assetBundleName))
        {
            return true;
        }
        return false;
    }

    /// <summary>
    /// 与上面接口一样，只是这个接口返回的是文件名的集合
    /// </summary>
    /// <param name="prefabPath"></param>
    /// <returns></returns>
    public static List<string> GetFileNames(string prefabPath)
    {
        var paths = GetPaths(prefabPath);
        return GetNames(paths);
    }

    /// <summary>
    /// 文件名路径集合 -> 文件名集合
    /// </summary>
    /// <param name="paths"></param>
    /// <returns></returns>
    public static List<string> GetNames(List<string> paths)
    {
        var names = new List<string>();
        foreach (var path in paths)
        {
            var name = Path.GetFileName(path);
            names.Add(name);
        }
        return names;
    }

    /// <summary>
    /// 查找预设文件内冗余shader的节点关键字名称
    /// </summary>
    /// <param name="prefabPath"></param>
    /// <returns></returns>
    public static HashSet<string> GetTipsUniqueKey(string prefabPath)
    {
        if (File.Exists(prefabPath) == false)
        {
            Debug.LogWarning($"错误提示：传入文件{prefabPath}不存在");
            return new HashSet<string>();
        }

        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
        if (obj == null)
        {
            Debug.LogWarning($"错误提示：传入文件{prefabPath}加载失败，请检查资源");
            return new HashSet<string>();
        }

        var list = new HashSet<string>();
        var renderers = obj.GetComponentsInChildren<Renderer>(true);
        foreach (var render in renderers)
        {
            if (render.sharedMaterials == null)
            {
                continue;
            }

            foreach (var mat in render.sharedMaterials)
            {
                if (mat == null)
                {
                    continue;
                }

                var path = AssetDatabase.GetAssetPath(mat.shader);
                if (IsRedundanceFile(path))
                {
                    var key = AssetsCheckUILogic.GetTipsUniqueKey(render.gameObject);
                    if (list.Contains(key) == false)
                    {
                        list.Add(key);
                    }
                }
            }
        }
        return list;
    }
}
