using System;
using System.Collections.Generic;
using UnityEditor;

using UnityEngine;
using EditerUtils;
using UnityEditor.Experimental.SceneManagement;

public static class AssetsCheckUILogic
{
    private static HashSet<string> _tipsUniqueKeys = new HashSet<string>();

    /// <summary>
    /// 显示弹出菜单选择栏
    /// </summary>
    /// <param name="txtArr"> 菜单数组 </param>
    /// <param name="cb"> 点击菜单回调，索引从0开始 </param>
    public static void ShowPopMenu(List<string> txtArr, Action<int> cb)
    {
        GenericMenu.MenuFunction2 f = (o) =>
        {
            cb((int)o);
        };
        var menu = new GenericMenu();
        for (int i = 0; i < txtArr.Count; i++)
        {
            menu.AddItem(new GUIContent(txtArr[i]), false, f, i);
        }
        menu.ShowAsContext();
    }

    /// <summary>
    /// ASTC三种格式选择
    /// </summary>
    /// <param name="txtArr"></param>
    /// <param name="cb"></param>
    public static void ShowASTCPopMenu(Action<TextureImporterFormat> cb)
    {
        var pops = new List<string>()
        {
            "ASTC_4x4",
            "ASTC_5x5",
            "ASTC_6x6",
            "ASTC_8x8"
        };
        AssetsCheckUILogic.ShowPopMenu(pops, (index) =>
        {
            var format = _GetTexutreFormtFromIndex(index);
            cb?.Invoke(format);
        });
    }

    private static TextureImporterFormat _GetTexutreFormtFromIndex(int index)
    {
        if (index == 0)
            return TextureImporterFormat.ASTC_4x4;
        else if (index == 1)
            return TextureImporterFormat.ASTC_5x5;
        else if (index == 2)
            return TextureImporterFormat.ASTC_6x6;
        return TextureImporterFormat.ASTC_8x8;
    }

