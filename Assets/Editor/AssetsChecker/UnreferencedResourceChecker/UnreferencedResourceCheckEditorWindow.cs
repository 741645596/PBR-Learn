using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class UnreferencedResourceCheckEditorWindow : AssetCheckEditorWindowBase<UnreferencedResourceInfo>
{
    public const string Title = "未被引用资源";

    private static string _filterSuffix = ".json;.mp3;.ttf;.txt;.asmdef;.spriteatlas";
    private static string _filterContent = "";
    private static int _filterType = 0; // 0隐藏prefab、1显示全部、2只显示prefab
    private static Vector2 _regionSize = Vector2.zero;

    private void _ShowRuleDes()
    {
        const string s_Des = "查找所有未被prefab引用的资源\n" +
               "备注1：有些资源是代码动态创建的，所以需要人工检查，如果没用到请删除\n" +
               "备注2：prefab资源一般都是程序内动态创建的，但是需要关注prefab本身是否有冗余";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowToggleLogic()
    {
        //EditorGUILayout.BeginHorizontal();

        _regionSize = EditorGUILayout.Vector2Field("筛选区间大小，0表示不限制(KB)：", _regionSize, GUILayout.Width(450));

        _filterSuffix = EditorGUILayout.TextField("过滤后缀(请用小写)：", _filterSuffix, GUILayout.Width(450));

        _filterContent = EditorGUILayout.TextField("过滤文件包含内容：", _filterContent, GUILayout.Width(450));

        var des = "";
        if (_filterType == 0) des = "隐藏prefab";
        else if (_filterType == 1) des = "显示全部";
        else des = "只显示prefab";
        if (GUILayout.Button(des, GUILayout.Width(100)))
        {
            _filterType++;
            if (_filterType == 3) _filterType = 0;
            Reload();
        }

        if (GUILayout.Button("查找", GUILayout.Width(100)))
        {
            Reload();
        }
    }

    private bool _IsContentInPath(string[] contents, string filePath)
    {
        foreach (var content in contents)
        {
            if (string.IsNullOrEmpty(content))
            {
                continue;
            }

            if (filePath.Contains(content))
            {
                return true;
            }
        }
        return false;
    }

    private List<UnreferencedResourceInfo> _GetFilterSuffix()
    {
        var res = new List<UnreferencedResourceInfo>();

        var filterSuffs = _filterSuffix.Split(';');
        var suffixs = new List<string>(filterSuffs);
        foreach (var info in _assetsInfos)
        {
            var lowSuff = Path.GetExtension(info.assetPath).ToLower();
            if (suffixs.Contains(lowSuff) == false)
            {
                res.Add(info);
            }
        }
        return res;
    }

    private List<UnreferencedResourceInfo> _GetShowInfos()
    {
        var showInfos = new List<UnreferencedResourceInfo>();

        var filterContent = _filterContent.Split(';');
        var sizex = _regionSize.x * 1024;
        var sizey = _regionSize.y <= 0 ? int.MaxValue : _regionSize.y * 1024;
        var files = _GetFilterSuffix();
        foreach (var file in files)
        {
            // 不在指定大小区间
            if (file.filesize < sizex ||
                file.filesize > sizey)
            {
                continue;
            }

            if (_IsContentInPath(filterContent, file.assetPath))
            {
                continue;
            }
            showInfos.Add(file);
        }
        return showInfos;
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<UnreferencedResourceInfo>> finishCB)
    {
        var res = UnreferencedResourceChecker.CollectAssetInfo();
        finishCB(res);
    }

    protected override void OnShowCellButton(UnreferencedResourceInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        //GUILogicHelper.ShowFourCheckBt(rect, info.assetPath);
        var copyRect = GUILogicHelper.GetCheckRect(rect);
        GUI.color = Color.white;
        if (GUI.Button(copyRect, "搜索"))
        {
            var name = Path.GetFileName(info.assetPath);
            UnreferencedScriptCheckEditorWindow.Open(name);
        }

        // 删除按钮
        GUI.color = Color.green;
        var newRect = GUILogicHelper.GetButtonRect(rect, 1);
        if (GUI.Button(newRect, "删除"))
        {
            AssetDatabase.DeleteAsset(info.assetPath);

            EditorApplication.delayCall = () =>
            {
                _assetsInfos.Remove(info);
                EditorApplication.delayCall = null;

                Reload();
            };
        }
        GUI.color = Color.white;
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示复选框和
        _ShowToggleLogic();
    }

    protected override float OnGetListViewPosY()
    {
        return 188;
    }

    protected override List<UnreferencedResourceInfo> OnGetShowInfos()
    {
        var showInfos = _GetShowInfos();
        if (_filterType == 0)
            return UnreferencedResourceChecker.GetHidePrefabs(showInfos);
        else if (_filterType == 1)
            return showInfos;

        return UnreferencedResourceChecker.GetShowPrefabs(showInfos); ;
    }

    public override void OnDidSelectCell(AssetInfoBase info)
    {
        if (info.assetPath.EndsWith(".prefab"))
        {
            var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(info.assetPath);
            AssetDatabase.OpenAsset(obj);
            Selection.activeObject = obj;
        }
        else
        {
            base.OnDidSelectCell(info);
        }
    }
}
