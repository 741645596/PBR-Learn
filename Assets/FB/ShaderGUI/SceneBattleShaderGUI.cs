using System;
using UnityEngine;
using UnityEditor;

namespace FBShaderGUI
{

    /// <summary>
    /// 局内英雄面板
    /// </summary>
    public class SceneBattleShaderGUI : CommonShaderGUI
    {
        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.OnGUI(materialEditor, materialProperties);
            Material material = m_MaterialEditor.target as Material;

            DrawSkinGUI(materialEditor, material);
            base.SetupMaterialKeywords(material);
            CopyLightMappingProperties();
        }

        void CopyLightMappingProperties()
        {
            MaterialProperty mainTex = FindMaterialProperty("_MainTex");

            MaterialProperty baseMap = FindMaterialProperty("_BaseMap");
            MaterialProperty baseMapMatCap = FindMaterialProperty("_BaseMapMatCap");
            MaterialProperty baseMapMatCapPBR = FindMaterialProperty("_BaseMapMatCapPBR");
            MaterialProperty pbrBaseMap = FindMaterialProperty("_PBRBaseMap");

            if (mainTex != null)
            {
                if (baseMap != null)
                {
                    mainTex.textureValue = baseMap.textureValue;
                    mainTex.textureScaleAndOffset = baseMap.textureScaleAndOffset;
                }

                if (baseMapMatCap != null)
                {
                    mainTex.textureValue = baseMapMatCap.textureValue;
                    mainTex.textureScaleAndOffset = baseMapMatCap.textureScaleAndOffset;
                }

                if (baseMapMatCapPBR != null)
                {
                    mainTex.textureValue = baseMapMatCapPBR.textureValue;
                    mainTex.textureScaleAndOffset = baseMapMatCapPBR.textureScaleAndOffset;
                }

                if (pbrBaseMap != null)
                {
                    mainTex.textureValue = pbrBaseMap.textureValue;
                    mainTex.textureScaleAndOffset = pbrBaseMap.textureScaleAndOffset;
                }
            }

            MaterialProperty color = FindMaterialProperty("_Color");
            MaterialProperty baseColor = FindMaterialProperty("_BaseColor");
            if (color != null && baseColor != null)
            {
                color.colorValue = baseColor.colorValue;
            }

        }


        static string[] _matTypes;

        static string[] matTypes
        {
            get
            {
                if (_matTypes==null)
                {
                    _matTypes = new string[] { "非PBR,不透明", "非PBR,透明", "PBR,不透明", "PBR,透明" };
                }
                return _matTypes;
            }
        }

        static string[] _matTypesNotPBR;

        static string[] matTypesNotPBR
        {
            get
            {
                if (_matTypesNotPBR == null)
                {
                    _matTypesNotPBR = new string[] { "非PBR,不透明", "非PBR,透明"};
                }
                return _matTypesNotPBR;
            }
        }

        static string[] _qualityType;

        static string[] qualityType
        {
            get
            {
                if (_qualityType == null)
                {
                    _qualityType = new string[] { "低配", "中配" , "高配" };
                }
                return _qualityType;
            }
        }

