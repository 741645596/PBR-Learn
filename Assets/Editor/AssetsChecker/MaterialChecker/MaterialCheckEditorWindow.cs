
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MaterialCheckEditorWindow : AssetCheckEditorWindowBase<MaterialAssetInfo>
{
    public const string Title = "材质球资源";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "1、是否包含空纹理采样。空纹理还是会有采样以及相关的计算消耗，所以建议选择适用的shader（变体关闭采样除外）\n" +
            "2、由于unity自身的机制设定，在切换材质球的shader时，材质球会自动保存上一个shader的Keywords。这有可能会导致SRP合批失败\n" +
            "3、由于unity自身的机制设定，在切换材质球的shader时，材质球会自动保存上一个shader的纹理采样信息。这有可能会导致资源冗余";
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
            MaterialChecker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;
        EditorGUILayout.EndHorizontal();
    }

    private void _FixAction(MaterialAssetInfo info)
    {
        info.Fix();

        // 如果已经没有错误了，删除本条
        if (info.IsError() == false)
        {
            // 直接删除GUI遍历会报错，下帧删除
            EditorApplication.delayCall = () =>
            {
                _assetsInfos.Remove(info);
                EditorApplication.delayCall = null;

                Reload();
            };
        }
        else
        {
            Reload();
        }
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<MaterialAssetInfo>> finishCB)
    {
        MaterialChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(MaterialAssetInfo info, Rect rect, bool isError)
    {
        // 修复按钮
        if (info.CanFix())
        {
            GUILogicHelper.ShowFixBt(rect, () =>
            {
                _FixAction(info);

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
        return 110;
    }

    protected override List<MaterialAssetInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }
}
