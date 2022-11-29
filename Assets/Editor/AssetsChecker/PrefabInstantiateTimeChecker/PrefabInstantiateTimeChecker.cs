using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.VersionControl;
using UnityEngine;
using UnityEngine.SceneManagement;
using Debug = UnityEngine.Debug;
using Object = UnityEngine.Object;

public static class PrefabInstantiateTimeChecker
{
    /// <summary>
    /// 搜集实例化prefab耗时信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabInstantiateTimeAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabInstantiateTimeAssetInfo>(files, (file) =>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            res = res.OrderByDescending((info) => { return info.instantiateTime; }).ToList();
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设实例化时间
    /// </summary>
    /// <param name="file"></param>
    /// <returns></returns>
    public static PrefabInstantiateTimeAssetInfo GetAssetInfo(string file)
    {
        var info = new PrefabInstantiateTimeAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.instantiateTime = InstantiateTime(file);
        return info;
    }

    /// <summary>
    /// 创建预设对象耗时检测
    /// </summary>
    /// <param name="path"> 资源路径 </param>
    /// <returns></returns>
    public static float InstantiateTime(string unityPath)
    {
        Stopwatch stopwatch = new Stopwatch();
        stopwatch.Start();

        var gameObject = AssetDatabase.LoadAssetAtPath<GameObject>(unityPath);
        if (gameObject == null)
        {
            Debug.LogError($"检测耗时对象丢失:{unityPath}，解决方法:耗时检测时预制不要放到 ~ 这种隐藏文件夹内");
            return -1;
        }
        GameObject go = Object.Instantiate(gameObject);
        stopwatch.Stop();

        //  获取当前实例测量得出的总时间
        TimeSpan timespan = stopwatch.Elapsed;
        double milliseconds = timespan.TotalMilliseconds;
        GameObject.DestroyImmediate(go);
        return (float)milliseconds;
    }
}
