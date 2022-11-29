
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEngine;

public static class ModelChecker
{
    /// <summary>
    /// 搜集模型信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<ModelAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".fbx");
        FixHelper.AsyncCollect<ModelAssetInfo>(files, (file)=>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取fbx模型信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 非模型格式返回null </returns>
    public static ModelAssetInfo GetAssetInfo(string file)
    {
        var importer = AssetImporter.GetAtPath(file) as ModelImporter;
        if (importer == null)
        {
            Debug.LogWarning($"错误提示：模型{file}读取ModelImporter失败，请检查资源");
            return null;
        }

        var info = new ModelAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.isReadable = importer.isReadable;

        info.isImportNormals = importer.importNormals != ModelImporterNormals.None;
        info.isImportTangents = importer.importTangents != ModelImporterTangents.None;

        info.isImportBlendShapes = importer.importBlendShapes;
        info.isImportCameras = importer.importCameras;
        info.isImportLights = importer.importLights;
        info.isImportVisibility = importer.importVisibility;
        info.isCloseOptimizeMesh = importer.optimizeMeshPolygons == false &&
            importer.optimizeMeshVertices == false;

        info.isNeedOptimizeGameObjects = IsNeedOptimizeGameObject(importer);
        info.isNeedAnimCompressionOptimal = IsNeedAnimCompression(importer);

        info.isMaterialsCreationModeNone = importer.materialImportMode != ModelImporterMaterialImportMode.None;

        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj != null)
        {
            info.isMaterialsNameLit = IsMaterialsNameLit(obj);
            info.meshColorCount = GetMeshColorCount(obj);
            info.isImportUV2 = IsImportUV2(obj);
            info.isImportUV34 = IsImportUV34(obj);
        }

        return info;
    }

    public static bool IsImportUV2(GameObject obj)
    {
        var mf = obj.GetComponent<MeshFilter>();
        if (mf != null && mf.sharedMesh != null)
        {
            var sharedMesh = mf.sharedMesh;
            Vector2[] sharedMeshUV2 = sharedMesh.uv2;
            return sharedMeshUV2.Length != 0;
        }
        return false;
    }

    public static bool IsImportUV34(GameObject obj)
    {
        var mf = obj.GetComponent<MeshFilter>();
        if (mf != null && mf.sharedMesh != null)
        {
            var sharedMesh = mf.sharedMesh;
            var sharedMeshUV3 = sharedMesh.uv3;
            var sharedMeshUV4 = sharedMesh.uv4;
            return sharedMeshUV3.Length != 0 && sharedMeshUV4.Length != 0;
        }
        return false;
    }

    public static int GetMeshColorCount(GameObject obj)
    {
        var mf = obj.GetComponent<MeshFilter>();
        if (mf != null && mf.sharedMesh != null)
        {
            return mf.sharedMesh.colors.Length;
        }
        return 0;
    }

    public static bool IsMaterialsNameLit(GameObject obj)
    {
        Renderer renderer = obj.GetComponent<Renderer>();
        if (renderer == null)
        {
            return false;
        }

        foreach (var material in renderer.sharedMaterials)
        {
            if (material == null)
            {
                continue;
            }

            if (material.name == "Lit")
            {
                return true;
            }
        }
        return false;
    }

    public static bool IsNeedOptimizeGameObject(ModelImporter importer)
    {
        if (importer.avatarSetup == ModelImporterAvatarSetup.CreateFromThisModel)
        {
            return importer.optimizeGameObjects == false;
        }

        return false;
    }

    public static bool IsNeedAnimCompression(ModelImporter importer)
    {
        bool clipNotNull = importer.defaultClipAnimations.Length > 0;
        bool importerAnimation = importer.importAnimation;

        return importer.animationCompression != ModelImporterAnimationCompression.Optimal &&
            clipNotNull &&
            importerAnimation;
    }

