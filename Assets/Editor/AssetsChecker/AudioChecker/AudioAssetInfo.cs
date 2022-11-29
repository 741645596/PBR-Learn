
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 音频资源信息
/// </summary>
public class AudioAssetInfo : AssetInfoBase
{
    // 音频时长超过这个长度建议用Streaming方式播放
    public const float Time_Threshold = 5f;
    public const float Quality_Ratio = 0.88f;
    public const uint Sample_Rate = 22050;

    public bool isMono;
    public bool isVorbis;
    public bool isNormalize;
    public float audioLength;
    public float quality;
    public uint sampleRate;
    public AudioClipLoadType loadType;

    public override bool CanFix()
    {
        return IsError();
    }

    public override void Fix()
    {
        var importer = AssetImporter.GetAtPath(assetPath) as AudioImporter;

        // Mono 勾选为单声道
        if (isMono == false)
        {
            importer.forceToMono = true;
            isMono = true;
        }

        // 勾选表示统一音效声音，建议关闭
        if (isNormalize == true)
        {
            SerializedObject serializedObject = new SerializedObject(importer);
            SerializedProperty normalize = serializedObject.FindProperty("m_Normalize");
            normalize.boolValue = false;
            serializedObject.ApplyModifiedProperties();

            isNormalize = false;
        }

        // Vorbis表示可压缩，建议开启
        if (isVorbis == false || quality > Quality_Ratio)
        {
            var newSampleSettings = importer.defaultSampleSettings;
            newSampleSettings.compressionFormat = AudioCompressionFormat.Vorbis; // 压缩格式修复
            newSampleSettings.quality = Quality_Ratio;                       // 音频质量修复
            importer.defaultSampleSettings = newSampleSettings;

            isVorbis = true;
            quality = Quality_Ratio;
        }

        // 音效格式设置是否正确
        if (IsVaildLoadType() == false)
        {
            var format = audioLength >= Time_Threshold ?
                AudioClipLoadType.Streaming :
                AudioClipLoadType.DecompressOnLoad;
            var newSampleSettings = importer.defaultSampleSettings;
            newSampleSettings.loadType = format;
            importer.defaultSampleSettings = newSampleSettings;

            loadType = format;
        }

        importer.SaveAndReimport();
    }

    public override string GetErrorDes()
    {
        if (IsError() == false) return $"时长{audioLength.ToString("0.0")}s；采样率{sampleRate}";

        var errors = new List<string>();

        errors.Add($"时长{audioLength.ToString("0.0")}s；采样率{sampleRate}");

        // Mono 勾选为单声道
        if (isMono == false)
        {
            errors.Add("建议设置为单声道");
        }

        // 勾选表示统一音效声音，建议关闭
        if (isNormalize == true)
        {
            errors.Add("建议取消Normalize");
        }

        // Vorbis表示可压缩，建议开启
        if (isVorbis == false)
        {
            errors.Add("建议设置为Vorbis压缩格式");
        }

        if (quality > Quality_Ratio)
        {
            errors.Add("建议设置Quality=88");
        }

        // 音效格式设置是否正确
        if (IsVaildLoadType() == false)
        {
            var err = audioLength >= Time_Threshold ?
                "音乐建议设置为Streaming" :
                "音效建议设置为DecompressOnLoad";
            errors.Add(err);
        }

        return string.Join("；", errors);
    }

    public override bool IsError()
    {
        // Mono 勾选为单声道
        if (isMono == false)
        {
            return true;
        }

        // 勾选表示统一音效声音，建议关闭
        if (isNormalize == true)
        {
            return true;
        }

        // Vorbis表示可压缩，建议开启
        if (isVorbis == false)
        {
            return true;
        }

        if (quality > Quality_Ratio)
        {
            return true;
        }

        // 音效格式设置是否正确
        if (IsVaildLoadType() == false)
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// 是否是合理的加载模式
    /// </summary>
    /// <param name="info"></param>
    /// <returns></returns>
    public bool IsVaildLoadType()
    {
        // 音效超过指定长度，需要用Streaming
        if (audioLength >= Time_Threshold)
        {
            return loadType == AudioClipLoadType.Streaming;
        }
        return loadType == AudioClipLoadType.DecompressOnLoad;
    }

    public void SetSampleRate(uint rate)
    {
        var importer = AssetImporter.GetAtPath(assetPath) as AudioImporter;
        var defaultSetting = importer.defaultSampleSettings;
        defaultSetting.sampleRateSetting = AudioSampleRateSetting.OverrideSampleRate;
        defaultSetting.sampleRateOverride = rate;
        importer.defaultSampleSettings = defaultSetting;
        importer.SaveAndReimport();

        sampleRate = rate;
        Debug.Log(sampleRate);
    }

    public void RevertSampleRate()
    {
        var importer = AssetImporter.GetAtPath(assetPath) as AudioImporter;
        var defaultSetting = importer.defaultSampleSettings;
        defaultSetting.sampleRateSetting = AudioSampleRateSetting.PreserveSampleRate;
        defaultSetting.sampleRateOverride = 44100;
        importer.defaultSampleSettings = defaultSetting;
        importer.SaveAndReimport();
        sampleRate = 44100;
    }
}
