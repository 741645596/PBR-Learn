using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEditor;

public class DependInfo
{
    static Dictionary<string, List<string>> cannot_contain_modules = new Dictionary<string, List<string>>()
    {
        {"AppRes", new List<string> { "RoomRes1", "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"BattleRes", new List<string> { "RoomRes1", "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"CommonRes", new List<string> { "RoomRes1", "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"LanguageRes", new List<string> { "RoomRes1", "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"Shaders", new List<string> { "RoomRes1", "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },

        {"RoomRes1", new List<string> { "RoomRes1XZ", "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"RoomRes1XZ", new List<string> { "RoomRes2", "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"RoomRes2", new List<string> { "RoomRes3", "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"RoomRes3", new List<string> { "RoomRes4", "SGRoomRes1", "SGRoomRes2" } },
        {"RoomRes4", new List<string> { "SGRoomRes1", "SGRoomRes2" } },
   
        {"SGRoomRes1", new List<string> { "SGRoomRes2" } },
        {"SGRoomRes2", new List<string> {  } },


    };

    public Dictionary<string, List<string>> GetCannotContainModules()
    {
        return cannot_contain_modules;
    }


    public static string CalcModuleName(string path)
    {
        string subPath = path.Replace("Assets/GameData/", "");
        int idx = subPath.IndexOf("/");
        string moduleName = subPath.Substring(0, idx);
        return moduleName;
    }

    public static string CalcSubModuleName(string path)
    {
        string subPath = path.Replace("Assets/GameData/RoomRes1XZ/", "");
        int idx = subPath.IndexOf("/");
        string moduleName = subPath.Substring(0, idx);
        return moduleName;
    }

    [MenuItem("资源检查/分包/资源引用检查")]
    static void DoIt()
    {
        var data = new ReferenceFinderData();
        GetInvalidDependInfo(data);
        data = null;
    }

    public static List<string> GetInvalidDependInfo(ReferenceFinderData data)
    {
        List<string> list = new List<string>();

        data.CollectDependenciesInfo();

        foreach (var key in data.m_assetDict)
        {
            string path = key.Value.path;
            int idx = path.IndexOf("Assets/GameData/");
            if (idx < 0)
            {
                continue;
            }
            //if (path.IndexOf("FX_Material_319_dilie_001") < 0)
            //{
            //    continue;
            //}
            string moduleName = CalcModuleName(path);
            if (string.IsNullOrEmpty(moduleName))
            {
                continue;
            }

            var depends = key.Value.dependencies;
            if (depends.Count <= 0)
            {
                continue;
            }
            //Debug.Log(path);
            if (!cannot_contain_modules.ContainsKey(moduleName))
            {
                continue;
            }
            var cannotContainsModules = cannot_contain_modules[moduleName];
            for (int i = depends.Count - 1; i >= 0; i--)
            {
                if (data.m_assetDict.ContainsKey(depends[i]))
                {
                    var depItemInfo = data.m_assetDict[depends[i]];
                    if (depItemInfo.path == path)
                    {
                        continue;
                    }
                    string dependModuleName = CalcModuleName(depItemInfo.path);
                    if (string.IsNullOrEmpty(dependModuleName))
                    {
                        continue;
                    }
                    //Debug.Log($"{depItemInfo.path} {dependModuleName} {string.Join(";", cannotContainsModules)}");
                    if (cannotContainsModules.IndexOf(dependModuleName) > -1)
                    {
                        if (list.IndexOf(key.Key) < 0)
                        {
                            list.Add(key.Key);
                        }
                    }
                    // 都是动态加载的资源，不可以互相引用
                    else if (moduleName == "RoomRes1XZ" && dependModuleName == "RoomRes1XZ")
                    {
                        string sub1 = CalcSubModuleName(path);
                        string sub2 = CalcSubModuleName(depItemInfo.path);
                        if (sub1 != sub2)
                        {
                            if (list.IndexOf(key.Key) < 0)
                            {
                                list.Add(key.Key);
                            }
                        }
                        else
                        {
                            depends.RemoveAt(i);
                        }
                    }
                    else
                    {
                        depends.RemoveAt(i);
                    }
                }
            }
        }

        if (list.Count == 0)
        {
            Debug.Log("恭喜你，未发现错误的依赖关系！");
        }
        return list;
    }

    // 鱼引用到除了自身和公用资源的情况
    public static List<string> GetInvalidFishDependInfo(ReferenceFinderData data)
    {

        Dictionary<string, int> canReferencePath = new Dictionary<string, int>()
        {
            {"Assets/GameData/CommonRes", 1 },
            {"Assets/GameData/Shaders", 1 },
            {"Assets/GameData/AppRes", 1 },
            {"Assets/GameData/BattleRes", 1 },
        };

        List<string> list = new List<string>();

        Dictionary<string, string> alreadyContains = new Dictionary<string, string>();

        data.CollectDependenciesInfo();

        foreach (var key in data.m_assetDict)
        {
            string path = key.Value.path;
            int idx = path.IndexOf("Assets/GameData/");
            if (idx < 0)
            {
                continue;
            }

            if (!path.Contains("RoomRes") && !path.Contains("CommonRes") && !path.Contains("Wing"))
            {
                continue;
            }

            var dependencies = key.Value.dependencies;
            if (dependencies.Count <= 0)
            {
                continue;
            }
            string dir = Path.GetDirectoryName(path);
            dir = dir.Replace("\\", "/");

            string[] array = dir.Split('/');
            if (array.Length >= 4)
            {
                string str = "";
                for (int i = 0; i < 4; i++)
                {
                    str += array[i] + "/";
                }
                dir = str;
                //Debug.Log(dir);
            }

            for (int i = dependencies.Count - 1; i >= 0; i--)
            {
                var depItemInfo = data.m_assetDict[dependencies[i]];
                string refPath = depItemInfo.path.Replace("\\", "/");
                if (!refPath.Contains("Assets/GameData/"))
                {
                    dependencies.RemoveAt(i);
                    continue;
                }
                bool bSuccess = false;
                if (!refPath.Contains(dir))
                {
                    //Debug.Log(refPath + " " + path);
                    foreach (var allowPath in canReferencePath.Keys)
                    {
                        if (refPath.Contains(allowPath))
                        {
                            bSuccess = true;
                            break;
                        }
                    }
                }
                else
                {
                    bSuccess = true;
                }
                if (!bSuccess)
                {
                    if (!alreadyContains.ContainsKey(key.Key))
                    {
                        alreadyContains[key.Key] = "t";
                        list.Add(key.Key);
                    }
                }
                else
                {
                    dependencies.RemoveAt(i);
                }
            }
        }

        if (list.Count == 0)
        {
            Debug.Log("恭喜你，未发现错误的依赖关系！");
        }
        return list;
    }
}
