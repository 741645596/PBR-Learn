using System;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEngine;

public static class PrefabRedundanceChecker
{
    /// <summary>
    /// 搜集冗余信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabRedundanceAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabRedundanceAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设冗余信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 未包含冗余信息返回null </returns>
    public static PrefabRedundanceAssetInfo GetAssetInfo(string file)
    {
        var names = PrefabRedundanceLogic.GetFileNames(file);
        if (names.Count == 0)
        {
            return null;
        }

        PrefabRedundanceAssetInfo info = new PrefabRedundanceAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        var tips = string.Join("；", names);
        info.redundanceFileName = tips;

        return info;
    }
}
