using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;


namespace EditerUtils
{
    /// <summary>
    /// 文件帮助类
    /// </summary>
    public static class FileHelper
    {
        // 可以包含其他文件对象的格式
        public static string[] References_Suffixs = new string[] { ".prefab", ".unity", ".mat", ".asset", ".controller", ".overrideController", ".playable" };

        // 查找文件一般需要忽略的文件后缀（会忽略后缀大小写）
        public static string[] Ignore_Suffixs = new string[] { ".meta", ".ds_store", ".git", ".gitignore", ".cs" };

        /// <summary>
        /// 移动文件
        /// </summary>
        /// <param name="oldFilePath"></param>
        /// <param name="newFilePath"></param>
        public static void Move(string oldFilePath, string newFilePath)
        {
            if (File.Exists(oldFilePath) == false)
            {
                Debug.LogError($"错误提示：{oldFilePath}文件不存在");
                return;
            }

            if (File.Exists(newFilePath))
            {
                Debug.LogError($"错误提示：{newFilePath}目标文件已存在，请先删除");
                return;
            }

            // 确保目标文件夹存在
            var newDir = Path.GetDirectoryName(newFilePath);
            DirectoryHelper.CreateDirectory(newDir);

            File.Move(oldFilePath, newFilePath);
        }

        /// <summary>
        /// 更改文件名
        /// </summary>
        /// <param name="filePath"> 文件路径 </param>
        /// <param name="newName"> 新的文件名，不包括后缀 </param>
        public static void Rename(string filePath, string newName)
        {
            if (File.Exists(filePath) == false)
            {
                Debug.LogError($"错误提示：{filePath}文件不存在");
                return;
            }

            var dir = Path.GetDirectoryName(filePath);
            var suffix = Path.GetExtension(filePath);
            var newPath = $"{dir}/{newName}{suffix}";
            Move(filePath, newPath);
        }

        /// <summary>
        /// 拷贝文件，如果目标文件已存在则直接覆盖
        /// </summary>
        /// <param name="currentPath"> 当前路径 </param>
        /// <param name="targetPath"> 目标路径 </param>
        public static bool Copy(string currentPath, string targetPath)
        {
            if (File.Exists(currentPath) == false)
            {
                Debug.LogError($"错误提示：{currentPath}文件不存在");
                return false;
            }

            if (currentPath == targetPath)
            {
                Debug.LogError($"错误提示：{currentPath}拷贝文件路径一致");
                return false;
            }

            // 确保目标文件夹存在
            var newDir = Path.GetDirectoryName(targetPath);
            DirectoryHelper.CreateDirectory(newDir);

            File.Copy(currentPath, targetPath, true);
            return true;
        }

        /// <summary>
        /// 删除资源文件，包括meta会一起删除
        /// </summary>
        /// <param name="path"> 全路径或相对路径都可以 </param>
        public static void DeleteFile(string path)
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }

            var metaPath = path + ".meta";
            if (File.Exists(metaPath))
            {
                File.Delete(metaPath);
            }
        }

        /// <summary>
        /// 删除文件集合
        /// </summary>
        /// <param name="paths"></param>
        public static void DeleteFiles(List<string> paths)
        {
            foreach (var path in paths)
            {
                DeleteFile(path);
            }
        }

        /// <summary>
        /// 忽略隐藏和不必要的文件
        /// </summary>
        /// <param name="files"></param>
        /// <returns></returns>
        public static List<string> IgnoreFiles(List<string> files)
        {
            var newFiles = new List<string>();
            foreach (var file in files)
            {
                if (file.EndsWith(".meta") == false &&
                    file.EndsWith(".DS_Store") == false)
                {
                    newFiles.Add(file);
                }
            }
            return newFiles;
        }

        /// <summary>
        /// 忽略CSProject~工程文件夹
        /// </summary>
        /// <param name="files"></param>
        /// <returns></returns>
        public static List<string> IgnoreCSProjectFiles(List<string> files)
        {
            var newFiles = new List<string>();
            foreach (var file in files)
            {
                if (file.EndsWith("~") == false)
                {
                    newFiles.Add(file);
                }
            }
            return newFiles;
        }

        /// <summary>
        /// 获取文件大小
        /// </summary>
        /// <param name="filePath"></param>
        /// <returns></returns>
        public static long GetFileSize(string filePath)
        {
            if (File.Exists(filePath) == false)
            {
                Debug.LogWarning($"错误提示：{filePath}文件不存在");
                return 0;
            }

            var fileInfo = new FileInfo(filePath);
            return fileInfo.Length;
        }

        /// <summary>
        /// 查找content是否存在文件内
        /// </summary>
        /// <param name="content"> 要查找的内容 </param>
        /// <param name="filePaths"> 要超找的文件的路径集合 </param>
        /// <returns></returns>
        public static bool IsContentInFile(string content, List<string> filePaths)
        {
            foreach (var filePath in filePaths)
            {
                if (IsContentInFile(content, filePath))
                {
                    return true;
                }
            }
            return false;
        }

        public static bool IsContentInFile(string content, string filePath)
        {
            string readAllText = File.ReadAllText(filePath);
            return readAllText.Contains(content);
        }

        /// <summary>
        /// 异步搜索content是否在指定文件集合内
        /// </summary>
        /// <param name="content"> 搜索内容 </param>
        /// <param name="filePaths"> 搜索路径集合 </param>
        /// <param name="cb"> 匹配结果集合 </param>
        public static void GetContentFile(string content, List<string> filePaths, Action<List<string>> cb)
        {
            if (filePaths.Count == 0)
            {
                cb(new List<string>());
                return;
            }

            int startIndex = 0;
            var resPaths = new List<string>();
            EditorApplication.update = delegate ()
            {
                string file = filePaths[startIndex];
                if (IsContentInFile(content, file))
                {
                    resPaths.Add(file);
                }

                startIndex++;
                bool isCancel = EditorUtility.DisplayCancelableProgressBar("匹配资源中", file, (float)startIndex / (float)filePaths.Count);
                if (isCancel || startIndex >= filePaths.Count)
                {
                    EditorUtility.ClearProgressBar();
                    EditorApplication.update = null;
                    startIndex = 0;
                    cb(resPaths);
                }
            };
        }

        /// <summary>
        /// 文本替换，有多个一样全部替换
        /// </summary>
        /// <param name="filePath"> 文件路径 </param>
        /// <param name="oldTxt"> 旧的文本 </param>
        /// <param name="newTxt"> 新的文本 </param>
        public static void Replace(string filePath, string oldTxt, string newTxt)
        {
            if (File.Exists(filePath) == false)
            {
                Debug.LogWarning($"错误提示：{filePath}文件不存在");
                return;
            }

            var readAllText = File.ReadAllText(filePath);
            var replaceText = readAllText.Replace(oldTxt, newTxt);
            File.WriteAllText(filePath, replaceText);

            Debug.Log($"提示：文件{filePath}的文本<{oldTxt}>已替换为<{newTxt}>");
        }

        /// <summary>
        /// 文件大小文本描述
        /// </summary>
        /// <param name="fileSize"></param>
        /// <returns></returns>
        public static string GetFileSizeDes(double fileSize)
        {
            if (fileSize > 1048576f)
            {
                return $"文件大小：{fileSize / 1048576f:n1}MB";
            }
            return $"文件大小：{fileSize / 1024:n0}KB";
        }

        
    }

}

