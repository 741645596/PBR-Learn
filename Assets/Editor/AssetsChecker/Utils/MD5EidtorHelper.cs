using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using UnityEngine;

namespace EditerUtils
{
    public class MD5EidtorHelper
    {
        /// <summary>
        /// 将content转为MD5值
        /// </summary>
        /// <param name="content"></param>
        /// <returns></returns>
        public static string GetMD5(string content)
        {
            var md5 = MD5.Create();
            byte[] hash = md5.ComputeHash(Encoding.UTF8.GetBytes(content));

            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < hash.Length; i++)
            {
                sb.Append(hash[i].ToString("x2"));
            }

            return sb.ToString();
        }

        /// <summary>
        /// 将文件转为MD5值
        /// </summary>
        /// <param name="fileName"> 文件地址 </param>
        /// <returns></returns>
        public static string GetMD5FromFile(string fileName)
        {
            try
            {
                FileStream file = new FileStream(fileName, FileMode.Open);
                MD5 md5 = new MD5CryptoServiceProvider();
                byte[] retVal = md5.ComputeHash(file); //计算指定Stream 对象的哈希值
                file.Close();

                StringBuilder Ac = new StringBuilder();
                for (int i = 0; i < retVal.Length; i++)
                {
                    Ac.Append(retVal[i].ToString("x2"));
                }

                return Ac.ToString();
            }
            catch (Exception ex)
            {
                throw new Exception("GetMD5FromFile() fail,error:" + ex.Message);
            }
        }

        //将文件转为MD5值，
        //这个方法存去MD5Helper.cs
        public static string CalcMD5(byte[] data)
        {
            var md5 = MD5.Create();
            var fileMD5Bytes = md5.ComputeHash(data);
            return System.BitConverter.ToString(fileMD5Bytes).Replace("-", "").ToLower();
        }

        /// <summary>
        /// 将提取AssetbundleManifest里的转为Hash值：
        /// 如果存在文件后缀名为".manifest"的文件，那么就可以确定有对应的AB包存在，
        /// 在名为AssetBundles的AB包可以读取清单信息（AssetBundleManifest），
        /// 通过manifest.GetAssetBundleHash（ab包路径）这个方法就可以找到清单信息中的MD5值
        ///
        /// 另外一种是非AB包文件的MD5值获取，通过CalcMD5（File.ReadAllBytes(ab包完整路径)）方法获取
        /// </summary>
        /// <param name="fullPath"> ab包完整路径 </param>
        /// <param name="path"> ab包路径 </param>
        /// <returns></returns>
        //public static string GetAssetBundleHash(string fullPath, string path)
        //{
        //    string abManifestPath = fullPath + ".manifest";
        //    if (File.Exists(abManifestPath))
        //    {
        //        var parentPath = Path.GetDirectoryName(Application.dataPath);
        //        string assetBundlesPath = Path.Combine(parentPath, "AssetBundles");
        //        string manifestPath = assetBundlesPath + "/AssetBundles"; // 总的清单文件路径
        //        AssetBundleManifest manifest = _ReadAbManifestData(manifestPath);
        //        Hash128 hash = manifest.GetAssetBundleHash(path);
        //        return hash.ToString();
        //    }

        //    byte[] data = File.ReadAllBytes(fullPath);
        //    return CalcMD5(data);
        //}

        /// <summary>
        /// 读取AssetBundles清单文件 ReadAbManifestData(string abManifestPath)
        /// </summary>
        /// <param name="manifestPath"> 官方生成清单文件路径 </param>
        /// <returns></returns>
        //private static AssetBundleManifest _ReadAbManifestData(string manifestPath)
        //{
        //    // editor加载清单文件Json
        //    AssetBundle.UnloadAllAssetBundles(true); // 先卸载，防止多次加载
        //                                             // 加载清单文件对应的Ab包
        //    AssetBundle single = AssetBundle.LoadFromFile(manifestPath);
        //    if (single == null)
        //    {
        //        Debug.LogWarning($"错误提示：加载ab清单失败，请检查清单文件{manifestPath}是否存在");
        //        return null;
        //    }

        //    //加载清单文件
        //    var manifest = single.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
        //    if (manifest == null)
        //    {
        //        Debug.LogWarning($"错误提示：加载AssetBundleManifest失败，请检查清单文件{manifestPath}是否正确");
        //    }

        //    return manifest;
        //}
    }

}

