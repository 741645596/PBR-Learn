using System;
using UnityEngine;
using UnityEditor;

namespace FBShaderGUI
{
    public class GlassShaderGUI : CommonShaderGUI
    {

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.saveMaterialProperties = materialProperties;

            base.OnGUI(materialEditor, materialProperties);
            Material material = m_MaterialEditor.target as Material;
            if (material == null)
            {
                throw new ArgumentNullException("Material is null.");
            }
            DrawInputGUI(material);
        }

        GUIStyle _FoldoutStyle;

        private void DrawInputGUI(Material material)
        {
            _FoldoutStyle = new GUIStyle(EditorStyles.foldout);
            _FoldoutStyle.fontStyle = FontStyle.Bold;
            EditorGUI.TextArea(new Rect(0, -8, 300, 20), "开启 Opaque Texture,Transparent");
            EditorGUILayout.Space();
            DrawHead();
            DrawMain();
            DrawDecal();
            DrawShadow(material);
        }

        bool drawHead;

        void DrawHead()
        {
            GUILayout.BeginVertical("GroupBox");

            //EditorGUI.indentLevel = 1;
            //drawHead = EditorGUILayout.Foldout(drawHead, "设置", _FoldoutStyle);
            //if (!drawHead)
            //{
            //    GUILayout.EndVertical();
            //    return;
            //}
            DrawProperty("_ColorCubemap", "环境颜色");
            DrawProperty("_PowerFresnel", "菲尼尔Pow");
            DrawProperty("_GlobalIlluminationIns", "环境强度");
            DrawProperty("_IndexofRefraction", "折射强度");
            DrawProperty("_ChromaticAberration", "偏色");
            DrawProperty("_OpaqueColor", "背景颜色");
            DrawProperty("_PBRON", "Pbr高光");
            if (FindMaterialProperty("_PBRON").floatValue == 1)
            {
                DrawProperty("_SpecIntensity", "高光强度");
            }

            GUILayout.EndVertical();
        }

        bool drawMain;

        void DrawMain()
        {
            GUILayout.BeginVertical("GroupBox");

            //EditorGUI.indentLevel = 1;
            //drawMain = EditorGUILayout.Foldout(drawMain, "纹理设置", _FoldoutStyle);
            //if (!drawMain)
            //{
            //    GUILayout.EndVertical();
            //    return;
            //}

            //DrawProperty("_PSON", "明度饱和度调整");
            //if (FindMaterialProperty("_PSON").floatValue == 1)
            //{
            //    EditorGUI.indentLevel++;
            //    DrawProperty("_Brightness", "明度");
            //    DrawProperty("_Saturation", "饱和度");
            //    EditorGUI.indentLevel--;
            //}

            DrawProperty("_BaseColor", "颜色");
            DrawPropertyTexture("_BaseMap", "颜色纹理");
            DrawDoubleVector2FromVector4("_BaseMap_TilingOffset", "Tiling", "Offset");
            DrawProperty("_NormalScale", "法线强度");
            DrawProperty("_NormalMap", "法线纹理");
            DrawProperty("_MainEmissionColor", "自发光颜色");
            DrawProperty("_MainEmission", "自发光纹理");
            DrawProperty("_MainMetallicStrength", "金属度");
            DrawProperty("_MainSmoothnessStrength", "光滑度");
            DrawProperty("_MainAOStrength", "AO");
            DrawPropertyTexture("_MainMTex", "混合纹理（R:金属度 G:AO B:空 A:光滑度）");

            GUILayout.EndVertical();
        }

        bool drawDecal;

        void DrawDecal()
        {
            if (FindMaterialProperty("_DECALON") == null)
            {
                return;
            }

            GUILayout.BeginVertical("GroupBox");

            //EditorGUI.indentLevel = 1;
            //drawDecal = EditorGUILayout.Foldout(drawDecal, "细节纹理", _FoldoutStyle);
            //if (!drawDecal)
            //{
            //    GUILayout.EndVertical();
            //    return;
            //}

            DrawProperty("_DECALON", "细节");
            if (FindMaterialProperty("_DECALON").floatValue != 1)
            {
                GUILayout.EndVertical();
                return;
            }

            //DrawProperty("_PSON", "明度饱和度调整");
            //if (FindMaterialProperty("_PSON").floatValue == 1)
            //{
            //    EditorGUI.indentLevel++;
            //    DrawProperty("_BrightnessDecal", "明度");
            //    DrawProperty("_SaturationDecal", "饱和度");
            //    EditorGUI.indentLevel--;
            //}

            DrawProperty("_DetailColor", "细节纹理颜色（A通道：透明度）");
            DrawProperty("_DetailAlbedo", "细节颜色纹理（A通道：透明度）");
            DrawProperty("_DetailAlbedoMask", "细节范围（R通道：细节范围）");
            DrawDoubleVector2FromVector4("_Detail_TilingOffset", "Tiling", "Offset");
            DrawProperty("_NormalDetailScale", "细节法线强度");
            DrawPropertyTexture("_NormalMapDetail", "细节法线纹理");
            DrawProperty("_BumpScaleDecal", "细节法线占比");
            DrawProperty("_DecalEmissionColor", "细节自发光颜色");
            DrawPropertyTexture("_DecalEmission", "细节自发光纹理");
            DrawProperty("_DecalMetallicStrength", "金属度");
            DrawProperty("_DecalSmoothnessStrength", "光滑度");
            DrawProperty("_DecalAOStrength", "AO");
            DrawPropertyTexture("_DecalMTex", "混合纹理（R:金属度 G:AO B:空 A:光滑度）");

            GUILayout.EndVertical();
        }

        bool drawShadow;

        void DrawShadow(Material material)
        {
            GUILayout.BeginVertical("GroupBox");

            //EditorGUI.indentLevel = 1;
            //drawShadow = EditorGUILayout.Foldout(drawShadow, "平面阴影", _FoldoutStyle);
            //if (!drawShadow)
            //{
            //    GUILayout.EndVertical();
            //    return;
            //}

            //PlantShadow
            MaterialProperty plantShadowOpen = FindMaterialProperty("_PlantShadowOpen");
            if (plantShadowOpen != null)
            {
                EditorGUILayout.Space();
                bool shadowOpen = plantShadowOpen.floatValue == 1;
                shadowOpen = EditorGUILayout.Toggle("平面阴影", shadowOpen);
                if (shadowOpen)
                {
                    plantShadowOpen.floatValue = 1;
                    EditorGUILayout.LabelField(new GUIContent("PlantShadow"), EditorStyles.boldLabel);
                    base.DrawProperty(FindMaterialProperty("_ShadowColor"), "ShadowColor");
                    base.DrawProperty(FindMaterialProperty("_ShadowHeight"), "ShadowHeight");
                    base.DrawProperty(FindMaterialProperty("_ShadowOffsetX"), "ShadowOffsetX");
                    base.DrawProperty(FindMaterialProperty("_ShadowOffsetZ"), "ShadowOffsetZ");
                    base.DrawProperty(FindMaterialProperty("_ProGameOutDir"), "ProGameOutDir");
                    material.SetShaderPassEnabled("SGameShadowPass", true);
                }
                else
                {
                    plantShadowOpen.floatValue = 0;
                    material.SetShaderPassEnabled("SGameShadowPass", false);
                }
            }

            GUILayout.EndVertical();
        }
    }
}

