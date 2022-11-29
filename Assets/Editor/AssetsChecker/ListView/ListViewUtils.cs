

using System.Collections.Generic;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

namespace EditerUtils
{

    public class ListViewUtils
    {
        /// <summary>
        /// 列表标题头
        /// </summary>
        /// <returns></returns>
        public static MultiColumnHeader CreateDefaultMultiColumnHeader()
        {
            var columns = new[]
            {
                // 图标
                new MultiColumnHeaderState.Column
                {
                    headerContent = new GUIContent("图标"),
                    contextMenuText = "Asset",
                    headerTextAlignment = TextAlignment.Center,
                    sortedAscending = false,
                    width = 40,
                    minWidth = 40,
                    maxWidth = 40,
                    autoResize = false,
                    allowToggleVisibility = false,
                    canSort = false
                },
                // 路径
                new MultiColumnHeaderState.Column
                {
                    headerContent = new GUIContent("文件"),
                    headerTextAlignment = TextAlignment.Center,
                    sortedAscending = false,
                    width = 400,
                    maxWidth = 650,
                    minWidth = 300,
                    autoResize = true,
                    allowToggleVisibility = false,
                    canSort = false
                },
                // 描述
                new MultiColumnHeaderState.Column {
                    headerContent = new GUIContent("问题描述"),
                    headerTextAlignment = TextAlignment.Center,
                    sortedAscending = false,
                    width = 400,
                    minWidth = 200,
                    autoResize = true,
                    allowToggleVisibility = false,
                    canSort = false
                },
                // 操作
                new MultiColumnHeaderState.Column {
                    headerContent = new GUIContent("操作"),
                    headerTextAlignment = TextAlignment.Center,
                    sortedAscending = false,
                    width = 160,
                    minWidth = 160,
                    maxWidth = 160,
                    autoResize = false,
                    allowToggleVisibility = false,
                    canSort = false
                },

            };
            var state = new MultiColumnHeaderState(columns);
            return new MultiColumnHeader(state);
        }
    }
}


