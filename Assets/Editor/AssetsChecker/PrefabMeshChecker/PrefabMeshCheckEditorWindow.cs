
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

/// <summary>
/// 预制网格检测,EditorUI界面
/// </summary>
public class PrefabMeshCheckEditorWindow : AssetCheckEditorWindowBase<PrefabMeshAssetInfo>
{
    public const string Title = "预制阴影开关";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "不产生阴影且不接受阴影、关闭光照探针和反射探针、关闭动态遮挡";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowFixAll()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        ShowProblemToggle();

        GUI.color = Color.green;
        if (GUILayout.Button("全部修复", GUILayout.Width(100)))
        {
            PrefabMeshChecker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;
        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<PrefabMeshAssetInfo>> finishCB)
    {
        PrefabMeshChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabMeshAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath);

        // 修复按钮
        if (isError)
        {
            GUILogicHelper.ShowFourFixBt(rect, () =>
            {
                info.Fix();

                Reload();
            });
        }
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示复选框和全部修复按钮
        _ShowFixAll();
    }

    protected override float OnGetListViewPosY()
    {
        return 80;
    }

    protected override List<PrefabMeshAssetInfo> OnGetShowInfos()
    {
        return _isFilter ? PrefabMeshChecker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
    }
}
