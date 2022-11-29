using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public static class UnreferencedResourceChecker
{
    /// <summary>
    /// 获取问题资源集合
    /// </summary>
    /// <returns></returns>
    public static List<UnreferencedResourceInfo> CollectAssetInfo()
    {
        var list = new List<UnreferencedResourceInfo>();
        var files = GetUnreferenceRes();
        foreach (var file in files) 
        {
            var info = new UnreferencedResourceInfo();
            info.assetPath = file;
            info.filesize = EditerUtils.FileHelper.GetFileSize(file);
            info.isPrefabType = file.EndsWith(".prefab");
            list.Add(info);
        }

        list.Sort((a, b) => { return (int)(b.filesize - a.filesize); });
        return list;
    }

    /// <summary>
    /// 获取所有依赖关系集合
    /// </summary>
    /// <returns></returns>
    public static HashSet<string> GetAllDependencies()
    {
        var res = new HashSet<string>();

        var prefabPaths = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.ForeachCollect(prefabPaths, (prefabPath)=>
        {
            var paths = AssetDatabase.GetDependencies(prefabPath);
            foreach (var path in paths)
            {
                if ((res.Contains(path) == false) && (path != prefabPath))
                {
                    res.Add(path);
                }
            }
        });
        return res;
    }

    /// <summary>
    /// 获取未被引用到的资源路径集合
    /// </summary>
    /// <returns></returns>
    public static List<string> GetUnreferenceRes()
    {
        var res = new List<string>(2048);

        var allFiles = DirectoryHelper.GetAllFilesIgnoreExts(AssetsCheckEditorWindow.Asset_Search_Path, EditerUtils.FileHelper.Ignore_Suffixs);
        var seachFiles = EditerUtils.FileHelper.IgnoreCSProjectFiles(allFiles);
        var depPaths = GetAllDependencies();
        foreach (var fullPath in seachFiles)
        {
            if (depPaths.Contains(fullPath) == false)
            {
                res.Add(fullPath);
            }
        }

        return res;
    }

    /// <summary>
    /// 获取
    /// </summary>
    /// <returns></returns>
    public static List<UnreferencedResourceInfo> GetHidePrefabs(List<UnreferencedResourceInfo> assetInfos)
    {
        var infos = new List<UnreferencedResourceInfo>();
        foreach (var info in assetInfos)
        {
            if (info.isPrefabType == false)
            {
                infos.Add(info);
            }
        }
        return infos;
    }

    public static List<UnreferencedResourceInfo> GetShowPrefabs(List<UnreferencedResourceInfo> assetInfos)
    {
        var infos = new List<UnreferencedResourceInfo>();
        foreach (var info in assetInfos)
        {
            if (info.isPrefabType == true)
            {
                infos.Add(info);
            }
        }
        return infos;
    }

}