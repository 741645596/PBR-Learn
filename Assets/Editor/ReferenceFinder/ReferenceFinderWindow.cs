using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;

public class ReferenceFinderWindow : EditorWindow
{
    [MenuItem("GameObject/复制名称", false, 10)]
    public static void CreateTextArea() {
        List<string> strings = new List<string>();

        for (int i = 0; i < Selection.objects.Length; i++) {
            var obj = Selection.objects[i];
            strings.Add(obj.name);
        }

        GUIUtility.systemCopyBuffer = string.Join("\n", strings);
    }
    
    //依赖模式的key
    const string isDependPrefKey = "ReferenceFinderData_IsDepend";

    //是否需要更新信息状态的key
    const string needUpdateStatePrefKey = "ReferenceFinderData_needUpdateState";

    public static ReferenceFinderData m_data = new ReferenceFinderData();
    private static bool initializedData = false;

    private bool m_isDepend = false;
    private bool m_needUpdateState = true;

    private bool needUpdateAssetTree = false;

    private bool initializedGUIStyle = false;

    //工具栏按钮样式
    private GUIStyle toolbarButtonGUIStyle;

    //工具栏样式
    private GUIStyle toolbarGUIStyle;

    //选中资源列表
    private List<string> m_selectedAssetGuidList = new List<string>();

    private AssetTreeView m_AssetTreeView;

    [SerializeField] private TreeViewState m_TreeViewState;

    //查找资源引用信息
    [MenuItem("Assets/Find References In Project #&f", false, 25)] //%Ctrl #Shift &Alt
    static void FindRef()
    {
        InitDataIfNeeded();
        OpenWindow();
        ReferenceFinderWindow window = GetWindow<ReferenceFinderWindow>();
        window.UpdateSelectedAssets();
    }

    class tagMeshInfo
    {
        public string path;
        public int count;
    }

    private void OnSelectionChange()
    {
        
        var sel = Selection.activeObject;
        if (sel != null)
        {
            if (sel is Shader)
            {
                var shader = sel as Shader;
                Debug.Log(sel.name);
            }
        }
    }

    [MenuItem("Tools/Art/GenMaterialInfo", false, 1000)] //生成Assets/mesh_info.txt
    static void GenMaterialInfo()
    {
        List<string> rslt = new List<string>();
        var allAssets = AssetDatabase.GetAllAssetPaths();
        //allAssets = new string[] { "Assets/GameAssets/fish_100000372/Mat/T_daoguang_06.mat" };
        for (int i = 0; i < allAssets.Length; i++)
        {
            var assetPath = allAssets[i];
            if (!assetPath.EndsWith(".mat"))
                continue;

            Material material = AssetDatabase.LoadAssetAtPath(assetPath, typeof(Material)) as Material;
            string[] names = material.GetTexturePropertyNames();
            for (int j = 0; j < names.Length; j++)
            {
                string texName = names[j];

                if (material.shader.FindPropertyIndex(texName) == -1)
                    continue;


                var shaderName = material.shader.name;

                var path = "null";
                var texture = material.GetTexture(texName);
                if (texture != null)
                    path = AssetDatabase.GetAssetPath(texture);

                rslt.Add(string.Format("SHD:%s PTH:%s TEX:%s MAT:%s", shaderName, path, texName, assetPath));
            }
            //material.shader.GetPropertyTextureDefaultName()
        }

        string tex = string.Join("\n", rslt.ToArray());
        File.WriteAllLines(Path.Combine(Application.dataPath, "../tex_check.txt"), rslt.ToArray());
    }

