using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;

public enum ViewType {
    NONE,
    COMMON_1REF, //通用目录资源 只有一次引用
    DUP_TEX //重复贴图替换
}

public enum TVItemType {
    NONE,
    Asset,
    HASH
}

//带数据的TreeViewItem
public class AssetViewItem : TreeViewItem {
    public ViewType vtype = ViewType.NONE;
    public TVItemType type = TVItemType.NONE;
    public string hash;
    public ReferenceFinderData.AssetDescription data;

    public AssetViewItem() {
    }

    public List<string> sub_data;
}

//资源引用树
public class AssetTreeView : TreeView {
    //图标宽度
    const float kIconWidth = 18f;

    //列表高度
    const float kRowHeights = 20f;
    public AssetViewItem assetRoot;

    private GUIStyle stateGUIStyle = new GUIStyle { richText = true, alignment = TextAnchor.MiddleCenter };
    public IDictionary<string, List<string>> hashTextures;


    enum MyColumns {
        //列信息
        Name,
        Path,
        State,
    }

    public AssetTreeView(TreeViewState state, MultiColumnHeader multicolumnHeader) : base(state, multicolumnHeader) {
        rowHeight = kRowHeights;
        columnIndexForTreeFoldouts = 0;
        showAlternatingRowBackgrounds = true;
        showBorder = false;
        customFoldoutYOffset =
            (kRowHeights - EditorGUIUtility.singleLineHeight) *
            0.5f; // center foldout in the row since we also center content. See RowGUI
        extraSpaceBeforeIconAndLabel = kIconWidth;
    }

    //响应右击事件
    protected override void ContextClickedItem(int id) {
        var item = (AssetViewItem)FindItem(id, rootItem);
        if (item == null)
            return;

        GenericMenu menu = new GenericMenu();
        if (item.sub_data != null) {
            if (item.vtype == ViewType.COMMON_1REF) {
                menu.AddItem(new GUIContent("移到对应目录mul"), false, MoveToMul, item);
            }
        }

        if (item.data != null) {
            menu.AddItem(new GUIContent("Copy Path"), false, x => {
                // var assetViewItem = (x as AssetViewItem);

                var selection = this.GetSelection();
                List<string> rslt = new List<string>();
                for (int i = 0; i < selection.Count; i++) {
                    var selId = selection[i];
                    var findItem = this.FindItem(selId, item.parent) as AssetViewItem;
                    rslt.Add(findItem.data.path);
                }

                RefUtil.clipboard = string.Join("\n", rslt.ToArray());
            }, item);

            menu.AddItem(new GUIContent("Delete Asset"), false, x => {
                var selection = this.GetSelection();
                List<string> rslt = new List<string>();
                for (int i = 0; i < selection.Count; i++) {
                    var selId = selection[i];
                    var findItem = this.FindItem(selId, item.parent) as AssetViewItem;
                    AssetDatabase.DeleteAsset(findItem.data.path);
                    rslt.Add(findItem.data.path);
                }
            }, item);

            var treeViewItem = item.parent as AssetViewItem;
            if (treeViewItem != null) {
                switch (treeViewItem.vtype) {
                    case ViewType.DUP_TEX:
                        menu.AddItem(new GUIContent("用这个贴图替换其他贴图"), false, ReplaceOtherMaterial, item);
                        break;
                    // case ViewType.COMMON_1REF:
                    //     menu.AddItem(new GUIContent("移到对应目录"), false, MoveTo, item);
                    //     break;
                }
            }

            var assetObject = AssetDatabase.LoadAssetAtPath(item.data.path, typeof(UnityEngine.Object));
            var isMat = assetObject is UnityEngine.Material;
            if (isMat) {
                menu.AddItem(new GUIContent("ChangeShader"), false, ChangeShader, assetObject);
                menu.AddItem(new GUIContent("SetCompileKeyByTextureState"), false, SetCompileKeyByTextureState, item);
            }
        }

        if (menu.GetItemCount() > 0)
            menu.ShowAsContext();
        else {
            SetExpanded(id, !IsExpanded(id));
        }
    }

