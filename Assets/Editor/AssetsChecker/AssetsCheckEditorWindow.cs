
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;


public class AssetsCheckEditorWindow : EditorWindow
{
    public static string Asset_Search_Path { get { return "Assets/" + _searchPath; } }
    public static readonly string[] Texture_Types = new string[] { ".png", ".jpg", ".bmp", ".gif", ".tga", ".svg", ".psd" };
    public static readonly string[] Audio_Types = new string[] { ".mp3", ".ogg", ".wav" };
    public static readonly string[] Anim_Types = new string[] { ".anim", ".fbx" };
    public static readonly string Model_Type = ".fbx";
    public static readonly string Material_Type = ".mat";
    public static readonly string Sprite_Atlas_Type = ".spriteatlas";
    public static readonly string Shader_Type = ".shader";
    public static readonly string Prefab_Type = ".prefab";


    private static string _searchPath = "GameData";

    [MenuItem("Tools/资源检查", false)]
    private static void DoIt()
    {
        var window = GetWindow<AssetsCheckEditorWindow>();
        window.titleContent = new GUIContent("资源检查");
        window.minSize      = new Vector2(1000, 800);
        window.Show();
    }

    private void OnGUI()
    {
        EditorGUILayout.BeginVertical();

        EditorGUILayout.Space();
        _searchPath = EditorGUILayout.TextField("检测路径：Assets/", _searchPath);
        EditorGUILayout.Space();

        // 音频检测
        _ShowAudioWindow();

        // 模型fbx资源
        _ShowModeResWindow();

        // 材质球资源
        _ShowMaterialWindow();

        // 纹理图片
        _ShowBigPictureWindow();

        // 合图资源
        _ShowSpriteAtlasWindow2();

        // Shader资源
        _ShowShaderWindow();

        // 动画资源
        _ShowAnimZipWindow();

        // 预制模型面数
        _ShowModelStandardWindow();

        // 预制阴影开关
        _ShowPrefabMeshWindow();

        // 预制实例耗时
        _ShowPrefabInstantiateWindow();

        // 预制粒子
        _ShowPrefabParticleWindow();

        // 预制Raycast
        _ShowPrefabUIWindow();

        // 预制嵌套层级
        _ShowPrefabMaxLayersWindow();

        // AB冗余
        _ShowAssetBundleRedundanceWindow();

        // 资源重复
        _ShowRepeatResWindow();

        // Mesh重复
        _ShowRepeatMeshWindow();

        // 未被引用资源
        _ShowUnuseResWindow();

        EditorGUILayout.EndVertical();
    }

    private void _ShowAudioWindow()
    {
        if (GUILayout.Button(AudioCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var audioTab = GetWindow<AudioCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            audioTab.Show();
        }
    }

    private void _ShowModelStandardWindow()
    {
        if (GUILayout.Button(ModelFaceCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var modelFaceTab = GetWindow<ModelFaceCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            modelFaceTab.Show();
        }
    }

    private void _ShowModeResWindow()
    {
        if (GUILayout.Button(ModelCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var modelTab = GetWindow<ModelCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            modelTab.Show();
        }
    }

    private void _ShowPrefabMeshWindow()
    {
        if (GUILayout.Button(PrefabMeshCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var prefabMeshTab = GetWindow<PrefabMeshCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabMeshTab.Show();
        }
    }

    private void _ShowBigPictureWindow()
    {
        if (GUILayout.Button(BigPicCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var bigPicTab = GetWindow<BigPicCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            bigPicTab.Show();
        }
    }

    private void _ShowSpriteAtlasWindow2()
    {
        if (GUILayout.Button(AtlasCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var atlasTab = GetWindow<AtlasCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            atlasTab.Show();
        }
    }

    private void _ShowPrefabInstantiateWindow()
    {
        if (GUILayout.Button(PrefabInstantiateTimeCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            _Collect();
            var prefabInstantiateTimeTab = GetWindow<PrefabInstantiateTimeCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabInstantiateTimeTab.Show();
        }
    }

    private void _ShowPrefabParticleWindow()
    {
        if (GUILayout.Button(PrefabParticleCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var prefabParticleTab = GetWindow<PrefabParticleCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabParticleTab.Show();
        }
    }

    private void _ShowPrefabUIWindow()
    {
        if (GUILayout.Button(PrefabUICheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var prefabUITab = GetWindow<PrefabUICheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabUITab.Show();
        }
    }

    private void _ShowPrefabMaxLayersWindow()
    {
        if (GUILayout.Button(PrefabHierarchyCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var prefabHierarchyTab = GetWindow<PrefabHierarchyCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabHierarchyTab.Show();
        }
    }

    private void _ShowMaterialWindow()
    {
        if (GUILayout.Button(MaterialCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var materialTab = GetWindow<MaterialCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            materialTab.Show();
        }
    }

    private void _ShowShaderWindow()
    {
        if (GUILayout.Button(ShaderCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var prefabShaderTab = GetWindow<ShaderCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            prefabShaderTab.Show();
        }
    }

    private void _ShowAssetBundleRedundanceWindow()
    {
        if (GUILayout.Button(PrefabRedundanceCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var refabRedundanceTab = GetWindow<PrefabRedundanceCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            refabRedundanceTab.Show();
        }
    }

    private void _ShowRepeatResWindow()
    {
        if (GUILayout.Button(RepeatResourceCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var refabRedundanceTab = GetWindow<RepeatResourceCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            refabRedundanceTab.Show();
        }
    }

    private void _ShowRepeatMeshWindow()
    {
        if (GUILayout.Button(RepeatMeshEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var refabRedundanceTab = GetWindow<RepeatMeshEditorWindow>(typeof(AssetsCheckEditorWindow));
            refabRedundanceTab.Show();
        }
    }

    private void _ShowUnuseResWindow()
    {
        if (GUILayout.Button(UnreferencedResourceCheckEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var unreferencedTab = GetWindow<UnreferencedResourceCheckEditorWindow>(typeof(AssetsCheckEditorWindow));
            unreferencedTab.Show();
        }
    }

    private void _ShowAnimZipWindow()
    {
        if (GUILayout.Button(AnimAssetEditorWindow.Title, GUILayout.Width(100), GUILayout.Height(40)))
        {
            var unreferencedTab = GetWindow<AnimAssetEditorWindow>(typeof(AssetsCheckEditorWindow));
            unreferencedTab.Show();
        }
    }

    /// <summary>
    /// 垃圾回收
    /// </summary>
    /// <returns></returns>
    private static void _Collect()
    {
        AssetDatabase.ReleaseCachedFileHandles();
        GC.Collect();
        //EditorSceneManager.OpenScene("Assets/Scenes/GameScene/EntryScene.unity");
        AssetDatabase.Refresh();
    }
}
