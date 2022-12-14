using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class FeiYunZhiJiaSkinGUI : CommonShaderGUI
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

        // MaterialProperty shadowType;

        // void ChangeShadowType(Material mat)
        // {
        //     // mat.SetShaderPassEnabled("SGameShadowPass", true);
        //     if (shadowType != null)
        //     {
        //         switch (shadowType.floatValue)
        //         {
        //             case 0:     // Off
        //                 mat.SetFloat("ENABLE_HQ", 0);
        //                 mat.SetFloat("_HQShadow", 0);
        //                 mat.DisableKeyword("ENABLE_HQ_SHADOW");
        //                 mat.DisableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
        //                 break;
        //             case 1f:    // ENABLE_HQ_SHADOW
        //                 mat.SetFloat("ENABLE_HQ", 1);
        //                 mat.EnableKeyword("ENABLE_HQ_SHADOW");
        //                 mat.DisableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
        //                 break;
        //             case 2f:    // ENABLE_HQ_AND_UNITY_SHADOW
        //                 mat.SetFloat("ENABLE_HQ", 2);
        //                 mat.EnableKeyword("ENABLE_HQ_AND_UNITY_SHADOW");
        //                 mat.DisableKeyword("ENABLE_HQ_SHADOW");
        //                 break;
        //         }

        //     }
        // }

        bool optionsFoldOut;
        protected readonly GUIContent OptionsText = new GUIContent("????????????", "?????????????????????");

        protected readonly GUIContent SkinText = new GUIContent("????????????", "??????????????????");

        //bool plantShadowFoldOut;
        //protected readonly GUIContent PlantShadow = new GUIContent("Plane Shadow(Not Self Shadow)");

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
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Row"), "???", 2);
//            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Col"), "???", 2);

            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("????????????"), FindMaterialProperty("_BaseMap"), FindMaterialProperty("_BaseColor"));

            // Normal
            MaterialProperty normal = FindMaterialProperty("_NormalMap");
            base.DrawPropertyTexture(normal, "????????????");
            if (normal.textureValue != null)
                material.EnableKeyword("_NORMAL_ON");
            else
                material.DisableKeyword("_NORMAL_ON");

            // SkinMap
            base.DrawPropertyTexture(FindMaterialProperty("_SkinMap"), "????????????");

            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SSSRange"), "R ?????? : ??????", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Occlusion"), "G ?????? : AO", 2);

            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_lobe0Smoothness"), "B ?????? : ???????????????1", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_lobe1Smoothness"), "B ?????? : ???????????????2", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LobeMix"), "?????????????????????", 2);
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();
            // Skin Other Property
            EditorGUILayout.BeginVertical("box");
            {
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_EnvDiffInt"), "??????????????????", 2);
                // m_MaterialEditor.ShaderProperty(FindMaterialProperty("_PBRToDiffuse"), "PBR??????????????????", 2);
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DiffusePower"), "SSS????????????", 2);
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();
            // ThickMap
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty thick_map = FindMaterialProperty("_ThickMap");
                m_MaterialEditor.TexturePropertyWithHDRColor(EditorGUIUtility.TrTextContent("????????????"), thick_map, FindMaterialProperty("_BackLightColor"), true);
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_BackLightIntensity"), "????????????", 2);
            }
            EditorGUILayout.EndVertical();

           // PlantShadow ----------------------
            // plantShadowFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(plantShadowFoldOut, PlantShadow);
            // if (plantShadowFoldOut)
            // {
            //     EditorGUILayout.BeginVertical("box");
            //     {
            //         //?????????TA_HighQualityShadow.cs????????????
            //         shadowType = FindMaterialProperty("ENABLE_HQ");
            //         m_MaterialEditor.ShaderProperty(shadowType, "ShadowType", 2);
            //         m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowColor"), "Shadow Color", 2);
            //         m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowHeight"), "Shadow Height", 2);
            //         m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetX"), "Shadow Offset X", 2);
            //         m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetZ"), "Shadow Offset Z", 2);
            //         m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ProGameOutDir"), "Pro Game Out Dir", 2);
            //     }
            //     EditorGUILayout.EndVertical();

            // }
            // EditorGUILayout.EndFoldoutHeaderGroup();

            // EditorGUILayout.Space();
            // SGameUberEffectGUI.Report();
            // EditorGUILayout.Space();
            
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

