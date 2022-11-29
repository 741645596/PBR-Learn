
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;

/// <summary>
/// 图集专有属性
/// </summary>
public class AtlasAssetInfo : AssetInfoBase
{
    public const int Max_Atlas_Size = 2048 * 2048;

    // 图集是否存在
    public bool isSpriteAtlasExist;

    // 是否是ASTC格式
    public bool isAstcFormat;
    public TextureImporterFormat iosTextureFormat;
    public TextureImporterFormat androidTextureFormat;

    // 是否开启Override
    public bool isOpenOverride;

    // 是否勾选include in build
    public bool isIncludeInBuild = true;

    // 原图是否都是Sprite（2D and UI）格式
    public bool isAllSprite2DFormat;

    // 原图是否都是ASTC 4x4格式或是未开启override
    public bool isAllCloseOverride;

    // 合图包含纹理数量
    public int spriteCount;

    // Packing数量
    public int packCount;

    // 图集路径
    public string spriteAtlasAssetPath;

    // 合图的资源文件集合
    public List<string> fileChilds;

    // 子文件总尺寸大小，无法获取合图数量，只能用子图的大小总和判断
    public int totalSize;
    public bool isOverMaxSize
    {
        get { return totalSize > Max_Atlas_Size; }
    }

    public override bool CanFix()
    {
        if (isSpriteAtlasExist == false) return true;

        if (isAllSprite2DFormat == false) return true;

        if (isIncludeInBuild == false) return true;

        if (isAllCloseOverride == false) return true;

        if (isAstcFormat == false) return true;

        if (isOpenOverride == false) return true;

        return false;
    }

    public override void Fix()
    {
        // 默认使用ASTC 5x5
        Fix(1);
    }

    public void Fix(int astcIndex)
    {
        if (isAllSprite2DFormat == false ||
            isAllCloseOverride == false)
        {
            _FixSprite2D();
        }

        if (isSpriteAtlasExist == false)
        {
            _FixCreateSpriteAtlas();
            return;
        }

        if (isAstcFormat == false ||
            isOpenOverride == false)
        {
            _FixAstcFormat(astcIndex);
        }

        if (isIncludeInBuild == false)
        {
            AtlasChecker.SetInclude(spriteAtlasAssetPath, true);
            isIncludeInBuild = true;
        }
    }

    /// <summary>
    /// 修复非ASTC格式
    /// </summary>
    /// <param name="info"></param>
    /// <param name="astcIndex"> 0:ASTC_4x4，1:ASTC_5x5，其他ASTC_6x6 </param>
    private void _FixAstcFormat(int astcIndex)
    {
        var format = _GetTextureFormat(astcIndex);
        SetAstcFormat(format);
    }

    /// <summary>
    /// 设置纹理格式
    /// </summary>
    /// <param name="info"></param>
    /// <param name="newFormat"></param>
    public void SetAstcFormat(TextureImporterFormat newFormat)
    {
        var res = AtlasChecker.SetASTC(spriteAtlasAssetPath, newFormat);
        if (res)
        {
            isAstcFormat = true;
            isOpenOverride = true;
            iosTextureFormat = newFormat;
            androidTextureFormat = newFormat;
        }
        else
        {
            Debug.LogError($"错误提示：修改{spriteAtlasAssetPath}ASTC格式失败，请检查");
        }
    }

    public override string GetErrorDes()
    {
        if (IsError() == false) return $"纹理格式{BigPicChecker.GetAstcName(androidTextureFormat)}";

        var desArr = new List<string>();

        if (isAllSprite2DFormat == false)
        {
            desArr.Add("包含非Sprite(2D and UI)资源");
        }

        if (isIncludeInBuild == false)
        {
            desArr.Add("Include in Build需要勾选");
        }

        if (isAllCloseOverride == false)
        {
            desArr.Add("原图需要关闭override");
        }

        if (spriteCount == 0)
        {
            desArr.Add("合图数量为空");
        }

        if (packCount > 1)
        {
            desArr.Add($"Pack数量{packCount}");
        }

        if (isOverMaxSize)
        {
            desArr.Add($"尺寸可能超过2048");
        }

        if (isSpriteAtlasExist == false)
        {
            desArr.Add("SpriteAtlas不存在");
        }
        else
        {
            if (isAstcFormat == false)
            {
                desArr.Add("非ASTC格式");
            }
            else
            {
                var des = _GetASTCDes(this);
                desArr.Add(des);
            }

            if (isOpenOverride == false)
            {
                desArr.Add("Override未开启");
            }
        }

        return string.Join("；", desArr);
    }

    public override bool IsError()
    {
        if (isSpriteAtlasExist == false) return true;

        if (isAllSprite2DFormat == false) return true;

        if (isIncludeInBuild == false) return true;

        if (isAllCloseOverride == false) return true;

        if (isAstcFormat == false) return true;

        if (isOpenOverride == false) return true;

        if (spriteCount == 0) return true;

        if (packCount > 1) return true;

        if (isOverMaxSize) return true;

        return false;
    }

    private static string _GetASTCDes(AtlasAssetInfo info)
    {
        if (info.androidTextureFormat == info.iosTextureFormat)
        {
            return $"纹理格式:{BigPicChecker.GetAstcName(info.androidTextureFormat)}";
        }

        return $"android:{BigPicChecker.GetAstcName(info.androidTextureFormat)},ios:{BigPicChecker.GetAstcName(info.iosTextureFormat)}";
    }

    private static bool _SetSprite2DAndCloseOverride(string assetPath)
    {
        var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (importer == null)
        {
            Debug.LogWarning($"错误提示：{assetPath}非TextureImporter格式，请检查资源");
            return false;
        }

        var androidSettings = importer.GetPlatformTextureSettings("Android");
        var iosSettings = importer.GetPlatformTextureSettings("iPhone");
        androidSettings.overridden = false;
        iosSettings.overridden = false;
        importer.SetPlatformTextureSettings(androidSettings);
        importer.SetPlatformTextureSettings(iosSettings);

        importer.textureType = TextureImporterType.Sprite;

        importer.SaveAndReimport();
        return true;
    }

    private static TextureImporterFormat _GetTextureFormat(int astcIndex)
    {
        if (astcIndex == 0) return TextureImporterFormat.ASTC_4x4;
        if (astcIndex == 1) return TextureImporterFormat.ASTC_5x5;
        return TextureImporterFormat.ASTC_6x6;
    }

    private void _FixSprite2D()
    {
        foreach (var file in fileChilds)
        {
            _SetSprite2DAndCloseOverride(file);
        }
        isAllSprite2DFormat = AtlasChecker.IsAllSprite2DFormat(fileChilds);
        isAllCloseOverride = AtlasChecker.IsAllCloseOverride(fileChilds);
    }

    private void _FixCreateSpriteAtlas()
    {
        AtlasCreater.CreateAtlasAsset(assetPath);
        isSpriteAtlasExist = File.Exists(spriteAtlasAssetPath);
        isAstcFormat = true;
        isOpenOverride = true;
    }

}
