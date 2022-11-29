
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public class RepeatMeshEditorWindow : AssetCheckEditorWindowBase<RepeatMeshInfo>
{
    public const string Title = "Mesh重复";

    private static bool _isExpand = true;

    private void _ShowRuleDes()
    {
        const string s_Des = "检查fbx模型里的Mesh是否有重复，如果有，需要美术人员只保留一份，重新导出冗余的fbx\r\n" +
            "* 检查条件为：顶点数 + 三角面数 + bunds center + bunds size 数值都一致\n" +
            "* 有重复的需要美术人员删除冗余资源，统一引用同一份\n" +
            "* 文件大小指的是fbx的大小，方便定位哪些资源比较大，不代表最后优化的大小";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowExpendOrCloseBt()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        var str = _isExpand ? "折叠" : "展开";
        if (GUILayout.Button(str, GUILayout.Width(100)))
        {
            if (_isExpand)
            {
                _listView.CollapseAll();
            }
            else
            {
                _listView.ExpandAll();
            }
            _isExpand = !_isExpand;
        }

        EditorGUILayout.EndHorizontal();
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<RepeatMeshInfo>> finishCB)
    {
        var res = RepeatMeshChecker.CollectAssetInfo();
        finishCB(res);
    }

    protected override void OnShowTopInfo()
    {
        // 显示规则信息
        _ShowRuleDes();

        // 显示展开/折叠按钮
        _ShowExpendOrCloseBt();
    }

    protected override float OnGetListViewPosY()
    {
        return 105;
    }

    protected override List<RepeatMeshInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }

    public override void Reload()
    {
        _listView.SetFoldoutIndex(1);

        _showInfos = OnGetShowInfos();

        // 组织多层级列表
        var datas = new List<ListView<RepeatMeshInfo>.ListCellItem>(_showInfos.Count);
        int idIndex = 1;
        for (int i = 0; i < _showInfos.Count; i++)
        {
            var info = _showInfos[i];
            for (int meshIndex = 0; meshIndex<info.repeatDatas.Count; meshIndex++)
            {
                var meshData = info.repeatDatas[meshIndex];

                // 拷贝一份，且路径改为需要显示
                var newData = info.Copy();
                newData.assetPath = meshData.assetPath;
                var item = new ListView<RepeatMeshInfo>.ListCellItem
                {
                    id = idIndex++,                 // id必须唯一
                    depth = meshIndex==0 ? 0 : 1,   // 显示深度，0为根节点，1为子节点
                    displayName = $"{meshData.assetPath} | {meshData.name}",
                    data = newData,
                };
                datas.Add(item);
            }
        }
        _listView.ReloadData(datas);
        _listView.ExpandAll();
    }

    public override void ListViewDidShowCell(RepeatMeshInfo info, Rect rect, int rowIndex, ListView<RepeatMeshInfo>.ListCellItem item)
    {
        // 子节点不显示图标
        if (0 == rowIndex && item.depth==0)
        {
            // 显示第1列图标
            GUILogicHelper.ShowOneContent(rect, info.assetPath);
            return;
        }

        //var isError = info.IsError();
        GUI.color = Color.yellow;
        if (1 == rowIndex)
        {
            // 显示第2列资源路径
            rect.x += _listView.GetFoldoutOffsetX(item);
            GUILogicHelper.ShowSecondContent(rect, item.displayName);
            return;
        }

        if (2 == rowIndex && item.depth == 0)
        {
            // 显示第3列错误描述
            var des = info.GetErrorDes();
            GUILogicHelper.ShowThirdContent(rect, des);
            return;
        }

        GUI.color = Color.white;

        //if (3 == rowIndex)
        //{
        //    OnShowCellButton(info, rect, isError);
        //}
    }
}
