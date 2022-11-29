using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class FabricShaderGUI : CommonShaderGUI
    {
        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.OnGUI(materialEditor, materialProperties);
            EditorGUI.BeginChangeCheck();

            Material material = m_MaterialEditor.target as Material;
            DrawSkinGUI(materialEditor, material);
            base.SetupMaterialKeywords(material);
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material mat in m_MaterialEditor.targets)
                {
                    MaterialChanged(mat);

                    if (fabricType == FabricType.丝绸)
                    {
                        if (silkDefaulChange)
                        {
                            switch (silkDefault)
                            {
                                case SilkDefault.金色:
                                    SetUpDefault(mat, new Color(0.6313726f, 0.5852338f, 0.4419608f, 1f), new Color(0.8705883f, 0.8078432f, 0.6117647f, 1f), -0.7f, 0.2f);
                                    break;
                                case SilkDefault.蓝色:
                                    SetUpDefault(mat, new Color(0.1506588f, 0.1610689f, 0.2235294f, 1f), new Color(0.2823529f, 0.3137255f, 0.4352941f, 1f), -0.8f, 0f);
                                    break;
                            }
                        }
                    }
                    else
                    {
                        if (woolDefaulChange)
                        {
                            switch (woolDefault)
                            {
                                case WoolDefault.红绒:
                                    SetUpDefault(mat, Color.white, Color.red, 0f, 1f);
                                    break;
                                case WoolDefault.粗布:
                                    SetUpDefault(mat, Color.gray, new Color(0.4099999f, 0.4099999f, 0.4099999f, 1f), 0f, 0.4f, 1.0f, 22f, 0.295f, 0.05f);
                                    break;
                            }
                        }
                    }
                }
            }
        }

        void SetUpDefault(Material mat, Color base_color, Color spec_color, float anisotropy, float smoothness,
                            float useThreadMap = 0, float threadTilling = 0, float threadAlbedo = 0, float threadSmoothness = 0)
        {
            mat.SetTexture("_BaseMap", null);
            mat.SetTexture("_NormalMap", null);
            mat.SetFloat("_NormalScale", 1f);
            mat.SetTexture("_MaskMap", null);

            mat.SetColor("_BaseColor", base_color);
            mat.SetColor("_SpecColor", spec_color);
            mat.SetColor("_Transmission_Tint", Color.black);

            mat.SetFloat("_Anisotropy", anisotropy);
            mat.SetFloat("_SmoothnessMax", smoothness);
            mat.SetFloat("_OcclusionStrength", 1f);

            mat.SetFloat("_UseThreadMap", useThreadMap);
            mat.SetTexture("_ThreadMap", AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath("963d136eca7b7bc4e838b34654450ab2")));
            mat.SetFloat("_ThreadTilling", threadTilling);
            mat.SetFloat("_ThreadAOStrength", threadAlbedo);
            mat.SetFloat("_ThreadNormalStrength", 1);
            mat.SetFloat("_ThreadSmoothnessScale", threadSmoothness);

            mat.SetFloat("_Fuzz", 0);
        }

        MaterialProperty fabricProb;

        GUIContent fabricText = new GUIContent("渲染模式", "丝绸/布料");

        public enum FabricType
        {
            丝绸 = 0,
            布料 = 1
        }

        FabricType fabricType;
        FabricType DrawFabricType(Material material)
        {
            fabricProb = FindMaterialProperty("_Silk");
            if (fabricProb != null)
            {
                DoPopup(fabricText, fabricProb, Enum.GetNames(typeof(FabricType)));
                return (FabricType)material.GetFloat("_Silk");
            }
            return 0;
        }

        MaterialProperty FDG;

        public enum SilkDefault
        {
            金色 = 0,
            蓝色 = 1
        }

        SilkDefault currentSilkDefault;
        SilkDefault silkDefault;
        MaterialProperty silkDefaultProb;
        GUIContent silkDefaultText = new GUIContent("丝绸预设", "选择会覆盖当前数值");
        SilkDefault DrawSilkDefault(Material material)
        {
            silkDefaultProb = FindMaterialProperty("_SilkDefault");
            if (silkDefaultProb != null)
            {
                material.EnableKeyword("_SILK_ON");
                FDG = FindMaterialProperty("_preIntegratedFGD");
                FDG.textureValue = AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath("680e541674540d04f8b44453c24ba9a1"));
                DoPopup(silkDefaultText, silkDefaultProb, Enum.GetNames(typeof(SilkDefault)));
                return (SilkDefault)material.GetFloat("_SilkDefault");
            }
            return 0;
        }

        public enum WoolDefault
        {
            红绒 = 0,
            粗布 = 1
        }
        WoolDefault currentWoolDefault;
        WoolDefault woolDefault;

        MaterialProperty woolDefaultProb;
        GUIContent woolDefaultText = new GUIContent("布料预设", "选择会覆盖当前数值");
        WoolDefault DrawWoolDefault(Material material)
        {
            woolDefaultProb = FindMaterialProperty("_WoolDefault");
            if (woolDefaultProb != null)
            {
                material.DisableKeyword("_SILK_ON");
                FDG = FindMaterialProperty("_preIntegratedFGD");
                FDG.textureValue = AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath("feb5f9bf31e8bfd4ea525c51095b777f"));
                DoPopup(woolDefaultText, woolDefaultProb, Enum.GetNames(typeof(WoolDefault)));
                return (WoolDefault)material.GetFloat("_WoolDefault");
            }
            return 0;
        }

        bool silkDefaulChange;
        bool woolDefaulChange;

        bool optionsFoldOut;
        protected readonly GUIContent OptionsText = new GUIContent("配置参数", "可配置参数设置");

        protected readonly GUIContent FabricText = new GUIContent("布料/丝绸参数", "基本参数设置");

        bool plantShadowFoldOut;
        protected readonly GUIContent PlantShadow = new GUIContent("Plane Shadow(Not Self Shadow)");

        static int detailCount;

        Texture2D fabricExampleTex;

        void DrawSkinGUI(MaterialEditor materialEditor, Material material)
        {
            // Other ----------------------
            EditorGUILayout.Space();

            optionsFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(optionsFoldOut, OptionsText);
            if (optionsFoldOut)
            {
                EditorGUILayout.BeginVertical("box");
                {
                    SurfaceType surfaceType = DrawSurfaceTypeProp(material);
                    DrawCullModeProp(material);
                    DrawReceiveShadows(material);
                    if (surfaceType != SurfaceType.Transparent)
                        DrawAlphaClipProp(material);
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            EditorGUILayout.Space();
            EditorGUILayout.LabelField(FabricText, EditorStyles.boldLabel);

            // Toggle
            EditorGUILayout.BeginVertical("box");
            fabricType = DrawFabricType(material);

            // FabricType Default
            if (fabricType == FabricType.丝绸)
            {
                silkDefault = DrawSilkDefault(material);
                if (silkDefaulChange)
                {
                    currentSilkDefault = silkDefault;
                    silkDefaulChange = false;
                }

                if (currentSilkDefault != silkDefault)
                    silkDefaulChange = true;
            }
            else
            {
                woolDefault = DrawWoolDefault(material);
                if (woolDefaulChange)
                {
                    currentWoolDefault = woolDefault;
                    woolDefaulChange = false;
                }

                if (currentWoolDefault != woolDefault)
                    woolDefaulChange = true;
            }

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();

            // Main ------------------------
            EditorGUILayout.BeginVertical("box");

            // Base
            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("颜色贴图"), FindMaterialProperty("_BaseMap"), FindMaterialProperty("_BaseColor"));
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SpecColor"), "高光颜色", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SpecTintStrength"), "高光颜色强度", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Transmission_Tint"), "透光颜色", 2);

            // Normal
            MaterialProperty normal = FindMaterialProperty("_NormalMap");
            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("法线贴图"), normal, FindMaterialProperty("_NormalScale"));
            if (normal.textureValue != null)
                material.EnableKeyword("_NORMAL_ON");
            else
                material.DisableKeyword("_NORMAL_ON");

            // Mask Map
            base.DrawPropertyTexture(FindMaterialProperty("_MaskMap"), "PBR遮罩");
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Metallic"), "R 通道 : 金属度", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SmoothnessMax"), "B 通道 : 光滑度", 2);
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_OcclusionStrength"), "G 通道 : AO", 2);

            EditorGUILayout.EndVertical();


            EditorGUILayout.BeginVertical("box");

            if (fabricType == FabricType.丝绸)
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Anisotropy"), "各向异性方向", 2);

            EditorGUILayout.EndVertical();

            // Thread
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty thread = FindMaterialProperty("_UseThreadMap");
                if (thread != null)
                {
                    materialEditor.ShaderProperty(thread, EditorGUIUtility.TrTextContent("细节效果开启"), 2);
                    if (thread.floatValue != 0)
                    {
                        material.EnableKeyword("_THREADMAP_ON");
                        base.DrawPropertyTexture(FindMaterialProperty("_ThreadMap"), "细节贴图");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ThreadTilling"), "细节Tilling", 2);
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ThreadAOStrength"), "细节 Albedo", 2);
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ThreadNormalStrength"), "细节法线强度", 2);
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ThreadSmoothnessScale"), "细节光滑", 2);
                    }
                    else
                        material.DisableKeyword("_THREADMAP_ON");
                }
            }
            EditorGUILayout.EndVertical();

            // Fuzz
            EditorGUILayout.BeginVertical("box");
            {
                MaterialProperty fuzz = FindMaterialProperty("_Fuzz");
                if (fuzz != null)
                {
                    materialEditor.ShaderProperty(fuzz, EditorGUIUtility.TrTextContent("绒毛(Fuzz)效果开启"), 2);
                    if (fuzz.floatValue != 0)
                    {
                        material.EnableKeyword("_FUZZMAP_ON");

                        materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("绒毛贴图"), FindMaterialProperty("_FuzzMap"), FindMaterialProperty("_FuzzStrength"));
                        materialEditor.ShaderProperty(FindMaterialProperty("_FuzzMapUVScale"), "绒毛Tilling", 2);
                    }
                    else
                        material.DisableKeyword("_FUZZMAP_ON");
                }
            }
            EditorGUILayout.EndVertical();

            // Picture ----------------------
            EditorGUILayout.Space();
            if (fabricExampleTex == null)
                fabricExampleTex = AssetDatabase.LoadAssetAtPath<Texture2D>(AssetDatabase.GUIDToAssetPath("5ad59c94f48da9b4ba55f9d952869ef9"));
            else
                GUILayout.Box(fabricExampleTex, new GUIStyle("ButtonMid"));

            // PlantShadow ----------------------
            plantShadowFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(plantShadowFoldOut, PlantShadow);
            if (plantShadowFoldOut)
            {
                EditorGUILayout.BeginVertical("box");
                {
                    //需要与TA_HighQualityShadow.cs配合使用
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("ENABLE_HQ"), "ShadowType", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowColor"), "Shadow Color", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowHeight"), "Shadow Height", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetX"), "Shadow Offset X", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetZ"), "Shadow Offset Z", 2);
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ProGameOutDir"), "Pro Game Out Dir", 2);
                }
                EditorGUILayout.EndVertical();
                material.SetShaderPassEnabled("SGameShadowPass", true);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

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
