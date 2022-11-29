using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using System;

public static class AudioCheckLogic
{
    /// <summary>
    /// 获取所有音频文件信息列表
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<AudioAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path,
            AssetsCheckEditorWindow.Audio_Types);
        FixHelper.AsyncCollect<AudioAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res) =>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取音频文件信息AudioAssetInfo
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 找不到返回null </returns>
    public static AudioAssetInfo GetAssetInfo(string file)
    {
        var importer = AssetImporter.GetAtPath(file) as AudioImporter;
        if (importer == null)
        {
            Debug.LogWarning($"错误提示：{file}不支持AudioImporter");
            return null;
        }
        var info = new AudioAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.isMono = importer.forceToMono;
        info.loadType = importer.defaultSampleSettings.loadType;
        info.isVorbis = importer.defaultSampleSettings.compressionFormat == AudioCompressionFormat.Vorbis;
        info.quality = importer.defaultSampleSettings.quality;

        var audio = AssetDatabase.LoadAssetAtPath<AudioClip>(file);
        if (audio != null)
        {
            info.sampleRate = (uint)audio.frequency;
            info.audioLength = audio.length;
        }
        
        info.isNormalize = _IsNormalize(importer);
        return info;
    }

    //public static float GetAudioLength(string audioPath)
    //{
    //    var clip = AssetDatabase.LoadAssetAtPath<AudioClip>(audioPath);
    //    if (clip != null)
    //    {
    //        return clip.length;
    //    }
    //    return 0;
    //}

    /// <summary>
    /// 找出不合规的资源列表
    /// </summary>
    /// <param name="assetInfos"></param>
    /// <returns></returns>
    public static List<AudioAssetInfo> GetErrorAssetInfos(List<AudioAssetInfo> assetInfos)
    {
        var infos = new List<AudioAssetInfo>();
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
    /// 一键修复
    /// </summary>
    /// <param name="infos"></param>
    public static void FixAll(List<AudioAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<AudioAssetInfo>(infos, (info) =>
        {
            if (info.IsError())
            {
                info.Fix();
            }
        },
        (isCancel) =>
        {
            finishCB(isCancel);
        });
    }

    private static bool _IsNormalize(AudioImporter importer)
    {
        SerializedObject serializedObject = new SerializedObject(importer);
        SerializedProperty normalize = serializedObject.FindProperty("m_Normalize");
        return normalize.boolValue;
    }
}
