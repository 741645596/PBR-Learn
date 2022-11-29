using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEngine;
using Debug = UnityEngine.Debug;

public static class PrefabHierarchyChecker
{
    private const string ART_TEXT_CHARACTER_IMAGE_UNIQUE_NAME = "@Art_Text_Character_Image_Unique_Name";

    /// <summary>
    /// 搜集层级不规范的prefab
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabHierarchyAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabHierarchyAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            res = res.OrderByDescending((info) => { return info.maxHierarchyCount; }).ToList();
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设层级信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 预设读取失败返回null </returns>
    public static PrefabHierarchyAssetInfo GetAssetInfo(string file)
    {
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj == null)
        {
            Debug.LogWarning($"错误提示：{file}示例化失败，请检查资源是否有无问题");
            return null;
        }

        var info = new PrefabHierarchyAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        var transform = obj.transform;
        info.allNodeCount = GetFilterTransformsCount(transform);
        info.notActiveNodeCount = GetNoActiveCount(transform);
        info.maxHierarchyCount = GetMaxHierarchyCount(transform);

        info.notActiveRatio = (float)info.notActiveNodeCount / info.allNodeCount;

        return info;
    }

    /// <summary>
    /// 获取不合规资源集合
    /// </summary>
    /// <param name="assetInfos"></param>
    /// <returns></returns>
    public static List<PrefabHierarchyAssetInfo> GetErrorAssetInfos(List<PrefabHierarchyAssetInfo> assetInfos)
    {
        var infos = new List<PrefabHierarchyAssetInfo>();
        foreach (var info in assetInfos)
        {
            if (info.IsError())
            {
                infos.Add(info);
            }
        }
        return infos;
    }

    /// <summary>
    /// 过滤掉自定义特殊的transform
    /// </summary>
    /// <param name="transforms"></param>
    /// <returns></returns>
    public static List<Transform> FilterTransforms(Transform[] transforms)
    {
        var newTrans = new List<Transform>();
        foreach (var tran in transforms)
        {
            if (tran.name != ART_TEXT_CHARACTER_IMAGE_UNIQUE_NAME)
            {
                newTrans.Add(tran);
            }
        }
        return newTrans;
    }

    /// <summary>
    /// 获取过滤无效组件
    /// </summary>
    /// <param name="t"></param>
    /// <returns></returns>
    public static List<Transform> GetFilterTransforms(Transform t)
    {
        var childs = t.GetComponentsInChildren<Transform>(true);
        return FilterTransforms(childs);
    }

    /// <summary>
    /// 获取过滤无效组件后的Transform数量，包含自身
    /// </summary>
    /// <param name="t"></param>
    /// <returns></returns>
    public static int GetFilterTransformsCount(Transform t)
    {
        return GetFilterTransforms(t).Count;
    }

    /// <summary>
    /// 获取非活动的Transform数量
    /// </summary>
    /// <param name="transforms"></param>
    /// <returns></returns>
    public static int GetNoActiveCount(Transform transform)
    {
        // 父节点为非活动则全部的子节点都认为是非活动
        if (transform.gameObject.activeSelf == false)
        {
            return GetFilterTransformsCount(transform);
        }

        int count = 0;
        for (int i = 0; i < transform.childCount; i++)
        {    
            var child = transform.GetChild(i);
            if (child.gameObject.activeSelf == false)
            {
                count += GetFilterTransformsCount(child);
            }
            else
            {
                count += GetNoActiveCount(child);
            }
        }
        return count;
    }

    /// <summary>
    /// 获取Transform的最大嵌套层级
    /// </summary>
    /// <param name="t"></param>
    /// <returns></returns>
    public static int GetMaxHierarchyCount(Transform t)
    {
        int max = 0;
        var transforms = GetFilterTransforms(t);
        foreach (var trans in transforms)
        {
            var count = GetHierarchyCount(trans);
            if (count > max)
            {
                max = count;
            }
        }
        return max;
    }

    /// <summary>
    /// 获取Transform的层级
    /// </summary>
    /// <param name="t"></param>
    /// <returns></returns>
    public static int GetHierarchyCount(Transform t)
    {
        int count = 1;
        Transform tmp = t.parent;
        while (tmp != null)
        {
            count++;
            tmp = tmp.parent;
        }
        return count;
    }
}