    [MenuItem("Tools/Art/GenMeshInfo", false, 1000)] //生成Assets/mesh_info.txt
    static void GenMeshInfo()
    {
        List<tagMeshInfo> list = new List<tagMeshInfo>();
        string dir = Application.dataPath + "/GameData";
        DirectoryInfo directoryInfo = new DirectoryInfo(dir);
        var array = directoryInfo.GetFiles("*.fbx", SearchOption.AllDirectories);
        Debug.Log(array.Length);
        for (int i = 0; i < array.Length; i++)
        {
            var fileinfo = array[i];
            var fullname = fileinfo.FullName.Replace("\\", "/");
            var path = fullname.Replace(dir, "Assets/GameData");
            var mesh = AssetDatabase.LoadAssetAtPath<Mesh>(path);
            if (mesh)
            {
                var info = new tagMeshInfo();
                info.path = path.Replace("Assets/GameData/", "");
                info.count = mesh.triangles.Length / 3;
                list.Add(info);
                Debug.Log(string.Format("%s %s", info.path, info.count));
            }
        }

        //list.Sort((a, b) => { return b.count - a.count;});
        List<string> rslt = new List<string>();
        for (int i = 0; i < list.Count; i++)
        {
            string message = string.Format("{0},{1}", list[i].path, list[i].count);
            rslt.Add(message);
        }

        var str_rslt = String.Join("\n", rslt.ToArray());
        string savePath = "Assets/mesh_info.csv";
        File.WriteAllText(savePath, str_rslt);
        Debug.Log("导出成功");
    }


    //打开窗口
    [MenuItem("Window/Reference Finder", false, 1000)]
    static void OpenWindow()
    {
        ReferenceFinderWindow window = GetWindow<ReferenceFinderWindow>();
        window.wantsMouseMove = false;
        window.titleContent = new GUIContent("Ref Finder");
        window.Show();
        window.Focus();
    }

    //初始化数据
    static void InitDataIfNeeded()
    {
        if (!initializedData)
        {
            //初始化数据
            if (!m_data.ReadFromCache())
            {
                m_data.CollectDependenciesInfo();
            }

            initializedData = true;
        }
    }

    //初始化GUIStyle
    void InitGUIStyleIfNeeded()
    {
        if (!initializedGUIStyle)
        {
            toolbarButtonGUIStyle = new GUIStyle("ToolbarButton");
            toolbarGUIStyle = new GUIStyle("Toolbar");
            initializedGUIStyle = true;
        }
    }

    void SelectInvalidDependcy()
    {
        m_selectedAssetGuidList.Clear();
        m_selectedAssetGuidList.AddRange(DependInfo.GetInvalidDependInfo(m_data));
        needUpdateAssetTree = true;
    }

    private void selectNotRefTextures()
    {
        m_selectedAssetGuidList.Clear();
        m_selectedAssetGuidList.AddRange(m_data.getNoRefTextures());
        needUpdateAssetTree = true;
    }

    private void getMatRefTextures()
    {
        Dictionary<string, List<string>> sameHashTextures = m_data.getDupTextures();
        var root = mapToTvRoot(sameHashTextures, ViewType.DUP_TEX);
        updateTreeView(root);
        m_AssetTreeView.hashTextures = sameHashTextures;
        needUpdateAssetTree = false;
    }

    private AssetViewItem mapToTvRoot(IDictionary<string, List<string>> selectedAssetGuid, ViewType vt)
    {
        updatedAssetSet.Clear();
        int elementCount = 0;
        var root = new AssetViewItem { id = elementCount, depth = -1, displayName = "Root", data = null };
        int depth = 0;
        var stack = new Stack<string>();

        foreach (var itm in selectedAssetGuid.OrderByDescending(x => x.Value.Count()))
        {
            string hash = itm.Key;
            List<string> textureGUIDList = itm.Value;
            if (textureGUIDList.Count == 1)
                continue;

            var hashRefCount = 0;
            for (int i = 0; i < textureGUIDList.Count; i++)
            {
                var childGuid = textureGUIDList[i];
                if (m_data.m_assetDict[childGuid].references.Count == 0)
                    continue;
                hashRefCount++;
            }

            if (hashRefCount == 0)
                continue;

            elementCount++;

            var hashRoot = new AssetViewItem
            {
                vtype = vt,
                type = TVItemType.HASH,
                hash = hash,
                id = elementCount,
                depth = depth,
                displayName = textureGUIDList.Count + "",
                data = null,
                sub_data = textureGUIDList
            };

            root.AddChild(hashRoot);

            for (int i = 0; i < textureGUIDList.Count; i++)
            {
                var childGuid = textureGUIDList[i];
                var child = CreateTree(childGuid, ref elementCount, depth + 1, stack);
                if (child != null)
                    hashRoot.AddChild(child);
            }
        }

        updatedAssetSet.Clear();
        return root;
    }

