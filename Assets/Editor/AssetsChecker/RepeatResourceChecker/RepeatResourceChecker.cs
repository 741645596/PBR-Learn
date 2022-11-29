

using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public static class RepeatResourceChecker
{
    /// <summary>
    /// 搜集重复资源信息
    /// </summary>
    /// <returns></returns>
    public static List<RepeatResourceAssetInfo> CollectAssetInfo()
    {
        List<RepeatResourceAssetInfo> list = new List<RepeatResourceAssetInfo>();
 
        var md5Dic = CollectAllAssetInfo();
        var md5Fils = GetGreaterOneData(md5Dic);
        foreach (var dic in md5Fils)
        {
            RepeatResourceAssetInfo info = new RepeatResourceAssetInfo();
            info.assetPath = dic.Value[0];
            info.filesize = EditerUtils.FileHelper.GetFileSize(info.assetPath);
            info.repeatList = dic.Value;
            list.Add(info);
        }

        list.Sort((a, b) => { return (int)(b.filesize - a.filesize); });
        return list;
    }

    /// <summary>
    /// 获取所有资源的md5信息集合
    /// </summary>
    /// <returns></returns>
    public static Dictionary<string, List<string>> CollectAllAssetInfo()
    {
        var allFiles = EditerUtils.DirectoryHelper.GetAllFilesIgnoreExts(AssetsCheckEditorWindow.Asset_Search_Path,
            EditerUtils.FileHelper.Ignore_Suffixs);
        var files = EditerUtils.FileHelper.IgnoreCSProjectFiles(allFiles);
        return GetFileMD5Value(files);
    }

    /// <summary>
    /// 将文件信息转为md5当key，value存相同md5的字典结构
    /// </summary>
    /// <param name="files"></param>
    /// <returns></returns>
    public static Dictionary<string, List<string>> GetFileMD5Value(List<string> files)
    {
        var dictionary = new Dictionary<string, List<string>>();
        FixHelper.ForeachCollect(files, (file) =>
        {
            string md5 = GetMD5(file);
            if (dictionary.ContainsKey(md5))
            {
                dictionary[md5].Add(file);
            }
            else
            {
                var list = new List<string>();
                list.Add(file);
                dictionary.Add(md5, list);
            }
        });
        return dictionary;
    }

    public static string GetMD5(string file)
    {
        return MD5EidtorHelper.GetMD5FromFile(file);
    }

    /// <summary>
    /// 将上面的数据转为只有数量大于1的数据
    /// </summary>
    /// <param name="dic"></param>
    /// <returns></returns>
    public static Dictionary<string, List<string>> GetGreaterOneData(Dictionary<string, List<string>> dic)
    {
        var newDic = new Dictionary<string, List<string>>();
        foreach (var v in dic)
        {
            if (v.Value.Count > 1)
            {
                newDic.Add(v.Key, v.Value);
            }
        }
        return newDic;
    }
}
