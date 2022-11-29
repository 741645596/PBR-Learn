
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

public class ModelFaceCheckEditorWindow : AssetCheckEditorWindowBase<ModelFaceAssetInfo>
{
    public const string Title = "预制模型面数";

    private int _sortIndex = 0;

    private void _ShowRuleDes()
    {
        const string s_Des = "模型三角面数和尺寸规范参考：\r\n" +
               "小怪：2000面 + 256~512尺寸 + 5根骨骼\r\n" +
               "中怪：5000面 + 512~1024尺寸 + 10根骨骼\r\n" +
               "Boss：10000面  + 1024~2048尺寸 + 20根骨骼\r\n" +
               "欢乐麻将人物裸模：20000面 + 尺寸（根据部位） + 110根骨骼\r\n" +
               "奇迹暖暖人物精美模型：40000面\r\n" +
               "备注：骨骼数量可以通过Optimize Game Object优化掉\r\n" +
               "备注：像人物模型的脚部位图片尺寸只要256~512，所以具体以模型大小、部位多少具体分析\r\n" +
               "备注：如果预设带有多个模型组件，则统计的为总的数量；";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private string _GetSortDes()
    {
        if (_sortIndex == 0) return "排序：总面数";
        if (_sortIndex == 1) return "排序：总顶点数";
        if (_sortIndex == 2) return "排序：总尺寸";
        if (_sortIndex == 3) return "排序：总渲染数";
        if (_sortIndex == 4) return "排序：总材质球";
        if (_sortIndex == 5) return "排序：总节点";
        return "排序：bone数量";
    }

    private void _SortAction()
    {
        _sortIndex++;
        _sortIndex = _sortIndex > 6 ? 0 : _sortIndex;
        if (_sortIndex == 0)
            _assetsInfos.Sort((a, b) => { return b.faceCount - a.faceCount; });
        else if (_sortIndex == 1)
            _assetsInfos.Sort((a, b) => { return b.vertexCount - a.vertexCount; });
        else if (_sortIndex == 2)
            _assetsInfos.Sort((a, b) => { return (int)(b.textureSizeCount.x* b.textureSizeCount.y - a.textureSizeCount.x* a.textureSizeCount.y); });
        else if (_sortIndex == 3)
            _assetsInfos.Sort((a, b) => { return b.renderCount - a.renderCount; });
        else if (_sortIndex == 4)
            _assetsInfos.Sort((a, b) => { return b.materialCount - a.materialCount; });
        else if (_sortIndex == 5)
            _assetsInfos.Sort((a, b) => { return b.nodeCount - a.nodeCount; });
        else
            _assetsInfos.Sort((a, b) => { return b.boneCount - a.boneCount; });

        Reload();
    }

    private void _ShowSort()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        if (GUILayout.Button(_GetSortDes(), GUILayout.Width(100)))
        {
            _SortAction();
        }

        AssetsCheckUILogic.ShowCancelTipsBt();
        EditorGUILayout.EndHorizontal();    
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<ModelFaceAssetInfo>> finishCB)
    {
        ModelFaceChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(ModelFaceAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, () =>
        {
            var keys = ModelFaceChecker.GetErrorObjUniqueKeys(info);
            AssetsCheckUILogic.GoToAndSelectTips(info.assetPath, keys);
        });
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示取消[!]
        _ShowSort();
    }

    protected override float OnGetListViewPosY()
    {
        return 184;
    }

    protected override List<ModelFaceAssetInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }
}
