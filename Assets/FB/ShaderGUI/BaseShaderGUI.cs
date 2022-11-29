using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace FBShaderGUI
{
    public class BaseShaderGUI : CommonShaderGUI
    {

        private enum BlendMode
        {
            Alpha,
            Additive
        }

        #region PROPERTIES & GUITEXT

        // Blend mode
        protected MaterialProperty m_BlendModeProp;
        protected static GUIContent m_BlendModeText = new GUIContent("BlendMode(混合模式)", "设置前景和背景的颜色混合方式");

        // Queue Offset
        protected MaterialProperty m_QueueOffsetProp;
        protected static GUIContent m_QueueOffsetText = new GUIContent("Queue Offset(渲染优先级)", "渲染队列的偏移量");
        protected const int m_QueueOffsetRange = 50;

        // Base map & color
        protected MaterialProperty m_BaseMapProp;
        protected static GUIContent m_BaseMapText = new GUIContent("Base Map(主贴图)", "主贴图/固有色贴图");
        protected MaterialProperty m_BaseColorProp;
        protected static GUIContent m_BaseColorText = new GUIContent("Base Color(主颜色)", "主颜色/固有色");

        // Advance options
        protected bool m_AdvancedFoldout = false;
        protected static GUIContent m_AdvanceOptionsText = new GUIContent("Advance Options");

        #endregion

        private bool m_FirstApply = true;

        public override void FindProperties(MaterialProperty[] properties)
        {
            // Surface options
            m_BlendModeProp = FindProperty("_Blend", properties);
            m_QueueOffsetProp = FindProperty("_QueueOffset", properties);

            // Base inputs
            m_BaseMapProp = FindProperty("_BaseMap", properties);
            m_BaseColorProp = FindProperty("_BaseColor", properties);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.OnGUI(materialEditor, materialProperties);
            FindProperties(materialProperties);
            Material material = m_MaterialEditor.target as Material;
            if (m_FirstApply)
            {
                foreach (Material mat in m_MaterialEditor.targets)
                {
                    MaterialChanged(material);
                }
                m_FirstApply = false;
            }
            ShaderPropertiesGUI(material);
        }

        public override void ShaderPropertiesGUI(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("Material is null.");
            }
            base.ShaderPropertiesGUI(material);
            EditorGUI.BeginChangeCheck();
            DrawSurfaceOptionsGUI(material);
            DrawBaseInputsGUI(material);
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material mat in m_MaterialEditor.targets)
                {
                    MaterialChanged(mat);
                }
            }
        }

        public virtual void MaterialChanged(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }
                
            //material.shaderKeywords = null;
            SetupMaterialBlendMode(material);
            SetupMaterialKeywords(material);
        }

        private void DrawSurfaceOptionsGUI(Material material)
        {
            EditorGUILayout.LabelField(m_surfaceOptionsText, EditorStyles.boldLabel);

            // Surface type
            SurfaceType surfaceType = DrawSurfaceTypeProp(material);

            // Blend mode if type == transparent
            if (surfaceType== SurfaceType.Transparent)
            {
                DoPopup(m_BlendModeText, m_BlendModeProp, Enum.GetNames(typeof(BlendMode)));
            }

            // Render face
            DrawCullModeProp(material);

            // Alpha clip
            DrawAlphaClipProp(material);

            // Receive shadow
            DrawReceiveShadows(material);
        }

        public virtual void DrawAdvancedOptions(Material material)
        {
            EditorGUILayout.Space();
            m_AdvancedFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout, m_AdvanceOptionsText);

            if (m_AdvancedFoldout)
            {
                // Instancing
                m_MaterialEditor.EnableInstancingField();

                // Render priority
                if (m_QueueOffsetProp != null)
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUI.showMixedValue = m_QueueOffsetProp.hasMixedValue;
                    var queue = EditorGUILayout.IntSlider(m_QueueOffsetText, (int)m_QueueOffsetProp.floatValue, -m_QueueOffsetRange, m_QueueOffsetRange);
                    if (EditorGUI.EndChangeCheck())
                        m_QueueOffsetProp.floatValue = queue;
                    EditorGUI.showMixedValue = false;
                }
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void DrawBaseInputsGUI(Material material)
        {
            EditorGUILayout.Space();

            m_MaterialEditor.TexturePropertySingleLine(m_BaseMapText, m_BaseMapProp, m_BaseColorProp);
            if (m_BaseMapProp.textureValue != null)
            {
                m_MaterialEditor.TextureScaleOffsetProperty(m_BaseMapProp);
            }
            
            EditorGUILayout.Space();
        }

        private void SetupMaterialBlendMode(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }
            
            bool alphaClip = false;
            if(material.HasProperty("_AlphaClip"))
                alphaClip = material.GetFloat("_AlphaClip") >= 0.5;

            if (material.HasProperty("_Surface"))
            {
                SurfaceType surfaceType = (SurfaceType) material.GetFloat("_Surface");
                if (surfaceType == SurfaceType.Opaque)
                {
                    if (alphaClip)
                    {
                        material.renderQueue = (int) RenderQueue.AlphaTest;
                        material.SetOverrideTag("RenderType", "TransparentCutout");
                    }
                    else
                    {
                        material.renderQueue = (int) RenderQueue.Geometry;
                        material.SetOverrideTag("RenderType", "Opaque");
                    }

                    material.renderQueue += material.HasProperty("_QueueOffset") ? (int) material.GetFloat("_QueueOffset") : 0;
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetShaderPassEnabled("ShadowCaster", true);
                    material.SetShaderPassEnabled("DepthOnly", true);
                }
                else
                {
                    // General Transparent Material Settings
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)RenderQueue.Transparent;
                    material.renderQueue += material.HasProperty("_QueueOffset") ? (int) material.GetFloat("_QueueOffset") : 0;
                    material.SetShaderPassEnabled("ShadowCaster", false);
                    material.SetShaderPassEnabled("DepthOnly", false);
                }
            }
        }

        public override void SetupMaterialKeywords(Material material)
        {
            base.SetupMaterialKeywords(material);
        }

    }
}
