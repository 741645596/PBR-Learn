using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 检测资源是否重复
    /// </summary>
    public static class RepeatResourceHelper
    {
        private static Dictionary<string, List<string>> _repeatResDatas = null;

        /// <summary>
        /// 打印重复资源信息
        /// </summary>
        /// <param name="fbxPath"></param>
        /// <returns></returns>
        public static void PrintRepeatRes(string assetPath)
        {
            PrintRepeatRes(new string[] { assetPath });
        }

        public static void PrintRepeatRes(string[] assetPaths)
        {
            _Init();

            bool hasRepeat = false;
            foreach (var assetPath in assetPaths)
            {
                var md5 = RepeatResourceChecker.GetMD5(assetPath);

                // 检查文件是否已经被删除
                _CheckFileNotExist(assetPath, md5);

                // 检查资源本身是否新增的
                _CheckNewData(assetPath, md5);

                // 数量超过2个则表示有冗余了
                if (_repeatResDatas.ContainsKey(md5) &&
                    _repeatResDatas[md5].Count > 1)
                {
                    _Print(_repeatResDatas[md5]);
                    hasRepeat = true;
                }
            }
            if (hasRepeat == false)
            {
                Debug.Log("未发现重复资源 ok!!!");
            }
        }

        private static void _Print(List<string> paths)
        {
            Debug.LogWarning($"以下 {paths.Count} 个文件相同，请根据需求删除冗余，点击Log信息可以跳转");
            foreach (var path in paths)
            {
                LogHelper.Log($"{path}", path);
            }
        }

        // 去掉已经被删掉的文件
        private static void _CheckFileNotExist(string file, string md5)
        {
            if (_repeatResDatas.ContainsKey(md5) == false)
            {
                return;
            }

            var values = _repeatResDatas[md5];
            for (int i = values.Count - 1; i >= 0; i--)
            {
                var path = values[i];
                if (File.Exists(path) == false)
                {
                    values.RemoveAt(i);
                }
            }
        }

        // 检查本身资源资源是否存在，不存在则添加进缓存。（有可能已经有缓存，美术导入新资源则会）
        private static void _CheckNewData(string file, string md5)
        {
            if (_repeatResDatas.ContainsKey(md5))
            {
                // 还得判断是否存在
                foreach (var path in _repeatResDatas[md5])
                {
                    if (path == file)
                    {
                        return;
                    }
                }
                _repeatResDatas[md5].Add(file);
            }
            else
            {
                _repeatResDatas.Add(md5, new List<string> { file });
            }
        }

        private static void _Init()
        {
            if (_repeatResDatas == null)
                _repeatResDatas = RepeatResourceChecker.CollectAllAssetInfo();
        }
    }
}


