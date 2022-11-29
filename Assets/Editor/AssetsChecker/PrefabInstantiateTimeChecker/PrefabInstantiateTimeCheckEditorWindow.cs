using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

public class PrefabInstantiateTimeCheckEditorWindow : AssetCheckEditorWindowBase<PrefabInstantiateTimeAssetInfo>
{
    public const string Title = "预制实例耗时";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "因为unity本身有缓存，而且pc和手机的性能不一致，所以有一定不准确，但是大致可以分析哪些prefab加载耗时最严重\n";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowFilter()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        EditorGUI.BeginChangeCheck();
        _isFilter = EditorGUILayout.ToggleLeft("只显示超过10ms预设", _isFilter);
        if (EditorGUI.EndChangeCheck())
        {
            Reload();
        }

        EditorGUILayout.EndHorizontal();
    }

    protected override List<PrefabInstantiateTimeAssetInfo> OnGetShowInfos()
    {
        if (_isFilter == false)
        {
            return _assetsInfos;
        }

        var showInfos = new List<PrefabInstantiateTimeAssetInfo>();
        foreach (var info in _assetsInfos)
        {
            if (info.IsError())
            {
                showInfos.Add(info);
            }
        }
        return showInfos;
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(Action<List<PrefabInstantiateTimeAssetInfo>> finishCB)
    {
        PrefabInstantiateTimeChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabInstantiateTimeAssetInfo info, Rect rect, bool isError)
    {
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, () =>
        {
            var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(info.assetPath);
            AssetDatabase.OpenAsset(obj);
            Selection.activeObject = obj;
        });
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示复选框和全部修复按钮
        _ShowFilter();
    }

    protected override float OnGetListViewPosY()
    {
        return 100;
    }
}
