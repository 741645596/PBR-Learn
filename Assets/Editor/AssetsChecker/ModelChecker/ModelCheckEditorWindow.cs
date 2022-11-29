
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

public class ModelCheckEditorWindow : AssetCheckEditorWindowBase<ModelAssetInfo>
{
    public const string Title = "模型fbx资源";

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则，以下规则需要根据具体情况选择性优化：\n" +
            "1、如果模型是用在粒子系统或者是使用静态合批需要开启R&W，否则有可能Crash；其他情况请关闭（这边可以统一关闭，“预制粒子”栏会提示开启）\n" +
            "2、Import BlendShapes/Visibility/Cameras/Lights建议不勾选\n" +
            "3、建议开启Optimize Mesh\n" +
            "4、如果定义了Avatar Definition，请开启Optimize Game Object，手动优化节点。可大幅提升性能\n" +
            "5、动画压缩优化：Anim.Compression==Optimal（对于精度要求较高的动画，优化后有可能造成动作看起来顿挫，请根据效果优化）\n" +
            "6、Materials通常情况应该设置为None\n" +
            "7、模型一般都是使用纹理采样，不需要包含Color数据（需要美术导出资源时去掉）\n" +
            "8、常规情况只会用到 UV1，UV2，一般不会用到UV3和UV4；如无必要建议不进行导入 \n" +
            "9、顶点包含Normal、Tangents、UV2数据，项目根据模型具体是否需要使用去除\n" +
            "备注1：模型默认材质球引用了Lit Shader导致ab包shader冗余\n" +
            "备注2：Project Setting开启Optimize Mesh Data会自动去除没有使用到Color、Normal等属性，默认开启，所以游戏内动态获取网格属性的需要注意下\n" +
            "备注3：修复/全部修复按钮功能只处理：关闭R&W、去掉Lit材质球、Mat设置为None";
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
            ModelChecker.FixAll(_showInfos, ()=>
            {
                Reload();
            });
        }
        GUI.color = Color.white;
        EditorGUILayout.EndHorizontal();
    }

    private void _FixWithToolAction(ModelAssetInfo info)
    {
        var names = ModelChecker.GetFixToolNames(info);
        AssetsCheckUILogic.ShowPopMenu(names, (index) =>
        {
            var name = names[index];
            ModelChecker.FixWithToolName(name, info);

            Reload();
        });
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<ModelAssetInfo>> finishCB)
    {
        ModelChecker.CollectAssetInfo(finishCB);
    }

    protected override void OnShowCellButton(ModelAssetInfo info, Rect rect, bool isError)
    {
        // 修复按钮
        if (info.CanFix())
        {
            GUILogicHelper.ShowFixBt(rect, () =>
            {
                info.Fix();

                Reload();
            });
            return;
        }

        // 是否有工具可以修复的
        var isToolsFix = ModelChecker.IsFixWithTool(info);
        if (isToolsFix)
        {
            GUI.color = Color.white;
            var newRect = GUILogicHelper.GetButtonRect(rect, 0);
            if (GUI.Button(newRect, "可选修复"))
            {
                _FixWithToolAction(info);
            }
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
        return 240.0f;
    }

    protected override List<ModelAssetInfo> OnGetShowInfos()
    {
        return _isFilter ? ModelChecker.GetErrorAssetInfos(_assetsInfos) : _assetsInfos;
    }
}
