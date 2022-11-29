using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 检测是否mesh重复帮助类
    /// </summary>
    public static class RepeatMeshHelper
    {
        private static Dictionary<string, List<RepeatMeshData>> _repeatMeshDatas = null;

        /// <summary>
        /// 打印重复资源信息
        /// </summary>
        /// <param name="fbxPath"></param>
        /// <returns></returns>
        public static void PrintRepeatMesh(string fbxPath)
        {
            _Init();

            bool hasRepeat = false;
            var meshDatas = RepeatMeshChecker.GetMeshData(fbxPath);
            foreach (var data in meshDatas)
            {
                // 检查文件是否已经被删除
                _CheckFileNotExist(data);

                // 检查资源本身是否新增的
                _CheckNewMeshData(data);

                // 数量超过2个则表示有冗余了
                var key = data.GetUniqueKey();
                if (_repeatMeshDatas.ContainsKey(key) &&
                    _repeatMeshDatas[key].Count > 1)
                {
                    _Print(_repeatMeshDatas[key]);
                    hasRepeat = true;
                }
            }

            if (hasRepeat == false)
            {
                Debug.Log("未找到相同mesh ok!!!");
            }
        }

        private static void _Print(List<RepeatMeshData> datas)
        {
            Debug.LogWarning($"以下 {datas.Count} 文件有相同Mesh，点击Log信息可以跳转");
            foreach (var data in datas)
            {
                LogHelper.Log($"{data.assetPath} | {data.name}", data.assetPath);
            }
        }

        // 去掉已经被删掉的文件
        private static void _CheckFileNotExist(RepeatMeshData data)
        {
            var key = data.GetUniqueKey();
            if (_repeatMeshDatas.ContainsKey(key) == false)
            {
                return;
            }

            var values = _repeatMeshDatas[key];
            for (int i = values.Count - 1; i >= 0; i--)
            {
                var value = values[i];
                if (File.Exists(value.assetPath) == false)
                {
                    values.RemoveAt(i);
                }
            }
        }

        // 检查本身资源资源是否存在，不存在则添加进缓存。（有可能已经有缓存，美术导入新资源则会）
        private static void _CheckNewMeshData(RepeatMeshData data)
        {
            var key = data.GetUniqueKey();
            if (_repeatMeshDatas.ContainsKey(key))
            {
                // 还得判断是否存在
                foreach (var d in _repeatMeshDatas[key])
                {
                    if (d.assetPath == data.assetPath)
                    {
                        return;
                    }
                }
                _repeatMeshDatas[key].Add(data);
            }
            else
            {
                _repeatMeshDatas.Add(key, new List<RepeatMeshData>() { data });
            }
        }

        private static void _Init()
        {
            if (_repeatMeshDatas == null)
                _repeatMeshDatas = RepeatMeshChecker.CollectAllAssetInfo();
        }
    }
}


