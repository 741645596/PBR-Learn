using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Bindings;
using UnityEngine.Scripting;

namespace FBShaderGUI
{
    public class PBRShaderGUI : BaseShaderGUI
    {
        private static GUIContent m_PBRInputsText = new GUIContent("PBR");

        // Roughness, Metallic, Occlusion
        private MaterialProperty m_MixMapProp;
        private static GUIContent m_MixMapText = new GUIContent("MOBSMap(R:金属度,G:AO,B:,A:光滑度)");
        private MaterialProperty m_SmothnessProp;
        private static GUIContent m_SmothnessText = new GUIContent("Smothness(光滑度)");
        private MaterialProperty m_MetallicProp;
        private static GUIContent m_MetallicText = new GUIContent("Metallic(金属度)");
        private MaterialProperty m_OcclusionProp;
        private static GUIContent  m_OcclusionText = new GUIContent("Occlusion(AO)");

        // Bump
        private MaterialProperty m_BumpMapProp;
        private static GUIContent m_BumpMapText = new GUIContent("Normal Map(法线贴图)");

        // Emissive
        private MaterialProperty m_EmissionMapProp;
        private static GUIContent m_EmissionMapText = new GUIContent("Emission(自发光贴图,A通道:阴影强度)");
        private MaterialProperty m_EmissionColorProp;
        private static GUIContent m_EmissionColorText = new GUIContent("Emission Color(自发光颜色)");

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);

            m_MixMapProp            = FindProperty("_MixMap", properties);
            m_SmothnessProp = FindProperty("_Smothness", properties);
            m_MetallicProp          = FindProperty("_Metallic", properties);
            m_OcclusionProp         = FindProperty("_Occlusion", properties);

            m_BumpMapProp           = FindProperty("_BumpMap", properties);

            m_EmissionMapProp       = FindProperty("_EmissionMap", properties);
            m_EmissionColorProp     = FindProperty("_EmissionColor", properties);

        }

        public override void ShaderPropertiesGUI(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("Material is null.");
            }

            EditorGUI.BeginChangeCheck();
            base.ShaderPropertiesGUI(material);
            DrawPBRInputGUI(material);
            DrawStencil(material);
            base.DrawAdvancedOptions(material);
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

          /*  material.SetKeyword(new LocalKeyword (material.shader,), m_MixMapProp.textureValue != null);
            material.SetKeyword("ENABLE_NORMALMAP", m_BumpMapProp.textureValue != null);
            material.SetKeyword("ENABLE_EMISSION", m_EmissionMapProp.textureValue != null);*/

            material.SetKeyword("ENABLE_MIXMAP", m_MixMapProp.textureValue != null);
            material.SetKeyword("ENABLE_NORMALMAP", m_BumpMapProp.textureValue != null);
            material.SetKeyword("ENABLE_EMISSION", m_EmissionMapProp.textureValue != null);
        }

        private void DrawPBRInputGUI(Material material)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(m_PBRInputsText, EditorStyles.boldLabel);

            m_MaterialEditor.TexturePropertySingleLine(m_BumpMapText, m_BumpMapProp);
            m_MaterialEditor.TexturePropertySingleLine(m_MixMapText, m_MixMapProp);
            m_MaterialEditor.ShaderProperty(m_SmothnessProp, m_SmothnessText);
            m_MaterialEditor.ShaderProperty(m_MetallicProp, m_MetallicText);
            m_MaterialEditor.ShaderProperty(m_OcclusionProp, m_OcclusionText);

            m_MaterialEditor.TexturePropertySingleLine(m_EmissionMapText, m_EmissionMapProp, m_EmissionColorProp);
            EditorGUILayout.Space();

            //需要与TA_HighQualityShadow.cs配合使用
            //DrawProperty("ENABLE_HQ", "ShadowType(阴影种类)");
        }
    }
}
