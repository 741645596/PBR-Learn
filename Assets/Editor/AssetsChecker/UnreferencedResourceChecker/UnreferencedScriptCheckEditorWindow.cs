using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using EditerUtils;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

public class UnreferencedScriptCheckEditorWindow : EditorWindow, ListView<string>.IListViewCell
{
    /// <summary>
    /// 在脚本文件和配置表文件搜索指定信息是否存在窗口
    /// </summary>
    /// <param name="searchContent"></param>
    public static void Open(string searchContent)
    {
        UnreferencedScriptCheckEditorWindow.searchContent = searchContent;

        var window = GetWindow<UnreferencedScriptCheckEditorWindow>(false);
        window.minSize = new Vector2(800, 600);
        window.Show();
    }

    public static string searchContent = "";
    public static string searchScriptPath = "";
    public static string searchConfigPath = "";

    private ListView<string> _listView;

    private void OnEnable()
    {
        titleContent = new GUIContent("搜索");
        if (string.IsNullOrEmpty(searchScriptPath))
        {
            searchScriptPath = Application.dataPath;
        }

        // 初始化
        var header = CreateDefaultMultiColumnHeader();
        header.ResizeToFit();
        _listView = new ListView<string>(new TreeViewState(), header, this, 24f);
        _listView.Reload();
    }

    private void _ShowContentGUI()
    {
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();

        searchContent = EditorGUILayout.TextField("搜索内容:", searchContent);

        if (GUILayout.Button("去除后缀", GUILayout.Width(100)))
        {
            searchContent = Path.GetFileNameWithoutExtension(searchContent);
        }

        if (GUILayout.Button("复制", GUILayout.Width(100)))
        {
            GUIUtility.systemCopyBuffer = searchContent;
            ShowNotification(new GUIContent($"已复制{searchContent}"));
        }

        EditorGUILayout.EndHorizontal();
    }

    private void _ShowScriptPathGUI()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("搜索脚本路径：");

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.TextField("", searchScriptPath);

        if (GUILayout.Button("目录", GUILayout.Width(100)))
        {
            searchScriptPath = EditorUtility.OpenFolderPanel("脚本路径", searchScriptPath, "");
            GUIUtility.ExitGUI();
        }
        EditorGUILayout.EndHorizontal();
    }

    private void _ShowConfigPathGUI()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("搜索配置表路径：");

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.TextField("", searchConfigPath);

        if (GUILayout.Button("目录", GUILayout.Width(100)))
        {
            searchConfigPath = EditorUtility.OpenFolderPanel("配置表路径", searchScriptPath, "");
            GUIUtility.ExitGUI();
        }
        EditorGUILayout.EndHorizontal();
    }

    private void _SearchBtnGUI()
    {
        EditorGUILayout.Space();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space();
        if (GUILayout.Button("开始搜索", GUILayout.Width(100)))
        {
            if (string.IsNullOrEmpty(searchContent))
            {
                ShowNotification(new GUIContent("搜索内容不能为空"));
                return;
            }

            var targetFiles = _GetSearchFiles();
            FileHelper.GetContentFile(searchContent, targetFiles, (res)=>
            {
                _listView.Reload(res);
            });
        }
        EditorGUILayout.EndHorizontal();
    }

    // 获取需要查找的文件夹集合
    private List<string> _GetSearchFiles()
    {
        // 脚本路径
        var scripts = _GetScriptFiles();
        var configs = _GetConfigFiles();
        scripts.AddRange(configs);
        return scripts;
    }

    private List<string> _GetConfigFiles()
    {
        if (string.IsNullOrEmpty(searchConfigPath))
        {
            return new List<string>();
        }

        return DirectoryHelper.GetAllFilesIgnoreExt(searchConfigPath, ".meta");
    }

    private List<string> _GetScriptFiles()
    {
        if (string.IsNullOrEmpty(searchScriptPath))
        {
            return new List<string>();
        }

        return DirectoryHelper.GetAllFiles(searchScriptPath, ".cs");
    }

    private void OnGUI()
    {
        EditorGUILayout.BeginVertical();

        _ShowContentGUI();

        _ShowScriptPathGUI();

        _ShowConfigPathGUI();

        _SearchBtnGUI();

        var posy = 160.0f;
        _listView.OnGUI(new Rect(0, posy, position.width, position.height - posy - 4));

        EditorGUILayout.EndVertical();
    }

    public void ListViewDidShowCell(string t, Rect r, int column, ListView<string>.ListCellItem item)
    {
        if (0 == column)
        {
            GUI.Label(r, PathHelper.FullPath2AssetPath(t));
        }
        else if (1 == column)
        {
            var space = 2;
            r.x += space;
            r.y += space;
            r.width -= space * 2;
            r.height -= space * 2;
            if (GUI.Button(r, "打开"))
            {
                var pStartInfo = new System.Diagnostics.ProcessStartInfo("open");
                pStartInfo.Arguments = t;
                pStartInfo.CreateNoWindow = false;
                pStartInfo.UseShellExecute = false;
                System.Diagnostics.Process.Start(pStartInfo);
            }
        }
    }

    public void ListViewDidClickCell(string t, ListView<string>.ListCellItem item)
    {
        //throw new System.NotImplementedException();
    }

    public void ListViewDidSelectCell(string t, ListView<string>.ListCellItem item, int selectIndex)
    {
        //throw new System.NotImplementedException();
    }

    public void ListViewDidDoubleClickCell(string t, ListView<string>.ListCellItem item)
    {
        //throw new System.NotImplementedException();
    }

    public void ListViewDidRightClickCell(string t, ListView<string>.ListCellItem item)
    {
        //throw new System.NotImplementedException();
    }

    private static MultiColumnHeader CreateDefaultMultiColumnHeader()
    {
        var columns = new[]
        {
            // 路径
            new MultiColumnHeaderState.Column
            {
                headerContent = new GUIContent("文件"),
                headerTextAlignment = TextAlignment.Center,
                sortedAscending = false,
                width = 400,
                maxWidth = 900,
                minWidth = 300,
                autoResize = true,
                allowToggleVisibility = false,
                canSort = false
            },
            // 操作
            new MultiColumnHeaderState.Column {
                headerContent = new GUIContent("操作"),
                headerTextAlignment = TextAlignment.Center,
                sortedAscending = false,
                width = 80,
                minWidth = 80,
                maxWidth = 80,
                autoResize = false,
                allowToggleVisibility = false,
                canSort = false
            },
        };
        var state = new MultiColumnHeaderState(columns);
        return new MultiColumnHeader(state);
    }
}
