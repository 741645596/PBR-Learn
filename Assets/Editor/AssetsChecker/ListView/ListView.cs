

using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class ListView<T> : TreeView
    {
        // Cell相关回调
        public interface IListViewCell
        {
            public void ListViewDidShowCell(T t, Rect r, int column, ListCellItem item);
            public void ListViewDidClickCell(T t, ListCellItem item);
            public void ListViewDidSelectCell(T t, ListCellItem item, int selectIndex);
            public void ListViewDidDoubleClickCell(T t, ListCellItem item);
            public void ListViewDidRightClickCell(T t, ListCellItem item);
        }

        public class ListCellItem : TreeViewItem
        {
            public T data;
        }

        // 图标宽度
        const float kIconWidth = 18f;

        private List<TreeViewItem> _datas;
        private IListViewCell _iCellCB;

        public ListView(TreeViewState state,
            MultiColumnHeader multicolumnHeader,
            IListViewCell cellCallback,
            float cellRowHeight)
            : base(state, multicolumnHeader)
        {
            rowHeight = cellRowHeight;
            columnIndexForTreeFoldouts = 0;
            customFoldoutYOffset = 0;
            showAlternatingRowBackgrounds = true;
            showBorder = true;
            extraSpaceBeforeIconAndLabel = kIconWidth;

            _iCellCB = cellCallback;
            _datas = new List<TreeViewItem>();
        }

        /// <summary>
        /// T为自己指定的数据结构，用于回调使用
        /// </summary>
        /// <param name="datas"></param>
        public void Reload(List<T> datas)
        {
            _datas.Clear();

            for (int i=0; i<datas.Count; i++)
            {
                var item = new ListCellItem
                {
                    id = i+1,       // id必须唯一
                    depth = 0,      // 显示深度，默认从0开始，如果有子层级+1
                    displayName = "",
                    data = datas[i],
                };
                _datas.Add(item);
            }
            Reload();
        }

        /// <summary>
        /// 自己指定，用来显示多层级(树形)结构
        /// </summary>
        /// <param name="datas"></param>
        public void ReloadData(List<ListCellItem> datas)
        {
            _datas.Clear();
            foreach (TreeViewItem item in datas)
            {
                _datas.Add(item);
            }
            Reload();
        }

        /// <summary>
        /// 设置树形结构三角标起始位置在哪个column，0是第一个
        /// </summary>
        /// <param name="foldoutIndex"></param>
        public void SetFoldoutIndex(int foldoutIndex)
        {
            columnIndexForTreeFoldouts = foldoutIndex;
            //customFoldoutYOffset = (rowHeight - EditorGUIUtility.singleLineHeight) * 0.5f;
        }

        /// <summary>
        /// 获取树形结构三角标结束位置，如果该列有三角标需要加上该偏移量才是正确显示的起始位置
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public float GetFoldoutOffsetX(TreeViewItem item)
        {
            return GetContentIndent(item);
        }

        protected override TreeViewItem BuildRoot()
        {
            var root = new TreeViewItem { id = 0, depth = -1 };
            SetupParentsAndChildrenFromDepths(root, _datas);
            return root;
        }

        protected override void RowGUI(RowGUIArgs args)
        {
            var item = (ListCellItem)args.item;
            for (int i = 0; i < args.GetNumVisibleColumns(); ++i)
            {
                var rect = args.GetCellRect(i);
                var colomnIndex = args.GetColumn(i);
                _iCellCB.ListViewDidShowCell(item.data, rect, colomnIndex, item);
            }
        }

        // 右键回调
        protected override void ContextClickedItem(int id)
        {
            var item = FindItem(id, rootItem) as ListCellItem;
            _iCellCB.ListViewDidRightClickCell(item.data, item);
        }

        protected override void SingleClickedItem(int id)
        {
            var item = FindItem(id, rootItem) as ListCellItem;
            _iCellCB.ListViewDidClickCell(item.data, item);
        }

        protected override void SelectionChanged(IList<int> selectedIds)
        {
            if (selectedIds.Count != 1)
            {
                return;
            }

            var id = selectedIds[0];
            var item = FindItem(id, rootItem) as ListCellItem;
            _iCellCB.ListViewDidSelectCell(item.data, item, id);
        }

        protected override void DoubleClickedItem(int id)
        {
            var item = FindItem(id, rootItem) as ListCellItem;
            _iCellCB.ListViewDidDoubleClickCell(item.data, item);
        }

        protected override bool CanMultiSelect(TreeViewItem item)
        {
            return false;
        }
    }
}


