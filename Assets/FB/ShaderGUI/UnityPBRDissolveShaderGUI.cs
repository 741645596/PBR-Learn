using System;
using UnityEngine;
using UnityEditor;

namespace FBShaderGUI
{
    public class UnityPBRDissolveShaderGUI : CommonShaderGUI
    {
        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.OnGUI(materialEditor, materialProperties);

            Material material = m_MaterialEditor.target as Material;
            DrawSkinGUI(materialEditor,material);
            base.SetupMaterialKeywords(material);
        }

        bool m_AdvancedFoldout;

        void DrawSkinGUI(MaterialEditor materialEditor,Material material)
        {
            EditorGUILayout.LabelField(m_surfaceOptionsText, EditorStyles.boldLabel);
            DrawCullModeProp(material);
            DrawAlphaClipProp(material);
            DrawReceiveShadows(material);

            //
            EditorGUILayout.Space();
            base.DrawPropertyTexture(FindMaterialProperty("_BaseMap"), FindMaterialProperty("_MainColor"), "Base Map(主贴图)", "主贴图/固有色贴图",true);
            base.DrawProperty(FindMaterialProperty("_BaseColor"), "Color");
            //
            EditorGUILayout.Space();
            base.DrawProperty(FindMaterialProperty("_BumpScale"), "法线强度");
            base.DrawPropertyTexture(FindMaterialProperty("_BumpMap"), "Normal(法线)");

            //
            EditorGUILayout.Space();
            base.DrawProperty(FindMaterialProperty("_EmissionColor"), "自发光,A通道阴影强度");
            base.DrawPropertyTexture(FindMaterialProperty("_EmissionMap"), "Emission Map(自发光,A通道阴影强度)", "自发光贴图", false);

            //
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(new GUIContent("PBR", "物理参数设置"), EditorStyles.boldLabel);
            base.DrawPropertyTexture(FindMaterialProperty("_MetallicGlossMap"), "Metallic(R:金属度 G:AO B: A:光滑度)");
            base.DrawProperty(FindMaterialProperty("_Smoothness"), "Smoothness(光滑度)");
            base.DrawProperty(FindMaterialProperty("_Metallic"), "Metallic(金属度)");
            base.DrawProperty(FindMaterialProperty("_OcclusionStrength"), "AOStrength(ao强度)");

            //
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(new GUIContent("SET"), EditorStyles.boldLabel);
            base.DrawProperty(FindMaterialProperty("_SpecularTwoLobesA"), "SpecularTwoLobesA(底层粗糙度)");
            base.DrawProperty(FindMaterialProperty("_SpecularTwoLobesB"), "SpecularTwoLobesB(顶层高光比例)");
            base.DrawProperty(FindMaterialProperty("_ShadeMin"), "ShadeMin(暗部强度)");
            base.DrawProperty(FindMaterialProperty("_ShadeSaturation"), "ShadeSaturation(阴影饱和度)");
            base.DrawProperty(FindMaterialProperty("_PBRGIInst"), "PBRGIInst(PBR GI强度)");
            base.DrawProperty(FindMaterialProperty("_GIIrradiance"), "GIIrradiance(环境Hdr强度)");



            EditorGUILayout.Space();
            EditorGUILayout.LabelField(new GUIContent("Dissolve", "物理参数设置"), EditorStyles.boldLabel);
            base.DrawPropertyTexture(FindMaterialProperty("_DissolveMap"),"溶解贴图");
            base.DrawProperty(FindMaterialProperty("_DissolveStrength"), "溶解强度");
            base.DrawProperty(FindMaterialProperty("_DissolveEdgeWidth"), "溶解边宽");
            base.DrawProperty(FindMaterialProperty("_EdgeEmission"), "边界自发光颜色");

            base.DrawProperty(FindMaterialProperty("_PolarEnable"), "开启极坐标");

            base.DrawProperty(FindMaterialProperty("_DissolveTexAngle"), "溶解贴图旋转角度");
            base.DrawVector2FromVector4(FindMaterialProperty("_UVDissolveSpeed"), "溶解贴图uv流速");


            //PlantShadow
            MaterialProperty plantShadowOpen = FindMaterialProperty("_PlantShadowOpen");
            if (plantShadowOpen!=null)
            {
                EditorGUILayout.Space();
                bool shadowOpen = plantShadowOpen.floatValue == 1;
                shadowOpen = EditorGUILayout.Toggle("平面阴影",shadowOpen);
                if (shadowOpen)
                {
                    plantShadowOpen.floatValue = 1;
                    EditorGUILayout.LabelField(new GUIContent("PlantShadow"), EditorStyles.boldLabel);
                    base.DrawProperty(FindMaterialProperty("_ShadowColor"), "ShadowColor");
                    base.DrawProperty(FindMaterialProperty("_ShadowHeight"), "ShadowHeight");
                    base.DrawProperty(FindMaterialProperty("_ShadowOffsetX"), "ShadowOffsetX");
                    base.DrawProperty(FindMaterialProperty("_ShadowOffsetZ"), "ShadowOffsetZ");
                    base.DrawProperty(FindMaterialProperty("_ProGameOutDir"), "ProGameOutDir");
                    material.SetShaderPassEnabled("SGameShadowPass",true);
                }
                else
                {
                    plantShadowOpen.floatValue = 0;
                    material.SetShaderPassEnabled("SGameShadowPass", false);
                }
            }

            DrawStencil(material);

            //
            EditorGUILayout.Space();
            m_AdvancedFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout, new GUIContent("Advance Options"));
            if (m_AdvancedFoldout)
            {
                DrawInstancingOnGUI(materialEditor);

                //需要与TA_HighQualityShadow.cs配合使用
                //DrawProperty("ENABLE_HQ", "ShadowType(阴影种类)");
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            //
            DrawQueueOnGUI(materialEditor);
        }

    }
}

