using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using System;

public static class AnimAssetCherker
{
    /// <summary>
    /// 获取所有动画文件信息列表
    /// </summary>
    /// <returns></returns>
    public static List<AnimAssetInfo> CollectAssetInfo()
    {
        var res = new List<AnimAssetInfo>();

        // .anim文件
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".anim");
        FixHelper.ForeachCollect(files, (file) =>
        {
            var info = GetAnimAssetInfo(file);
            res.Add(info);
        });
        
        var fbxFils = _GetAnimFromFbx();
        for (int i = 0; i < fbxFils.Count; i++)
        {
            var file = fbxFils[i];
            var info = GetFbxAssetInfo(file);
            res.Add(info);
        }
        return res;
    }

    public static AnimAssetInfo GetAssetInfo(string file)
    {
        if (PathHelper.IsSuffixExist(file, ".anim"))
        {
            return GetAnimAssetInfo(file);
        }
        else if (PathHelper.IsSuffixExist(file, ".fbx"))
        {
            return GetFbxAssetInfo(file);
        }
        return null;
    }

    /// <summary>
    /// 获得.anim信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 文件非.anim返回null </returns>
    public static AnimAssetInfo GetAnimAssetInfo(string file)
    {
        var info = new AnimAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.isFbx = false;
        info.canDelete = AnimAssetHelper.CanDeleteData(file);
        info.canFloat3 = AnimAssetHelper.CanFloat3(file);

        return info;
    }

    /// <summary>
    /// 获得.fbx的信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 文件非.fbx返回null  </returns>
    public static AnimAssetInfo GetFbxAssetInfo(string file)
    {
        var info = new AnimAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.isFbx = true;
        info.canDelete = false;
        info.canFloat3 = false;

        return info;
    }

    public static List<AnimAssetInfo> GetErrorAssetInfos(List<AnimAssetInfo> infos)
    {
        var res = new List<AnimAssetInfo>();
        foreach (var info in infos)
        {
            if (info.CanFix())
            {
                res.Add(info);
            }
        }
        return res;
    }

    /// <summary>
    /// 压缩文件
    /// </summary>
    /// <param name="infos"></param>
    public static void FixAll(List<AnimAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<AnimAssetInfo>(infos, (info) =>
        {
            if (info.CanFix() == false)
            {
                return;
            }

            AnimAssetHelper.Zip(info.assetPath);
            info.canDelete = false;
            info.canFloat3 = false;
        },
        (isCancel) =>
        {
            AssetDatabase.SaveAssets();
            finishCB(isCancel);
            //EditorUtility.DisplayDialog("提示", "压缩结束", "OK");
        });
    }

    // 获取含有动画文件的fbx路径集合
    private static List<string> _GetAnimFromFbx()
    {
        var res = new List<string>();

        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".fbx");
        FixHelper.ForeachCollect(files, (file) =>
        {
            var animClips = AnimAssetHelper.GetAnimClips(file);
            if (animClips.Count != 0)
            {
                res.Add(file);
            }
        });
        return res;
    }
}
