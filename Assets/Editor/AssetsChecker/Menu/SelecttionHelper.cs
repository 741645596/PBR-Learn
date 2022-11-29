using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 选中资源帮助类
    /// </summary>
    public static class SelectionHelper
    {
        /// <summary>
        /// 获取当前选中的资源路径集合
        /// </summary>
        /// <returns></returns>
        public static List<string> GetSelectPaths()
        {
            var paths = new List<string>();
            var guids = Selection.assetGUIDs;
            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                paths.Add(path);
            }
            return paths;
        }

        /// <summary>
        /// 当前选中资源是否
        /// </summary>
        /// <param name="suffix"></param>
        /// <returns></returns>
        public static bool IsSuffixExist(string suffix)
        {
            var paths = GetSelectPaths();
            foreach (var path in paths)
            {
                if (PathHelper.IsSuffixExist(path, suffix))
                {
                    return true;
                }
            }
            return false;
        }

        public static bool IsSuffixExist(string[] suffixs)
        {
            var paths = GetSelectPaths();
            foreach (var path in paths)
            {
                if (PathHelper.IsSuffixExist(path, suffixs))
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// 遍历符合后缀条件的文件
        /// </summary>
        /// <param name="suffixs"></param>
        /// <param name="cb"></param>
        public static void Foreach(string suffix, Action<string> cb)
        {
            var paths = SelectionHelper.GetSelectPaths();
            foreach (var path in paths)
            {
                if (PathHelper.IsSuffixExist(path, suffix))
                {
                    cb(path);
                }
            }
        }

        public static void Foreach(string[] suffixs, Action<string> cb)
        {
            var paths = SelectionHelper.GetSelectPaths();
            foreach (var path in paths)
            {
                if (PathHelper.IsSuffixExist(path, suffixs))
                {
                    cb(path);
                }
            }
        }

    }
}


