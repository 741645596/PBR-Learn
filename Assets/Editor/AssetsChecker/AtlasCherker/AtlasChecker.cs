
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEngine.U2D;
using UnityEditor.U2D;
using EditerUtils;
using System;

public static class AtlasChecker
{
    /// <summary>
    /// 搜集图集相关信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<AtlasAssetInfo>> finishCB)
    {
        // 获取所有图集文件
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Sprite_Atlas_Type);
        FixHelper.AsyncCollect<AtlasAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res) =>
        {
            // 获取所有以_atlas文件夹结尾
            var notExist = _GetNotExistAtlasDir();
            res.AddRange(notExist);
            if (notExist.Count > 0)
            {
                res.OrderBy(r => r.assetPath);
            }
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取合图信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 非合图格式返回null </returns>
    public static AtlasAssetInfo GetAssetInfo(string file)
    {
        if (PathHelper.IsSuffixExist(file, AssetsCheckEditorWindow.Sprite_Atlas_Type) == false)
        {
            return null;
        }

        var info = new AtlasAssetInfo();
        info.assetPath = file;

        info.spriteAtlasAssetPath = file;
        info.isSpriteAtlasExist = true;
        AtlasChecker._InitAtlasFormat(info);

        var dir = GetSpriteAtlasPackDir(file);
        if (string.IsNullOrEmpty(dir))
        {
            info.fileChilds = new List<string>();
        }
        else
        {
            var childs = DirectoryHelper.GetAllFilesIgnoreExt(dir, AssetsCheckEditorWindow.Sprite_Atlas_Type);
            var targetFiles = EditerUtils.FileHelper.IgnoreFiles(childs);
            info.fileChilds = targetFiles;
            info.isAllSprite2DFormat = AtlasChecker.IsAllSprite2DFormat(targetFiles);
            info.isAllCloseOverride = IsAllCloseOverride(targetFiles);
            info.totalSize = GetTotalArea(targetFiles);
        }
        return info;
    }

    /// <summary>
    /// 获取文件集合总的面积
    /// </summary>
    /// <param name="filePaths"></param>
    /// <returns></returns>
    public static int GetTotalArea(List<string> filePaths)
    {
        int area = 0;
        foreach (var path in filePaths)
        {
            var a = BigPicChecker.GetTextureSize(path);
            area += (int)(a.x * a.y);
        }
        return area;
    }

    /// <summary>
    /// 获取合图包含的文件夹路径，找不到返回null
    /// </summary>
    /// <param name="atlasPath"></param>
    /// <returns></returns>
    public static string GetSpriteAtlasPackDir(string atlasPath)
    {
        var asset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(atlasPath);
        if (asset == null)
        {
            return null;
        }

        var packs = asset.GetPackables();
        if (packs.Length != 1)
        {
            return null;
        }

        var path = AssetDatabase.GetAssetPath(packs[0]);
        if (Directory.Exists(path))
        {
            return path;
        }
        return null;
    }

    /// <summary>
    /// 获取所有图集文件夹
    /// </summary>
    /// <returns></returns>
    public static List<string> GetTotalAtlasDir()
    {
        var res = new List<string>();
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Sprite_Atlas_Type);
        foreach (var file in files)
        {
            var dir = GetSpriteAtlasPackDir(file);
            if (string.IsNullOrEmpty(dir) == false)
            {
                res.Add(dir);
            }
        }
        return res;
    }

    /// <summary>
    /// 资源纹理格式是不是都是Sprite（2D and UI）格式
    /// </summary>
    /// <param name="assetPaths"></param>
    /// <returns></returns>
    public static bool IsAllSprite2DFormat(List<string> assetPaths)
    {
        foreach (var path in assetPaths)
        {
            if (IsSprite2DFormat(path) == false)
            {
                return false;
            }
        }
        return true;
    }

    /// <summary>
    /// 路径集合的资源是否都是astc 4x4
    /// </summary>
    /// <param name="assetPaths"></param>
    /// <returns></returns>
    public static bool IsAllCloseOverride(List<string> assetPaths)
    {
        foreach (var path in assetPaths)
        {
            if (IsCloseOverride(path) == false)
            {
                return false;
            }
        }
        return true;
    }

    public static bool IsCloseOverride(string assetPath)
    {
        var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (importer == null)
        {
            return false;
        }

        var androidSettings = importer.GetPlatformTextureSettings("Android");
        var iosSettings = importer.GetPlatformTextureSettings("iPhone");
        return androidSettings.overridden == false &&
            iosSettings.overridden == false;
    }

    /// <summary>
    /// 资源纹理格式是不是Sprite（2D and UI）格式
    /// </summary>
    /// <param name="assetPath"></param>
    /// <returns></returns>
    public static bool IsSprite2DFormat(string assetPath)
    {
        var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (importer == null)
        {
            return false;
        }
        return importer.textureType == TextureImporterType.Sprite;
    }

    /// <summary>
    /// 找出不合规的资源列表
    /// </summary>
    /// <param name="assetInfos"></param>
    /// <returns></returns>
    public static List<AtlasAssetInfo> GetErrorAssetInfos(List<AtlasAssetInfo> assetInfos)
    {
        var infos = new List<AtlasAssetInfo>();
        foreach (var info in assetInfos)
        {
            if (info.IsError())
            {
                infos.Add(info);
            }
        }
        return infos;
    }

    public static void FixAll(List<AtlasAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<AtlasAssetInfo>(infos, (info)=>
        {
            info.Fix();
        },
        (isCancel) =>
        {
            finishCB(isCancel);
        });
    }

    /// <summary>
    /// 一键设置所有ASTC格式
    /// </summary>
    /// <param name="infos"></param>
    /// <param name="newFormat"></param>
    public static void SetAllAstcFormat(List<AtlasAssetInfo> infos,
        TextureImporterFormat newFormat,
        Action<bool> finishCB)
    {
        FixHelper.FixStep<AtlasAssetInfo>(infos, (info) =>
        {
            info.SetAstcFormat(newFormat);
        },
        (isCancel) =>
        {
            finishCB(isCancel);
        });
    }

    /// <summary>
    /// 初始化合图默认参数
    /// </summary>
    /// <param name="path"></param>
    public static void InitAtlasFormat(string path)
    {
        var asset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(path);
        if (asset == null)
        {
            Debug.LogWarning($"错误提示：传入资源路径不存在{path}");
            return;
        }

        var androidSettings = asset.GetPlatformSettings("Android");
        var iosSettings = asset.GetPlatformSettings("iPhone");
        if (androidSettings.overridden == false ||
            BigPicChecker.IsAstcFormat(androidSettings.format) == false ||
            iosSettings.overridden == false ||
            BigPicChecker.IsAstcFormat(iosSettings.format) == false)
        {
            SetASTC(path, TextureImporterFormat.ASTC_5x5);

            Debug.Log($"完成初始化合图参数, {path}");
        }
    }

    public static void SetInclude(string atlasAssetPath, bool include)
    {
        var asset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(atlasAssetPath);
        if (asset == null)
        {
            return;
        }

        asset.SetIncludeInBuild(true);
    }

    /// <summary>
    /// 设置合图纹理格式
    /// </summary>
    /// <param name="atlasAssetPath"></param>
    /// <param name="tpFormat"></param>
    /// <returns></returns>
    public static bool SetASTC(string atlasAssetPath, TextureImporterFormat tpFormat)
    {
        var asset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(atlasAssetPath);
        if (asset == null)
        {
            return false;
        }

        TextureImporterPlatformSettings platformSetting = asset.GetPlatformSettings("Android");
        platformSetting.overridden = true;
        platformSetting.maxTextureSize = 2048;
        platformSetting.format = tpFormat;
        asset.SetPlatformSettings(platformSetting);

        platformSetting = asset.GetPlatformSettings("iPhone");
        platformSetting.overridden = true;
        platformSetting.maxTextureSize = 2048;
        platformSetting.format = tpFormat;
        asset.SetPlatformSettings(platformSetting); 

        //SpriteAtlasPackingSettings packSetting = new SpriteAtlasPackingSettings()
        //{
        //    blockOffset = 1,
        //    enableRotation = false,
        //    enableTightPacking = false,
        //    padding = 2
        //};
        //asset.SetPackingSettings(packSetting);

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        return true;
    }

    // 获取文件夹以_atlas结尾，但是合图文件不存在的集合
    private static List<AtlasAssetInfo> _GetNotExistAtlasDir()
    {
        var list = new List<AtlasAssetInfo>();

        var dirs = AtlasCreater.GetAtlasDirs();
        foreach (var dir in dirs)
        {
            var atlasPath = AtlasCreater.GetAtlasAssetPath(dir);
            if (File.Exists(atlasPath))
            {
                continue;
            }

            var info = new AtlasAssetInfo();
            info.assetPath = dir;
            info.spriteAtlasAssetPath = atlasPath;
            info.isSpriteAtlasExist = false;

            var files = DirectoryHelper.GetAllFiles(dir);
            var targetFiles = EditerUtils.FileHelper.IgnoreFiles(files);
            info.fileChilds = targetFiles;
            info.isAllSprite2DFormat = IsAllSprite2DFormat(targetFiles);
            info.isAllCloseOverride = IsAllCloseOverride(targetFiles);

            list.Add(info);
        }

        return list;
    }

    private static void _InitAtlasFormat(AtlasAssetInfo info)
    {
        var asset = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(info.spriteAtlasAssetPath);
        if (asset == null)
        {
            return;
        }

        var android = asset.GetPlatformSettings("Android");
        var ios = asset.GetPlatformSettings("iPhone");
        info.iosTextureFormat = ios.format;
        info.androidTextureFormat = android.format;
        info.isAstcFormat = BigPicChecker.IsAstcFormat(android.format) && BigPicChecker.IsAstcFormat(ios.format);
        info.isOpenOverride = android.overridden && ios.overridden;
        //info.isIncludeInBuild = asset.IsIncludeInBuild();

        info.packCount = asset.GetPackables().Length;
        info.spriteCount = asset.spriteCount;
    }
}
