using System;
using UnityEditor;
using UnityEngine;

public class InputPath : EditorWindow {
    [MenuItem("Tools/Test")]
    public static void Init(Action<string> doChangeShader) {
        var window = ScriptableObject.CreateInstance<InputPath>();
        window.position = new Rect(Screen.width / 2, Screen.height / 2, 250, 150);
        window.titleContent.text = " Path settings ";
        window.callback = doChangeShader;
        window.ShowPopup();
    }

    public string Path;

    void OnGUI() {
        EditorGUILayout.LabelField("Path:");
        //Path = RelativeAssetPathTextField(Path, ".prefab");

        float num = 1; //TextFieldRoundEdge.CalcSize(new GUIContent("Assets/")).x - 2f;
        Rect position = EditorGUILayout.GetControlRect();
        Rect rect = position;
        rect.x += num;
        rect.y += 1f;
        rect.width -= num;

        GUIStyle guiStyle = new GUIStyle(EditorStyles.whiteLabel);
        guiStyle.normal.textColor = EditorStyles.textField.normal.textColor;
        guiStyle.normal.background = Texture2D.whiteTexture;
        Path = EditorGUI.TextField(rect, "Fish/FishShaderGraph_Little", guiStyle);

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("OK")) {
            this.Close();
            if(callback!=null)
                callback.Invoke(Path);
        }

        if (GUILayout.Button("Cancel"))
            this.Close();
        EditorGUILayout.EndHorizontal();
    }

    public Action<string> callback;

    public static GUIStyle TextFieldRoundEdge;
    public static GUIStyle TextFieldRoundEdgeCancelButton;
    public static GUIStyle TextFieldRoundEdgeCancelButtonEmpty;
    public static GUIStyle TransparentTextField;

    private string RelativeAssetPathTextField(string path, string extension) {
        if (TextFieldRoundEdge == null) {
            TextFieldRoundEdge = new GUIStyle("SearchTextField");
            TextFieldRoundEdgeCancelButton = new GUIStyle("SearchCancelButton");
            TextFieldRoundEdgeCancelButtonEmpty = new GUIStyle("SearchCancelButtonEmpty");
            TransparentTextField = new GUIStyle(EditorStyles.whiteLabel);
            TransparentTextField.normal.textColor = EditorStyles.textField.normal.textColor;
        }

        Rect position = EditorGUILayout.GetControlRect();
        GUIStyle textFieldRoundEdge = TextFieldRoundEdge;
        GUIStyle transparentTextField = TransparentTextField;
        GUIStyle gUIStyle = (path != "") ? TextFieldRoundEdgeCancelButton : TextFieldRoundEdgeCancelButtonEmpty;
        position.width -= gUIStyle.fixedWidth;
        if (Event.current.type == EventType.Repaint) {
            GUI.contentColor = (EditorGUIUtility.isProSkin ? Color.black : new Color(0f, 0f, 0f, 0.5f));
            textFieldRoundEdge.Draw(position, new GUIContent("Assets/"), 0);
            GUI.contentColor = Color.white;
        }

        Rect rect = position;
        float num = textFieldRoundEdge.CalcSize(new GUIContent("Assets/")).x - 2f;
        rect.x += num;
        rect.y += 1f;
        rect.width -= num;
        EditorGUI.BeginChangeCheck();
        path = EditorGUI.TextField(rect, path, transparentTextField);
        if (EditorGUI.EndChangeCheck()) {
            path = path.Replace('\\', '/');
        }

        if (Event.current.type == EventType.Repaint) {
            Rect position2 = rect;
            float num2 = transparentTextField.CalcSize(new GUIContent(path + ".")).x -
                         EditorStyles.whiteLabel.CalcSize(new GUIContent(".")).x;
            ;
            position2.x += num2;
            position2.width -= num2;
            GUI.contentColor = (EditorGUIUtility.isProSkin ? Color.black : new Color(0f, 0f, 0f, 0.5f));
            EditorStyles.label.Draw(position2, extension, false, false, false, false);
            GUI.contentColor = Color.white;
        }

        position.x += position.width;
        position.width = gUIStyle.fixedWidth;
        position.height = gUIStyle.fixedHeight;
        if (GUI.Button(position, GUIContent.none, gUIStyle) && path != "") {
            path = "";
            GUI.changed = true;
            GUIUtility.keyboardControl = 0;
        }

        return path;
    }
}