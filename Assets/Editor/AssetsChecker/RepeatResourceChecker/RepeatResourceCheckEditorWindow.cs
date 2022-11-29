
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEngine;

public class RepeatResourceCheckEditorWindow : AssetCheckEditorWindowBase<RepeatResourceAssetInfo>
{
    public const string Title = "重复资源";

    private static bool _isExpand = true;
    //private static int _index = 0;

    private void _ShowRuleDes()
    {
        const string s_Des = "检查规则：\n" +
            "1、修复按钮功能：选择一个保留的文件，未选择的引用会被替换为选中，最后删除未被选中的资源 \n" +
            "提醒：有一种情况是代码动态创建的(比如音效资源)，需要自己留意下，修改代码 \n" +
            "Reload依赖按钮：如果你有手动修改过资源的依赖关系，请点该按钮，重新加载依赖关系";
        AssetsCheckUILogic.ShowRuleDes(s_Des);
    }

    private void _ShowExpendOrCloseBt()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();

        if (GUILayout.Button("Reload依赖", GUILayout.Width(100)))
        {
            AssetsHelper.Reload();
        }

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

    // menun控件会将"/"进行分级，所以需要将“/”改为"."
    private List<string> _Slash2Dot(List<string> values)
    {
        var newData = new List<string>();
        foreach (var v in values)
        {
            newData.Add(v.Replace("/", "."));
        }
        return newData;
    }

    // 修复按钮逻辑
    private void _FixAction(RepeatResourceAssetInfo info)
    {
        var menuTxt = _Slash2Dot(info.repeatList);
        AssetsCheckUILogic.ShowPopMenu(menuTxt, (index) =>
        {
            _FixActionAtIndex(info, index);
        });
    }

    private void _FixActionAtIndex(RepeatResourceAssetInfo info, int index)
    {
        var replacePaths = new List<string>(info.repeatList.ToArray());
        var retainFilePath = replacePaths[index];
        // 删除查找，剩下就是需要替换的
        replacePaths.RemoveAt(index);

        // 替换
        _Replace(retainFilePath, replacePaths);

        // 删除被替换资源
        _Delete(replacePaths);

        // 刷新
        EditorApplication.delayCall = () =>
        {
            foreach (var aInfo in _assetsInfos)
            {
                if (aInfo.assetPath == info.assetPath)
                {
                    _assetsInfos.Remove(aInfo);
                    break;
                }
            }
            EditorApplication.delayCall = null;
            Reload();
        };

        AssetDatabase.Refresh();

        // 提示
        ShowNotification(new GUIContent("替换成功且已删除多余资源"));


        /*
        // 下面方式是使用查找文件的方式
        FindReferences.FindResArr(replacePaths, (filesDic)=>
        {
            _Replace(filesDic, replaceFilePath);

            // 删除多余资源
            _Delete(filesDic);

            // 刷新
            EditorApplication.delayCall = () =>
            {
                foreach (var aInfo in _assetsInfos)
                {
                    if (aInfo.assetPath == info.assetPath)
                    {
                        _assetsInfos.Remove(aInfo);
                        break;
                    }
                }
                EditorApplication.delayCall = null;
                Reload();
            };

            AssetDatabase.Refresh();

            // 提示
            ShowNotification(new GUIContent("替换成功且已删除多余资源"));
        });
        */
    }

    private int _GetFileCount()
    {
        var count = 0;
        foreach (var info in _assetsInfos)
        {
            count += info.repeatList.Count;
        }
        return count;
    }

    private long _GetRedundancyFileSize()
    {
        long size = 0;
        foreach (var info in _assetsInfos)
        {
            size += (info.repeatList.Count - 1) * info.filesize;
        }
        return size;
    }

    protected override void OnShowBottomInfo()
    {
        var count = _GetFileCount();
        var fileSize = _GetRedundancyFileSize();
        var des = $"文件数量：{count} | 冗余大小：{fileSize / 1048576f:n2}MB";
        GUI.Label(new Rect(0f, position.height - 20f, position.width, 20f), des);
    }

