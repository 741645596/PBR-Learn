using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class MatcapShaderGUI : BaseShaderGUI
    {
        #region PROPERTIES & GUITEXT
        private GUIContent m_MatcapText = new GUIContent("Matcap Option");
        private MaterialProperty m_MatcapMapProp;
        private static GUIContent m_MatcapMapText = new GUIContent("Matcap Map(材质捕获贴图)");
        private MaterialProperty m_MatcapScaleProp;
        private static GUIContent m_MatcapScaleText = new GUIContent("Matcap Scale(材质捕获强度)");
        
        private MaterialProperty m_NormalMapProp;
        private static GUIContent m_NormalMapText = new GUIContent("Normal Map(法线贴图)");
        private MaterialProperty m_NormalScaleProp;
        private static GUIContent m_NormalScaleText = new GUIContent("Normal Scale(法线缩放系数)");

        private MaterialProperty m_NormalAnimProp;
        private static GUIContent m_NormalAnimText = new GUIContent("Normal Anim(法线动画 xyz:方向 z:速度)");

        private MaterialProperty m_NormalAnimToggleProp;
        private static GUIContent m_NormalAnimToggleText = new GUIContent("NormalAnim");

        private MaterialProperty m_UVScaleProp;
        private static GUIContent m_UVScaleText = new GUIContent("UV Scale(缩放)");

        private enum ColorBlendMode
        {
            Overlay,
            Multiply,
            Additive,
            SoftLight,
            PinLight,
            Lighten,
            Darken,
        };
        private MaterialProperty m_ColorBlendModeProp;
        private static GUIContent m_ColorBlendModeText = new GUIContent("Color Blend Mode(混合方式)");
        #endregion

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);

            m_MatcapMapProp = FindProperty("_MatcapMap", properties);
            m_MatcapScaleProp = FindProperty("_MatcapScale", properties);
            m_NormalMapProp = FindProperty("_NormalMap", properties);
            m_NormalScaleProp = FindProperty("_NormalScale", properties);
            m_ColorBlendModeProp = FindProperty("_ColorBlendMode", properties);

            m_NormalAnimToggleProp= FindProperty("_NormalAnimToggle", properties);
            m_NormalAnimProp = FindProperty("_NormalAnim", properties);

            m_UVScaleProp = FindProperty("_UVScale", properties);
        }

        public override void ShaderPropertiesGUI(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("Material is null.");
            }

            EditorGUI.BeginChangeCheck();
            base.ShaderPropertiesGUI(material);
            DrawMatcapGUI(material);
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material mat in m_MaterialEditor.targets)
                {
                    MaterialChanged(mat);
                }
            }
        }

        public override void SetupMaterialKeywords(Material material)
        {

            base.SetupMaterialKeywords(material);

            material.SetKeyword("ENABLE_MATCAP", m_MatcapMapProp.textureValue != null);
            material.SetKeyword("ENABLE_NORMALMAP", m_NormalMapProp.textureValue != null);
            material.SetKeyword("ENABLE_NORMALANIMTOGGLE", m_NormalAnimToggleProp.floatValue != 0);

            if (m_MatcapMapProp.textureValue != null)
            {
                material.DisableKeyword("MATCAP_OVERLAY");
                material.DisableKeyword("MATCAP_MULTIPLY");
                material.DisableKeyword("MATCAP_ADDITIVE");
                material.DisableKeyword("MATCAP_SOFTLIGHT");
                material.DisableKeyword("MATCAP_PINLIGHT");
                material.DisableKeyword("MATCAP_LIGHTEN");
                material.DisableKeyword("MATCAP_DARKEN");
                switch (m_ColorBlendModeProp.floatValue)
                {
                    case (int)ColorBlendMode.Overlay:
                        material.EnableKeyword("MATCAP_OVERLAY");
                        break;
                    case (int)ColorBlendMode.Multiply:
                        material.EnableKeyword("MATCAP_MULTIPLY");
                        break;
                    case (int)ColorBlendMode.Additive:
                        material.EnableKeyword("MATCAP_ADDITIVE");
                        break;
                    case (int)ColorBlendMode.SoftLight:
                        material.EnableKeyword("MATCAP_SOFTLIGHT");
                        break;
                    case (int)ColorBlendMode.PinLight:
                        material.EnableKeyword("MATCAP_PINLIGHT");
                        break;
                    case (int)ColorBlendMode.Lighten:
                        material.EnableKeyword("MATCAP_LIGHTEN");
                        break;
                    case (int)ColorBlendMode.Darken:
                        material.EnableKeyword("MATCAP_DARKEN");
                        break;
                    default:
                        material.EnableKeyword("MATCAP_ADDITIVE");
                        break;
                }
            }
        }

        private void DrawMatcapGUI(Material material)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(m_MatcapText, EditorStyles.boldLabel);
            m_MaterialEditor.TexturePropertySingleLine(m_MatcapMapText, m_MatcapMapProp, m_MatcapScaleProp);
            if (m_MatcapMapProp.textureValue != null)
            {
                m_MaterialEditor.TexturePropertySingleLine(m_NormalMapText, m_NormalMapProp, m_NormalScaleProp);
                DoPopup(m_ColorBlendModeText, m_ColorBlendModeProp, Enum.GetNames(typeof(ColorBlendMode)));
            }
            DrawProperty(m_UVScaleProp, m_UVScaleText);
            bool normalAnim = EditorGUILayout.Toggle(m_NormalAnimToggleText, m_NormalAnimToggleProp.floatValue!=0);
            m_NormalAnimToggleProp.floatValue = normalAnim ? 1 : 0;
            if (normalAnim)
            {
                DrawProperty(m_NormalAnimProp, m_NormalAnimText);
            }
        }
    }
}
