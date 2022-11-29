
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

/// <summary>
/// 图集检测
/// </summary>
public class AtlasCheckEditorWindow : AssetCheckEditorWindowBase<AtlasAssetInfo>
{
    public const string Title = "合图资源";

    private void _ShowRuleDes()
    {
        const string s_Des = "规范以及检查规则：\n" +
            "1、文件夹以_atlas结尾的表示为合图，合图文件放在同级目录或是_atlas都可以\n" +
            "2、合图文件(.spriteatlas)Packing文件夹，不要Packing单个文件，方便管理\n" +
            "3、合图Packing的文件夹内必须都是Sprite(2D and UI)类型纹理，否则不会打入合图\n" +
            "4、合图会对原图二次压缩，所以原图不要勾选override\n" +
            "5、合图需要勾选Include in Build\n" +
            "6、合图纹理压缩格式是astc 4x4 || 5x5 || 6x6，修复按钮使用astc 5x5\n";
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
            AtlasChecker.FixAll(_showInfos, (isCancel)=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;

        if (GUILayout.Button("一键设置ASTC", GUILayout.Width(100)))
        {
            AssetsCheckUILogic.ShowASTCPopMenu(format =>
            {
                AtlasChecker.SetAllAstcFormat(_showInfos, format, (isCancel)=>
                {
                    Reload();
                });
            });
        }

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<AtlasAssetInfo>> finishCB)
    {
        AtlasChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(AtlasAssetInfo info, Rect rect, bool isError)
    {
        // 检视按钮
        GUILogicHelper.ShowFourCheckBt(rect, info.assetPath, () =>
        {
            var path = info.isSpriteAtlasExist ? info.spriteAtlasAssetPath : info.assetPath;
            Selection.activeObject = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(path);
        });

        // 单独设置ASTC
        GUILogicHelper.ShowFourCustiomBt("设置ASTC", rect, () =>
        {
            AssetsCheckUILogic.ShowASTCPopMenu(format =>
            {
                info.SetAstcFormat(format);
            });
        });

        // 修复按钮
        if (info.CanFix())
        {
            GUILogicHelper.ShowFourFixBt(rect, 2, () =>
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
        return 164;
    }

    protected override List<AtlasAssetInfo> OnGetShowInfos()
    {
        return _isFilter ? AtlasChecker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
    }
}