        /// <summary>
        /// 打包AB前对英雄材质无用纹理清空 
        /// </summary>
        /// <param name="material"></param>
        /// <param name="qualityType"></param>
        /// <returns></returns>
        public static void MatTextureClear(Material material,int qualityType)
        {

            material.SetFloat("_AlphaVal", 1);
            //关闭所有Pass
            material.SetShaderPassEnabled("UniversalForward", false);
            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", false);

            //关闭Key
            material.DisableKeyword("_LIGHT_TEX_ON");
            material.DisableKeyword("_LIGHT_TEX_HIFHT_ON");
            material.DisableKeyword("_LIGHT_TEXNORMAL_ON");
            material.DisableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
            material.DisableKeyword("_TRANSLUCENT");
            material.DisableKeyword("_LIGHT_ON");

            //纹理关联清空
            switch (qualityType)
            {
                case 0:
                    {
                        //低配
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Low"));//开启美术半透明控制
                        if (material.GetFloat("_MatType_Low") == 0 || material.GetFloat("_MatType_Low") == 1)
                        {
                            material.SetShaderPassEnabled("UniversalForward", true);
                            if (material.GetFloat("_MatType_Low") == 0)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                        }
                        else
                        {
                            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                            if (material.GetFloat("_MatType_Low") == 2)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                        }
                        material.renderQueue = 2000;
                    }
                    break;
                case 1:
                    {
                        //中配
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Mid"));//开启美术半透明控制

                        if (material.GetFloat("_MatCap_Mid") == 0)
                        {
                        }
                        else if(material.GetFloat("_MatCap_Mid") == 1)
                        {
                            //key
                            material.EnableKeyword("_LIGHT_TEX_ON");
                        }
                        else
                        {
                            //key
                            material.EnableKeyword("_LIGHT_TEXNORMAL_ON");
                        }
                        //pass
                        if (material.GetFloat("_MatType_Mid") == 0 || material.GetFloat("_MatType_Mid") == 1)
                        {
                            material.SetShaderPassEnabled("UniversalForward", true);
                            if (material.GetFloat("_MatType_Mid") == 0)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                        }
                        else
                        {
                            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                            if (material.GetFloat("_MatType_Mid") == 2)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                        }
                        material.renderQueue = 2000;
                    }
                    break;
                case 2:
                    {
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Hight"));//开启美术半透明控制
                                                                                                    //高配
                        if (material.GetFloat("_MatType_Hight") == 2 || material.GetFloat("_MatType_Hight") == 3)
                        {
                            //pass
                            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                            material.renderQueue = 2000;
                            if (material.GetFloat("_MatType_Hight") == 2)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                        }
                        else
                        {
                            if (material.GetFloat("_MatCap_Hight") == 0)
                            {
                            }
                            else if (material.GetFloat("_MatCap_Hight") == 1)
                            {
                                //key
                                material.EnableKeyword("_LIGHT_TEX_HIFHT_ON");
                            }
                            else
                            {
                                //key
                                material.EnableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
                            }
                            //pass
                            if (material.GetFloat("_MatType_Hight") == 0)
                            {
                                material.DisableKeyword("_TRANSLUCENT");
                            }
                            else
                            {
                                material.EnableKeyword("_TRANSLUCENT");
                            }
                            material.SetShaderPassEnabled("UniversalForward", true);
                            material.renderQueue = 2000;
                            if (material.GetFloat("_LightOn") == 1)
                            {
                                material.EnableKeyword("_LIGHT_ON");
                            }
                        }
                    }
                    break;
            }

            MatTextureClearGUI(material, qualityType);
        }

