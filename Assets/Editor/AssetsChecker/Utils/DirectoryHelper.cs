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
    /// 文件夹相关帮助类
    /// </summary>
    public static class DirectoryHelper
    {
        public class FileData
        {
            public string path;
            public float size;
        }

        /// <summary>
        /// 获取文件夹下的文件集合，不包括文子文件夹
        /// </summary>
        /// <param name="dirPath"> 传入的绝对路径，则返回绝对路径的集合；传相对路径则返回相对路径集合 </param>
        /// <returns></returns>
        public static List<string> GetFiles(string dirPath)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath);
            var list = new List<string>();
            foreach (var file in files)
            {
                list.Add(PathHelper.PathFormat(file));
            }
            return list;
        }

        /// <summary>
        /// 获取dirPath文件夹下，指定suffix后缀的所有文件集合，不包括子文件夹
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="suffix"></param>
        /// <returns></returns>
        public static List<string> GetFiles(string dirPath, string suffix)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            if (suffix.StartsWith(".") == false)
            {
                Debug.LogError($"错误提示：后缀名必须以.开头，suffix={suffix}");
                return new List<string>();
            }

            var search = "*" + suffix;
            var files = Directory.GetFiles(dirPath, search);
            var list = new List<string>();
            foreach (var file in files)
            {
                list.Add(PathHelper.PathFormat(file));
            }
            return list;
        }

        /// <summary>
        /// 获取dirPath文件夹下，指定suffix后缀的所有文件集合，不包括子文件夹下的文件 
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="suffixs"> 后缀的集合，如：[.prefab, .png ...] </param>
        /// <returns></returns>
        public static List<string> GetFiles(string dirPath, List<string> suffixs)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath, "*");
            var res = new List<string>();
            foreach (var file in files)
            {
                var formatFile = PathHelper.PathFormat(file);
                foreach (var suffix in suffixs)
                {
                    if (formatFile.EndsWith(suffix))
                    {
                        res.Add(formatFile);
                    }
                }
            }
            return res;
        }

        /// <summary>
        /// 获取文件夹下的所有文件集合，包括子文件夹下的文件 
        /// </summary>
        /// <param name="dirPath"> 传入的绝对路径，则返回绝对路径的集合；传相对路径则返回相对路径集合 </param>
        /// <returns></returns>
        public static List<string> GetAllFiles(string dirPath)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath, "*", SearchOption.AllDirectories);
            var list = new List<string>();
            foreach (var file in files)
            {
                list.Add(PathHelper.PathFormat(file));
            }
            return list;
        }


        /// <summary>
        /// 获取dirPath文件夹下，指定suffix后缀的所有文件集合，包括子文件夹下的文件 
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="suffix"> 规范使用小写后缀(文件后缀统一变为小写判断)，如：.prefab </param>
        /// <returns></returns>
        public static List<string> GetAllFiles(string dirPath, string suffix)
        {
            if (Directory.Exists(dirPath) == false)
            {
                //Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            return GetAllFiles(dirPath, new List<string>() { suffix });
        }

        /// <summary>
        /// 获取dirPath文件夹下，指定suffix后缀的所有文件集合，包括子文件夹下的文件
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="suffixs"> 规范使用小写后缀(文件后缀统一变为小写判断)，如：[.prefab, .png ...] </param>
        /// <returns></returns>
        public static List<string> GetAllFiles(string dirPath, List<string> suffixs)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath, "*", SearchOption.AllDirectories);
            var res = new List<string>();
            foreach (var file in files)
            {
                var formatFile = PathHelper.PathFormat(file);
                var lowExt = Path.GetExtension(formatFile).ToLower();
                foreach (var suffix in suffixs)
                {
                    if (lowExt == suffix)
                    {
                        res.Add(formatFile);
                    }
                }
            }
            return res;
        }

        public static List<string> GetAllFiles(string dirPath, string[] suffixs)
        {
            return GetAllFiles(dirPath, suffixs.ToList());
        }

        /// <summary>
        /// 获取忽略ignoreSuffix后缀的所有文件
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="ignoreSuffix"> 规范使用小写后缀(文件后缀统一变为小写判断)，如".prefab" </param>
        /// <returns></returns>
        public static List<string> GetAllFilesIgnoreExt(string dirPath, string ignoreSuffix)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath, "*", SearchOption.AllDirectories);
            var res = new List<string>();
            foreach (var file in files)
            {
                var formatFile = PathHelper.PathFormat(file);
                var suffix = Path.GetExtension(formatFile).ToLower();
                if (ignoreSuffix != suffix)
                {
                    res.Add(formatFile);
                }
            }
            return res;
        }

        /// <summary>
        /// 获取忽略ignoreSuffixs后缀的所有文件
        /// </summary>
        /// <param name="dirPath"></param>
        /// <param name="ignoreSuffixs"> 规范使用小写后缀(文件后缀统一变为小写判断) </param>
        /// <returns></returns>
        public static List<string> GetAllFilesIgnoreExts(string dirPath, string[] ignoreSuffixs)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var files = Directory.GetFiles(dirPath, "*", SearchOption.AllDirectories);
            var res = new List<string>();
            foreach (var file in files)
            {
                var formatFile = PathHelper.PathFormat(file);
                var suffix = Path.GetExtension(formatFile).ToLower();
                if (ignoreSuffixs.Contains(suffix) == false)
                {
                    res.Add(formatFile);
                }
            }
            return res;
        }

        /// <summary>
        /// 获取dirPath文件夹下的文件夹集合，不包括子文件夹
        /// </summary>
        /// <param name="dirPath"></param>
        /// <returns></returns>
        public static List<string> GetDirectorys(string dirPath)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var dirs = Directory.GetDirectories(dirPath);
            var list = new List<string>();
            foreach (var dir in dirs)
            {
                list.Add(PathHelper.PathFormat(dir));
            }
            return list;
        }

        /// <summary>
        /// 获取dir文件夹下，指定搜集层级的所有文件夹集合。只会包含第layers层的文件夹
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="layer"> 指定搜集层级，至少得传1层 </param>
        /// <returns></returns>
        public static List<string> GetDirectorysFromLayer(string dir, int layer)
        {
            Debug.Assert(layer > 0, $"传入layer必须大于0");

            var subDirs = GetDirectorys(dir);
            for (int i = 0; i < layer - 1; i++)
            {
                subDirs = GetDirectorsFromDirs(subDirs);
            }
            return subDirs;
        }

        /// <summary>
        /// 获取文件夹集合下的所有文件夹集合
        /// </summary>
        /// <param name="dirs"></param>
        /// <returns></returns>
        public static List<string> GetDirectorsFromDirs(List<string> dirs)
        {
            var newDirs = new List<string>();
            foreach (var dir in dirs)
            {
                var subDirs = GetDirectorys(dir);
                newDirs.AddRange(subDirs);
            }
            return newDirs;
        }

        /// <summary>
        /// 获取dirPath文件夹下的文件夹集合，包括子文件夹
        /// </summary>
        /// <param name="dirPath"></param>
        /// <returns></returns>
        public static List<string> GetAllDirectorys(string dirPath)
        {
            if (Directory.Exists(dirPath) == false)
            {
                Debug.LogWarning($"警告：传入的文件夹路径不存在{dirPath}");
                return new List<string>();
            }

            var dirs = Directory.GetDirectories(dirPath, "*", SearchOption.AllDirectories);
            var list = new List<string>();
            foreach (var dir in dirs)
            {
                list.Add(PathHelper.PathFormat(dir));
            }
            return list;
        }

        /// <summary>
        /// 安全创建文件夹
        /// </summary>
        /// <param name="dirPath"></param>
        public static void CreateDirectory(string dirPath)
        {
            if (Directory.Exists(dirPath))
            {
                return;
            }

            Directory.CreateDirectory(dirPath);
        }

        /// <summary>
        /// 删除文件夹，连同meta一起删了
        /// </summary>
        /// <param name="dirPath"></param>
        public static void DeleteDirectory(string dirPath)
        {
            if (Directory.Exists(dirPath) == false)
            {
                return;
            }

            Directory.Delete(dirPath, true);

            // meta文件一起删了
            var metaPath = dirPath + ".meta";
            if (File.Exists(metaPath))
            {
                File.Delete(metaPath);
            }
        }

        /// <summary>
        /// 是否是空文件夹
        /// </summary>
        /// <param name="dirPath"></param>
        /// <returns></returns>
        public static bool IsEmptyDirectory(string dirPath)
        {
            if (!Directory.Exists(dirPath))
            {
                return true;
            }

            return Directory.GetFileSystemEntries(dirPath).Length == 0;
        }

        /// <summary>
        /// 拷贝文件夹
        /// </summary>
        /// <param name="srcDir"> 当前路径 </param>
        /// <param name="tgtDir"> 目标路径 </param>
        /// <param name="isOverWrite"> 是否覆盖目标文件夹（删除原本目标文件夹自带的） </param>
        public static void Copy(string srcDir, string tgtDir, bool isOverWrite)
        {
            if (Directory.Exists(srcDir) == false)
            {
                Debug.LogError($"错误提示：拷贝文件夹不存在{srcDir}，请检查代码");
                return;
            }

            DirectoryInfo source = new DirectoryInfo(srcDir);
            DirectoryInfo target = new DirectoryInfo(tgtDir);
            if (target.FullName.StartsWith(source.FullName, StringComparison.CurrentCultureIgnoreCase))
            {
                Debug.LogError($"错误提示：父目录{srcDir}不能拷贝到子目录{tgtDir}！");
                return;
            }

            if (isOverWrite)
            {
                DirectoryHelper.DeleteDirectory(target.FullName);
                DirectoryHelper.CreateDirectory(target.FullName);
            }
            else
            {
                DirectoryHelper.CreateDirectory(target.FullName);
            }

            FileInfo[] files = source.GetFiles();
            for (int i = 0; i < files.Length; i++)
            {
                File.Copy(files[i].FullName, Path.Combine(target.FullName, files[i].Name), true);
            }

            DirectoryInfo[] dirs = source.GetDirectories();
            for (int j = 0; j < dirs.Length; j++)
            {
                Copy(dirs[j].FullName, Path.Combine(target.FullName, dirs[j].Name), isOverWrite);
            }
        }


        /// <summary>
        /// 收集指定文件夹文件信息
        /// </summary>
        /// <param name="dir"> 文件夹路径 </param>
        /// <param name="suffix"> 指定文件后缀 </param>
        /// <returns></returns>
        public static List<FileData> GetFileDatas(string dir, string suffix = "")
        {
            if (Directory.Exists(dir) == false)
            {
                Debug.LogWarning($"{dir} 文件夹不存在");
                return new List<FileData>();
            }

            var infos = new List<FileData>();

            var paths = string.IsNullOrEmpty(suffix) ?
                DirectoryHelper.GetAllFiles(dir) :
                DirectoryHelper.GetAllFiles(dir, suffix);
            foreach (var path in paths)
            {
                var info = new FileData()
                {
                    path = path,
                    size = FileHelper.GetFileSize(path)
                };
                infos.Add(info);
            }

            return infos;
        }
    }

}

