using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEditor;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;

public static class AtlasCreater
{
    // 文件夹后缀名称是图集标识
    public const string Sprite_Atlas_Mark = "_atlas";

    /// <summary>
    /// 创建所有SpriteAtlas，所有文件夹名称后缀_atlas表示图集，每个文件夹对应一个SpriteAtlas
    /// </summary>
    public static void CreateAtlas()
    {
        // 收集有哪些文件夹需要创建SpriteAtlas
        var atlasPaths = GetAtlasDirs();

        // 创建Atlas图集
        _CreateAtlas(atlasPaths);

        AssetDatabase.Refresh();
    }

    /// <summary>
    /// 收集有哪些文件夹需要创建SpriteAtlas
    /// </summary>
    public static List<string> GetAtlasDirs()
    {
        // 规范：文件夹后缀是_atlas表示图集文件夹
        var paths = new List<string>();
        var dirs = DirectoryHelper.GetAllDirectorys(PathHelper.Game_Assets_Unity_Path);
        foreach (var dir in dirs)
        {
            if (dir.EndsWith(Sprite_Atlas_Mark))
            {
                paths.Add(dir);
            }
        }
        return paths;
    }

    /// <summary>
    /// 与上面区别是，参数一个是绝对路径，一个是相对路径
    /// </summary>
    /// <param name="assetPath"></param>
    /// <returns></returns>
    public static string GetAtlasAssetPath(string assetPath)
    {
        if (assetPath.StartsWith("/") == true)
        {
            Debug.LogError($"错误提示：图集路径必须是相对路径{assetPath}");
            return "";
        }

        var atlasFileName = Path.GetFileName(assetPath) + AssetsCheckEditorWindow.Sprite_Atlas_Type;
        return Path.Combine(assetPath, atlasFileName);
    }

    /// <summary>
    /// 创建图集
    /// </summary>
    /// <param name="atlasPaths"></param>
    private static void _CreateAtlas(List<string> dirPaths)
    {
        foreach (var dirPath in dirPaths)
        {
            // 已存在则不处理
            var atlasPath = GetAtlasAssetPath(dirPath);
            if (File.Exists(atlasPath))
            {
                continue;
            }

            CreateAtlasAsset(dirPath);
        }
    }

    /// <summary>
    /// 传入需要打成合图的文件夹Asset路径，在该目录下创建AtlasSprite
    /// </summary>
    /// <param name="atlasPath"> 图集的绝对路径 </param>
    public static void CreateAtlasAsset(string dirPath)
    {
        if (Directory.Exists(dirPath) == false)
        {
            Debug.LogWarning($"错误提示：{dirPath}不是一个文件夹路径");
            return;
        }

        SpriteAtlas atlas = new SpriteAtlas();

        SpriteAtlasPackingSettings packSetting = new SpriteAtlasPackingSettings()
        {
            blockOffset = 1,
            enableRotation = false,
            enableTightPacking = false,
            padding = 2
        };
        atlas.SetPackingSettings(packSetting);

        SpriteAtlasTextureSettings textureSetting = new SpriteAtlasTextureSettings()
        {
            readable = false,
            generateMipMaps = false,
            sRGB = true,
            filterMode = FilterMode.Bilinear
        };
        atlas.SetTextureSettings(textureSetting);

        // 设置TextureImporterPlatformSettings属性
        _TextureImporterPlatformSettings(atlas);

        // Include In Build 必须设置为true，才能实现atlas不放ab包文件夹也能打出图集
        atlas.SetIncludeInBuild(true);

        // 指定合图
        _ObjectsForPacking(dirPath, atlas);

        // 创建合图资源，需要用unity路径才能创建
        var atlasPath = GetAtlasAssetPath(dirPath);
        AssetDatabase.CreateAsset(atlas, atlasPath);
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    /// 设置TextureImporterPlatformSettings属性
    /// </summary>
    /// <param name="atlas"></param>
    /// <returns></returns>
    private static void _TextureImporterPlatformSettings(SpriteAtlas atlas)
    {
        TextureImporterPlatformSettings platformSetting = atlas.GetPlatformSettings("Android");
        platformSetting.overridden = true;
        platformSetting.maxTextureSize = 2048;
        platformSetting.format = TextureImporterFormat.ASTC_4x4;
        atlas.SetPlatformSettings(platformSetting);

        platformSetting = atlas.GetPlatformSettings("iPhone");
        platformSetting.overridden = true;
        platformSetting.maxTextureSize = 2048;
        platformSetting.format = TextureImporterFormat.ASTC_4x4;
        atlas.SetPlatformSettings(platformSetting);
    }

    /// <summary>
    /// 给SpriteAtlas绑定要打进图集的文件夹
    /// </summary>
    /// <param name="path"> 要打进图集的文件夹路径（这个路径下所有贴图会被打成图集） </param>
    /// <param name="atlas"> SpriteAtlas文件 </param>
    private static void _ObjectsForPacking(string path, SpriteAtlas atlas)
    {
        Object obj = AssetDatabase.LoadAssetAtPath(path, typeof(Object));
        atlas.Add(new[] { obj });
    }
}