    //更新选中资源列表
    private void UpdateSelectedAssets()
    {
        m_selectedAssetGuidList.Clear();
        foreach (var obj in Selection.objects)
        {
            string path = AssetDatabase.GetAssetPath(obj);

            if (Directory.Exists(path))
            {
                //如果是文件夹
                string[] folder = new string[] { path };
                //将文件夹下所有资源作为选择资源
                string[] guids = AssetDatabase.FindAssets(null, folder);
                foreach (var guid in guids)
                {
                    if (!m_selectedAssetGuidList.Contains(guid) &&
                        !Directory.Exists(AssetDatabase.GUIDToAssetPath(guid)))
                    {
                        m_selectedAssetGuidList.Add(guid);
                    }
                }
            }
            else
            {
                //如果是文件资源
                string guid = AssetDatabase.AssetPathToGUID(path);
                m_selectedAssetGuidList.Add(guid);
            }
        }

        needUpdateAssetTree = true;
    }

    //通过选中资源列表更新TreeView
    private void UpdateAssetTree()
    {
        if (needUpdateAssetTree && m_selectedAssetGuidList.Count != 0)
        {
            var root = SelectedAssetGuidToRootItem(m_selectedAssetGuidList);
            updateTreeView(root);
            needUpdateAssetTree = false;
        }
    }

    private void updateTreeView(AssetViewItem root)
    {
        if (m_AssetTreeView == null)
        {
            //初始化TreeView
            if (m_TreeViewState == null)
                m_TreeViewState = new TreeViewState();
            var headerState = AssetTreeView.CreateDefaultMultiColumnHeaderState(position.width);
            var multiColumnHeader = new MultiColumnHeader(headerState);
            m_AssetTreeView = new AssetTreeView(m_TreeViewState, multiColumnHeader);
        }

        m_AssetTreeView.assetRoot = root;
        m_AssetTreeView.CollapseAll();
        m_AssetTreeView.Reload();
    }

    private void OnEnable()
    {
        m_isDepend = PlayerPrefs.GetInt(isDependPrefKey, 0) == 1;
        m_needUpdateState = PlayerPrefs.GetInt(needUpdateStatePrefKey, 1) == 1;
    }

    private void OnGUI()
    {
        InitGUIStyleIfNeeded();
        DrawOptionBar();
        UpdateAssetTree();
        if (m_AssetTreeView != null)
        {
            //绘制Treeview
            m_AssetTreeView.OnGUI(new Rect(0, toolbarGUIStyle.fixedHeight, position.width,
                position.height - toolbarGUIStyle.fixedHeight));
        }
    }

    //绘制上条
    public void DrawOptionBar()
    {
        EditorGUILayout.BeginHorizontal(toolbarGUIStyle);
        //刷新数据
        if (GUILayout.Button("Refresh Data", toolbarButtonGUIStyle))
        {
            m_data.CollectDependenciesInfo();
            needUpdateAssetTree = true;
            EditorGUIUtility.ExitGUI();
        }

        //修改模式
        bool PreIsDepend = m_isDepend;
        m_isDepend = GUILayout.Toggle(m_isDepend, m_isDepend ? "依赖显示中" : "引用显示中", toolbarButtonGUIStyle,
            GUILayout.Width(100));
        if (PreIsDepend != m_isDepend)
        {
            OnModelSelect();
        }

        //是否需要更新状态
        bool PreNeedUpdateState = m_needUpdateState;
        m_needUpdateState = GUILayout.Toggle(m_needUpdateState, "Need Update State", toolbarButtonGUIStyle);
        if (PreNeedUpdateState != m_needUpdateState)
        {
            PlayerPrefs.SetInt(needUpdateStatePrefKey, m_needUpdateState ? 1 : 0);
        }

        if (GUILayout.Button("没引用的贴图", toolbarButtonGUIStyle))
        {
            selectNotRefTextures();
        }

        if (GUILayout.Button("CommonRef1", toolbarButtonGUIStyle))
        {
            //通用贴图 单次引用
            listCommonRef1();
        }

        if (GUILayout.Button("重复贴图替换", toolbarButtonGUIStyle))
        {
            getMatRefTextures();
        }

        if (GUILayout.Button("字体引用情况", toolbarButtonGUIStyle))
        {
            string savePath = "Assets/font_info.csv";
            m_data.genRefInfo("fontsettings", savePath);
        }


        if (GUILayout.Button("FBX RW检查", toolbarButtonGUIStyle))
        {
            CheckFBXRW();
        }

        GUILayout.FlexibleSpace();

        //扩展
        if (GUILayout.Button("Expand", toolbarButtonGUIStyle))
        {
            if (m_AssetTreeView != null) m_AssetTreeView.ExpandAll();
        }

        //折叠
        if (GUILayout.Button("Collapse", toolbarButtonGUIStyle))
        {
            if (m_AssetTreeView != null) m_AssetTreeView.CollapseAll();
        }

        EditorGUILayout.EndHorizontal();
    }

