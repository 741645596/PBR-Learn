
using System;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public static class ShaderChecker
{
    /// <summary>
    /// 搜集变体信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<ShaderAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".shader");
        FixHelper.AsyncCollect<ShaderAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            foreach (var r in res)
            {
                r.references = AssetsHelper.GetFullDepPathsByAssetPath(r.assetPath);
            }
            finishCB(res);
        });
    }

    

    /// <summary>
    /// 获取shader信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> shader文件读取失败返回null </returns>
    public static ShaderAssetInfo GetAssetInfo(string file)
    {
        var data = ShaderKit.GetData(file);
        if (data == null)
        {
            return null;
        }

        var info = new ShaderAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.textureCount = data.textureCount;
        info.isSRP = data.isSupportSRP;
        info.variantCount = data.variantCount;

        return info;
    }

    public static List<ShaderAssetInfo> GetErrorAssetInfos(List<ShaderAssetInfo> assetInfos)
    {
        var infos = new List<ShaderAssetInfo>();
        foreach (var info in assetInfos)
        {
            if (info.IsError())
            {
                infos.Add(info);
            }
        }
        return infos;
    }

}