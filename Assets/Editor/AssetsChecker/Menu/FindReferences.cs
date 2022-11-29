

using UnityEngine;
using System.Collections;
using UnityEditor;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;
using EditerUtils;

namespace EditerUtils
{

    public class FindReferences
    {
        //[MenuItem("Assets/查找引用该资源的对象", true)]
        //private static bool vFind()
        //{
        //    return false;
        //}

        //[MenuItem("Assets/查找引用该资源的对象(使用缓存)", false, 0)]
        private static void Find()
        {
            // 清除控制台信息
            LogHelper.ClearLogConsole();

            string filePath = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(filePath))
            {
                return;
            }

            var pathsArr = AssetsHelper.GetFullDepPathsByAssetPath(filePath);
            Debug.Log($"总共查到 {pathsArr.Count} 条依赖路径：");
            for (int i=0; i< pathsArr.Count; i++)
            {
                Debug.Log($"第 {i+1} 条路径 ======================================================");
                foreach (var path in pathsArr[i])
                {
                    Debug.Log(path, AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(path));
                }
            }
        }

        //[MenuItem("Assets/查找引用该资源的对象(Reload缓存)", false, 0)]
        private static void FindForceReload()
        {
            AssetsHelper.Reload();

            Find();
        }

        //[MenuItem("Assets/查找引用该资源的C#脚本")]
        private static void FindResInCS()
        {
            // 清除控制台信息
            LogHelper.ClearLogConsole();

            string filePath = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (string.IsNullOrEmpty(filePath))
            {
                return;
            }

            // 备注：如果搜索全名(如xx.prefab)则搜索不到，应该是mdfind的bug
            GetResPathsInCS(filePath, (paths) =>
            {
                foreach (var path in paths)
                {
                    Debug.Log(path);
                }
                var content = Path.GetFileNameWithoutExtension(filePath);
                Debug.Log($"共找到{paths.Count}个.cs文件包含\"{content}\"");
            });
        }

        /// <summary>
        /// 查找哪些资源引用到了filePath这个资源
        /// </summary>
        /// <param name="filePath"> 资源路径 </param>
        /// <param name="cb"> 返回绝对路径集合 </param>
        public static void FindRes(string filePath, Action<List<string>> cb)
        {
            var guid = AssetDatabase.AssetPathToGUID(filePath);
            var searchPath = AssetsCheckEditorWindow.Asset_Search_Path;
            FindPath(guid, searchPath, FileHelper.References_Suffixs.ToList(), (paths) =>
            {
                // 排除自身meta文件
                var p = filePath + ".meta";
                var dir = Path.GetDirectoryName(Application.dataPath);
                var fileFullPath = Path.Combine(dir, p);
                var fullPath = PathHelper.PathFormat(fileFullPath);
                paths.Remove(fullPath);

                cb(paths);
            });
        }

        /// <summary>
        /// 查找文件集合对应的引用集合
        /// </summary>
        /// <param name="filePaths"></param>
        /// <param name="cb"> <文件, 引用集合> </param>
        public static void FindResArr(List<string> filePaths, Action<Dictionary<string, List<string>>> cb)
        {
            var res = new Dictionary<string, List<string>>();
            var index = 0;

            // 递归查找
            _RecursionFindRes(filePaths, cb, index, res);
        }

        private static void _RecursionFindRes(List<string> filePaths,
            Action<Dictionary<string, List<string>>> cb,
            int curIndex,
            Dictionary<string, List<string>> res)
        {
            FindRes(filePaths[curIndex], (relativePaths) =>
            {
                res.Add(filePaths[curIndex], relativePaths);

                curIndex++;
                if (curIndex >= filePaths.Count)
                {
                    cb(res);
                }
                else
                {
                    _RecursionFindRes(filePaths, cb, curIndex, res);
                }
            });
        }

