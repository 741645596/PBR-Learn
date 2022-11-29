using System;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public static class RepeatMeshChecker
{
    /// <summary>
    /// 搜集重复资源信息
    /// </summary>
    /// <returns></returns>
    public static List<RepeatMeshInfo> CollectAssetInfo()
    {
        List<RepeatMeshInfo> list = new List<RepeatMeshInfo>();

        var fbxFiles = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Model_Type);
        var repeatMeshDatas = _GetRepeatMeshPaths(fbxFiles);
        foreach (var repeatMeshData in repeatMeshDatas)
        {
            var info = new RepeatMeshInfo();
            info.assetPath = repeatMeshData[0].assetPath;
            info.filesize = EditerUtils.FileHelper.GetFileSize(info.assetPath);

            info.repeatDatas = repeatMeshData;
            
            list.Add(info);
        }

        list.Sort((a, b) => { return (int)(b.repeatDatas[0].vertexCount - a.repeatDatas[0].vertexCount); });

        return list;
    }

    /// <summary>
    /// 搜集所有mesh信息
    /// </summary>
    /// <returns></returns>
    public static Dictionary<string, List<RepeatMeshData>> CollectAllAssetInfo()
    {
        var fbxFiles = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Model_Type);
        return GetAllMeshDic(fbxFiles);
    }

    /// <summary>
    /// 获取ShaderMesh集合
    /// </summary>
    /// <param name="fbxPath"></param>
    /// <returns></returns>
    public static List<Mesh> GetSharedMeshs(string fbxPath)
    {
        var fbxObj = AssetDatabase.LoadAssetAtPath<GameObject>(fbxPath);
        if (fbxObj == null)
        {
            if (fbxPath.Contains("~"))
            {
                return new List<Mesh>();
            }
            Debug.LogWarning($"错误提示：读取资源错误，请检查资源：{fbxPath}");
            return new List<Mesh>();
        }
        return GetSharedMeshs(fbxObj);
    }

    public static List<Mesh> GetSharedMeshs(GameObject obj)
    {
        var res = new List<Mesh>();

        // MeshRenderer组件
        var meshRenderers = obj.GetComponentsInChildren<MeshRenderer>(true);
        foreach (var meshRender in meshRenderers)
        {
            var meshFilter = meshRender.GetComponent<MeshFilter>();
            if (meshFilter != null &&
                meshFilter.sharedMesh != null)
            {
                res.Add(meshFilter.sharedMesh);
            }
        }

        // SkinnedMeshRenderer组件
        var skinnedMeshRenderers = obj.GetComponentsInChildren<SkinnedMeshRenderer>(true);
        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            if (skinnedMeshRenderer != null &&
                skinnedMeshRenderer.sharedMesh != null)
            {
                res.Add(skinnedMeshRenderer.sharedMesh);
            }
        }

        return res;
    }

    /// <summary>
    /// 获取所有fbx文件内mesh的信息集合
    /// </summary>
    /// <param name="fbxPaths"></param>
    /// <returns> <Mesh数据唯一值，包含Mesh数据唯一值的文件集合></returns>
    public static Dictionary<string, List<RepeatMeshData>> GetAllMeshDic(List<string> fbxPaths)
    {
        var dic = new Dictionary<string, List<RepeatMeshData>>();
        FixHelper.ForeachCollect(fbxPaths, (fbxPath) =>
        {
            var datas = GetMeshData(fbxPath);
            foreach (var data in datas)
            {
                var key = data.GetUniqueKey();
                if (dic.ContainsKey(key))
                {
                    dic[key].Add(data);
                }
                else
                {
                    dic.Add(key, new List<RepeatMeshData>() { data });
                }
            }
        });
        return dic;
    }

    /// <summary>
    /// 获取fbx内的mesh信息集合(一个fbx内会有多个mesh)
    /// </summary>
    /// <param name="fbxPath"></param>
    /// <returns></returns>
    public static List<RepeatMeshData> GetMeshData(string fbxPath)
    {
        // 一个模型会有多个Mesh
        var res = new List<RepeatMeshData>();

        var sharedMeshs = GetSharedMeshs(fbxPath);
        foreach (var shaderdMesh in sharedMeshs)
        {
            var data = new RepeatMeshData(shaderdMesh, fbxPath);
            res.Add(data);
        }

        return res;
    }

    private static List<List<RepeatMeshData>> _GetRepeatMeshPaths(List<string> fbxPaths)
    {
        var res = new List<List<RepeatMeshData>>();

        var dic = GetAllMeshDic(fbxPaths);
        foreach (var v in dic)
        {
            if (v.Value.Count > 1)
            {
                res.Add(v.Value);
            }
        }

        return res;
    }
}