        public static void MatTextureClearGUI(Material material, int qualityType)
        {
            switch (qualityType)
            {
                case 0:
                    {
                        //低配
                        material.SetTexture("_BaseMapMatCap", null);
                        material.SetTexture("_BaseMapMatCapPBR", null);
                        material.SetTexture("_LightTex", null);
                        material.SetTexture("_LightTexG", null);
                        material.SetTexture("_LightTexB", null);
                        material.SetTexture("_LightTexA", null);
                        material.SetTexture("_MaskMap", null);
                        material.SetTexture("_AlbedoMap", null);
                        material.SetTexture("_BumpMap", null);
                        material.SetTexture("_MetallicGlossMap", null);
                        material.SetTexture("_EmissionMap", null);
                        material.SetTexture("_MatCapNormal", null);
                    }
                    break;
                case 1:
                    {
                        //中配
                        if (material.GetFloat("_MatCap_Mid") == 0)
                        {
                            material.SetTexture("_BaseMapMatCap", null);
                            material.SetTexture("_LightTex", null);
                            material.SetTexture("_LightTexG", null);
                            material.SetTexture("_MaskMap", null);
                            material.SetTexture("_MatCapNormal", null);
                        }
                        else if (material.GetFloat("_MatCap_Mid") == 1)
                        {
                            material.SetTexture("_BaseMap", null);
                            material.SetTexture("_MatCapNormal", null);
                        }
                        else
                        {
                            material.SetTexture("_BaseMap", null);
                        }
                        material.SetTexture("_BaseMapMatCapPBR", null);
                        material.SetTexture("_LightTexB", null);
                        material.SetTexture("_LightTexA", null);
                        material.SetTexture("_AlbedoMap", null);
                        material.SetTexture("_BumpMap", null);
                        material.SetTexture("_MetallicGlossMap", null);
                        material.SetTexture("_EmissionMap", null);
                    }
                    break;
                case 2:
                    {
                        //高配
                        if (material.GetFloat("_MatType_Hight") == 2 || material.GetFloat("_MatType_Hight") == 3)
                        {
                            //使用了PBR
                            material.SetTexture("_BaseMap", null);
                            material.SetTexture("_BaseMapMatCap", null);
                            material.SetTexture("_BaseMapMatCapPBR", null);
                            material.SetTexture("_LightTex", null);
                            material.SetTexture("_LightTexG", null);
                            material.SetTexture("_LightTexB", null);
                            material.SetTexture("_LightTexA", null);
                            material.SetTexture("_MaskMap", null);
                            material.SetTexture("_MatCapNormal", null);
                        }
                        else
                        {
                            if (material.GetFloat("_MatCap_Hight") == 0)
                            {
                                material.SetTexture("_BaseMapMatCap", null);
                                material.SetTexture("_BaseMapMatCapPBR", null);
                                material.SetTexture("_LightTex", null);
                                material.SetTexture("_LightTexG", null);
                                material.SetTexture("_LightTexB", null);
                                material.SetTexture("_LightTexA", null);
                                material.SetTexture("_MaskMap", null);
                                material.SetTexture("_MatCapNormal", null);
                            }
                            else if (material.GetFloat("_MatCap_Hight") == 1)
                            {
                                material.SetTexture("_BaseMap", null);
                                material.SetTexture("_BaseMapMatCap", null);
                                material.SetTexture("_MatCapNormal", null);
                            }
                            else
                            {
                                material.SetTexture("_BaseMap", null);
                                material.SetTexture("_BaseMapMatCap", null);
                            }
                            material.SetTexture("_AlbedoMap", null);
                            material.SetTexture("_BumpMap", null);
                            material.SetTexture("_MetallicGlossMap", null);
                            material.SetTexture("_EmissionMap", null);
                        }
                    }
                    break;
            }
        }