        /// <summary>
        /// 查找哪些资源引用到了Object这个资源对象
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="cb"></param>
        public static void FindRes(UnityEngine.Object obj, Action<List<string>> cb)
        {
            Debug.Assert(obj != null, "错误提示：obj不能为null");
            string filePath = AssetDatabase.GetAssetPath(obj);
            FindRes(filePath, cb);
        }

        /// <summary>
        /// 通过文件路径查找文件名是否存在GameAssets目录下的cs文件内
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="cb"></param>
        public static void IsResInCS(string filePath, Action<bool> cb)
        {
            GetResPathsInCS(filePath, (paths) =>
            {
                cb(paths.Count != 0);
            });
        }

        /// <summary>
        /// 查找GameAssets目录下包含filePaht文件名的所有cs文件
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="cb"></param>
        static public void GetResPathsInCS(string filePath, Action<List<string>> cb)
        {
            // 备注：如果搜索全名(如xx.prefab)则搜索不到，应该是mdfind的bug
            var content = Path.GetFileNameWithoutExtension(filePath);
            var unityRunPath = Path.GetDirectoryName(Application.dataPath);
            var rootPath = Path.GetDirectoryName(unityRunPath);
            var searchPath = Path.Combine(rootPath, "WLFishingGame");
            var exts = new List<string>() { ".cs" };
            FindPath(content, searchPath, exts, (paths) =>
            {
                cb(paths);
            });
        }

        /// <summary>
        /// 查找哪些文件包含content
        /// </summary>
        /// <param name="content"> 查找的字符串 </param>
        /// <param name="searchDir"> 要查找的文件夹 </param>
        /// <param name="searchExts"> 要查找的文件后缀名 </param>
        /// <param name="cb"> 返回查找到的文件集合 </param>
        public static void FindPath(string content, string searchDir, List<string> searchExts, Action<List<string>> cb)
        {
#if UNITY_EDITOR_OSX
            _FindPathWithMac(content, searchDir, searchExts, cb);
#else
        _FindPath(content, searchDir, searchExts, cb);
#endif
        }

        private static void _FindPath(string content, string searchDir, List<string> searchExts, Action<List<string>> cb)
        {
            EditorSettings.serializationMode = SerializationMode.ForceText;

            var resPaths = new List<string>();
            var files = DirectoryHelper.GetAllFiles(searchDir, searchExts);
            if (files.Count == 0)
            {
                Debug.LogError($"搜索路径{searchDir}找不到任何资源，请检查路径是否配置正确");
                cb(resPaths);
                return;
            }

            int startIndex = 0;
            EditorApplication.update = delegate ()
            {
                string file = files[startIndex];
                if (Regex.IsMatch(File.ReadAllText(file), content))
                {
                    resPaths.Add(file);
                }

                startIndex++;
                bool isCancel = EditorUtility.DisplayCancelableProgressBar("匹配资源中", file, (float)startIndex / (float)files.Count);
                if (isCancel || startIndex >= files.Count)
                {
                    EditorUtility.ClearProgressBar();
                    EditorApplication.update = null;
                    startIndex = 0;
                    cb(resPaths);
                }
            };
        }

        private static void _FindPathWithMac(string content, string searchDir, List<string> searchExts, Action<List<string>> cb)
        {
            // 使用mac的mdfind命名查找，速度非常的快
            var psi = new System.Diagnostics.ProcessStartInfo();
            psi.WindowStyle = System.Diagnostics.ProcessWindowStyle.Maximized;
            psi.FileName = "/usr/bin/mdfind";
            psi.Arguments = "-onlyin " + searchDir + " " + content;
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;

            System.Diagnostics.Process process = new System.Diagnostics.Process();
            process.StartInfo = psi;

            List<string> references = new List<string>();
            process.OutputDataReceived += (sender, e) =>
            {
                var path = e.Data;
                if (string.IsNullOrEmpty(path))
                {
                    return;
                }

                foreach (var ext in searchExts)
                {
                    if (path.EndsWith(ext))
                    {
                        references.Add(path);
                    }
                }
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            process.WaitForExit();

            cb(references);
        }
    }

}
