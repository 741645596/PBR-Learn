using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System;
using EditerUtils;

public static class ModelFaceChecker
{
    /// <summary>
    /// 搜集所有包含模型的预设资源
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<ModelFaceAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<ModelFaceAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res) =>
        {
            res = res.OrderByDescending((info) => { return info.faceCount; }).ToList();
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设包含模型信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 预设未包含模型信息返回null </returns>
    public static ModelFaceAssetInfo GetAssetInfo(string file)
    {
        GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj == null)
        {
            Debug.LogWarning($"错误提示：加载预设资源错误{file}");
            return null;
        }

        var tra = obj.transform;
        var meshRenderers = tra.GetComponentsInChildren<MeshRenderer>(true);
        var skinnedMeshRenderers = tra.GetComponentsInChildren<SkinnedMeshRenderer>(true);
        if (meshRenderers.Length == 0 && skinnedMeshRenderers.Length == 0)
        {
            return null;
        }

        var info = new ModelFaceAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        // 是否Mesh丢失
        info.isMeshMiss = _IsMeshMiss(meshRenderers, skinnedMeshRenderers);

        // 渲染数量
        info.renderCount = meshRenderers.Length + skinnedMeshRenderers.Length;

        // 模型面数
        info.faceCount = _GetFaceCount(meshRenderers, skinnedMeshRenderers);

        // 顶点数
        info.vertexCount = _GetVertexCount(meshRenderers, skinnedMeshRenderers);

        // 材质球数量
        info.materialCount = _GetMaterialCount(meshRenderers, skinnedMeshRenderers);

        // 骨骼数量
        var nodes = tra.GetComponentsInChildren<Transform>(true);
        info.boneCount = _GetBoneCount(nodes);
        info.nodeCount = nodes.Length;

        // 贴图尺寸
        var size = _GetTextureSize(meshRenderers, skinnedMeshRenderers);
        info.textureSizeCount = size;
        return info;
    }

    public static HashSet<string> GetErrorObjUniqueKeys(ModelFaceAssetInfo info)
    {
        GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(info.assetPath);
        var tra = obj.transform;
        var meshRenderers = tra.GetComponentsInChildren<MeshRenderer>(true);
        var skinnedMeshRenderers = tra.GetComponentsInChildren<SkinnedMeshRenderer>(true);

        return AssetsCheckUILogic.GetTipsUniqueKey(meshRenderers, skinnedMeshRenderers);
    }

    /// <summary>
    /// 获取fbx骨骼数量
    /// </summary>
    /// <param name="fbxPath"></param>
    /// <returns></returns>
    public static int GetBonesCount(string fbxPath)
    {
        var importer = AssetImporter.GetAtPath(fbxPath) as ModelImporter;
        if (importer == null)
        {
            Debug.LogWarning($"错误提示：传入路径{fbxPath}不能ModelImporter，请检查资源");
            return 0;
        }

        return importer.optimizeGameObjects ?
            importer.extraExposedTransformPaths.Length :
            importer.transformPaths.Length;
    }

    private static Vector2 _GetMatAllSize(Material[] mats)
    {
        var size = new Vector2();
        foreach (var mat in mats)
        {
            if (mat != null)
            {
                size += MaterialLogic.GetMainTextureSize(mat);
            }
        }
        return size;
    }

    private static Vector2 _GetTextureSize(MeshRenderer[] meshRenderers, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        Vector2 textureSize = new Vector2(0, 0);
        foreach (var meshRenderer in meshRenderers)
        {
            if (meshRenderer.sharedMaterials == null ||
                meshRenderer.sharedMaterials.Length == 0)
            {
                continue;
            }

            textureSize += _GetMatAllSize(meshRenderer.sharedMaterials);
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            if (skinnedMeshRenderer.sharedMaterials == null ||
                skinnedMeshRenderer.sharedMaterials.Length == 0)
            {
                continue;
            }

            textureSize += _GetMatAllSize(skinnedMeshRenderer.sharedMaterials);
        }

        return textureSize;
    }

    private static int _GetBoneCount(Transform[] transforms)
    {
        int boneCount = 0;
        foreach (var t in transforms)
        {
            var name = t.name;
            if (name.StartsWith("Bone") ||
                name.StartsWith("Bip"))
            {
                boneCount++;
            }
        }
        return boneCount;
    }

    private static bool _IsMeshMiss(MeshRenderer[] meshRenderers, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        foreach (var meshRender in meshRenderers)
        {
            var meshFilter = meshRender.GetComponent<MeshFilter>();
            if (meshFilter == null)
            {
                continue;
            }

            if (meshFilter.sharedMesh == null)
            {
                // spine组件不做判断
                //var spine = meshRender.GetComponent<Spine.Unity.SkeletonAnimation>();
                //return spine==null ? true : false;
                // TODO::spine
                return true;
            }
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            if (skinnedMeshRenderer == null ||
                skinnedMeshRenderer.sharedMesh == null)
            {
                return true;
            }
        }
        return false;
    }

    private static int _GetMaterialCount(MeshRenderer[] meshRenderers, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        int materialCount = 0;
        foreach (var meshRenderer in meshRenderers)
        {
            materialCount += meshRenderer.sharedMaterials.Length;
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            materialCount += skinnedMeshRenderer.sharedMaterials.Length;
        }

        return materialCount;
    }

    private static int _GetVertexCount(MeshRenderer[] meshRenderers, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        int vertexCount = 0;
        foreach (var meshRender in meshRenderers)
        {
            var meshFilter = meshRender.GetComponent<MeshFilter>();
            if (meshFilter == null ||
                meshFilter.sharedMesh == null)
            {
                continue;
            }

            vertexCount += meshFilter.sharedMesh.vertexCount;
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            if (skinnedMeshRenderer == null ||
                skinnedMeshRenderer.sharedMesh == null)
            {
                continue;
            }

            vertexCount += skinnedMeshRenderer.sharedMesh.vertexCount;
        }

        return vertexCount;
    }

    private static int _GetFaceCount(MeshRenderer[] meshRenderers, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        int faceCount = 0;
        foreach (var meshRender in meshRenderers)
        {
            var meshFilter = meshRender.GetComponent<MeshFilter>();
            if (meshFilter==null ||
                meshFilter.sharedMesh == null)
            {
                continue;
            }

            faceCount += meshFilter.sharedMesh.triangles.Length;
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            if (skinnedMeshRenderer==null ||
                skinnedMeshRenderer.sharedMesh == null)
            {
                continue;
            }

            faceCount += skinnedMeshRenderer.sharedMesh.triangles.Length;
        }

        return faceCount / 3;
    }
}
