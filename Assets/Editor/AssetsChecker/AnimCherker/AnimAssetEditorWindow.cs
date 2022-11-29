
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class AnimAssetEditorWindow : AssetCheckEditorWindowBase<AnimAssetInfo>
{
    public const string Title = "动画资源";

    private void _ShowRuleDes()
    {
        const string s_Des = "说明：提供精度压缩和剔除无用数据，进一步压缩ab包大小和内存，但有可能精度不够而导致动画不顺畅：\n" +
            "* Unity有两种动画文件，一种是直接.anim，一种是fbx内的.anim \n" +
            "* 由于fbx是只读文件，每次修改后重新打开unity又会变回去，所以对于fbx无法压缩。\n" +
            "* 但是可以从fbx拷贝一份出来(Ctrl+D)，然后在压缩拷贝那份。这种情况需要把美术只导出动画的fbx，这样拷贝完可以把fbx删掉，否则会多一份冗余";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowFixAll()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        ShowProblemToggle();

        GUI.color = Color.green;
        if (GUILayout.Button("压缩全部", GUILayout.Width(100)))
        {
            AnimAssetCherker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;
        EditorGUILayout.EndHorizontal();
    }

    private void _ShowBottomInfo()
    {
        AssetsCheckUILogic.ShowBottomInfo(_assetsInfos.Count);
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<AnimAssetInfo>> finishCB)
    {
        var res = AnimAssetCherker.CollectAssetInfo();
        finishCB(res);
    }

    protected override void OnShowCellButton(AnimAssetInfo info, Rect rect, bool isError)
    {
        if (isError)
        {
            var newRect = GUILogicHelper.GetButtonRect(rect, 0);
            GUI.color = Color.yellow;
            if (GUI.Button(newRect, "压缩"))
            {
                info.Fix();

                Reload();
            }
            GUI.color = Color.white;
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
        return 110;
    }

    protected override List<AnimAssetInfo> OnGetShowInfos()
    {
        return _isFilter ? AnimAssetCherker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
    }
}
