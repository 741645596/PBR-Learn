
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public static class BigPicChecker
{
    private static Dictionary<TextureImporterFormat, string> _ASTC_NAME = new Dictionary<TextureImporterFormat, string>()
    {
        { TextureImporterFormat.ASTC_4x4,   "ASTC_4x4" },
        { TextureImporterFormat.ASTC_5x5,   "ASTC_5x5" },
        { TextureImporterFormat.ASTC_6x6,   "ASTC_6x6" },
        { TextureImporterFormat.ASTC_8x8,   "ASTC_8x8" },
        { TextureImporterFormat.ASTC_10x10, "ASTC_10x10" },
        { TextureImporterFormat.ASTC_12x12, "ASTC_12x12" },

        { TextureImporterFormat.ASTC_HDR_4x4,   "ASTC_HDR_4x4" },
        { TextureImporterFormat.ASTC_HDR_5x5,   "ASTC_HDR_5x5" },
        { TextureImporterFormat.ASTC_HDR_6x6,   "ASTC_HDR_6x6" },
        { TextureImporterFormat.ASTC_HDR_8x8,   "ASTC_HDR_8x8" },
        { TextureImporterFormat.ASTC_HDR_10x10, "ASTC_HDR_10x10" },
        { TextureImporterFormat.ASTC_HDR_12x12, "ASTC_HDR_12x12" },
    };

    /// <summary>
    /// 搜集所有图片资源信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<BigPicAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Texture_Types);

        // 剔除合图文件
        _ClipAtlasFiles(files);

        FixHelper.AsyncCollect<BigPicAssetInfo>(files, (file)=>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            // 按面积排序
            finishCB(res);
        });
    }

    /// <summary>
    /// 剔除合图文件
    /// </summary>
    /// <param name="files"></param>
    private static void _ClipAtlasFiles(List<string> files)
    {
        var atlasDir = AtlasChecker.GetTotalAtlasDir();
        foreach (var dir in atlasDir)
        {
            for (int i = files.Count - 1; i >= 0; i--)
            {
                var file = files[i];
                if (file.StartsWith(dir))
                {
                    files.RemoveAt(i);
                }
            }
        }
    }

    /// <summary>
    /// 获取纹理信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 非纹理格式返回null </returns>
    public static BigPicAssetInfo GetAssetInfo(string file)
    {
        var importer = AssetImporter.GetAtPath(file) as TextureImporter;
        if (importer == null)
        {
            var gotoObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(file);
            Debug.LogWarning($"错误提示：{file}图片格式无法通过TextureImporter读取，请检查资源是否正确", gotoObj);
            return null;
        }

        var info = new BigPicAssetInfo(); //创建个贴图的信息对象
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.isSpriete2D = importer.textureType == TextureImporterType.Sprite;
        info.isReadable = _IsReadable(importer, file);
        info.isMipmap = importer.mipmapEnabled;
        info.filterMode = importer.filterMode;

        var textureSize = GetTextureSize(file);
        info.width = (int)textureSize.x;
        info.height = (int)textureSize.y;
        info.area = info.width * info.height;

        var android = importer.GetPlatformTextureSettings("Android");
        info.androidFormat = android.format;
        info.isAndroidOverride = android.overridden;

        var ios = importer.GetPlatformTextureSettings("iPhone");
        info.iosFormat = ios.format;
        info.isIosOverride = ios.overridden;

        info.haveAlpha = importer.DoesSourceTextureHaveAlpha();
        info.alphaSource = importer.alphaSource;

        info.isSameMaxSize = importer.maxTextureSize == ios.maxTextureSize && ios.maxTextureSize == android.maxTextureSize;

        return info;
    }

    /// <summary>
    /// 获取图片尺寸大小
    /// </summary>
    public static Vector2 GetTextureSize(string filePath)
    {
        // 这样才能获取真实的尺寸大小
        var obj = AssetDatabase.LoadAssetAtPath<Texture>(filePath); //贴图的文件信息
        if (obj == null)
        {
            var gotoObj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(filePath);
            Debug.LogWarning($"错误提示：{filePath}图片格式不是Texture类型，请检查资源是否正确", gotoObj);
            return Vector2.zero;
        }

        return new Vector2(obj.width, obj.height);
    }

    /// <summary>
    /// ASTC格式文本
    /// </summary>
    public static string GetAstcName(TextureImporterFormat format)
    {
        if (_ASTC_NAME.ContainsKey(format))
        {
            return _ASTC_NAME[format];
        }
        return "非ASTC格式";
    }

    /// <summary>
    /// 纹理格式是否是ASTC格式
    /// </summary>
    /// <param name="format"></param>
    /// <returns></returns>
    public static bool IsAstcFormat(TextureImporterFormat format)
    {
        return TextureImporterFormat.ASTC_4x4 <= format &&
            format <= TextureImporterFormat.ASTC_HDR_12x12;
    }

    /// <summary>
    /// 推荐的纹理格式，带透明通道ASTC_5x5，否则ASTC_6x6
    /// </summary>
    /// <param name="info"></param>
    /// <returns></returns>
    public static TextureImporterFormat GetRecommonFormat(bool haveAlpha)
    {
        return haveAlpha ? TextureImporterFormat.ASTC_5x5 : TextureImporterFormat.ASTC_6x6;
    }

    /// <summary>
    /// 初始化纹理格式，一般用在导入贴图时调用
    /// </summary>
    /// <param name="importer"></param>
    public static void InitDefaultFormat(TextureImporter importer)
    {
        var androidSettings = importer.GetPlatformTextureSettings("Android");
        var iosSettings = importer.GetPlatformTextureSettings("iPhone");
        if (androidSettings.overridden == false ||
            IsAstcFormat(androidSettings.format) == false ||
            iosSettings.overridden == false ||
            IsAstcFormat(iosSettings.format) == false)
        {
            var newFormat = GetRecommonFormat(importer.DoesSourceTextureHaveAlpha());
            SetTextureFormat(importer, newFormat);
            importer.SaveAndReimport();

            Debug.Log($"已将导入贴图转为ASTC格式，{importer.assetPath}");
        }
    }

    public static void SetTextureFormat(TextureImporter importer, TextureImporterFormat newFormat)
    {
        // 安卓设置
        var androidSettings = importer.GetPlatformTextureSettings("Android");
        androidSettings.overridden = true;
        androidSettings.format = newFormat;
        importer.SetPlatformTextureSettings(androidSettings);

        // IOS设置
        var iosSettings = importer.GetPlatformTextureSettings("iPhone");
        iosSettings.overridden = true;
        iosSettings.format = newFormat;
        importer.SetPlatformTextureSettings(iosSettings);
    }

    public static void SetOverridden(TextureImporter importer, bool isOverriden)
    {
        // 安卓设置
        var androidSettings = importer.GetPlatformTextureSettings("Android");
        androidSettings.overridden = isOverriden;
        importer.SetPlatformTextureSettings(androidSettings);

        // IOS设置
        var iosSettings = importer.GetPlatformTextureSettings("iPhone");
        iosSettings.overridden = isOverriden;
        importer.SetPlatformTextureSettings(iosSettings);
    }

    // 规定：文件名称后缀为_RW，则表示需要开启RW，工具这边就直接忽略了
    private static bool _IsReadable(TextureImporter import, string file)
    {
        if (import.isReadable == false) return false;

        // 规范：判断文件后缀是否_RW
        var name = Path.GetFileNameWithoutExtension(file);
        if (name.EndsWith("_RW"))
        {
            return false;
        }

        return true;
    }
}
