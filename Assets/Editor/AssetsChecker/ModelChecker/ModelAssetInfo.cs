
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ModelAssetInfo : AssetInfoBase
{
    // 是否可读写
    public bool isReadable;

    // 导入颜色
    public int meshColorCount;

    // 导入法线
    public bool isImportNormals;

    // 导入切线
    public bool isImportTangents;

    // 导入UV2
    public bool isImportUV2;

    // 导入UV3、UV4
    public bool isImportUV34;

    // 导入混合形状
    public bool isImportBlendShapes;

    public bool isImportVisibility;

    public bool isImportCameras;

    public bool isImportLights;

    // 是否关闭了Optimize Mesh，推荐开启
    public bool isCloseOptimizeMesh;

    // 是否优化游戏对象
    public bool isNeedOptimizeGameObjects;

    // 是否优化动画
    public bool isNeedAnimCompressionOptimal;

    // 是否材质球名称为Lit
    public bool isMaterialsNameLit;

    // 是否材质导入模式为none
    public bool isMaterialsCreationModeNone;

    public override bool CanFix()
    {
        if (isReadable) return true;

        if (isMaterialsCreationModeNone) return true;

        if (isMaterialsNameLit) return true;

        return false;
    }

    public override void Fix()
    {
        if (isReadable) FixRW();

        if (isMaterialsCreationModeNone) FixMaterialImport();

        if (isMaterialsNameLit) FixLitMaterial();
    }

    public override string GetErrorDes()
    {
        var desArr = new List<string>();

        if (isReadable) desArr.Add("RW未关闭");

        if (isImportNormals) desArr.Add("包含法线");
        if (isImportTangents) desArr.Add("包含切线");
        if (isImportUV2) desArr.Add("包含UV2");
        if (isImportUV34) desArr.Add("包含UV34");
        if (meshColorCount != 0) desArr.Add("包含Color数据");

        if (isImportBlendShapes) desArr.Add("ImportBlendShapes");
        if (isImportCameras) desArr.Add("ImportCameras");
        if (isImportLights) desArr.Add("ImportLights");
        if (isImportVisibility) desArr.Add("ImportVisibility");
        if (isCloseOptimizeMesh) desArr.Add("未勾选Optimize Mesh");

        if (isNeedOptimizeGameObjects) desArr.Add("未勾选Optimize Game Object");

        if (isNeedAnimCompressionOptimal) desArr.Add("未优化Anim.Compression = Optimal");

        if (isMaterialsCreationModeNone) desArr.Add("Materials!=None");

        if (isMaterialsNameLit) desArr.Add("包含Lit材质");

        return string.Join("；", desArr);
    }

    public override bool IsError()
    {
        if (isReadable) return true;

        if (isMaterialsCreationModeNone) return true;

        if (isMaterialsNameLit) return true;

        if (meshColorCount != 0) return true;

        if (isImportUV34) return true;

        if (isCloseOptimizeMesh) return true;

        return false;
    }

    public void FixRW()
    {
        var importer = AssetImporter.GetAtPath(assetPath) as ModelImporter;
        if (importer.isReadable)
        {
            importer.isReadable = false;
            importer.SaveAndReimport();
        }
        isReadable = false;
    }

    public void FixMaterialImport()
    {
        var importer = AssetImporter.GetAtPath(assetPath) as ModelImporter;
        if (importer.materialImportMode != ModelImporterMaterialImportMode.None)
        {
            importer.materialImportMode = ModelImporterMaterialImportMode.None;
            importer.SaveAndReimport();
        }
        isMaterialsCreationModeNone = false;
    }

    public void FixLitMaterial()
    {
        if (isMaterialsNameLit == false)
        {
            return;
        }

        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
        if (obj == null)
        {
            return;
        }

        var renderers = obj.transform.GetComponentsInChildren<Renderer>(true);
        if (renderers == null)
        {
            return;
        }

        foreach (var renderer in renderers)
        {
            if (renderer == null)
            {
                continue;
            }

            foreach (var material in renderer.sharedMaterials)
            {
                if (material == null)
                {
                    continue;
                }

                if (material.name == "Lit")
                {
                    renderer.sharedMaterials = new Material[0];
                }
            }
        }

        isMaterialsNameLit = false;
    }
}
