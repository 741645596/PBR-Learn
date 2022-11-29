using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    public static class LogHelper
    {
        /// <summary>
        /// 清除unity控制台log信息
        /// </summary>
        public static void ClearLogConsole()
        {
#if UNITY_EDITOR
            Assembly assembly = Assembly.GetAssembly(typeof(SceneView));
            Type logEntries = assembly.GetType("UnityEditor.LogEntries");
            var method = logEntries.GetMethod("Clear");
            method?.Invoke(new object(), null);
#endif
        }

        /// <summary>
        /// 打印白色信息，点击信息可以跳转到资源
        /// </summary>
        /// <param name="msg"></param>
        /// <param name="assetPath"></param>
        public static void Log(string msg, string assetPath)
        {
            Debug.Log(msg, AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath));
        }

        /// <summary>
        /// 打印黄色的警告信息，点击信息可以跳转到资源
        /// </summary>
        /// <param name="msg"></param>
        /// <param name="assetPath"></param>
        public static void Warning(string msg, string assetPath)
        {
            Debug.LogWarning(msg, AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath));
        }

        /// <summary>
        /// 打印红色错误信息，点击信息可以跳转到资源
        /// </summary>
        /// <param name="msg"></param>
        /// <param name="assetPath"></param>
        public static void Error(string msg, string assetPath)
        {
            Debug.LogError(msg, AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath));
        }
    }
}




