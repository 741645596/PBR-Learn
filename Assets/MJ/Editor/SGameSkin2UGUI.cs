using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class SGameSkin2UGUI : CommonShaderGUI
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

        MaterialProperty shadowType;

        void ChangeShadowType(Material mat)
        {
            // mat.SetShaderPassEnabled("SGameShadowPass", true);
            if (shadowType != null)
            {
                switch (shadowType.floatValue)
                {
                    case 0:     // Off
                        mat.SetFloat("ENABLE_HQ", 0);
                        mat.SetFloat("_HQShadow", 0);
                        mat.DisableKeyword("ENABLE_HQ_SHADOW");
                        mat.DisableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
                        break;
                    case 1f:    // ENABLE_HQ_SHADOW
                        mat.SetFloat("ENABLE_HQ", 1);
                        mat.EnableKeyword("ENABLE_HQ_SHADOW");
                        mat.DisableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
                        break;
                    case 2f:    // ENABLE_HQ_AND_UNITY_SHADOW
                        mat.SetFloat("ENABLE_HQ", 2);
                        mat.EnableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
                        mat.DisableKeyword("ENABLE_HQ_SHADOW");
                        break;
                }

            }
        }

        bool optionsFoldOut;
        protected readonly GUIContent OptionsText = new GUIContent("配置参数", "可配置参数设置");

        protected readonly GUIContent SkinText = new GUIContent("皮肤参数", "基本参数设置");

        bool plantShadowFoldOut;
        protected readonly GUIContent PlantShadow = new GUIContent("Plane Shadow(Not Self Shadow)");

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


            // Skin -----------------------
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(SkinText, EditorStyles.boldLabel);

            EditorGUILayout.BeginVertical("box");
            // Base
            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("颜色贴图"), FindMaterialProperty("_BaseMap"), FindMaterialProperty("_BaseColor"));

            // Normal
            MaterialProperty normal = FindMaterialProperty("_NormalMap");
            base.DrawPropertyTexture(normal, "法线贴图");
            if (normal.textureValue != null)
                material.EnableKeyword("_NORMAL_ON");
            else
                material.DisableKeyword("_NORMAL_ON");

            // SkinMap
            base.DrawPropertyTexture(FindMaterialProperty("_SkinMap"), "皮肤遮罩");


            
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SSSRange"), "R 通道 : 曲率", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Occlusion"), "G 通道 : AO", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_lobe0Smoothness"), "B 通道 : 皮肤光滑度", 2);
        
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();
            // Skin Other Property
            EditorGUILayout.BeginVertical("box");
            {
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_EnvDiffInt"), "环境补光强度", 2);
            
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();
            // ThickMap
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty thick_map = FindMaterialProperty("_ThickMap");
                m_MaterialEditor.TexturePropertyWithHDRColor(EditorGUIUtility.TrTextContent("厚度贴图"), thick_map, FindMaterialProperty("_BackLightColor"), true);
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_BackLightIntensity"), "透光强度", 2);
            }
            EditorGUILayout.EndVertical();
            
            EditorGUILayout.Space();
            // 2U
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty use2u = FindMaterialProperty("_Open2UDecal");
                // if (use2u == null) return;
                m_MaterialEditor.ShaderProperty(use2u, EditorGUIUtility.TrTextContent("使用2u"), 2);
                if (use2u.floatValue == 0)
                {
                     material.DisableKeyword("_OPEN2UDECAL");
                }
                else
                {
                    material.EnableKeyword("_OPEN2UDECAL");
                    MaterialProperty map2U = FindMaterialProperty("_BaseMap_2U");
                    m_MaterialEditor.TexturePropertyWithHDRColor(EditorGUIUtility.TrTextContent("RGB:颜色 A:遮罩"), map2U, FindMaterialProperty("_BaseColor_2U"), true);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Metallic_2U"), "金属度", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Smoothness_2U"), "光滑度", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Normal_2U"), "法线减淡", 2);
                }

            }
            EditorGUILayout.EndVertical();

            // PlantShadow ----------------------
            plantShadowFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(plantShadowFoldOut, PlantShadow);
            if (plantShadowFoldOut)
            {
                EditorGUILayout.BeginVertical("box");
                {
                    //需要与TA_HighQualityShadow.cs配合使用
                    shadowType = FindMaterialProperty("ENABLE_HQ");
                    m_MaterialEditor.ShaderProperty(shadowType, "ShadowType", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowColor"), "Shadow Color", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowHeight"), "Shadow Height", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetX"), "Shadow Offset X", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetZ"), "Shadow Offset Z", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ProGameOutDir"), "Pro Game Out Dir", 2);
                }
                EditorGUILayout.EndVertical();

            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            EditorGUILayout.Space();
            SGameUberEffectGUI.Report();
            EditorGUILayout.Space();
            
            // DrawStencil(material);

            //
            // EditorGUILayout.Space();
            // m_AdvancedFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout, new GUIContent("Advance Options"));
            // if (m_AdvancedFoldout)
            // {
            //     DrawInstancingOnGUI(materialEditor);
            // }
            // EditorGUILayout.EndFoldoutHeaderGroup();

            //
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

                    material.renderQueue += material.HasProperty("_QueueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetShaderPassEnabled("ShadowCaster", true);
                    material.SetShaderPassEnabled("DepthOnly", true);
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
                    material.SetShaderPassEnabled("ShadowCaster", false);
                    material.SetShaderPassEnabled("DepthOnly", false);
                }
            }
        }
    }
}

