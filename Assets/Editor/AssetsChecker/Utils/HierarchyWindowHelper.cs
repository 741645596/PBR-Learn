using System;
using System.Reflection;
using UnityEditor;
using UnityEditor.Experimental.SceneManagement;
using UnityEngine;

public static class HierarchyWindowHelper
{
    /// <summary>
    /// 展开Hierarchy窗口的所有节点
    /// </summary>
    public static void ExpandAllObject()
    {
        var stage = PrefabStageUtility.GetCurrentPrefabStage();
        if (stage == null)
        {
            return;
        }

        var root = stage.prefabContentsRoot;
        if (root == null)
        {
            return;
        }

        SetExpandedRecursive(root, true);
    }

    public static void SetExpandedRecursive(GameObject go, bool expand)
    {
        object sceneHierarchy = GetSceneHierarchy();

        MethodInfo methodInfo = sceneHierarchy
            .GetType()
            .GetMethod("SetExpandedRecursive", BindingFlags.Public | BindingFlags.Instance);

        methodInfo.Invoke(sceneHierarchy, new object[] { go.GetInstanceID(), expand });
    }

    private static object GetSceneHierarchy()
    {
        EditorWindow window = GetHierarchyWindow();

        object sceneHierarchy = typeof(EditorWindow).Assembly
            .GetType("UnityEditor.SceneHierarchyWindow")
            .GetProperty("sceneHierarchy")
            .GetValue(window);

        return sceneHierarchy;
    }

    private static EditorWindow GetHierarchyWindow()
    {
        // For it to open, so that it the current focused window.
        EditorApplication.ExecuteMenuItem("Window/General/Hierarchy");
        return EditorWindow.focusedWindow;
    }

}
