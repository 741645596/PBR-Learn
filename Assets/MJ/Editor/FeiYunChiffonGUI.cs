using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class FeiYunChiffonGUI : CommonShaderGUI
    {
        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.saveMaterialProperties = materialProperties;
            base.OnGUI(materialEditor, materialProperties);
            Material material = m_MaterialEditor.target as Material;
            DrawSkinGUI(materialEditor, material);
            base.SetupMaterialKeywords(material);
        }

        bool optionsFoldOut;
        protected readonly GUIContent OptionsText = new GUIContent("配置参数", "可配置参数设置");

        protected readonly GUIContent PBRText = new GUIContent("PBR参数", "基本参数设置");

        protected readonly GUIContent SparkleText = new GUIContent("闪点参数", "闪点参数设置");

        MaterialProperty emission_map;

        void DrawSkinGUI(MaterialEditor materialEditor, Material material)
        {

            // Other ----------------------
            EditorGUILayout.Space();

            optionsFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(optionsFoldOut, OptionsText);
            if (optionsFoldOut)
            {
                EditorGUILayout.BeginVertical("box");
                {
                    EditorGUI.BeginChangeCheck();
                    SurfaceType surfaceType = DrawSurfaceTypeProp(material);

                    DrawCullModeProp(material);
                    DrawReceiveShadows(material);
                    if (surfaceType != SurfaceType.Transparent)
                        DrawAlphaClipProp(material);

                    if (EditorGUI.EndChangeCheck())
                        MaterialChanged(material);

                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();


            // PBR -----------------------
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(PBRText, EditorStyles.boldLabel);

            EditorGUILayout.BeginVertical("box");
            // Base
            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("颜色贴图"), FindMaterialProperty("_BaseMap"), FindMaterialProperty("_BaseColor"));

            // Normal
            MaterialProperty normal = FindMaterialProperty("_NormalMap");
            base.DrawPropertyTexture(normal, "法线贴图");
            // MetallicGlossMap
            base.DrawPropertyTexture(FindMaterialProperty("_MetallicGlossMap"), "PBR 遮罩");

            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Metallic"), "R 通道 : 金属度", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_OcclusionStrength"), "G 通道 : AO", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Smoothness"), "B 通道 : 光滑度", 2);

            EditorGUILayout.Space();
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Reflectance"), "反射率", 2);

            EditorGUILayout.EndVertical();

            // Emission
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty emission = FindMaterialProperty("_Emission");
                if (emission != null)
                {
                    m_MaterialEditor.ShaderProperty(emission, EditorGUIUtility.TrTextContent("自发光"), 2);
                    if (emission.floatValue != 0)
                    {
                        material.EnableKeyword("_EMISSION_ON");
                        emission_map = FindMaterialProperty("_EmissionMap");
                        m_MaterialEditor.TexturePropertyWithHDRColor(EditorGUIUtility.TrTextContent("自发光遮罩"), emission_map, FindMaterialProperty("_EmissionColor"), true);
                        if (emission_map.textureValue != null)
                            material.EnableKeyword("_EMISSION_MAP");
                        else
                            material.DisableKeyword("_EMISSION_MAP");
                    }
                    else
                    {
                        material.DisableKeyword("_EMISSION_ON");

                        if (emission_map != null)
                            emission_map.textureValue = null;
                    }
                }
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.EndFoldoutHeaderGroup();

            // 闪点 -----------------------
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(SparkleText, EditorStyles.boldLabel);
            base.DrawPropertyTexture(FindMaterialProperty("_SparkleTex"), "闪点纹理");
            base.DrawPropertyTexture(FindMaterialProperty("_SparkleMaskTex"), "闪点遮罩");
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleSize"), "SparkleSize", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleDependency"), "Sparkle Dependency", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleRoughness"), "闪点光滑度", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleColor"), "Sparkle Color", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleScaleMin"), "Sparkle MIN", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SparkleDensity"), "Sparkle Density[密度]", 2);
            EditorGUILayout.EndFoldoutHeaderGroup();


            DrawQueueOnGUI(materialEditor);
        }


        public virtual void MaterialChanged(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }

            //material.shaderKeywords = null;
            SetupMaterialBlendMode(material);
            // SetupMaterialKeywords(material);
        }

        private void SetupMaterialBlendMode(Material material)
        {
            if (material == null)
            {
                throw new ArgumentNullException("material");
            }

            bool alphaClip = false;
            if (material.HasProperty("_AlphaClip"))
                alphaClip = material.GetFloat("_AlphaClip") >= 0.5;

            if (material.HasProperty("_Surface"))
            {
                SurfaceType surfaceType = (SurfaceType)material.GetFloat("_Surface");
                if (surfaceType == SurfaceType.Opaque)
                {
                    if (alphaClip)
                    {
                        material.renderQueue = (int)RenderQueue.AlphaTest;
                        material.SetOverrideTag("RenderType", "TransparentCutout");
                    }
                    else
                    {
                        material.renderQueue = (int)RenderQueue.Geometry;
                        material.SetOverrideTag("RenderType", "Opaque");
                    }

                    material.renderQueue += material.HasProperty("_queueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                }
                else
                {
                    // General Transparent Material Settings
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)RenderQueue.Transparent;
                    material.renderQueue += material.HasProperty("_QueueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
                }
            }
        }
    }
}

