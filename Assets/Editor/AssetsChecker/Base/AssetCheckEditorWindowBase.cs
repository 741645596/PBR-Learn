

using System;
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;


public abstract class AssetCheckEditorWindowBase<T> : EditorWindow, ListView<T>.IListViewCell
    where T : AssetInfoBase
{
    // 所有资源信息
    protected List<T> _assetsInfos;

    // 显示的资源的嘻嘻
    protected List<T> _showInfos;

    protected ListView<T> _listView;
    protected bool _isFilter = true;

    // Title
    protected abstract string OnGetTitle();

    // 开始搜集信息
    protected abstract void OnStartCollectAssetInfo(Action<List<T>> finishCB);

    // 显示顶部信息内容，描述/全部修复按钮等
    protected abstract void OnShowTopInfo();

    // ListView显示的起始位置
    protected abstract float OnGetListViewPosY();

    // 获取需要显示的信息
    protected abstract List<T> OnGetShowInfos();

    // 显示操作按钮
    protected virtual void OnShowCellButton(T info, Rect rect, bool isError) { }

    // 显示底栏信息
    protected virtual void OnShowBottomInfo()
    {
        GUILogicHelper.ShowBottomInfo<T>(_showInfos, position);
    }

    /// <summary>
    /// 只显示问题资源，根据需求调用
    /// </summary>
    protected void ShowProblemToggle()
    {
        EditorGUI.BeginChangeCheck();
        _isFilter = EditorGUILayout.ToggleLeft("只显示问题资源", _isFilter);
        if (EditorGUI.EndChangeCheck())
        {
            Reload();
        }
    }

    private void OnGUI()
    {
        if (_assetsInfos == null)
        {
            return;
        }

        OnShowTopInfo();

        // 具体内容
        var posy = OnGetListViewPosY();
        _listView.OnGUI(new Rect(0, posy, position.width, position.height - posy - 20.0f));

        // 显示底部文件信息
        OnShowBottomInfo();
    }

    private void OnEnable()
    {
        titleContent = new GUIContent(OnGetTitle());

        // 初始化
        var header = ListViewUtils.CreateDefaultMultiColumnHeader();
        header.ResizeToFit();
        _listView = new ListView<T>(new TreeViewState(), header, this, 24f);
        _listView.Reload();

        OnStartCollectAssetInfo((res)=>
        {
            _assetsInfos = res;

            Reload();
        });
    }

    /// <summary>
    /// 重新load数据
    /// </summary>
    public virtual void Reload()
    {
        _showInfos = OnGetShowInfos();
        _listView.Reload(_showInfos);
    }

    #region ListView回调
    public virtual void ListViewDidShowCell(T info, Rect rect, int rowIndex, ListView<T>.ListCellItem item)
    {
        if (0 == rowIndex)
        {
            // 显示第1列图标
            GUILogicHelper.ShowOneContent(rect, info.assetPath);
            return;
        }

        var isError = info.IsError();
        GUI.color = isError ? Color.yellow : Color.white;
        if (1 == rowIndex)
        {
            // 显示第2列资源路径
            GUILogicHelper.ShowSecondContent(rect, info.assetPath);
            return;
        }

        if (2 == rowIndex)
        {
            // 显示第3列错误描述
            var des = info.GetErrorDes();
            GUILogicHelper.ShowThirdContent(rect, des);
            return;
        }

        if (3 == rowIndex)
        {
            OnShowCellButton(info, rect, isError);
        }
        GUI.color = Color.white;
    }

    public void ListViewDidClickCell(T info, ListView<T>.ListCellItem item)
    {
        
    }

    public void ListViewDidDoubleClickCell(T info, ListView<T>.ListCellItem item)
    {
        //throw new NotImplementedException();
    }

    public void ListViewDidRightClickCell(T info, ListView<T>.ListCellItem item)
    {
        //throw new NotImplementedException();
    }

    public virtual void OnDidSelectCell(AssetInfoBase info)
    {
        Selection.activeObject = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(info.assetPath);
    }

    public void ListViewDidSelectCell(T info, ListView<T>.ListCellItem item, int selectIndex)
    {
        OnDidSelectCell(info);
    }
    #endregion
}

