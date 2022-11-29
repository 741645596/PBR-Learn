using System;
using UnityEngine;
using UnityEditor;

namespace FBShaderGUI
{

    /// <summary>
    /// 局内动态草面板
    /// </summary>
    public class GrassBattleShaderGUI : CommonShaderGUI
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

        //[MenuItem("GameObject/设置为半透明")]
        //static void SetModel()
        //{
        //    GameObject obj = Selection.activeGameObject;
        //    SkinnedMeshRenderer[] skms = obj.GetComponentsInChildren<SkinnedMeshRenderer>();
        //    for (int i = 0, listCount = skms.Length; i < listCount; ++i)
        //    {
        //        SkinnedMeshRenderer smr = skms[i];
        //        Material[] mats = smr.sharedMaterials;
        //        for (int j = 0, listCount2 = mats.Length; j < listCount2; ++j)
        //        {
        //            SetModelTrans(mats[j]);
        //        }
        //    }
        //}

        //[MenuItem("GameObject/设置为不透明")]
        //static void SetModel2()
        //{
        //    GameObject obj = Selection.activeGameObject;
        //    SkinnedMeshRenderer[] skms = obj.GetComponentsInChildren<SkinnedMeshRenderer>();
        //    for (int i = 0, listCount = skms.Length; i < listCount; ++i)
        //    {
        //        SkinnedMeshRenderer smr = skms[i];
        //        Material[] mats = smr.sharedMaterials;
        //        for (int j = 0, listCount2 = mats.Length; j < listCount2; ++j)
        //        {
        //            SetModelOp(mats[j]);
        //        }
        //    }
        //}

        //[MenuItem("GameObject/三级")]
        //static void SetModel3()
        //{
        //    GameObject obj = Selection.activeGameObject;
        //    GetCloneModel(0, obj);
        //    GetCloneModel(1, obj);
        //    GetCloneModel(2, obj);
        //}

        /// <summary>
        /// 设置为半透明 程序调用 调用后程序使用_AlphaVal参数调整半透明
        /// </summary>
        /// <param name="srcMaterial"></param>
        public static void SetModelTrans(Material srcMaterial)
        {
            if (srcMaterial.shader==null || srcMaterial.shader.name.CompareTo("FB/GameHero/HeroBattle") !=0) return;
            srcMaterial.SetFloat("_AlphaSet", 1); //关闭美术半透明参数
            srcMaterial.SetFloat("_AlphaValClientTag", 1); //开启程序控制标记
            switch (srcMaterial.GetFloat("_QualityType"))
            {
                case 0: //低配
                    {
                        srcMaterial.SetShaderPassEnabled("UniversalForward", false);
                        srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", true);
                        srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                        srcMaterial.renderQueue = 2600;
                        srcMaterial.SetFloat("_MatType_Low",1);
                    }
                    break;
                case 1: //中配
                    {
                        srcMaterial.SetShaderPassEnabled("UniversalForward", false);
                        srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", true);
                        srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                        srcMaterial.renderQueue = 2600;
                        srcMaterial.SetFloat("_MatType_Mid", 1);
                    }
                    break;
                case 2: //高配
                    {
                        if (srcMaterial.GetFloat("_MatType_Hight") == 0)
                        {
                            //非PBR
                            srcMaterial.SetShaderPassEnabled("UniversalForward", false);
                            srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", true);
                            srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                            srcMaterial.SetFloat("_MatType_Hight", 1);
                        }
                        else
                        {
                            //PBR
                            srcMaterial.SetShaderPassEnabled("UniversalForwardPbrOpacity", false);
                            srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", true);
                            srcMaterial.SetShaderPassEnabled("UniversalForwardPbrTranslucent", true);
                            srcMaterial.SetFloat("_MatType_Hight", 3);
                        }
                        srcMaterial.renderQueue = 2600;
                    }
                    break;
            }
        }

