using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class PrefabRedundanceCheckEditorWindow : AssetCheckEditorWindowBase<PrefabRedundanceAssetInfo>
{
    public const string Title = "预制AB冗余";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "检测prefab是否引用到了Packages/目录下的资源(Shader、Material等)，我们规范禁止引用Packages的资源，目前的打包方式会造成ab冗余和内存重复加载。\n" +
            "备注1：如果是ParticlesUnlit.mat冗余，可以先使用：预制粒子 -> 全部修复 尝试修复一下\n" +
            "备注2：如果是Spine这类第三方资源，可以直接在Unity内设置统一的ab包名。(重要提醒：ab名必须在GameAsset有设置过，否则可能会被清空)";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(Action<List<PrefabRedundanceAssetInfo>> finishCB)
    {
        PrefabRedundanceChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabRedundanceAssetInfo info, Rect rect, bool isError)
    {
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, ()=>
        {
            var keys = PrefabRedundanceLogic.GetTipsUniqueKey(info.assetPath);
            AssetsCheckUILogic.GoToAndSelectTips(info.assetPath, keys);
        });
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示取消[!]
        AssetsCheckUILogic.ShowCancelTips();
    }

    protected override float OnGetListViewPosY()
    {
        return 130;
    }

    protected override List<PrefabRedundanceAssetInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }
}