    protected override string OnGetTitle()
    {
        return Title;
    }

    protected override void OnStartCollectAssetInfo(System.Action<List<RepeatResourceAssetInfo>> finishCB)
    {
        var res = RepeatResourceChecker.CollectAssetInfo();
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
        return 106;
    }

    protected override List<RepeatResourceAssetInfo> OnGetShowInfos()
    {
        return _assetsInfos;
    }

    public override void Reload()
    {
        _listView.SetFoldoutIndex(1);

        _showInfos = OnGetShowInfos();

        // 组织多层级列表
        var datas = new List<ListView<RepeatResourceAssetInfo>.ListCellItem>(_showInfos.Count);
        int idIndex = 1;
        for (int i = 0; i < _showInfos.Count; i++)
        {
            var info = _showInfos[i];
            for (int repeatIndex = 0; repeatIndex < info.repeatList.Count; repeatIndex++)
            {
                var path = info.repeatList[repeatIndex];

                // 拷贝一份，且路径改为需要显示
                var newData = info.Copy();
                newData.assetPath = path;
                var item = new ListView<RepeatResourceAssetInfo>.ListCellItem
                {
                    id = idIndex++,                     // id必须唯一
                    depth = repeatIndex == 0 ? 0 : 1,   // 显示深度，0为根节点，1为子节点
                    displayName = "",
                    data = newData,
                };
                datas.Add(item);
            }
        }
        _listView.ReloadData(datas);
        _listView.ExpandAll();
    }

    public override void ListViewDidShowCell(RepeatResourceAssetInfo info, Rect rect, int rowIndex, ListView<RepeatResourceAssetInfo>.ListCellItem item)
    {
        // 子节点不显示图标
        if (0 == rowIndex && item.depth == 0)
        {
            // 显示第1列图标
            GUILogicHelper.ShowOneContent(rect, info.assetPath);
            return;
        }

        GUI.color = Color.yellow;
        if (1 == rowIndex)
        {
            // 显示第2列资源路径
            //rect.x += _listView.GetFoldoutOffsetX(item);
            rect.x += 20;
            GUILogicHelper.ShowSecondContent(rect, info.assetPath);
            return;
        }

        if (2 == rowIndex && item.depth == 0)
        {
            // 显示第3列错误描述
            var des = info.GetErrorDes();
            GUILogicHelper.ShowThirdContent(rect, des);
            return;
        }

        if (3 == rowIndex && item.depth == 0)
        {
            GUILogicHelper.ShowFixBt(rect, () =>
            {
                _FixAction(info);

                Reload();
            });
        }

        GUI.color = Color.white;

    }

    private static void _Delete(Dictionary<string, List<string>> fileDic)
    {
        foreach (var file in fileDic)
        {
            EditerUtils.FileHelper.DeleteFile(file.Key);
        }
    }

    private static void _Delete(List<string> replacePaths)
    {
        foreach (var path in replacePaths)
        {
            AssetDatabase.DeleteAsset(path);
        }
    }

    private static void _Replace(Dictionary<string, List<string>> fileDic, string replaceFilePath)
    {
        var newGuid = AssetDatabase.AssetPathToGUID(replaceFilePath);

        foreach (var file in fileDic)
        {
            if (file.Value.Count == 0)
            {
                continue;
            }

            var oldGuid = AssetDatabase.AssetPathToGUID(file.Key);
            foreach (var filePath in file.Value)
            {
                EditerUtils.FileHelper.Replace(filePath, oldGuid, newGuid);
            }
        }
    }

    private static void _Replace(string retainPath, List<string> replacePaths)
    {
        var newGuid = AssetDatabase.AssetPathToGUID(retainPath);
        foreach (var targetPath in replacePaths)
        {
            var oldGuid = AssetDatabase.AssetPathToGUID(targetPath);
            var targetDepPaths = AssetsHelper.GetDepPathsByAssetPath(targetPath);
            foreach (var depPath in targetDepPaths)
            {
                EditerUtils.FileHelper.Replace(depPath, oldGuid, newGuid);
            }
        }
    }
}

