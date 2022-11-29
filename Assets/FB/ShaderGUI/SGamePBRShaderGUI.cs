using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

namespace FBShaderGUI
{
    public class SGamePBRShaderGUI : CommonShaderGUI
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
            ClosePass(material);
            DrawSkinGUI(materialEditor, material);
            base.SetupMaterialKeywords(material);
            ChangeShadowType(material);
        }

        MaterialProperty shadowType;

        void ClosePass(Material material)
        {
            material.SetShaderPassEnabled("SGameShadowPassTrans", false);
            material.SetShaderPassEnabled("SGameShadowPass", false);
        }

        void ChangeShadowType(Material mat)
        {
            if (shadowType != null)
            {
                switch (shadowType.floatValue)
                {
                    case 0:     // Unity Shadow
                        mat.SetFloat("ENABLE_HQ", 0);
                        mat.DisableKeyword("ENABLE_HQ_SHADOW");
                        break;
                    case 1f:    // HQ SHADOW
                        mat.SetFloat("ENABLE_HQ", 1);
                        mat.EnableKeyword("ENABLE_HQ_SHADOW");
                        break;
                }

            }
        }

        bool optionsFoldOut;
        protected readonly GUIContent OptionsText = new GUIContent("配置参数", "可配置参数设置");

        protected readonly GUIContent PBRText = new GUIContent("PBR参数", "基本参数设置");

        bool shadowFoldOut;
        protected readonly GUIContent ShadowSetting = new GUIContent("阴影设置");

        MaterialProperty detailCount;
        MaterialProperty emission_map;
        MaterialProperty clearcoat_map;
        MaterialProperty clearCoatCubeMap;
        MaterialProperty detail_id;
        MaterialProperty laser_map;
        MaterialProperty iridescence;
        MaterialProperty iridescence_map;

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

                    if (surfaceType == SurfaceType.Transparent)
                    {
                        MaterialProperty preZ = FindMaterialProperty("_PreZ");
                        m_MaterialEditor.ShaderProperty(preZ, "预写入深度");
                        material.SetShaderPassEnabled("SGameShadowPassTrans", preZ.floatValue != 0);
                    }
                    else
                    {
                        material.SetShaderPassEnabled("SGameShadowPassTrans", false);
                    }

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
            if (normal.textureValue != null && material.shader.name.CompareTo("FB/Standard/SGamePBRUber_real") == 0)
            {
                // Bent normal
                MaterialProperty bent_normal = FindMaterialProperty("_BentNormalMap");
                m_MaterialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("Bent法线贴图"), bent_normal, FindMaterialProperty("_SpecularOcclusionStrength"));
                if (normal != null && bent_normal != null && bent_normal.textureValue != null)
                    material.EnableKeyword("_SPECULAROCCLUSION_ON");
                else
                    material.DisableKeyword("_SPECULAROCCLUSION_ON");
            }


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

            // PBRUber Part
            if (material.shader.name.CompareTo("FB/Standard/SGamePBRUber") == 0 || material.shader.name.CompareTo("FB/Standard/SGamePBRUber_real") == 0)
            {
                MaterialProperty detail = null;
                // Clear Coat
                EditorGUILayout.BeginVertical("box");
                {
                    MaterialProperty clearCoat = FindMaterialProperty("_ClearCoat");
                    if (clearCoat != null)
                    {
                        m_MaterialEditor.ShaderProperty(clearCoat, EditorGUIUtility.TrTextContent("清漆"), 2);
                        if (clearCoat.floatValue != 0)
                        {
                            material.EnableKeyword("_CLEARCOAT_ON");

                            clearcoat_map = FindMaterialProperty("_ClearCoatMap");
                            base.DrawPropertyTexture(clearcoat_map, "清漆遮罩(透明度)");
                            if (clearcoat_map.textureValue != null)
                                material.EnableKeyword("_CLEARCOATMAP");
                            else
                                material.DisableKeyword("_CLEARCOATMAP");

                            clearCoatCubeMap = FindMaterialProperty("_ClearCoatCubeMap");
                            base.DrawPropertyTexture(clearCoatCubeMap, "清漆反射球");
                            if (clearCoatCubeMap.textureValue != null)
                                material.EnableKeyword("_CLEARCOATCUBEMAP_ON");
                            else
                                material.DisableKeyword("_CLEARCOATCUBEMAP_ON");

                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ClearCoatMask"), "清漆透明度", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ClearCoatSmoothness"), "清漆光滑度", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ClearCoatDownSmoothness"), "清漆底层光滑度", 2);

                            if (detail != null && detail.floatValue != 0)
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ClearCoat_Detail_Factor"), "清漆 Detail 强度", 2);

                        }
                        else
                        {
                            material.DisableKeyword("_CLEARCOAT_ON");

                            if (clearcoat_map != null)
                                clearcoat_map.textureValue = null;

                            if (clearCoatCubeMap != null)
                                clearCoatCubeMap.textureValue = null;
                        }
                    }
                }
                EditorGUILayout.EndVertical();

                // Detail Map
                EditorGUILayout.BeginVertical("box");
                {
                    detail = FindMaterialProperty("_UseDetailMap");
                    if (detail != null)
                    {
                        m_MaterialEditor.ShaderProperty(detail, EditorGUIUtility.TrTextContent("细节(Detail)"), 2);
                        if (detail.floatValue != 0)
                        {
                            material.EnableKeyword("_DETAILMAP_ON");

                            detail_id = FindMaterialProperty("_Detail_ID");
                            base.DrawPropertyTexture(detail_id, "细节 ID");

                            detailCount = FindMaterialProperty("_Detail_Layer");
                            m_MaterialEditor.ShaderProperty(detailCount, "细节层数", 2);

                            int count = (int)detailCount.floatValue;

                            for (int i = 1; i <= count; i++)
                            {
                                EditorGUILayout.BeginVertical("box");
                                {
                                    // m_MaterialEditor.TextureScaleOffsetProperty(detail_map);
                                    string channelName = "";
                                    switch (i)
                                    {
                                        case 1:
                                            channelName = " (R通道)";
                                            break;
                                        case 2:
                                            channelName = " (G通道)";
                                            break;
                                        case 3:
                                            channelName = " (B通道)";
                                            break;
                                        default:
                                            channelName = " (A通道)";
                                            break;
                                    }
                                    // base.DrawPropertyTexture(FindMaterialProperty("_DetailMap_" + i), "细节贴图" + i + channelName);
                                    m_MaterialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("细节贴图" + i + channelName), FindMaterialProperty("_DetailMap_" + i), FindMaterialProperty("_DetailAlbedoColor_" + i));
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DetailMap_Tilling_" + i), "缩放(Tilling)", 2);
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DetailAlbedoScale_" + i), "Albedo 强度", 2);
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DetailNormalScale_" + i), "法线强度", 2);
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DetailSmoothnessScale_" + i), "光滑度", 2);
                                }
                                EditorGUILayout.EndVertical();
                                EditorGUILayout.Space();
                            }
                        }
                        else
                        {
                            material.DisableKeyword("_DETAILMAP_ON");

                            if (detail_id != null)
                                detail_id.textureValue = null;

                            if (detailCount != null)
                            {
                                for (int i = 1; i <= (int)detailCount.floatValue; i++)
                                {
                                    if (FindMaterialProperty("_DetailMap_" + i) != null)
                                        FindMaterialProperty("_DetailMap_" + i).textureValue = null;
                                }
                            }
                        }
                    }
                }
                EditorGUILayout.EndVertical();

                // Laser
                EditorGUILayout.BeginVertical("box");
                {
                    MaterialProperty laser = FindMaterialProperty("_UseLaser");
                    if (laser != null)
                    {
                        m_MaterialEditor.ShaderProperty(laser, EditorGUIUtility.TrTextContent("风格化镭射"), 2);
                        if (laser.floatValue != 0)
                        {
                            material.EnableKeyword("_LASER_ON");
                            laser_map = FindMaterialProperty("_LaserMap");
                            materialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("镭射遮罩"), laser_map, FindMaterialProperty("_LaserColor"));
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserBrdfIntensity"), "PBR强度", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserIOR"), "颜色区间", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserThickness"), "镭射厚度", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserSmoothstepValue_1"), "镭射边缘阈值1", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserSmoothstepValue_2"), "镭射边缘阈值2", 2);

                            MaterialProperty universalLaser = FindMaterialProperty("_LaserUniversal");
                            m_MaterialEditor.ShaderProperty(universalLaser, "万向镭射", 2);
                            if (universalLaser.floatValue == 0)
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserAnisotropy"), "各向异性方向", 2);

                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_LaserAreaCubemapInt"), "环境球强度", 2);
                        }
                        else
                        {
                            material.DisableKeyword("_LASER_ON");

                            if (laser_map != null)
                                laser_map.textureValue = null;
                        }
                    }
                }
                EditorGUILayout.EndVertical();

                if (material.shader.name.CompareTo("FB/Standard/SGamePBRUber_real") == 0)
                {
                    // Iridescence
                    EditorGUILayout.BeginVertical("box");
                    {
                        MaterialProperty iridescence = FindMaterialProperty("_UseIridescence");
                        if (iridescence != null)
                        {
                            m_MaterialEditor.ShaderProperty(iridescence, EditorGUIUtility.TrTextContent("物理镭射"), 2);
                            if (iridescence.floatValue != 0)
                            {
                                material.EnableKeyword("_IRIDENSCENE_ON");
                                iridescence_map = FindMaterialProperty("_IridescenceMask");

                                m_MaterialEditor.TexturePropertySingleLine(EditorGUIUtility.TrTextContent("镭射遮罩"), iridescence_map, FindMaterialProperty("_Iridescence"));
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_IridescenceThickness"), "镭射厚度", 2);
                            }
                            else
                            {
                                material.DisableKeyword("_IRIDENSCENE_ON");

                                if (iridescence_map != null)
                                    iridescence_map.textureValue = null;
                            }
                        }
                    }
                    EditorGUILayout.EndVertical();

                    // Subsurface
                    EditorGUILayout.BeginVertical("box");
                    {
                        MaterialProperty subsurface = FindMaterialProperty("_UseSubsurface");
                        if (subsurface != null)
                        {
                            m_MaterialEditor.ShaderProperty(subsurface, EditorGUIUtility.TrTextContent("次表面散射"), 2);
                            if (subsurface.floatValue != 0)
                            {
                                material.EnableKeyword("_SUBSURFACE_ON");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SubsurfaceColor"), "次表面散射颜色", 2);
                            }
                            else
                                material.DisableKeyword("_SUBSURFACE_ON");
                        }
                    }
                    EditorGUILayout.EndVertical();

                    // Anisotropy
                    EditorGUILayout.BeginVertical("box");
                    {
                        MaterialProperty subsurface = FindMaterialProperty("_UseAnisotropy");
                        if (subsurface != null)
                        {
                            m_MaterialEditor.ShaderProperty(subsurface, EditorGUIUtility.TrTextContent("各向异性"), 2);
                            if (subsurface.floatValue != 0)
                            {
                                material.EnableKeyword("_ANISOTROPY_ON");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Anisotropy"), "各向异性方向", 2);
                            }
                            else
                                material.DisableKeyword("_ANISOTROPY_ON");
                        }
                    }
                    EditorGUILayout.EndVertical();
                }
            }

            // Shadow Setting ----------------------
            shadowFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(shadowFoldOut, ShadowSetting);
            if (shadowFoldOut)
            {
                //需要与TA_HighQualityShadow.cs配合使用
                shadowType = FindMaterialProperty("ENABLE_HQ");
                m_MaterialEditor.ShaderProperty(shadowType, "ShadowType", 2);


                MaterialProperty planarShadow = FindMaterialProperty("_PlanarShadow");
                if (planarShadow != null)
                {
                    m_MaterialEditor.ShaderProperty(planarShadow, EditorGUIUtility.TrTextContent("平面阴影"), 2);
                    if (planarShadow.floatValue != 0)
                    {
                        EditorGUILayout.BeginVertical("box");
                        {
                            material.SetShaderPassEnabled("SGameShadowPass", true);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowColor"), "Shadow Color", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowHeight"), "Shadow Height", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetX"), "Shadow Offset X", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ShadowOffsetZ"), "Shadow Offset Z", 2);
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ProGameOutDir"), "Pro Game Out Dir", 2);
                        }
                        EditorGUILayout.EndVertical();
                    }
                    else
                        material.SetShaderPassEnabled("SGameShadowPass", false);
                }

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

                    material.renderQueue += material.HasProperty("_queueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
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

