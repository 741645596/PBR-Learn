
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 预制UI检测,EditorUI界面
/// </summary>
public class PrefabUICheckEditorWindow : AssetCheckEditorWindowBase<PrefabUIAssetInfo>
{
    public const string Title = "预制Raycast";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "UI组件默认Raycast是开启的，对于射线检测有一定性能影响，以下是建议哪些情况应该关闭掉：\n" +
            "a. 组件是Slider或Toggle不做任何处理\n" +
            "b. 组件是Button或InputField或ScrollRect，当前节点不处理，但需要递归子节点\n" +
            "c. 其他情况建议关闭Raycast";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowFixAll()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        
        GUI.color = Color.green;
        if (GUILayout.Button("全部修复", GUILayout.Width(100)))
        {
            PrefabUIChecker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;

        // 取消[!]
        AssetsCheckUILogic.ShowCancelTipsBt();

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<PrefabUIAssetInfo>> finishCB)
    {
        PrefabUIChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabUIAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, ()=>
        {
            var keys = PrefabUIChecker.GetErrorObjUniqueKeys(info);
            AssetsCheckUILogic.GoToAndSelectTips(info.assetPath, keys);
        });

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
        return 130;
    }

    protected override List<PrefabUIAssetInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }
}