        void DrawSkinGUI(MaterialEditor materialEditor, Material material)
        {

            EditorGUILayout.LabelField(m_surfaceOptionsText, EditorStyles.boldLabel);

            EditorGUILayout.Space();

            //默认，草，河流
            DrawProperty(FindMaterialProperty("_MatType"), "材质球类型");

            if (material.IsKeywordEnabled("_MATTYPE_GRASSANIM"))
            {
                EditorGUILayout.Space();
                DrawProperty(FindMaterialProperty("_WindFreq"), "WindFreq");
                DrawProperty(FindMaterialProperty("_BendScale"), "BendScale");
                DrawProperty(FindMaterialProperty("_BranchAmp"), "BranchAmp");
                DrawProperty(FindMaterialProperty("_DetailFreq"), "DetailFreq");
                DrawProperty(FindMaterialProperty("_DetailAmp"), "DetailAmp");

                EditorGUILayout.Space();
            }

            if (material.IsKeywordEnabled("_MATTYPE_RIVER"))
            {
                EditorGUILayout.Space();
                DrawPropertyTexture(FindMaterialProperty("_WaveMaskTex"), "WaveMaskTex",false);
                DrawPropertyTexture(FindMaterialProperty("_WaveNoiseTex"), "WaveNoiseTex", true);
                DrawProperty(FindMaterialProperty("_WaveSpeed"), "WaveSpeed");
                DrawProperty(FindMaterialProperty("_WaveStrength"), "WaveStrength");
                EditorGUILayout.Space();
            }

            //品质选择
            bool qualityTypeChange = false;
            MaterialProperty quality = FindMaterialProperty("_QualityType");
            int qualityValue = (int)quality.floatValue;
            qualityValue = EditorGUILayout.Popup(qualityValue, qualityType);
            if (quality.floatValue != qualityValue)
            {
                qualityTypeChange = true;
            }
            quality.floatValue = qualityValue;

            EditorGUILayout.Space();
            //关闭所有Pass
            material.SetShaderPassEnabled("UniversalForward", false);
            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", false);

            MaterialProperty matTypeProperty = null;
            int matType = 0;
            switch (qualityValue)
            {
                case 0: //低配
                    {
                        matTypeProperty = FindMaterialProperty("_MatType_Low");
                        matType = (int)matTypeProperty.floatValue;
                        if (matType>1)
                        {
                            matType = matType - 2;
                        }
                        matType = EditorGUILayout.Popup(matType, matTypesNotPBR);

                        if (material.IsKeywordEnabled("_MATTYPE_GRASSANIM") || material.IsKeywordEnabled("_MATTYPE_RIVER"))
                        {
                            material.SetFloat("_MatType", 0);
                            material.EnableKeyword("_MATTYPE_NORMAL");
                            material.DisableKeyword("_MATTYPE_GRASSANIM");
                            material.DisableKeyword("_MATTYPE_RIVER");
                        }

                    }
                    break;
                case 1: //中配
                    {
                        matTypeProperty = FindMaterialProperty("_MatType_Mid");
                        matType = (int)matTypeProperty.floatValue;
                        if (matType > 1)
                        {
                            matType = matType - 2;
                        }
                        matType = EditorGUILayout.Popup(matType, matTypesNotPBR);

                    }
                    break;
                case 2: //高配
                    {
                        matTypeProperty = FindMaterialProperty("_MatType_Hight");
                        matType = (int)matTypeProperty.floatValue;
                        matType = EditorGUILayout.Popup(matType, matTypes);
                    }
                    break;
            }

            if (matType != 2 && matType != 3)
            {
                if (qualityValue==1)
                {
                    //MatCap
                    MaterialProperty lightTexOn = FindMaterialProperty("_LightTexOn");
                    if (lightTexOn != null && lightTexOn.floatValue == 1)
                    {
                        base.DrawPropertyTexture(FindMaterialProperty("_BaseMapMatCap"), "Base Map(RGB)", "", true);
                    }
                    else
                    {
                        base.DrawPropertyTexture(FindMaterialProperty("_BaseMap"), "Base Map(RGB)", "", true);
                    }
                }else if (qualityValue == 2)
                {
                    //MatCap
                    MaterialProperty lightTexOn = FindMaterialProperty("_LightTexOn");
                    if (lightTexOn != null && lightTexOn.floatValue == 1)
                    {
                        base.DrawPropertyTexture(FindMaterialProperty("_BaseMapMatCapPBR"), "Base Map(RGB)", "", true);
                    }
                    else
                    {
                        base.DrawPropertyTexture(FindMaterialProperty("_BaseMap"), "Base Map(RGB)", "", true);
                    }
                }
                else
                {
                    base.DrawPropertyTexture(FindMaterialProperty("_BaseMap"), "Base Map(RGB)", "", true);
                }
                base.DrawProperty(FindMaterialProperty("_BaseColor"), "颜色");
            }
            else
            {
                //PBR
                base.DrawPropertyTexture(FindMaterialProperty("_PBRBaseMap"), "AlbedoMap", "", true);
                base.DrawDoubleVector2FromVector4(FindMaterialProperty("_PBRBaseMapOffset"), "Tilling", "Offset");
                base.DrawProperty(FindMaterialProperty("_PBRBaseColor"), "AlbedoColor");
                EditorGUILayout.Space();
                base.DrawProperty(FindMaterialProperty("_BumpScale"), "法线强度");
                base.DrawPropertyTexture(FindMaterialProperty("_BumpMap"), "法线", "", false);
                EditorGUILayout.Space();
                base.DrawProperty(FindMaterialProperty("_Smoothness"), "光滑度");
                base.DrawProperty(FindMaterialProperty("_Metallic"), "金属度");
                base.DrawProperty(FindMaterialProperty("_OcclusionStrength"), "AO");
                base.DrawPropertyTexture(FindMaterialProperty("_MetallicGlossMap"), "R:金属度 G:AO B:皮肤范围 A:光滑度", "", false);
                EditorGUILayout.Space();

            }

            base.DrawProperty(FindMaterialProperty("_EmissionColor"), "EmissionColor");
            base.DrawPropertyTexture(FindMaterialProperty("_EmissionMap"), "Emission(自发光,A通道阴影强度)", "", false);

            matTypeProperty.floatValue = matType;
            switch (matType)
            {
                case 0: //非PBR,不透明
                    {
                        material.SetShaderPassEnabled("UniversalForward", true);
                        material.renderQueue = 2000;
                        material.DisableKeyword("_TRANSLUCENT");
                    }
                    break;
                case 1: //非PBR,透明
                    {
                        material.SetShaderPassEnabled("UniversalForward", true);
                        material.renderQueue = 2000;
                        material.EnableKeyword("_TRANSLUCENT");
                    }
                    break;
                case 2: //PBR,不透明
                    {
                        material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                        material.renderQueue = 2000;
                        material.DisableKeyword("_TRANSLUCENT");
                    }
                    break;
                case 3: //PBR,透明
                    {
                        material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                        material.renderQueue = 2000;
                        material.EnableKeyword("_TRANSLUCENT");
                    }
                    break;
            }

            if (matType == 1 || matType == 3)
            {
                if (FindMaterialProperty("_AlphaValClientTag").floatValue==1)
                {
                    base.DrawProperty(FindMaterialProperty("_AlphaVal"), "Alpha Val(程序用)");
                }
                else
                {
                    MaterialProperty alphaSet = FindMaterialProperty("_AlphaSet");
                    switch (qualityValue)
                    {
                        case 0:
                            {
                                MaterialProperty alphaSetSave_Low = FindMaterialProperty("_AlphaSetSave_Low");
                                alphaSet.floatValue = alphaSetSave_Low.floatValue;
                                base.DrawProperty(FindMaterialProperty("_AlphaSet"), "Alpha Val(美术用)");
                                alphaSetSave_Low.floatValue = alphaSet.floatValue;
                            }
                            break;
                        case 1:
                            {
                                MaterialProperty alphaSetSave_Mid = FindMaterialProperty("_AlphaSetSave_Mid");
                                alphaSet.floatValue = alphaSetSave_Mid.floatValue;
                                base.DrawProperty(FindMaterialProperty("_AlphaSet"), "Alpha Val(美术用)");
                                alphaSetSave_Mid.floatValue = alphaSet.floatValue;
                            }
                            break;
                        case 2:
                            {
                                MaterialProperty alphaSetSave_Hight = FindMaterialProperty("_AlphaSetSave_Hight");
                                alphaSet.floatValue = alphaSetSave_Hight.floatValue;
                                base.DrawProperty(FindMaterialProperty("_AlphaSet"), "Alpha Val(美术用)");
                                alphaSetSave_Hight.floatValue = alphaSet.floatValue;
                            }
                            break;
                    }
                }
            }

            EditorGUILayout.Space();
            //灯光反应
            EditorGUILayout.Space();
            switch (matType)
            {
                case 0: //非PBR,不透明
                case 1: //非PBR,透明
                    {
                        if (qualityValue!=2)
                        {
                            material.DisableKeyword("_LIGHT_ON");
                        }
                        else
                        {
                            MaterialProperty lightOn = FindMaterialProperty("_LightOn");
                            if (lightOn != null)
                            {
                                base.DrawProperty(lightOn, "灯光反应");
                                if (lightOn.floatValue == 1)
                                {
                                    base.DrawProperty(FindMaterialProperty("_MainLightStrength"), "主灯光反应");
                                    base.DrawProperty(FindMaterialProperty("_AddLightStrength"), "辅助灯光反应");
                                    material.EnableKeyword("_LIGHT_ON");
                                }
                                else
                                {
                                    material.DisableKeyword("_LIGHT_ON");
                                }
                            }
                            else
                            {
                                material.DisableKeyword("_LIGHT_ON");
                            }
                        }
                    }
                    break;
                case 2: //PBR,不透明
                case 3: //PBR,透明
                    {
                        //关闭灯光反应
                        material.DisableKeyword("_LIGHT_ON");
                    }
                    break;
            }

            //MatCap
            EditorGUILayout.Space();
            if (qualityValue != 0)
            {
                //中配
                //MatCap
                MaterialProperty lightTexOn = FindMaterialProperty("_LightTexOn");
                if (lightTexOn != null)
                {
                    bool matCapOpen = false;
                    if (qualityValue == 1 || (qualityValue == 2 && (matType == 0 || matType == 1)))
                    {
                        if (qualityValue == 1)
                        {
                            //中配
                            if (FindMaterialProperty("_MatCap_Mid").floatValue != 0)
                            {
                                matCapOpen = true;
                            }
                        }
                        else
                        {
                            //高配
                            if (FindMaterialProperty("_MatCap_Hight").floatValue != 0)
                            {
                                matCapOpen = true;
                            }
                        }
                        if (matCapOpen)
                        {
                            lightTexOn.floatValue = 1;
                        }
                        else
                        {
                            lightTexOn.floatValue = 0;
                        }
                        base.DrawProperty(lightTexOn, "开启MatCap");
                    }
                    else
                    {
                        lightTexOn.floatValue = 0;
                    }
                    if (lightTexOn.floatValue != 0)
                    {
                        if (qualityValue == 1)
                        {
                            //中配打开法线选项 此处禁用中配开启法线
                            bool openMatCapNormal = false;
                            //bool openMatCapNormal = FindMaterialProperty("_MatCap_Mid").floatValue == 2 ? true : false;
                            //openMatCapNormal = EditorGUILayout.Toggle("法线", openMatCapNormal);
                            FindMaterialProperty("_MatCap_Mid").floatValue = openMatCapNormal ? 2 : 1;
                            //
                            base.DrawProperty(FindMaterialProperty("_MainColor"), "MainColor(基本纹理比重)");
                            base.DrawProperty(FindMaterialProperty("_LightScale"), "Light Scale(MatCap强度)");
                            base.DrawProperty(FindMaterialProperty("_LightWeight"), "Light Scale(MatCap权重)");
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTex"), "Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTexG"), "Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_MaskMap"), "Mask: RG(MatCap区域)", "", false);
                            //
                            material.DisableKeyword("_LIGHT_TEX_HIFHT_ON");
                            material.DisableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
                            if (openMatCapNormal)
                            {
                                EditorGUILayout.Space();
                                base.DrawProperty(FindMaterialProperty("_MatCapNormalScale"), "NormalScale");
                                base.DrawPropertyTexture(FindMaterialProperty("_MatCapNormal"), "Normal", "", false);
                                //
                                material.DisableKeyword("_LIGHT_TEX_ON");
                                material.EnableKeyword("_LIGHT_TEXNORMAL_ON");
                            }
                            else
                            {
                                material.EnableKeyword("_LIGHT_TEX_ON");
                                material.DisableKeyword("_LIGHT_TEXNORMAL_ON");
                            }
                        }
                        else if (qualityValue == 2)
                        {
                            //高配打开法线选项
                            bool openMatCapNormal = FindMaterialProperty("_MatCap_Hight").floatValue == 2 ? true : false;
                            openMatCapNormal = EditorGUILayout.Toggle("法线", openMatCapNormal);
                            FindMaterialProperty("_MatCap_Hight").floatValue = openMatCapNormal ? 2 : 1;
                            //
                            base.DrawProperty(FindMaterialProperty("_MainColor"), "MainColor(基本纹理比重)");
                            base.DrawProperty(FindMaterialProperty("_LightScale"), "Light Scale(MatCap强度)");
                            base.DrawProperty(FindMaterialProperty("_LightWeight"), "Light Scale(MatCap权重)");
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTex"), "R Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTexG"), "G Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTexB"), "B Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTexA"), "A Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_MaskMap"), "Mask: RGBA(MatCap区域)", "", false);
                            //
                            material.DisableKeyword("_LIGHT_TEX_ON");
                            material.DisableKeyword("_LIGHT_TEXNORMAL_ON");
                            if (openMatCapNormal)
                            {
                                EditorGUILayout.Space();
                                base.DrawProperty(FindMaterialProperty("_MatCapNormalScale"), "NormalScale");
                                base.DrawPropertyTexture(FindMaterialProperty("_MatCapNormal"), "Normal", "", false);
                                //
                                material.DisableKeyword("_LIGHT_TEX_HIFHT_ON");
                                material.EnableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
                            }
                            else
                            {
                                material.EnableKeyword("_LIGHT_TEX_HIFHT_ON");
                                material.DisableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
                            }
                        }
                    }
                    else
                    {
                        if (qualityValue == 1)
                        {
                            //中配
                            FindMaterialProperty("_MatCap_Mid").floatValue = 0;
                        }
                        else if (qualityValue == 2)
                        {
                            //高配
                            FindMaterialProperty("_MatCap_Hight").floatValue = 0;
                        }
                        material.DisableKeyword("_LIGHT_TEX_ON");
                        material.DisableKeyword("_LIGHT_TEX_HIFHT_ON");
                        material.DisableKeyword("_LIGHT_TEXNORMAL_ON");
                        material.DisableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
                    }
                }
            }
            else
            {
                material.DisableKeyword("_LIGHT_TEX_ON");
                material.DisableKeyword("_LIGHT_TEX_HIFHT_ON");
                material.DisableKeyword("_LIGHT_TEXNORMAL_ON");
                material.DisableKeyword("_LIGHT_TEXNORMAL_HIFHT_ON");
            }

            //_ThisLightMapOn
            MaterialProperty thisLightMapOn = FindMaterialProperty("_THISLIGHTMAPON");
            if (thisLightMapOn!=null)
            {
                base.DrawProperty(thisLightMapOn, "LightMap");
                if (thisLightMapOn.floatValue==1)
                {
                    material.EnableKeyword("_THISLIGHTMAP_ON");
                }
                else
                {
                    material.DisableKeyword("_THISLIGHTMAP_ON");
                }
                if (thisLightMapOn.floatValue!=0)
                {
                    if (matType == 0 || matType == 1)
                    {
                        MaterialProperty lightMapEncodeOn = FindMaterialProperty("_LIGHTMAPENCODEON");
                        DrawProperty(lightMapEncodeOn, "LightMap解码");
                    }
                }
            }

            //DrawQueueOnGUI(materialEditor);
            if (qualityTypeChange)
            {
                //清理无效纹理关联
                MatTextureClearGUI(material, qualityValue);
            }

            if (material != null)
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
        }

    }

}

