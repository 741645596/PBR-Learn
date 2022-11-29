
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 预制粒子检测,EditorUI界面
/// </summary>
public class PrefabParticleCheckEditorWindow : AssetCheckEditorWindowBase<PrefabParticleAssetInfo>
{
    public const string Title = "预制粒子";

    private class SortInfo
    {
        public string des;
        public float width;

        public SortInfo(string d, float w)
        {
            des = d;
            width = w;
        }
    }
    private static readonly List<SortInfo> Sort_Infos = new List<SortInfo>()
    {
        new SortInfo( "排序：总发射数",       100),
        new SortInfo( "排序：发射数x纹理尺寸", 150),
        new SortInfo( "排序：发射数x三角面数", 150),
        new SortInfo( "排序：发射数x三角面数x纹理尺寸x纹理数量", 250),
        new SortInfo( "排序：组件数量",       100),
    };

    private int _sortIndex = 0;

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "1、建议关闭Collision和Trigger\n" +
            "2、建议关闭阴影和光照探针\n" +
            "3、粒子类型是Mesh，则Mesh的R&W建议开启，如果未开启而美术又修改mesh顶点则crash\n" +
            "4、最大粒子建议与Bursts发射粒子数一致\n" +
            "5、Prewarm打开会模拟一次粒子的整个生命周期有可能会造成卡顿，一般建议关闭\n" +
            "6、Renderer关闭时需要把Material置为空\n" +
            "7、设置过Mesh后，又改为Billboard模式，则之前设置的Mesh会冗余\n" +
            "8、建议材质总显示尺寸不要超过1024x1024，计算方式：发射粒子数 * 材质球第一个纹理尺寸 < 1024x1024\n" +
            "9、仅建议：粒子数量小于30\r\n" +
               "仅建议：粒子类型是Mesh，则发射数小于5个，网格面片小于500\r\n" +
            "问题描述说明：纹理:发射数量x[纹理尺寸大小]x纹理数量，网格:发射数量x三角面数x[纹理尺寸大小]x纹理数量";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowSortBt()
    {
        var info = Sort_Infos[_sortIndex];
        if (GUILayout.Button(info.des, GUILayout.Width(info.width)))
        {
            _sortIndex += 1;
            if (_sortIndex == Sort_Infos.Count) _sortIndex = 0;

            Reload();
        }
    }

    // 粒子数超过1000
    private void _SetMaxParticlesBt()
    {
        if (GUILayout.Button("一键设置默认粒子数=30", GUILayout.Width(250)))
        {
            foreach (var info in _showInfos)
            {
                if (info.IsDefaultMaxParticles())
                {
                    info.SetDefaultMaxParticles30();
                }
            }
            AssetDatabase.Refresh();

            Reload();
        }
    }

    private void _ShowButtons()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();

        _ShowSortBt();

        _SetMaxParticlesBt();

        GUILayout.FlexibleSpace();

        ShowProblemToggle();

        GUI.color = Color.green;
        if (GUILayout.Button("全部修复", GUILayout.Width(100)))
        {
            PrefabParticleChecker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;

        AssetsCheckUILogic.ShowCancelTipsBt();

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<PrefabParticleAssetInfo>> finishCB)
    {
        PrefabParticleChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(PrefabParticleAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, ()=>
        {
            var keys = PrefabParticleChecker.GetErrorObjUniqueKeys(info);
            AssetsCheckUILogic.GoToAndSelectTips(info.assetPath, keys);
        });

        // 修复按钮
        if (info.CanFix())
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
        _ShowButtons();
    }

    protected override float OnGetListViewPosY()
    {
        return 222;
    }

    protected override List<PrefabParticleAssetInfo> OnGetShowInfos()
    {
        var showInfos = _isFilter ? PrefabParticleChecker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
        if (_sortIndex == 0)
            showInfos.Sort((a, b) => { return b.GetTotalBurstCount() - a.GetTotalBurstCount(); });
        else if (_sortIndex == 1)
            showInfos.Sort((a, b) => { return b.GetTotalTextureSize() - a.GetTotalTextureSize(); });
        else if (_sortIndex == 2)
            showInfos.Sort((a, b) => { return b.GetTotalMeshTriangles() - a.GetTotalMeshTriangles(); });
        else if (_sortIndex == 3)
            showInfos.Sort((a, b) => { return b.GetTotalAll() - a.GetTotalAll(); });
        else
            showInfos.Sort((a, b) => { return b.particleInfos.Count - a.particleInfos.Count; });
        return showInfos;
    }

    public override void OnDidSelectCell(AssetInfoBase info)
    {
        base.OnDidSelectCell(info);

        // 粒子太长了，在控制台打印一下
        var particeInfo = (PrefabParticleAssetInfo)info;
        Debug.Log(particeInfo.GetParticleInfo());
    }

}
