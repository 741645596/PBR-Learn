using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

public class ReferenceFinderData
{
    //缓存路径
    private const string CACHE_PATH = "Library/ReferenceFinderCache";

    private const string CACHE_VERSION = "V1";

    public bool EnableNotInAssets = false;

    //资源引用信息字典
    public Dictionary<string, AssetDescription> m_assetDict = new Dictionary<string, AssetDescription>();

    //收集资源引用信息并更新缓存
    public void CollectDependenciesInfo()
    {
        AssetDatabase.Refresh();
        try
        {
            m_assetDict.Clear();
            ReadFromCache();

            var allAssets = AssetDatabase.GetAllAssetPaths();
            int totalCount = allAssets.Length;
            for (int i = 0; i < allAssets.Length; i++)
            {
                //每遍历100个Asset，更新一下进度条，同时对进度条的取消操作进行处理
                if ((i % 100 == 0) && EditorUtility.DisplayCancelableProgressBar("Refresh",
                    string.Format("Collecting {0} assets", i), (float)i / totalCount))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }

                var assetPath = allAssets[i];
                if (File.Exists(assetPath))
                    ImportAsset(assetPath);
                if (i % 2000 == 0)
                    GC.Collect();
            }

            //将信息写入缓存
            EditorUtility.DisplayCancelableProgressBar("Refresh", "Write to cache", 1f);
            WriteToChache();
            //生成引用数据
            EditorUtility.DisplayCancelableProgressBar("Refresh", "Generating asset reference info", 1f);
            UpdateReferenceInfo();
            EditorUtility.ClearProgressBar();
        }
        catch (Exception e)
        {
            Debug.LogError(e);
            EditorUtility.ClearProgressBar();
        }
    }

    //通过依赖信息更新引用信息
    private void UpdateReferenceInfo()
    {
        foreach (var asset in m_assetDict)
        {
            foreach (var assetGuid in asset.Value.dependencies)
            {
                if (assetGuid == "d0353a89b1f911e48b9e16bdc9f2e058") //AssetVersion.cs
                    continue;

                if (!m_assetDict.ContainsKey(assetGuid))
                {
                    Debug.Log("missing " + assetGuid);
                    continue;
                }

                AssetDescription assetDescription = m_assetDict[assetGuid];

                List<string> refList = assetDescription.references;
                if (!refList.Contains(asset.Key))
                    refList.Add(asset.Key);
            }
        }
    }

    void insertToHashMap(Dictionary<string, List<string>> map, string texAssetPath, string texGUID)
    {
        var exts = ".png;.jpg;.tga".Split(';');

        var ext = RefUtil.getExt(texAssetPath);
        if (!exts.Contains(ext))
            return;

        string texHash = null;
        var tex = RefUtil.getTexture(texAssetPath);
        if (tex != null)
        {
            texHash = tex.imageContentsHash.ToString();
        }

        if (texHash == null)
        {
            Debug.Log("TexFailed " + texAssetPath);
        }

        List<string> guidListWithSameHash;
        if (!map.ContainsKey(texHash))
            guidListWithSameHash = map[texHash] = new List<string>();
        else
        {
            guidListWithSameHash = map[texHash];
        }

        if (!guidListWithSameHash.Contains(texGUID))
            guidListWithSameHash.Add(texGUID);
    }

    public Dictionary<string, List<string>> getDupTextures()
    {
        List<string> matDepRes = new List<string>();
        var matLst = getFileByExt(".mat");
        for (int i = 0; i < matLst.Count; i++)
        {
            var guid = matLst[i];

            var dependencies = m_assetDict[guid].dependencies;
            matDepRes.AddRange(dependencies);
        }

        Dictionary<string, List<string>> map = new Dictionary<string, List<string>>();

        for (int i = 0; i < matDepRes.Count; i++)
        {
            var texGUID = matDepRes[i];
            var texAssetPath = AssetDatabase.GUIDToAssetPath(texGUID);
            insertToHashMap(map, texAssetPath, texGUID);
        }

        string[] allAssetPaths = AssetDatabase.GetAllAssetPaths();

        for (int i1 = 0; i1 < allAssetPaths.Length; i1++)
        {
            var texAssetPath = allAssetPaths[i1];
            if (texAssetPath.IndexOf("Assets") == -1)
                continue;

            if (texAssetPath.IndexOf('.') == -1)
                continue;

            var texGUID = AssetDatabase.AssetPathToGUID(texAssetPath);

            var mAssetDict = ReferenceFinderWindow.m_data.m_assetDict;
            if (mAssetDict.ContainsKey(texGUID) && mAssetDict[texGUID].references.Count > 0)
                this.insertToHashMap(map, texAssetPath, texGUID);
        }

        return map;
    }

    private void nop()
    {
    }

    public List<string> getNoRefTextures()
    {
        var rslt = getFileByExt(".png;.jpg;.tga;.cubemap");

        rslt = sortByName(rslt);

        return rslt;
    }

    public SortedDictionary<string, List<string>> getCommonRef1()
    {
        var exts = ".png;.jpg;.tga;.cubemap";
        var extlist = exts.Split(';');
        List<string> rslt = new List<string>();


        SortedDictionary<string, List<string>> result = new SortedDictionary<string, List<string>>();

        foreach (var asset in m_assetDict)
        {
            var texAssetKey = asset.Key;
            AssetDescription assetDes = asset.Value;
            if (assetDes.references.Count != 1)
                continue;

            var texAssetPath = assetDes.path; //AssetDatabase.GUIDToAssetPath(assetKey);
            if (texAssetPath.ToLower().IndexOf("common") == -1) //common
                continue;

            var lastIndexOf = texAssetPath.LastIndexOf(".");
            if (lastIndexOf == -1)
                continue;

            var ext = texAssetPath.Substring(lastIndexOf).ToLower();
            if (!extlist.Contains(ext))
                continue;

            string matAssetKey = assetDes.references[0];
            var matAssetPath = AssetDatabase.GUIDToAssetPath(matAssetKey);
            if (!matAssetPath.EndsWith(".mat"))
                continue;

            List<string> flatRefs = new List<string>();
            Stack<AssetDescription> tmpList = new Stack<AssetDescription>();
            AssetDescription matDesc = this.m_assetDict[matAssetKey];

            foreach (string dep_guids in matDesc.references)
            {
                tmpList.Push(this.m_assetDict[dep_guids]);
            }

            while (tmpList.Count != 0)
            {
                AssetDescription assetDescription = tmpList.Pop();
                string assetDescriptionPath = assetDescription.path;
                if (assetDescriptionPath.EndsWith(".unity"))
                    continue;

                flatRefs.Add(assetDescriptionPath);

                foreach (string dep_guids in assetDescription.references)
                {
                    tmpList.Push(this.m_assetDict[dep_guids]);
                }
            }

            var regex = new Regex(@"([^/]+/[^/]+/[^/]+/[^/]+/).*");
            List<string> folders = new List<string>();
            HashSet<string> hashSet = new HashSet<string>();

            foreach (string flatRef in flatRefs)
            {
                var match = regex.Match(flatRef);
                if (match.Success)
                {
                    var matchGroup = match.Groups[1];
                    var matchGroupValue = matchGroup.Value;
                    hashSet.Add(matchGroupValue);
                    //var exists = folders.Exists(matchGroupValue);
                }
                else
                {
                    Debug.Log(flatRef + "====================");
                }
            }

            if (hashSet.Count == 1)
            {
                rslt.Add(texAssetKey);
                //Debug.Log("===================="+ assetPath);
                string[] lst = { texAssetKey, matAssetKey };
                string key_floder = hashSet.ToList()[0];
                result[key_floder] = lst.ToList();
            }
            else
            {
                Debug.Log("hashSet.Count !=1 " + texAssetPath);
            }
        }

        rslt = sortByName(rslt);

        return result;
    }

    public static List<string> sortByName(List<string> rslt)
    {
        rslt = rslt.OrderBy(
            x => {
                var assetPath = AssetDatabase.GUIDToAssetPath(x);
                return assetPath;
            }).ToList();

        rslt = rslt.OrderBy(
            x => {
                var assetPath = AssetDatabase.GUIDToAssetPath(x);
                var lastIndexOf = assetPath.LastIndexOf(".");
                if (lastIndexOf != -1)
                    return assetPath.Substring(lastIndexOf);
                else
                    return assetPath;
            }).ToList();
        return rslt;
    }

    private List<string> getFileByExt(string exts)
    {
        var extlist = exts.Split(';');
        List<string> rslt = new List<string>();
        foreach (var asset in m_assetDict)
        {
            var assetKey = asset.Key;
            var assetDes = asset.Value;
            if (assetDes.references.Count > 0)
                continue;

            var assetPath = AssetDatabase.GUIDToAssetPath(assetKey);
            var lastIndexOf = assetPath.LastIndexOf(".");
            if (lastIndexOf == -1)
                continue;
            var ext = assetPath.Substring(lastIndexOf).ToLower();
            if (extlist.Contains(ext))
            {
                rslt.Add(assetKey);
            }
        }

        return rslt;
    }

    //生成并加入引用信息
    private void ImportAsset(string path)
    {
        if (!EnableNotInAssets)
        {
            if (!path.StartsWith("Assets/"))
                return;
        }


        //通过path获取guid进行储存
        string guid = AssetDatabase.AssetPathToGUID(path);
        //获取该资源的最后修改时间，用于之后的修改判断
        Hash128 assetDependencyHash = AssetDatabase.GetAssetDependencyHash(path);
        //如果assetDict没包含该guid或包含了修改时间不一样则需要更新
        if (!m_assetDict.ContainsKey(guid) || m_assetDict[guid].assetDependencyHash != assetDependencyHash.ToString())
        {
            //将每个资源的直接依赖资源转化为guid进行储存
            var guids = AssetDatabase.GetDependencies(path).Select(p => AssetDatabase.AssetPathToGUID(p))
                .ToList();

            //生成asset依赖信息，被引用需要在所有的asset依赖信息生成完后才能生成
            AssetDescription ad = new AssetDescription();
            ad.name = Path.GetFileNameWithoutExtension(path);
            ad.path = path;
            ad.assetDependencyHash = assetDependencyHash.ToString();
            ad.dependencies = guids;

            if (m_assetDict.ContainsKey(guid))
                m_assetDict[guid] = ad;
            else
                m_assetDict.Add(guid, ad);
        }
    }

    //读取缓存信息
    public bool ReadFromCache()
    {
        m_assetDict.Clear();
        if (!File.Exists(CACHE_PATH))
        {
            return false;
        }

        var serializedGuid = new List<string>();
        var serializedDependencyHash = new List<string>();
        var serializedDenpendencies = new List<int[]>();
        //反序列化数据
        FileStream fs = File.OpenRead(CACHE_PATH);
        try
        {
            BinaryFormatter bf = new BinaryFormatter();
            string cacheVersion = (string)bf.Deserialize(fs);
            if (cacheVersion != CACHE_VERSION)
            {
                return false;
            }

            EditorUtility.DisplayCancelableProgressBar("Import Cache", "Reading Cache", 0);
            serializedGuid = (List<string>)bf.Deserialize(fs);
            serializedDependencyHash = (List<string>)bf.Deserialize(fs);
            serializedDenpendencies = (List<int[]>)bf.Deserialize(fs);
            EditorUtility.ClearProgressBar();
        }
        catch
        {
            //兼容旧版本序列化格式
            return false;
        }
        finally
        {
            fs.Close();
        }

        for (int i = 0; i < serializedGuid.Count; ++i)
        {
            string path = AssetDatabase.GUIDToAssetPath(serializedGuid[i]);
            if (!string.IsNullOrEmpty(path))
            {
                var ad = new AssetDescription();
                ad.name = Path.GetFileNameWithoutExtension(path);
                ad.path = path;
                ad.assetDependencyHash = serializedDependencyHash[i];
                m_assetDict.Add(serializedGuid[i], ad);
            }
        }

        for (int i = 0; i < serializedGuid.Count; ++i)
        {
            string guid = serializedGuid[i];
            if (m_assetDict.ContainsKey(guid))
            {
                var guids = serializedDenpendencies[i].Select(index => serializedGuid[index])
                    .Where(g => m_assetDict.ContainsKey(g)).ToList();

                var enumerable = guids.Where(guid1 => {
                    var guidToAssetPath = AssetDatabase.GUIDToAssetPath(guid1);
                    return guidToAssetPath.Length != 0;
                });
                guids = enumerable.ToList();

                m_assetDict[guid].dependencies = guids;
            }
        }

        UpdateReferenceInfo();
        return true;
    }

    //写入缓存
    private void WriteToChache()
    {
        if (File.Exists(CACHE_PATH))
            File.Delete(CACHE_PATH);

        var serializedGuid = new List<string>();
        var serializedDependencyHash = new List<string>();
        var serializedDenpendencies = new List<int[]>();
        //辅助映射字典
        var guidIndex = new Dictionary<string, int>();
        //序列化
        using (FileStream fs = File.OpenWrite(CACHE_PATH))
        {
            foreach (var pair in m_assetDict)
            {
                guidIndex.Add(pair.Key, guidIndex.Count);
                serializedGuid.Add(pair.Key);
                serializedDependencyHash.Add(pair.Value.assetDependencyHash);
            }

            foreach (var guid in serializedGuid)
            {
                //使用 Where 子句过滤目录
                int[] indexes = m_assetDict[guid].dependencies.Where(s => guidIndex.ContainsKey(s))
                    .Select(s => guidIndex[s]).ToArray();
                serializedDenpendencies.Add(indexes);
            }

            BinaryFormatter bf = new BinaryFormatter();
            bf.Serialize(fs, CACHE_VERSION);
            bf.Serialize(fs, serializedGuid);
            bf.Serialize(fs, serializedDependencyHash);
            bf.Serialize(fs, serializedDenpendencies);
        }
    }

    //更新引用信息状态
    public void UpdateAssetState(string guid)
    {
        AssetDescription ad;
        if (m_assetDict.TryGetValue(guid, out ad) && ad.state != AssetState.NODATA)
        {
            if (File.Exists(ad.path))
            {
                //修改时间与记录的不同为修改过的资源
                if (ad.assetDependencyHash != AssetDatabase.GetAssetDependencyHash(ad.path).ToString())
                {
                    ad.state = AssetState.CHANGED;
                }
                else
                {
                    //默认为普通资源
                    ad.state = AssetState.NORMAL;
                }
            }
            //不存在为丢失
            else
            {
                ad.state = AssetState.MISSING;
            }
        }

        //字典中没有该数据
        else if (!m_assetDict.TryGetValue(guid, out ad))
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            ad = new AssetDescription();
            ad.name = Path.GetFileNameWithoutExtension(path);
            ad.path = path;
            ad.state = AssetState.NODATA;
            m_assetDict.Add(guid, ad);
        }
    }

    //根据引用信息状态获取状态描述
    public static string GetInfoByState(AssetState state)
    {
        if (state == AssetState.CHANGED)
        {
            return "<color=#F0672AFF>Changed</color>";
        }
        else if (state == AssetState.MISSING)
        {
            return "<color=#FF0000FF>Missing</color>";
        }
        else if (state == AssetState.NODATA)
        {
            return "<color=#FFE300FF>No Data</color>";
        }

        return "Normal";
    }

    public class AssetDescription
    {
        public string name = "";
        public string path = "";
        public string assetDependencyHash;
        public List<string> _dependencies = new List<string>();
        public List<string> references = new List<string>();
        public AssetState state = AssetState.NORMAL;
        public string desc = "";
        public List<string> uniqueKey = new List<string>();

        public List<string> dependencies
        {
            get { return _dependencies; }
            set { _dependencies = value; }
        }
    }

    public enum AssetState
    {
        NORMAL,
        CHANGED,
        MISSING,
        NODATA,
    }

    public void genRefInfo(string ext, string savePath)
    {
        List<string> rslt = new List<string>();
        rslt.Add("prefab,font");
        var mAssetDict = ReferenceFinderWindow.m_data.m_assetDict;
        foreach (var it in mAssetDict)
        {
            var asset_path = it.Value.path;

            if (!asset_path.EndsWith(ext))
                continue;
            for (int i = 0; i < it.Value.references.Count(); i++)
            {
                var prefab_guid = it.Value.references[i];
                string prefab_path = mAssetDict[prefab_guid].path;
                if (prefab_path.EndsWith(".prefab"))
                {
                    var info = prefab_path + "," + asset_path;
                    rslt.Add(info);
                }
            }
        }

        var str_rslt = String.Join("\n", rslt);

        File.WriteAllText(savePath, str_rslt);
        Debug.Log("File exported " + savePath);
    }
}