    void CheckFBXRW()
    {
        m_selectedAssetGuidList.Clear();
        m_data.CollectDependenciesInfo();
        foreach (var key in m_data.m_assetDict)
        {
            var info = key.Value;
            string path = key.Value.path;
            int idx = path.IndexOf(AssetsCheckerUtils.CheckPath);
            if (idx < 0)
            {
                continue;
            }
            string ext = Path.GetExtension(path);
            if (ext.ToLower() != ".fbx")
            {
                continue;
            }
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            var meshRenders = go.GetComponentsInChildren<MeshRenderer>();
            if (meshRenders.Length == 0)
            {
                continue;
            }
            
            var importer = AssetImporter.GetAtPath(path) as ModelImporter;
            if (importer.isReadable)
            {
                continue;
            }
            Debug.Log($"{path} {meshRenders.Length} {importer.isReadable}");
            m_selectedAssetGuidList.Add(key.Key);
            importer.isReadable = true;
            importer.SaveAndReimport();
        }
        needUpdateAssetTree = true;
    }

    private void listCommonRef1()
    {
        SortedDictionary<string, List<string>> sameHashTextures = m_data.getCommonRef1();
        var root = mapToTvRoot(sameHashTextures, ViewType.COMMON_1REF);
        updateTreeView(root);
        m_AssetTreeView.hashTextures = sameHashTextures;
        needUpdateAssetTree = false;
    }

    private void OnModelSelect()
    {
        needUpdateAssetTree = true;
        PlayerPrefs.SetInt(isDependPrefKey, m_isDepend ? 1 : 0);
    }


    //生成root相关
    private HashSet<string> updatedAssetSet = new HashSet<string>();

    //通过选择资源列表生成TreeView的根节点
    private AssetViewItem SelectedAssetGuidToRootItem(List<string> selectedAssetGuid)
    {
        updatedAssetSet.Clear();
        int elementCount = 0;
        var root = new AssetViewItem { id = elementCount, depth = -1, displayName = "Root", data = null };
        int depth = 0;
        var stack = new Stack<string>();
        foreach (var childGuid in selectedAssetGuid)
        {
            var child = CreateTree(childGuid, ref elementCount, depth, stack);
            if (child != null)
                root.AddChild(child);
        }

        updatedAssetSet.Clear();
        return root;
    }

    //通过每个节点的数据生成子节点
    private AssetViewItem CreateTree(string guid, ref int elementCount, int _depth, Stack<string> stack)
    {
        if (stack.Contains(guid))
            return null;

        AssetViewItem root = null;

        stack.Push(guid);
        if (m_needUpdateState && !updatedAssetSet.Contains(guid))
        {
            m_data.UpdateAssetState(guid);
            updatedAssetSet.Add(guid);
        }

        ++elementCount;
        if (m_data.m_assetDict.ContainsKey(guid))
        {
            var referenceData = m_data.m_assetDict[guid];
            root = new AssetViewItem
            { id = elementCount, displayName = referenceData.name, data = referenceData, depth = _depth };
            var childGuids = m_isDepend ? referenceData.dependencies : referenceData.references;
            foreach (var childGuid in childGuids)
            {
                var child = CreateTree(childGuid, ref elementCount, _depth + 1, stack);
                if (child != null)
                    root.AddChild(child);
            }
        }
        else
        {
            var guidToAssetPath = AssetDatabase.GUIDToAssetPath(guid);
            Debug.Log("GUID not in assetDict " + guidToAssetPath);
        }

        stack.Pop();
        return root;
    }
}