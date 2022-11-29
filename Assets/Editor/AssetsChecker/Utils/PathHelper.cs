using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 文件路径 帮助类
    /// </summary>
    public static class PathHelper
    {
        // Assets绝对路径
        public static readonly string Assets_Dir_Path = Application.dataPath;

        // Assets在unity工程内的相对路径
        public static readonly string Assets_Unity_Path = "Assets";

        // GameAssets绝对路径
        public static readonly string Game_Assets_Dir_Path = Application.dataPath + "/GameData";

        // GameAssets在unity工程内的相对路径
        public static readonly string Game_Assets_Unity_Path = "Assets/GameData";

        // StreamingAssets绝对路径
        public static readonly string Streaming_Assets_Dir_Path = Application.dataPath + "/StreamingAssets";

        // StreamingAssets在unity工程内的相对路径
        public static readonly string Streaming_Assets_Unity_Path = "Assets/StreamingAssets";

        /// <summary>
        /// 获得第一个分隔符“/”前的路径
        /// </summary>
        /// <param name="path"> 原路径【例：Assets/GameAssets/Common】 </param>
        /// <returns> 【例：Assets】 </returns>
        public static string GetFirstDirName(string path)
        {
            if (path.StartsWith("/"))
            {
                Debug.LogError($"错误提示：path={path}路径不能以‘/’开头");
                return "";
            }

            var index = path.IndexOf('/');
            return path.Substring(0, index);
        }

        /// <summary>
        /// 路径格式化："\\Users\\xxx\\UnityRuntime//Assets" -> "/Users/xxx/UnityRuntime/Assets"
        /// </summary>
        /// <param name="path">  </param>
        /// <returns></returns>
        public static string PathFormat(string path)
        {
            var p1 = path.Replace("\\", "/");
            return p1.Replace("//", "/");
        }

        /// <summary>
        /// 生成AssetBundles的绝对路径
        /// </summary>
        /// <param name="buildTarget"> 目标平台 </param>
        /// <returns> 【例如：/Users/xxx/UnityRuntime/AssetBundles/平台名称】 </returns>
        public static string AssetBundlesPath(BuildTarget buildTarget)
        {
            var root = AssetBundlesRootPath();
            var targetName = buildTarget.ToString().ToLower();
            return Path.Combine(root, targetName);
        }

        /// <summary>
        /// 生成AssetBundles的绝对路径
        /// </summary>
        /// <returns></returns>
        public static string AssetBundlesRootPath()
        {
            var path = Path.GetDirectoryName(Application.dataPath);
            return Path.Combine(path, $"AssetBundles");
        }

        /// <summary>
        /// 获得SteamingAsset下的相对路径
        /// </summary>
        /// <param name="str"> 全路径 【例如：/Users/xxx/UnityRuntime/Assets/StreamingAssets/common/module1】 </param>
        /// <returns> 【例如：common/module1】 </returns>
        public static string InSteamingAssetPath(string str)
        {
            if (str.StartsWith("/") == false)
            {
                Debug.LogWarning($"错误提示：InSteamingAssetPath传入参数需要绝对路径");
                return "";
            }

            str = PathHelper.PathFormat(str);
            return str.Substring(Application.streamingAssetsPath.Length + "/".Length);
        }

        /// <summary>
        /// 将绝对路径转为unity的Assets路径
        /// </summary>
        /// <param name="fullPath"></param>
        /// <returns></returns>
        public static string FullPath2AssetPath(string fullPath)
        {
            if (fullPath.StartsWith("/") == false)
            {
                Debug.LogError($"错误提示：传入文件不是绝对路径, path={fullPath}");
                return "";
            }

            return fullPath.Replace(Application.dataPath, "Assets");
        }

        /// <summary>
        /// 将unity的Assets路径转为绝对路径
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static string AssetPath2FullPath(string assetPath)
        {
            if (assetPath.StartsWith("/"))
            {
                Debug.LogError($"错误提示：传入文件不是相对路径, path={assetPath}");
                return "";
            }

            var prePath = Path.GetDirectoryName(Application.dataPath);
            return Path.Combine(prePath, assetPath);
        }

        /// <summary>
        /// 检查path的文件后缀是不是suffix，path统一转为小写在进行对比，所以suffix请使用小写，如".png"
        /// </summary>
        /// <param name="path"></param>
        /// <param name="suffix"></param>
        /// <returns></returns>
        public static bool IsSuffixExist(string path, string suffix)
        {
            var lowSuffix = Path.GetExtension(path).ToLower();
            return lowSuffix == suffix;
        }

        /// <summary>
        /// path的后缀是否包含与suffixs查找的路径集合
        /// </summary>
        /// <param name="path"></param>
        /// <param name="suffixs"></param>
        /// <returns></returns>
        public static bool IsSuffixExist(string path, string[] suffixs)
        {
            var lowSuffix = Path.GetExtension(path).ToLower();
            foreach (var suffix in suffixs)
            {
                if (suffix == lowSuffix)
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// 替换文件路径的后缀名，如ReplaceSuffix("xx/xx.png", ".jpg") -> "xx/xx.jpg"
        /// </summary>
        /// <param name="filePath"></param>
        /// <param name="newSuffix"></param>
        /// <returns></returns>
        public static string ReplaceSuffix(string filePath, string newSuffix)
        {
            var oldSuffix = Path.GetExtension(filePath);
            if (string.IsNullOrEmpty(oldSuffix))
            {
                Debug.LogError($"错误提示：文件路径{filePath}没有后缀");
                return "";
            }

            return filePath.Replace(oldSuffix, newSuffix);
        }

        /// <summary>
        /// 文件名是否包含空格
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static bool HasEmptyChar(string path)
        {
            var chars = path.ToCharArray();
            foreach (var c in chars)
            {
                if (c == 32)
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// 是否包含中文字符
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static bool HasChineseChar(string path)
        {
            var chars = path.ToCharArray();
            foreach (var c in chars)
            {
                if (c > 255)
                {
                    return true;
                }
            }
            return false;
        }

    }


}

