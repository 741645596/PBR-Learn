
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class PrefabMeshChecker
{
    /// <summary>
    /// 预制网格渲染信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabMeshAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabMeshAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res) =>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设带模型信息，阴影探针这些有没有关闭
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 预设未带mesh返回null </returns>
    public static PrefabMeshAssetInfo GetAssetInfo(string file)
    {
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj == null)
        {
            Debug.LogWarning($"错误提示：{file}预设文件读取失败，请检查文件");
            return null;
        }

        // 排除预制中没有网格渲染器
        if (obj.GetComponentsInChildren<Renderer>(true).Length == 0)
        {
            return null;
        }

        var info = new PrefabMeshAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        _Check(obj.transform, info);

        return info;
    }

    /// <summary>
    /// 找出不合规的资源列表
    /// </summary>
    /// <param name="assetInfos"></param>
    /// <returns></returns>
    public static List<PrefabMeshAssetInfo> GetErrorAssetInfos(List<PrefabMeshAssetInfo> assetInfos)
    {
        var infos = new List<PrefabMeshAssetInfo>();
        foreach (var info in assetInfos)
        {
            if (info.IsError())
            {
                infos.Add(info);
            }
        }
        return infos;
    }

    public static void FixAll(List<PrefabMeshAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<PrefabMeshAssetInfo>(infos, (info) =>
        {
            info.FixNotRefresh();
        },
        (isCancel) =>
        {
            AssetDatabase.Refresh();
            finishCB(isCancel);
        });
    }

    /// <summary>
    /// 检测每个节点是否 开启投射阴影
    /// </summary>
    /// <param name="obj"> 要遍历的预制父节点 </param>
    /// <param name="info"> 改预制保存的信息 </param>
    private static void _Check(Transform obj, PrefabMeshAssetInfo info)
    {
        foreach (var child in obj.GetComponentsInChildren<Renderer>(true))
        {
            if (child.shadowCastingMode != ShadowCastingMode.Off)
            {
                info.isOpenCastShadows = true;
            }

            if (child.receiveShadows)
            {
                info.isOpenReceiveShadows = true;
            }

            if (child.lightProbeUsage != LightProbeUsage.Off) 
            {
                info.isOpenLightProbes = true;
            }

            if (child.reflectionProbeUsage != ReflectionProbeUsage.Off)
            {
                info.isOpenReflectionProbes = true;
            }

            if (child.allowOcclusionWhenDynamic)
            {
                info.isOpenDynamicOcclusion = true;
            }
        }
    }
}
