
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public static class PrefabUIChecker
{
    /// <summary>
    /// 搜集预制是否需要关闭/打开Raycast
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabUIAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabUIAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预制是否需要关闭/打开Raycast
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 不需要返回null </returns>
    public static PrefabUIAssetInfo GetAssetInfo(string file)
    {
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj == null)
        {
            Debug.LogWarning($"错误提示：{file}预制文件加载失败，请检查资源文件");
            return null;
        }

        // 排除非UI组件预制
        var transform = obj.transform;
        if (transform.GetComponentsInChildren<RectTransform>(true).Length < 1)
        {
            return null;
        }

        // 不需要
        var needCloseList = GetNeedCloseTrans(transform).Count != 0;
        var needOpenList = GetNeedOpenTrans(transform).Count != 0;
        if (needCloseList == false &&
            needOpenList == false)
        {
            return null;
        }

        var info = new PrefabUIAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);
        info.isNeedCloseRay = needCloseList;
        info.isNeedOpenRay = needOpenList;

        return info;
    }

    /// <summary>
    /// 获取需要关闭raycast的组件
    /// </summary>
    /// <param name="root"></param>
    /// <returns></returns>
    public static List<Transform> GetNeedCloseTrans(Transform root)
    {
        var list = new List<Transform>();
        _CollectNeedCloseTrans(list, root);
        return list;
    }

    /// <summary>
    /// 获取需要打开raycast的组件
    /// </summary>
    /// <param name="root"></param>
    /// <returns></returns>
    public static List<Transform> GetNeedOpenTrans(Transform root)
    {
        var list = new List<Transform>();
        _CollectNeedOpenTrans(list, root);
        return list;
    }

    public static void FixAll(List<PrefabUIAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<PrefabUIAssetInfo>(infos, (info) =>
        {
            info.FixNotRefresh();
        },
        (isCancel) =>
        {
            AssetDatabase.Refresh();
            finishCB(isCancel);
        });
    }

    public static void FixCloseRaycast(Transform root)
    {
        var list = GetNeedCloseTrans(root);
        foreach (var t in list)
        {
            // 如果有按钮上的图片没打开，打开射线
            PrefabUILogic.SetRay(t, false);
        }
    }

    public static void FixOpenRaycast(Transform root)
    {
        var list = GetNeedOpenTrans(root);
        foreach (var t in list)
        {
            // 如果有按钮上的图片没打开，打开射线
            PrefabUILogic.SetRay(t, true);
        }
    }

    public static HashSet<string> GetErrorObjUniqueKeys(PrefabUIAssetInfo info)
    {
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(info.assetPath);
        var transform = obj.transform;
        var needCloseList = GetNeedCloseTrans(transform);
        var needOpenList = GetNeedOpenTrans(transform);
        return AssetsCheckUILogic.GetTipsUniqueKey(needCloseList, needOpenList);
    }

    private static void _CollectNeedOpenTrans(List<Transform> collect, Transform transform)
    {
        // 组件是Slider || Toggle，不处理，不递归子节点
        if (PrefabUILogic.IsSliderType(transform))
        {
            return;
        }

        // 如果预制内有Button InputField ScrollRect 组件，再查找内部
        if (PrefabUILogic.IsButtonType(transform))
        {
            // 如果有按钮上的图片没打开，就开下Ray
            if (PrefabUILogic.IsOpenRay(transform) == false)
            {
                collect.Add(transform);
            }
        }


        for (int i = 0; i < transform.childCount; i++)
        {
            Transform childTra = transform.GetChild(i);
            _CollectNeedOpenTrans(collect, childTra);
        }
    }

    private static void _CollectNeedCloseTrans(List<Transform> collect, Transform transform)
    {
        // 组件是Slider || Toggle，不处理，不递归子节点
        if (PrefabUILogic.IsSliderType(transform))
        {
            return;
        }

        // 如果预制内有Button InputField ScrollRect 组件，再查找内部
        if (PrefabUILogic.IsButtonType(transform) == false)
        {
            //is image or text 相关类型组件
            if (PrefabUILogic.IsOpenRay(transform))
            {
                collect.Add(transform);
            }
        }

        for (int i = 0; i < transform.childCount; i++)
        {
            Transform childTra = transform.GetChild(i);
            _CollectNeedCloseTrans(collect, childTra);
        }
    }
}