        /// <summary>
        /// 设置为不透明
        /// </summary>
        /// <param name="srcMaterial"></param>
        public static void SetModelOp(Material srcMaterial)
        {
            if (srcMaterial.shader == null || srcMaterial.shader.name.CompareTo("FB/GameHero/HeroBattle") != 0) return;
            srcMaterial.SetFloat("_AlphaVal",1);//关闭程序半透明控制
            srcMaterial.SetFloat("_AlphaValClientTag", 0); //关闭程序控制标记
            switch (srcMaterial.GetFloat("_QualityType"))
            {
                case 0: //低配
                    {
                        srcMaterial.SetFloat("_AlphaSet", srcMaterial.GetFloat("_AlphaSetSave_Low"));//开启美术半透明控制
                        srcMaterial.SetShaderPassEnabled("UniversalForward", true);
                        srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", false);
                        srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", false);
                        srcMaterial.renderQueue = 2272;
                        srcMaterial.SetFloat("_MatType_Low", 0);
                    }
                    break;
                case 1: //中配
                    {
                        srcMaterial.SetFloat("_AlphaSet", srcMaterial.GetFloat("_AlphaSetSave_Mid"));//开启美术半透明控制
                        srcMaterial.SetShaderPassEnabled("UniversalForward", true);
                        srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", false);
                        srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", false);
                        srcMaterial.renderQueue = 2272;
                        srcMaterial.SetFloat("_MatType_Low", 0);
                    }
                    break;
                case 2: //高配
                    {
                        srcMaterial.SetFloat("_AlphaSet", srcMaterial.GetFloat("_AlphaSetSave_Hight"));//开启美术半透明控制
                        if (srcMaterial.GetFloat("_MatType_Hight")==1)
                        {
                            //非PBR
                            srcMaterial.SetShaderPassEnabled("UniversalForward", true);
                            srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", false);
                            srcMaterial.SetShaderPassEnabled("UniversalForwardTranslucent", false);
                            srcMaterial.SetFloat("_MatType_Hight", 0);
                        }
                        else
                        {
                            //PBR
                            srcMaterial.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                            srcMaterial.SetShaderPassEnabled("SrpDefaultUnlit", false);
                            srcMaterial.SetShaderPassEnabled("UniversalForwardPbrTranslucent", false);
                            srcMaterial.SetFloat("_MatType_Hight", 2);
                        }
                        srcMaterial.renderQueue = 2272;
                    }
                    break;
            }
        }

        /// <summary>
        /// 根据 低中高 配置获得克隆模型
        /// </summary>
        /// <param name="qualityLV">0:低配 1：中配 2：高配</param>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static GameObject GetCloneModel(int qualityLV, GameObject obj)
        {
            GameObject instObj = GameObject.Instantiate(obj);
            SkinnedMeshRenderer[] smrs = instObj.GetComponentsInChildren<SkinnedMeshRenderer>();
            for (int i=0,listCount = smrs.Length;i< listCount;++i)
            {
                SkinnedMeshRenderer smr = smrs[i];
                Material[] sharedMats = smr.sharedMaterials;
                if (sharedMats!=null && sharedMats.Length>0)
                {
                    Material[] newMats = new Material[sharedMats.Length];
                    for (int j = 0, listCount2 = sharedMats.Length; j < listCount2; ++j)
                    {
                        Material newMat = null;
                        if (sharedMats[j]!=null)
                        {
                            newMat = GetCloneMat(qualityLV, sharedMats[j]);
                            if (newMat != null)
                            {
                                newMats[j] = newMat;
                            }
                            else
                            {
                                newMats[j] = sharedMats[j];
                            }
                        }
                        else
                        {
                            newMats[j] = null;
                        }

                    }
                    smr.sharedMaterials = newMats;
                }
            }
            return instObj;
        }

        /// <summary>
        /// 根据 低中高 配置获得克隆材质
        /// </summary>
        /// <param name="qualityLV">0:低配 1:中配 2:高配</param>
        /// <param name="material"></param>
        /// <returns></returns>
        public static Material GetCloneMat(int qualityLV, Material srcMaterial)
        {
            if (srcMaterial!=null && srcMaterial.shader!=null && srcMaterial.shader == Shader.Find("FB/GameHero/HeroBattle"))
            {
                Material material = GameObject.Instantiate(srcMaterial);
                material.SetFloat("_QualityType", qualityLV);
                MatTextureClear(material, qualityLV);
                return material;
            }
            return null;
        }