    void MoveToMul(object context) {
        var selection = this.GetSelection();

        for (int i = 0; i < selection.Count; i++) {
            var selId = selection[i];
            var hash_node = this.FindItem(selId, this.assetRoot) as AssetViewItem;

            foreach (string key in hash_node.sub_data) {
                var assetDescription = ReferenceFinderWindow.m_data.m_assetDict[key];
                var common_src = assetDescription.path;
                var fileName = Path.GetFileName(common_src);
                // Path.GetDirectoryName(assetDescriptionPath)

                string targetFolder = hash_node.hash;
                string target = Path.Combine(targetFolder, fileName);
                AssetDatabase.MoveAsset(common_src, target);

                Debug.Log(string.Format("move %s to %s", common_src, target));
            }
        }
    }

    void MoveTo(object context) {
    }

    void ReplaceOtherMaterial(object context) {
        var item = (AssetViewItem)context;
        var hashNode = item.parent as AssetViewItem;
        var hash = hashNode.hash;

        var dataPath = item.data.path;
        var texture = RefUtil.getTexture(dataPath);

        List<string> textureGUIDList = hashTextures[hash];
        for (int i = 0; i < textureGUIDList.Count; i++) {
            var guid = textureGUIDList[i];
            string path = AssetDatabase.GUIDToAssetPath(guid);
            if (path == dataPath)
                continue;

            var references = ReferenceFinderWindow.m_data.m_assetDict[guid].references;
            for (int j = 0; j < references.Count; j++) {
                var reference = references[j];
                var guidToAssetPath = AssetDatabase.GUIDToAssetPath(reference);
                var ext = RefUtil.getExt(guidToAssetPath);
                if (ext != ".mat")
                    continue;

                var material = AssetDatabase.LoadAssetAtPath<Material>(guidToAssetPath);
                var texIds = material.GetTexturePropertyNameIDs();
                for (int k = 0; k < texIds.Length; k++) {
                    var texId = texIds[k];
                    var texture1 = material.GetTexture(texId);
                    if (texture1 == null)
                        continue;

                    if (texture1.imageContentsHash.ToString() == hash) {
                        material.SetTexture(texId, texture);
                    }
                }
            }
            Debug.Log($"delete path {path}");
            AssetDatabase.DeleteAsset(path);
        }
    }

    void SetCompileKeyByTextureState(object context) {
        //根据贴图设置宏定义
        var item = (AssetViewItem)context;

        var selection = this.GetSelection();
        for (int i = 0; i < selection.Count; i++) {
            var selId = selection[i];
            var findItem = this.FindItem(selId, item.parent) as AssetViewItem;

            string matPath = findItem.data.path;
            var material = AssetDatabase.LoadAssetAtPath<Material>(matPath);

            if (material.GetTexture("_TexMask1") == null) {
                material.SetFloat("_MainMaskOn", 0);
                material.DisableKeyword("_MAINMASK_ON");
            }
            else {
                material.SetFloat("_MainMaskOn", 1);
                material.EnableKeyword("_MAINMASK_ON");
            }

            if (material.GetFloat("_Metallic") == 0 &&
                material.GetFloat("_EnableMetal") == 0
                //material.GetTexture("_TexMask1") == null
            ) {
                material.SetFloat("_EnableMatCap2", 0);
                material.DisableKeyword("_MATCAP2_ON");
            }
            else {
                material.SetFloat("_EnableMatCap2", 1);
                material.EnableKeyword("_MATCAP2_ON");
            }

            if (material.GetTexture("_TexMask2") == null) {
                material.SetFloat("_SubMaskOn", 0);
                material.DisableKeyword("_SUBMASK_ON");
            }
            else {
                material.SetFloat("_SubMaskOn", 1);
                material.EnableKeyword("_SUBMASK_ON");
            }
        }
    }

    void ChangeShader(object context) {
        InputPath.Init(doChangeShader);
    }