    public static List<ModelAssetInfo> GetErrorAssetInfos(List<ModelAssetInfo> assetInfos)
    {
        var infos = new List<ModelAssetInfo>();
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
    /// 修复上面的所有错误
    /// </summary>
    /// <param name="info"></param>
    public static void FixAll(List<ModelAssetInfo> infos, Action finishCB)
    {
        FixHelper.FixStep<ModelAssetInfo>(infos, (info) =>
        {
            info.Fix();
        },
        (isCancel) =>
        {
            finishCB();
        });
    }

    /// <summary>
    /// 是否有工具可修复的问题
    /// </summary>
    /// <param name="info"></param>
    /// <returns></returns>
    public static bool IsFixWithTool(ModelAssetInfo info)
    {
        // 法线/切线
        if (info.isImportTangents) return true;
        if (info.isImportNormals) return true;

        if (info.isImportBlendShapes) return true;
        if (info.isImportCameras) return true;
        if (info.isImportLights) return true;
        if (info.isImportVisibility) return true;
        if (info.isCloseOptimizeMesh) return true;

        if (info.isNeedAnimCompressionOptimal) return true;

        return false;
    }

    public const string Name_Close_Normal = "关闭法线和切线";
    public const string Name_Close_Import = "关闭Import BlendsShapes";
    public const string Name_Ani_Compression_Optimal = "Anim.Compression = Optimal";
    public const string Name_Optimal_Mesh = "开启Optimize Mesh";
    public static List<string> GetFixToolNames(ModelAssetInfo info)
    {
        var names = new List<string>();

        if (info.isImportTangents ||
            info.isImportNormals)
        {
            names.Add(Name_Close_Normal);
        }

        if (info.isImportBlendShapes ||
            info.isImportCameras ||
            info.isImportLights ||
            info.isImportVisibility)
        {
            names.Add(Name_Close_Import);
        }

        if (info.isCloseOptimizeMesh)
        {
            names.Add(Name_Optimal_Mesh);
        }

        if (info.isNeedAnimCompressionOptimal)
        {
            names.Add(Name_Ani_Compression_Optimal);
        }

        return names;
    }

    public static void FixWithToolName(string name, ModelAssetInfo info)
    {
        if (Name_Close_Normal == name)
        {
            FixNormalAndTangent(info);
        }
        else if (Name_Close_Import == name)
        {
            FixImprotBlendShapesXX(info);
        }
        else if (Name_Ani_Compression_Optimal == name)
        {
            FixAnimCompressionOptimal(info);
        }
        else if (Name_Optimal_Mesh == name)
        {
            FixOptimizeMesh(info);
        }
    }

    /// <summary>
    /// 去掉法线和切线，这两个一般是成对出现
    /// </summary>
    /// <param name="info"></param>
    public static void FixNormalAndTangent(ModelAssetInfo info)
    {
        var importer = AssetImporter.GetAtPath(info.assetPath) as ModelImporter;
        if (importer.importTangents != ModelImporterTangents.None ||
            importer.importNormals != ModelImporterNormals.None)
        {
            importer.importTangents = ModelImporterTangents.None;
            importer.importNormals = ModelImporterNormals.None;
            importer.SaveAndReimport();
        }
        info.isImportTangents = false;
        info.isImportNormals = false;
    }

    public static void FixImprotBlendShapesXX(ModelAssetInfo info)
    {
        var importer = AssetImporter.GetAtPath(info.assetPath) as ModelImporter;
        importer.importBlendShapes = false;
        importer.importVisibility = false;
        importer.importCameras = false;
        importer.importLights = false;
        importer.SaveAndReimport();

        info.isImportBlendShapes = false;
        info.isImportCameras = false;
        info.isImportLights = false;
        info.isImportVisibility = false;
    }

    public static void FixAnimCompressionOptimal(ModelAssetInfo info)
    {
        var importer = AssetImporter.GetAtPath(info.assetPath) as ModelImporter;
        if (importer.animationCompression != ModelImporterAnimationCompression.Optimal)
        {
            importer.animationCompression = ModelImporterAnimationCompression.Optimal;
            importer.SaveAndReimport();
        }
        info.isNeedAnimCompressionOptimal = false;
    }

    public static void FixOptimizeMesh(ModelAssetInfo info)
    {
        var importer = AssetImporter.GetAtPath(info.assetPath) as ModelImporter;
        importer.meshOptimizationFlags = MeshOptimizationFlags.Everything;
        importer.SaveAndReimport();
        info.isCloseOptimizeMesh = false;
    }
}

