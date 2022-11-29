using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// Unity资源管理
    /// </summary>
    public static class AssetsHelper
    {
        private static Dictionary<string, List<string>> _assetDependens = new Dictionary<string, List<string>>();

        /// <summary>
        /// 获取Assets/GameAssets路径的资源集合
        /// </summary>
        /// <returns></returns>
        public static List<string> GetGameAssetsPaths()
        {
            var gameAssets = new List<string>();
            
            var assetPaths = AssetDatabase.GetAllAssetPaths();
            foreach (var path in assetPaths)
            {
                if (path.StartsWith(PathHelper.Game_Assets_Unity_Path))
                {
                    gameAssets.Add(path);
                }
            }

            return gameAssets;
        }

        /// <summary>
        /// 获取所有GameAssets资源的依赖关系
        /// </summary>
        /// <returns>  < 资源GUID, 依赖key的资源GUID集合 >  </returns>
        public static Dictionary<string, List<string>> GetGameAssetDependens()
        {
            _InitData();
            return _assetDependens;
        }

        /// <summary>
        /// 获取assetPath依赖的资源GUID集合
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static List<string> GetDepGUIDsByAssetPath(string assetPath)
        {
            if (File.Exists(assetPath) == false)
            {
                Debug.LogWarning($"错误提示：传入资源{assetPath}路径不存在");
                return new List<string>();
            }
            var guid = AssetDatabase.AssetPathToGUID(assetPath);
            return GetDepGUIDsByGUID(guid);
        }

        /// <summary>
        /// 通过GUID获得该资源依赖的资源集合
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public static List<string> GetDepGUIDsByGUID(string guid)
        {
            // 生成缓存数据
            _InitData();

            // 至少会插入一条空数据
            if (_assetDependens.ContainsKey(guid))
            {
                return _assetDependens[guid];
            }

            return new List<string>();
        }

        /// <summary>
        /// 将GUIDs转为路径
        /// </summary>
        /// <param name="guids"></param>
        /// <returns></returns>
        public static List<string> GetDepPaths(List<string> guids)
        {
            var paths = new List<string>();
            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                paths.Add(path);
            }
            return paths;
        }

        /// <summary>
        /// 通过资源路径获得依赖的资源路径集合
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static List<string> GetDepPathsByAssetPath(string assetPath)
        {
            var guids = GetDepGUIDsByAssetPath(assetPath);
            return GetDepPaths(guids);
        }

        /// <summary>
        /// 通过GUID获得依赖的资源路径集合
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public static List<string> GetDepPathByGUID(string guid)
        {
            var guids = GetDepGUIDsByGUID(guid);
            return GetDepPaths(guids);
        }

        /// <summary>
        /// 获取资源的完整的所有依赖路径，如
        /// A.png -> B.mat -> C.prefab 并且 A.png -> D.mat -> E.prefab则返回
        /// [ [A.png, B.mat, C.prefab], [A.png, D.mat, E.prefab] ]
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static List<List<string>> GetFullDepGUIDsByGUID(string guid)
        {
            _InitData();

            // 处理缓存数据之后，unity又新增新的资源
            if (_assetDependens.ContainsKey(guid) == false)
            {
                Debug.Log("提示：未找到缓存信息。如果在Unit内新增资源或更改依赖关系，这是无法实时获取的，这是Unity问题，只能重开Unity才能获取最新的依赖关系");
                return new List<List<string>>();
            }

            var res = new List<List<string>>();
            var tmpList = new List<string>() { guid };
            _Recursion(res, tmpList, guid);

            // 都是1表示只有自己一个，表示没有其他依赖
            if (res.Count == 1 && res[0].Count == 1)
            {
                return new List<List<string>>();
            }

            return res;
        }

        /// <summary>
        /// 同上，只是参数是文件路径
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static List<List<string>> GetFullDepGUIDsByAssetPath(string assetPath)
        {
            var guid = AssetDatabase.AssetPathToGUID(assetPath);
            return GetFullDepGUIDsByGUID(guid);
        }

        /// <summary>
        /// 同上，返回值是依赖文件路径集合
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public static List<List<string>> GetFullDepPathsByGUID(string guid)
        {
            var res = GetFullDepGUIDsByGUID(guid);
            return GetFullDepPaths(res);
        }

        /// <summary>
        /// 同上，返回值是依赖文件路径集合
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static List<List<string>> GetFullDepPathsByAssetPath(string assetPath)
        {
            var res = GetFullDepGUIDsByAssetPath(assetPath);
            return GetFullDepPaths(res);
        }

        /// <summary>
        /// 将guids转为路径集合
        /// </summary>
        /// <param name="guidsArr"></param>
        /// <returns></returns>
        public static List<List<string>> GetFullDepPaths(List<List<string>> guidsArr)
        {
            var pathsArr = new List<List<string>>();
            foreach (var guidArr in guidsArr)
            {
                var paths = new List<string>();
                foreach (var guid in guidArr)
                {
                    var path = AssetDatabase.GUIDToAssetPath(guid);
                    paths.Add(path);
                }
                pathsArr.Add(paths);
            }
            return pathsArr;
        }

        /// <summary>
        /// 根据获取资源的预览小图标
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static Texture2D GetPreviewMiniIcon(string path)
        {
            var obj = AssetDatabase.LoadAssetAtPath(path, typeof(UnityEngine.Object));
            if (obj != null)
            {
                Texture2D icon = AssetPreview.GetMiniThumbnail(obj);
                if (icon == null)
                    icon = AssetPreview.GetMiniTypeThumbnail(obj.GetType());
                return icon;
            }

            return null;
        }

        /// <summary>
        /// 重新刷新
        /// </summary>
        public static void Reload()
        {
            _assetDependens.Clear();
            _InitData();
        }

        private static void _Recursion(List<List<string>> res, List<string> tmpList, string guid)
        {
            var depGUIDs = _assetDependens[guid];
            if (depGUIDs.Count == 0)
            {
                res.Add(tmpList);
                return;
            }

            foreach (var depGUID in depGUIDs)
            {
                var newTmpList = new List<string>(tmpList);
                newTmpList.Add(depGUID);

                _Recursion(res, newTmpList, depGUID);
            }
        }

        private static void _InitData()
        {
            if (_assetDependens.Count == 0)
            {
                _InitDependens();
            }
        }

        private static void _InitDependens()
        {
            var gameAssets = GetGameAssetsPaths();
            var count = gameAssets.Count;
            for (int i=0; i< count; i++)
            {
                if ((i % 100 == 0) && EditorUtility.DisplayCancelableProgressBar("第一次收集信息会比较慢",
                    string.Format("正在分析依赖关系 {0} assets", i), (float)i / count))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }
                _InitDependen(gameAssets[i]);
            }
            EditorUtility.ClearProgressBar();
        }

        // 保存依赖数据，<gameAsset的GUID，依赖他的文件集合>
        private static void _InitDependen(string gameAsset)
        {
            // 保证查找自己信息数据存在，方便后续判断资源是否为新增
            var assetGUID = AssetDatabase.AssetPathToGUID(gameAsset);
            if (_assetDependens.ContainsKey(assetGUID) == false)
            {
                _assetDependens.Add(assetGUID, new List<string>());
            }

            var depends = AssetDatabase.GetDependencies(gameAsset, false);
            foreach (var dep in depends)
            {
                // 脚本代码不处理
                //if (dep.EndsWith(".cs"))
                //{
                //    continue;
                //}

                // 可能漏掉的资源
                var depGUID = AssetDatabase.AssetPathToGUID(dep);
                if (string.IsNullOrEmpty(depGUID))
                {
                    Debug.LogWarning($"搜集path={dep}的GUID为Null，请检查下资源");
                    continue;
                }

                // 自己不处理
                if (depGUID == assetGUID)
                {
                    continue;
                }

                if (_assetDependens.ContainsKey(depGUID))
                {
                    _assetDependens[depGUID].Add(assetGUID);
                }
                else
                {
                    _assetDependens.Add(depGUID, new List<string>() { assetGUID });
                }
            }
        }
    }
}

