using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text.RegularExpressions;
using UnityEngine.Rendering;
using System;

// 自定义效果 - 折叠开始标识
internal class FoldoutDrawer : MaterialPropertyDrawer
{
    bool showPosition;
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        showPosition = EditorGUILayout.BeginFoldoutHeaderGroup(showPosition, label);
        prop.floatValue = Convert.ToSingle(showPosition);
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        //var height = base.GetPropertyHeight(prop, label, editor);
        return 0;
    }
}

/*
Properties
{
    [HDR] _Color("主颜色", Color) = (1,1,1,1)
    [Enum(UnityEngine.Rendering.BlendMode)] _MySrcMode ("SrcMode", Float) = 5
    [Enum(UnityEngine.Rendering.BlendMode)] _MyDstMode ("DstMode", Float) = 10
    [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2

    [Foldout] _DistortFoldout("扰动面板", Range (0, 1)) = 0
    [FoldoutItem] [Toggle] Distort("开启扰动", Float) = 0
    [Space]
    [FoldoutItem] [NoScaleOffset] _DistortTex("扰动贴图", 2D) = "white" {}
    [FoldoutItem] _DistortAmount("扰动强度", Range(0, 2)) = 0.5

    [HideInInspector] _Surface("__surface", Float) = 0.0
    [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}
}
1、官方默认支持的标签参考：https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
2、[Foldout] [FoldoutItem] 是自定义标签，其他都是官方的
*/
/// <summary>
/// 支持折叠的Shader GUI
/// </summary>
public class FoldoutShaderGUI : ShaderGUI
{
    private static bool _HasAttribute(string[] attributes, string attr)
    {
        foreach (var attribute in attributes)
        {
            if (attribute == attr)
            {
                return true;
            }
        }
        return false;
    }

    static List<MaterialProperty> s_List = new List<MaterialProperty>();
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _ShowDefaultBegin(materialEditor);

        // 自定义显示规则
        Shader shader = (materialEditor.target as Material).shader;
        bool isShow = true;
        for (int i = 0; i < properties.Length; i++)
        {
            var attributes = shader.GetPropertyAttributes(i);
            var propertie = properties[i];

            if (_HasAttribute(attributes, "Foldout"))
            {
                _ShowPropertiesGUI(materialEditor, propertie);
                isShow = propertie.floatValue != 0;
            }
            else if (_HasAttribute(attributes, "FoldoutItem"))
            {
                if (isShow)
                {
                    EditorGUI.indentLevel++;
                    _ShowPropertiesGUI(materialEditor, propertie);
                    EditorGUI.indentLevel--;
                }
            }
            else
            {
                isShow = true;
                _ShowPropertiesGUI(materialEditor, propertie);
            }
        }

        // 显示Render Queue等
        _ShowDefaultEnd(materialEditor);
    }

    private static int s_ControlHash = "EditorTextField".GetHashCode();
    private static void _ShowDefaultBegin(MaterialEditor materialEditor)
    {
        var f = materialEditor.GetType().GetField("m_InfoMessage", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        if (f != null)
        {
            string m_InfoMessage = (string)f.GetValue(materialEditor);
            materialEditor.SetDefaultGUIWidths();
            if (m_InfoMessage != null)
            {
                EditorGUILayout.HelpBox(m_InfoMessage, MessageType.Info);
            }
            else
            {
                GUIUtility.GetControlID(s_ControlHash, FocusType.Passive, new Rect(0f, 0f, 0f, 0f));
            }
        }
    }

    private static void _ShowDefaultEnd(MaterialEditor materialEditor)
    {
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        if (SupportedRenderingFeatures.active.editableMaterialRenderQueue)
        {
            materialEditor.RenderQueueField();
        }

        // 暂时屏蔽，也不知道干什么用
        //materialEditor.EnableInstancingField();
        //materialEditor.DoubleSidedGIField();
    }

    private void _ShowPropertiesGUI(MaterialEditor materialEditor, MaterialProperty prop)
    {
        if ((prop.flags & (MaterialProperty.PropFlags.HideInInspector | MaterialProperty.PropFlags.PerRendererData)) == MaterialProperty.PropFlags.None)
        {
            float propertyHeight = materialEditor.GetPropertyHeight(prop, prop.displayName);
            Rect controlRect = EditorGUILayout.GetControlRect(true, propertyHeight, EditorStyles.layerMaskField);
            materialEditor.ShaderProperty(controlRect, prop, prop.displayName);
        }
    }

    
    
}