    void doChangeShader(string path) {
        //var path = "Fish/ShaderGraph_Role";

        var materialShader = Shader.Find(path);
        if (materialShader == null)
            return;
        var selectedIDs = this.state.selectedIDs;
        for (int i = 0; i < selectedIDs.Count; i++) {
            var stateSelectedID = selectedIDs[i];
            var item = (AssetViewItem)FindItem(stateSelectedID, rootItem);

            var assetObject = AssetDatabase.LoadAssetAtPath(item.data.path, typeof(UnityEngine.Object));
            var isMat = assetObject is UnityEngine.Material;
            if (isMat) {
                var material = assetObject as UnityEngine.Material;
                // material.shader = Shader.Find("Shader Graphs/FishShaderGraph_Role");

                material.shader = materialShader;
                var assetPath = AssetDatabase.GetAssetPath(material);

                Debug.Log("Shader Changed " + assetPath);
            }
        }

        AssetDatabase.SaveAssets();

        // var selectedNodes = context as List<AssetBundleModel.BundleTreeItem>;
        // if (selectedNodes != null && selectedNodes.Count > 0)
        // {
        //     folder = selectedNodes[0].bundle as AssetBundleModel.BundleFolderConcreteInfo;
        // }
        // CreateBundleUnderParent(folder);
    }

    //响应双击事件
    protected override void DoubleClickedItem(int id) {
        var item = (AssetViewItem)FindItem(id, rootItem);
        //在ProjectWindow中高亮双击资源
        if (item == null)
            return;
        if (item.data == null)
            return;

        var assetObject = AssetDatabase.LoadAssetAtPath(item.data.path, typeof(UnityEngine.Object));
        EditorUtility.FocusProjectWindow();
        Selection.activeObject = assetObject;
        EditorGUIUtility.PingObject(assetObject);
    }

    //生成ColumnHeader
    public static MultiColumnHeaderState CreateDefaultMultiColumnHeaderState(float treeViewWidth) {
        var columns = new[] {
            //图标+名称
            new MultiColumnHeaderState.Column {
                headerContent = new GUIContent("Name"),
                headerTextAlignment = TextAlignment.Center,
                sortedAscending = false,
                width = 200,
                minWidth = 60,
                autoResize = false,
                allowToggleVisibility = false,
                canSort = false
            },
            //路径
            new MultiColumnHeaderState.Column {
                headerContent = new GUIContent("Path"),
                headerTextAlignment = TextAlignment.Center,
                sortedAscending = false,
                width = 360,
                minWidth = 60,
                autoResize = false,
                allowToggleVisibility = false,
                canSort = false
            },
            //状态
            new MultiColumnHeaderState.Column {
                headerContent = new GUIContent("State"),
                headerTextAlignment = TextAlignment.Center,
                sortedAscending = false,
                width = 60,
                minWidth = 60,
                autoResize = false,
                allowToggleVisibility = true,
                canSort = false
            },
        };
        var state = new MultiColumnHeaderState(columns);
        return state;
    }

    protected override TreeViewItem BuildRoot() {
        return assetRoot;
    }

    protected override void RowGUI(RowGUIArgs args) {
        var item = (AssetViewItem)args.item;
        for (int i = 0; i < args.GetNumVisibleColumns(); ++i) {
            CellGUI(args.GetCellRect(i), item, (MyColumns)args.GetColumn(i), ref args);
        }
    }

    void CellGUI(Rect cellRect, AssetViewItem item, MyColumns column, ref RowGUIArgs args) {
        //绘制列表中的每项内容
        CenterRectUsingSingleLineHeight(ref cellRect);
        var assetDescription = item.data;
        switch (column) {
            case MyColumns.Name: {
                var iconRect = cellRect;
                iconRect.x += GetContentIndent(item);
                iconRect.width = kIconWidth;
                if (iconRect.x < cellRect.xMax) {
                    var icon = assetDescription == null ? null : GetIcon(assetDescription.path);
                    if (icon != null)
                        GUI.DrawTexture(iconRect, icon, ScaleMode.ScaleToFit);
                }

                args.rowRect = cellRect;
                base.RowGUI(args);
            }
                break;
            case MyColumns.Path: {
                GUI.Label(cellRect, item.type == TVItemType.HASH ? item.hash : assetDescription.path);
            }
                break;
            case MyColumns.State: {
                if (assetDescription != null)
                    GUI.Label(cellRect, ReferenceFinderData.GetInfoByState(assetDescription.state), stateGUIStyle);
            }
                break;
        }
    }

    //根据资源信息获取资源图标
    private Texture2D GetIcon(string path) {
        Object obj = AssetDatabase.LoadAssetAtPath(path, typeof(Object));
        if (obj != null) {
            Texture2D icon = AssetPreview.GetMiniThumbnail(obj);
            if (icon == null)
                icon = AssetPreview.GetMiniTypeThumbnail(obj.GetType());
            return icon;
        }

        return null;
    }
}