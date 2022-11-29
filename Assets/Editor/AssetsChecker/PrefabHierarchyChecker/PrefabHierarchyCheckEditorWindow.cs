using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

public class PrefabHierarchyCheckEditorWindow : AssetCheckEditorWindowBase<PrefabHierarchyAssetInfo>
{
    public const string Title = "预制嵌套层级";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "1、建议嵌套层级小于7层。如果预设是模型，可以使用Optimize Game Object优化节点数量\n" +
            "2、检测非Active数量/总结点数量，如果非Active数量占比较多（暂定超过30%），请考虑是否要拆分，动态创建\n";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowToggle()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        ShowProblemToggle();

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(Action<List<PrefabHierarchyAssetInfo>> finishCB)
    {
        PrefabHierarchyChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabHierarchyAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, ()=>
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

        // 显示复选框
        _ShowToggle();
    }

    protected override float OnGetListViewPosY()
    {
        return 126;
    }

    protected override List<PrefabHierarchyAssetInfo> OnGetShowInfos()
    {
        return _isFilter ? PrefabHierarchyChecker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
    }
}