    /// <summary>
    /// 显示规则描述
    /// </summary>
    /// <param name="des"></param>
    public static void ShowRuleDes(string des)
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginVertical();
        EditorGUILayout.LabelField(des, EditorStyles.wordWrappedLabel);
        EditorGUILayout.EndVertical();
    }

    /// <summary>
    /// 显示文件路径、描述、操作栏
    /// </summary>
    public static void ShowContentTitle()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("文件");
        EditorGUILayout.LabelField("问题描述");
        EditorGUILayout.LabelField("操作", GUILayout.Width(100));
        EditorGUILayout.EndHorizontal();
    }

    /// <summary>
    /// 显示底部文件信息内容
    /// </summary>
    /// <param name="fileCount"> 文件数量 </param>
    /// <param name="fileSize"> 文件大小 </param>
    public static void ShowBottomInfo(int fileCount, long fileSize)
    {
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        EditorGUILayout.LabelField($"文件数量：{fileCount} | 总大小：{fileSize / 1048576f:n2}MB");
        EditorGUILayout.EndHorizontal();
    }

    public static void ShowBottomInfo(int fileCount)
    {
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        EditorGUILayout.LabelField($"文件数量：{fileCount}");
        EditorGUILayout.EndHorizontal();
    }

    /// <summary>
    /// 显示检视按钮
    /// </summary>
    /// <param name="assetPath"></param>
    public static void ShowGoToBt(string assetPath)
    {
        GUI.color = Color.white;
        if (GUILayout.Button("检视", GUILayout.Width(80)))
        {
            var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath);
            Selection.activeObject = obj;
        }
    }

    /// <summary>
    /// 查找指定的组件，多次点击会跳转到下一个
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="assetPath"></param>
    public static void GoToAndSelectTips(string assetPath, HashSet<string> tipsUniqueKeys)
    {
        var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath);
        if (assetPath.EndsWith(".prefab") == false)
        {
            Selection.activeObject = obj;
            return;
        }

        _tipsUniqueKeys = tipsUniqueKeys;

        // 如果是预设，打开预设资源
        AssetDatabase.OpenAsset(obj);

        // 展开所有节点
        HierarchyWindowHelper.ExpandAllObject();

        // 显示[!]代理
        EditorApplication.hierarchyWindowItemOnGUI = _OnHierarchyGUI;

        // 选中第一个指定组件
        _SelectFirstObject();
    }

    /// <summary>
    /// 取消[!]的提示
    /// </summary>
    public static void CancelTips()
    {
        EditorApplication.hierarchyWindowItemOnGUI = null;
        _tipsUniqueKeys.Clear();
    }

    /// <summary>
    /// 根据obj返回一个表示obj的唯一key值，主要用于在Hierarchy面板在问题obj右边显示[!]
    /// </summary>
    /// <param name="obj"></param>
    /// <returns></returns>
    public static string GetTipsUniqueKey(GameObject obj)
    {
        // 用父节点和子几点名称组合当唯一key，防止只用自己名字容易重名
        if (obj.transform.parent == null)
        {
            return $"null/{obj.name}";
        }
        return $"{obj.transform.parent.name}/{obj.name}";
    }

    /// <summary>
    /// 看上面
    /// </summary>
    /// <param name="objs"></param>
    /// <returns></returns>
    public static HashSet<string> GetTipsUniqueKey(List<GameObject> objs)
    {
        var set = new HashSet<string>();
        foreach (var obj in objs)
        {
            var key = GetTipsUniqueKey(obj);
            if (set.Contains(key) == false)
            {
                set.Add(key);
            }
        }
        return set;
    }

    public static HashSet<string> GetTipsUniqueKey(List<Transform> trans)
    {
        var set = new HashSet<string>();
        foreach (var tran in trans)
        {
            var key = GetTipsUniqueKey(tran.gameObject);
            if (set.Contains(key) == false)
            {
                set.Add(key);
            }
        }
        return set;
    }

    public static HashSet<string> GetTipsUniqueKey(List<Component> components)
    {
        var objs = components.ToGameObjects();
        return GetTipsUniqueKey(objs);
    }

    public static HashSet<string> GetTipsUniqueKey(Component[] component1, Component[] component2)
    {
        var list = new List<Component>(component1);
        list.AddRange(component2);
        return GetTipsUniqueKey(list);
    }

    public static HashSet<string> GetTipsUniqueKey(List<Transform> trans1, List<Transform> trans2)
    {
        var list = new List<Transform>(trans1.ToArray());
        list.AddRange(trans2);
        return GetTipsUniqueKey(list);
    }

    /// <summary>
    /// 取消[!]
    /// </summary>
    public static void ShowCancelTipsBt()
    {
        if (EditorApplication.hierarchyWindowItemOnGUI != null)
        {
            GUI.color = Color.yellow;
            if (GUILayout.Button("取消[!]", GUILayout.Width(100)))
            {
                CancelTips();
            }
            GUI.color = Color.white;
        }
    }

    /// <summary>
    /// 只显示取消[!]按钮
    /// </summary>
    public static void ShowCancelTips()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        AssetsCheckUILogic.ShowCancelTipsBt();

        EditorGUILayout.EndHorizontal();
        GUI.color = Color.white;
    }

    private static void _SelectFirstObject()
    {
        if (_tipsUniqueKeys.Count == 0)
        {
            return;
        }

        // 点击选择的子节点名称
        var stage = PrefabStageUtility.GetCurrentPrefabStage();
        if (stage == null)
        {
            return;
        }

        var key = _GetRandKey();
        var root = stage.prefabContentsRoot;
        var child = root.GetComponentsInChildren<Transform>(true);
        foreach (var c in child)
        {
            var obj = c.gameObject;
            var k = GetTipsUniqueKey(obj);
            if (k == key)
            {
                UnityEditor.EditorGUIUtility.PingObject(obj);
                Selection.activeGameObject = obj;
                return;
            }
        }
    }

    private static string _GetRandKey()
    {
        foreach (var v in _tipsUniqueKeys)
        {
            return v;
        }
        return "";
    }

    private static void _OnHierarchyGUI(int instanceID, Rect selectionRect)
    {
        var obj = EditorUtility.InstanceIDToObject(instanceID) as GameObject;
        if (obj == null)
        {
            return;
        }

        var key = GetTipsUniqueKey(obj);
        if (_tipsUniqueKeys.Contains(key))
        {
            Rect r = selectionRect;
            r.x += r.width;

            GUI.color = Color.yellow;
            GUI.Label(r, "[!]");
            GUI.color = Color.white;
        }
    }
}