        /// <summary>
        /// 打包AB前对英雄材质进行清理检测
        /// </summary>
        public static void BeforeABMatCheck()
        {
            //目录 Assets/Art/Character/player/Character  Assets/Art/Character/organ/Character  Assets/Art/Character/monster/Character Assets/Art/Character/soldier/Character
            System.Collections.Generic.List<Material> mats = new System.Collections.Generic.List<Material>();
            for (int i=0,listCount = mats.Count;i< listCount;++i)
            {
                Material mat = mats[i];
                int qualityLV = (int)mat.GetFloat("_QualityType");
                //设置材质状态 清空无效纹理
                MatTextureClear(mat, qualityLV);
                //检查材质正确性
                switch (qualityLV)
                {
                    case 0:
                        {
                            if (!mat.name.Contains("_L_"))
                            {
                                //材质配置错误
                                UnityEngine.Debug.LogError(string.Format("材质低配匹配错误：材质名{0}", mat.name));
                            }
                        }
                        break;
                    case 1:
                        {
                            if (!mat.name.Contains("_M_"))
                            {
                                //材质配置错误 
                                UnityEngine.Debug.LogError(string.Format("材质中配匹配错误：材质名{0}", mat.name));
                            }
                        }
                        break;
                    case 2:
                        {
                            if (!mat.name.Contains("_H_"))
                            {
                                //材质配置错误 
                                UnityEngine.Debug.LogError(string.Format("材质高配匹配错误：材质名{0}", mat.name));
                            }
                        }
                        break;
                }
            }
            AssetDatabase.Refresh();
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
            material.SetShaderPassEnabled("SrpDefaultUnlit", false);
            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", false);
            material.SetShaderPassEnabled("UniversalForwardTranslucent", false);
            material.SetShaderPassEnabled("UniversalForwardPbrTranslucent", false);

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
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Low"));//开启美术半透明控制
                                                                                                  //低配
                        //pass
                        if (material.GetFloat("_MatType_Low") == 0)
                        {
                            material.SetShaderPassEnabled("UniversalForward", true);
                            material.renderQueue = 2272;
                        }
                        else
                        {
                            material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                            material.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                            material.renderQueue = 2600;
                        }
                        //key

                    }
                    break;
                case 1:
                    {
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Mid"));//开启美术半透明控制
                                                                                                  //中配
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
                        if (material.GetFloat("_MatType_Mid") == 0)
                        {
                            material.SetShaderPassEnabled("UniversalForward", true);
                            material.renderQueue = 2272;
                        }
                        else
                        {
                            material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                            material.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                            material.renderQueue = 2600;
                        }
                    }
                    break;
                case 2:
                    {
                        material.SetFloat("_AlphaSet", material.GetFloat("_AlphaSetSave_Hight"));//开启美术半透明控制
                                                                                                    //高配
                        if (material.GetFloat("_MatType_Hight") == 2 || material.GetFloat("_MatType_Hight") == 3)
                        {
                            //pass
                            if (material.GetFloat("_MatType_Hight") == 2)
                            {
                                material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                                material.renderQueue = 2272;
                            }
                            else
                            {
                                material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                                material.SetShaderPassEnabled("UniversalForwardPbrTranslucent", true);
                                material.renderQueue = 2600;
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
                                material.SetShaderPassEnabled("UniversalForward", true);
                                material.renderQueue = 2272;
                            }
                            else
                            {
                                material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                                material.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                                material.renderQueue = 2600;
                            }
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
                        material.SetTexture("_LightTexG", null);
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
            material.SetShaderPassEnabled("SrpDefaultUnlit", false);
            material.SetShaderPassEnabled("UniversalForwardPbrOpacity", false);
            material.SetShaderPassEnabled("UniversalForwardTranslucent", false);
            material.SetShaderPassEnabled("UniversalForwardPbrTranslucent", false);

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
                base.DrawPropertyTexture(FindMaterialProperty("_AlbedoMap"), "AlbedoMap", "", true);
                base.DrawProperty(FindMaterialProperty("_AlbedoColor"), "AlbedoColor");
                EditorGUILayout.Space();
                base.DrawProperty(FindMaterialProperty("_BumpScale"), "法线强度");
                base.DrawPropertyTexture(FindMaterialProperty("_BumpMap"), "法线", "", false);
                EditorGUILayout.Space();
                base.DrawProperty(FindMaterialProperty("_Smoothness"), "光滑度");
                base.DrawProperty(FindMaterialProperty("_Metallic"), "金属度");
                base.DrawProperty(FindMaterialProperty("_OcclusionStrength"), "AO");
                base.DrawPropertyTexture(FindMaterialProperty("_MetallicGlossMap"), "R:金属度 G:AO B:皮肤范围 A:光滑度", "", false);
                EditorGUILayout.Space();
                base.DrawProperty(FindMaterialProperty("_EmissionColor"), "EmissionColor");
                base.DrawPropertyTexture(FindMaterialProperty("_EmissionMap"), "Emission(自发光,A通道阴影强度)", "", false);
            }
            matTypeProperty.floatValue = matType;
            switch (matType)
            {
                case 0: //非PBR,不透明
                    {
                        material.SetShaderPassEnabled("UniversalForward", true);
                        material.renderQueue = 2272;
                    }
                    break;
                case 1: //非PBR,透明
                    {
                        material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                        material.SetShaderPassEnabled("UniversalForwardTranslucent", true);
                        material.renderQueue = 2600;
                    }
                    break;
                case 2: //PBR,不透明
                    {
                        material.SetShaderPassEnabled("UniversalForwardPbrOpacity", true);
                        material.renderQueue = 2272;
                    }
                    break;
                case 3: //PBR,透明
                    {
                        material.SetShaderPassEnabled("SrpDefaultUnlit", true);
                        material.SetShaderPassEnabled("UniversalForwardPbrTranslucent", true);
                        material.renderQueue = 2600;
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
                            base.DrawPropertyTexture(FindMaterialProperty("_LightTex"), "Light Tex(MatCap)", "", false);
                            base.DrawPropertyTexture(FindMaterialProperty("_MaskMap"), "Mask: R(MatCap区域)", "", false);
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
            MaterialProperty thisLightMapOn = FindMaterialProperty("_ThisLightMapOn");
            if (thisLightMapOn!=null)
            {
                base.DrawProperty(thisLightMapOn, "LightMap");
                thisLightMapOn = FindMaterialProperty("_ThisLightMapOn");
                if (thisLightMapOn.floatValue==1)
                {
                    material.EnableKeyword("_THISLIGHTMAP_ON");
                }
                else
                {
                    material.DisableKeyword("_THISLIGHTMAP_ON");
                }
            }

            //DrawQueueOnGUI(materialEditor);
            if (qualityTypeChange)
            {
                //清理无效纹理关联
                MatTextureClearGUI(material, qualityValue);
            }
        }

    }

}

