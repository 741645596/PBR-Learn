using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System.Linq;
using System.Diagnostics;

namespace FBShaderGUI
{
    public class SGameUberEffectGUI : CommonShaderGUI
    {
        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            base.saveMaterialProperties = materialProperties;
            base.OnGUI(materialEditor, materialProperties);
            EditorGUI.BeginChangeCheck();

            Material material = m_MaterialEditor.target as Material;
            DrawSkinGUI(materialEditor, material);
            base.SetupMaterialKeywords(material);
        }

        bool optionsFoldOut = true;
        protected readonly GUIContent OptionsText = new GUIContent("配置参数", "可配置参数设置");

        protected readonly GUIContent EffectText = new GUIContent("特效参数", "基本参数设置");

        Dictionary<string, string> rimDic = new Dictionary<string, string> {
            {"_Rim","Fresnel"},
            {"_RimPower","Fresnel 范围"},
            {"_RimColor","Fresnel 颜色"}
        };

        Dictionary<string, string> rimDic2 = new Dictionary<string, string> {
            {"_Rim","Fresnel"},
            {"_RimPower","Fresnel 范围"},
            {"_RimColor","Fresnel 颜色"},
            {"_RimPower2","外层Fresnel范围"},
            {"_RimColor2","外层Fresnel颜色"}
        };

        MaterialProperty radial;
        void EffectProperty(MaterialEditor materialEditor, Material material, Dictionary<string, string> dic)
        {
            EditorGUILayout.BeginVertical("Button");

            List<string> keyList = dic.Keys.ToList<string>();
            MaterialProperty property = FindMaterialProperty(keyList[0]);

            if (property != null)
            {
                // m_MaterialEditor.ShaderProperty(property, EditorGUIUtility.TrTextContent(dic[keyList[0]]));

                float nval;
                EditorGUI.BeginChangeCheck();

                nval = EditorGUILayout.ToggleLeft(dic[keyList[0]], property.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                if (EditorGUI.EndChangeCheck())
                    property.floatValue = nval;

                string keyWord = keyList[0].ToUpper() + "_ON";

                if (property.floatValue != 0)
                {
                    material.EnableKeyword(keyWord);
                    foreach (KeyValuePair<string, string> kvp in dic)
                    {
                        if (kvp.Key == keyList[0]) continue;
                        materialEditor.ShaderProperty(FindMaterialProperty(kvp.Key), kvp.Value);
                    }
                }
                else
                {
                    material.DisableKeyword(keyWord);
                    Texture t;
                    foreach (KeyValuePair<string, string> kvp in dic)
                    {
                        if (kvp.Key == keyList[0]) continue;
                        t = FindMaterialProperty(kvp.Key).textureValue;
                        if (t != null)
                            FindMaterialProperty(kvp.Key).textureValue = null;
                    }
                }
            }
            EditorGUILayout.EndVertical();
        }

        private void showVerticalLabel(string label)
        {
            EditorGUILayout.BeginVertical();
            EditorGUILayout.LabelField(label);
            EditorGUILayout.EndVertical();
        }

        int queue = 0;
        string stencilComStr = "";
        string stencilPassStr = "";
        string otherInfo = "";
        MaterialProperty queueID;
        MaterialProperty surfaceType;
        MaterialProperty secondLayer;
        MaterialProperty distort;
        MaterialProperty alpha;
        MaterialProperty hideButtom;
        void DrawSkinGUI(MaterialEditor materialEditor, Material material)
        {
            // Other ----------------------
            EditorGUILayout.Space();

            MaterialProperty zwrite = FindMaterialProperty("_ZWrite");
            MaterialProperty ztest = FindMaterialProperty("_ZTest");
            MaterialProperty colorMask = FindMaterialProperty("_ColorMask");    // 1/15

            optionsFoldOut = EditorGUILayout.BeginFoldoutHeaderGroup(optionsFoldOut, OptionsText);
            if (optionsFoldOut)
            {
                // Color & Blend Mode
                EditorGUILayout.BeginVertical("box");
                {
                    m_MaterialEditor.ShaderProperty(colorMask, "写入颜色");
                    DrawCullModeProp(material);
                }
                EditorGUILayout.EndVertical();

                EditorGUILayout.BeginVertical("box");
                {
                    EditorGUI.BeginChangeCheck();
                    queueID = FindMaterialProperty("_QueueID");

                    surfaceType = FindMaterialProperty("_SurfaceType");

                    if (material.shader.name.CompareTo("FB/UI/SGameUIUber") != 0 && material.shader.name.CompareTo("FB/UI/SGameUIUber_Stencil") != 0)
                        m_MaterialEditor.ShaderProperty(surfaceType, "渲染模式");

                    if (material.shader.name.CompareTo("FB/UI/SGameUIUber") == 0 || material.shader.name.CompareTo("FB/UI/SGameUIUber_Stencil") == 0)
                    {
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_CloseLinearToSRGB"), "关闭线性转SRGB");
                        surfaceType.floatValue = 0;
                    }

                    MaterialProperty blendSrc = FindMaterialProperty("_BlendSrc");
                    MaterialProperty blendDes = FindMaterialProperty("_BlendDes");

                    MaterialProperty cutoff = FindMaterialProperty("_CutOff");
                    if (surfaceType.floatValue == 1.0f)    // AlphaTest
                        m_MaterialEditor.ShaderProperty(cutoff, "Threshold");

                    MaterialProperty blendMode = FindMaterialProperty("_BlendMode");
                    if (surfaceType.floatValue == 0.0f)    // AlphaTest
                        m_MaterialEditor.ShaderProperty(blendMode, "混合模式");

                    // m_MaterialEditor.ShaderProperty(blendSrc, "blendSrc");
                    // m_MaterialEditor.ShaderProperty(blendDes, "blendDes");

                    if (EditorGUI.EndChangeCheck())
                    {
                        if (surfaceType.floatValue == 1.0f)    // Transparent
                        {
                            material.EnableKeyword("_EFFECT_CLIP");
                            blendSrc.floatValue = 1f;
                            blendDes.floatValue = 0f;
                            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest + (int)queueID.floatValue;
                            queue = material.renderQueue;
                        }
                        else                                    // Transparent
                        {
                            material.DisableKeyword("_EFFECT_CLIP");

                            switch (blendMode.floatValue)
                            {
                                case 0:
                                    blendSrc.floatValue = 5f;
                                    blendDes.floatValue = 10f;
                                    break;
                                case 1:
                                    blendSrc.floatValue = 1f;
                                    blendDes.floatValue = 1f;
                                    break;
                                case 2:
                                    blendSrc.floatValue = 5f;
                                    blendDes.floatValue = 1f;
                                    break;
                                case 3:
                                    blendSrc.floatValue = 6f;
                                    blendDes.floatValue = 1f;
                                    break;
                                case 4:
                                    blendSrc.floatValue = 5f;
                                    blendDes.floatValue = 1f;
                                    break;
                                case 5:
                                    blendSrc.floatValue = 1f;
                                    blendDes.floatValue = 8f;
                                    break;
                                case 6:
                                    if (material.shader.name.CompareTo("FB/UI/SGameUIUber") == 0 || material.shader.name.CompareTo("FB/UI/SGameUIUber_Stencil") == 0)
                                    {
                                        blendSrc.floatValue = 1f;
                                        blendDes.floatValue = 10f;
                                    }
                                    else
                                    {
                                        blendSrc.floatValue = 2f;
                                        blendDes.floatValue = 3f;
                                    }
                                    break;
                            }
                            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent + (int)queueID.floatValue;
                            queue = material.renderQueue;
                        }
                    }
                }
                EditorGUILayout.EndVertical();

                // Depth
                EditorGUILayout.BeginVertical("box");
                {
                    MaterialProperty preZ = FindMaterialProperty("_PreZ");
                    m_MaterialEditor.ShaderProperty(preZ, "预写入深度");
                    material.SetShaderPassEnabled("SGameShadowPassTrans", preZ.floatValue != 0);

                    m_MaterialEditor.ShaderProperty(zwrite, "深度写入");
                    m_MaterialEditor.ShaderProperty(ztest, "深度测试");

                    hideButtom = FindMaterialProperty("_HideButtom");
                    m_MaterialEditor.ShaderProperty(hideButtom, "隐藏无贴图选项");

                    // m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DepthFade"), "深度边缘消隐");
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // Effect -----------------------
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(EffectText, EditorStyles.boldLabel);

            // Base
            BaseMap(material);

            // Alpha
            EditorGUILayout.BeginVertical("Button");
            {
                alpha = FindMaterialProperty("_Alpha");

                if (alpha != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("遮罩", alpha.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        alpha.floatValue = nval;

                    if (alpha.floatValue != 0)
                    {
                        material.EnableKeyword("_ALPHA_ON");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaTex"), "遮罩贴图");

                        if (FindMaterialProperty("_AlphaTex") != null && FindMaterialProperty("_AlphaTex").textureValue != null  || !(hideButtom.floatValue != 0))
                        {
                            EditorGUILayout.BeginHorizontal("box");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaUVXClamp"), "Clamp X");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaUVYClamp"), "Clamp Y");
                            EditorGUILayout.EndHorizontal();

                            EditorGUILayout.BeginHorizontal("box");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaUV"), "遮罩UV");
                            if (distort != null && distort.floatValue != 0)
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaDistort"), "遮罩扭曲");
                            EditorGUILayout.EndHorizontal();
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaChannel"), "遮罩通道");

                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaUVPanner"), "xy:流动 zw:旋转");
                        }
                    }
                    else
                    {
                        FindMaterialProperty("_AlphaTex").textureValue = null;
                        material.DisableKeyword("_ALPHA_ON");
                    }
                }
            }
            EditorGUILayout.EndVertical();


            // Second Tex
            SecondLayer(material);

            // Distort
            EditorGUILayout.BeginVertical("Button");
            {
                distort = FindMaterialProperty("_Distort");

                if (distort != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("扭曲", distort.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        distort.floatValue = nval;

                    if (distort.floatValue != 0)
                    {
                        material.EnableKeyword("_DISTORT_ON");

                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DistortionTex"), "扭曲贴图");
                        if (FindMaterialProperty("_DistortionTex") != null && FindMaterialProperty("_DistortionTex").textureValue != null || !(hideButtom.floatValue != 0))
                        {
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DistortUV"), "扭曲UV");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DistortChannel"), "扭曲通道");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DistortionIntensity"), "扭曲强度");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DistortUVPanner"), "扭曲UV");
                        }
                    }
                    else
                    {
                        FindMaterialProperty("_DistortionTex").textureValue = null;
                        material.DisableKeyword("_DISTORT_ON");
                    }
                }
            }
            EditorGUILayout.EndVertical();

            // Custom Data
            // maintex u,v;secondtex u,v
            // distort,dissolve,vertex offset,rim
            CustomData(material);

            // Dissolve
            Dissolve(material);

            // Radial
            // Raidal(material);

            // Rim
            if (material.shader.name.CompareTo("FB/UI/SGameUIUber") == 0 || material.shader.name.CompareTo("FB/UI/SGameUIUber_Stencil") == 0)
            EffectProperty(materialEditor, material, rimDic);
            else
            EffectProperty(materialEditor, material, rimDic2);
            

            // Stencil
            if (material.shader.name.CompareTo("FB/UI/SGameUIUber_Stencil") == 0)
            Stencil(material, ref colorMask, ref zwrite, ref ztest);

            EditorGUILayout.Space(20);

            // Queue
            // if (material.shader.name.CompareTo("FB/UI/SGameUIUber") == 0)
            DrawQueueOnGUI(materialEditor);
            // else
            // {
            //     if (queue != 0)
            //         EditorGUILayout.LabelField(new GUIContent("渲染队列：" + queue.ToString() + " （只能通过队列Offset修改）"));

            //     m_MaterialEditor.ShaderProperty(queueID, "队列Offset");
            // }

            EditorGUILayout.Space(20);

            // 反馈
            Report();

            EditorGUILayout.Space();
        }

        public static void Report()
        {
            string text = "材质文档";
            GUIStyle style = new GUIStyle();
            style.clipping = TextClipping.Overflow;
            style.normal.textColor = Color.cyan;
            Rect rect = GUILayoutUtility.GetRect(new GUIContent(text), style);
            if (Event.current.type == EventType.MouseUp && rect.Contains(Event.current.mousePosition))
            {
                Process ppt = new Process();
                ppt.StartInfo.FileName = Application.dataPath + "/Renders/Doc/SGame材质文档.pptx";
                ppt.Start();
            }

            GUI.Label(rect, text, style);

            EditorGUILayout.Space();

            string text2 = "材质反馈";
            GUIStyle style2 = new GUIStyle();
            style2.clipping = TextClipping.Overflow;
            style2.normal.textColor = Color.magenta;
            Rect rect2 = GUILayoutUtility.GetRect(new GUIContent(text2), style2);
            if (Event.current.type == EventType.MouseUp && rect2.Contains(Event.current.mousePosition))
            {
                string url = "https://docs.qq.com/sheet/DTWNMSktHRVpIYkNU?tab=BB08J2";
                Application.OpenURL(url);
            }
            GUI.Label(rect2, text2, style2);
        }

        void BaseMap(Material material)
        {
            EditorGUILayout.BeginVertical("box");
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_Color"), "颜色");
            MaterialProperty tex = FindMaterialProperty("_MainTex");
            m_MaterialEditor.ShaderProperty(tex, "颜色贴图");
            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_AlphaEnhance"), "透明度增强");

            if (tex != null && tex.textureValue != null || !(hideButtom.floatValue != 0))
            {
                EditorGUILayout.BeginHorizontal("box");
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_MainUVXClamp"), "Clamp X");
                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_MainUVYClamp"), "Clamp Y");
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal("box");

                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_MainUV"), "UV");

                if (distort != null && distort.floatValue != 0)
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_MainUVDistort"), "贴图扭曲");

                EditorGUILayout.EndHorizontal();

                if (tex != null && tex.textureValue != null || !(hideButtom.floatValue != 0))
                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_MainUVPanner"), "xy:流动 zw:旋转");

            }
            else
                EditorGUILayout.Space();

            EditorGUILayout.EndVertical();
        }

        void SecondLayer(Material material)
        {
            EditorGUILayout.BeginVertical("Button");
            {
                secondLayer = FindMaterialProperty("_SecondLayer");

                if (secondLayer != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("第二层", secondLayer.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        secondLayer.floatValue = nval;

                    if (secondLayer.floatValue != 0)
                    {
                        material.EnableKeyword("_SECONDLAYER_ON");

                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondColorBlend"), "混合模式");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondColor"), "第二贴图颜色");
                        MaterialProperty tex = FindMaterialProperty("_SecondTex");
                        m_MaterialEditor.ShaderProperty(tex, "第二贴图");

                        if ((tex != null && tex.textureValue != null) || !(hideButtom.floatValue != 0))
                        {
                            EditorGUILayout.BeginHorizontal("box");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondUVXClamp"), "Clamp X");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondUVYClamp"), "Clamp Y");
                            EditorGUILayout.EndHorizontal();

                            EditorGUILayout.BeginHorizontal("box");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondUV"), "UV");
                            if (distort != null && distort.floatValue != 0)
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondDistort"), "第二贴图扭曲");
                            EditorGUILayout.EndHorizontal();

                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_SecondUVPanner"), "xy:流动");
                        }
                    }
                    else
                    {
                        FindMaterialProperty("_SecondTex").textureValue = null;
                        material.DisableKeyword("_SECONDLAYER_ON");
                    }
                }
            }
            EditorGUILayout.EndVertical();
        }

        void Raidal(Material material)
        {
            EditorGUILayout.BeginVertical("Button");
            {
                radial = FindMaterialProperty("_Radial");

                if (radial != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("极坐标", radial.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        radial.floatValue = nval;

                    if (radial.floatValue != 0)
                    {
                        material.EnableKeyword("_RADIAL_ON");
                        // RadialRing
                        MaterialProperty radialRing = FindMaterialProperty("_RadialRing");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_RadialSpeed"), "极坐标速度");

                        if (radialRing != null)
                        {
                            m_MaterialEditor.ShaderProperty(radialRing, EditorGUIUtility.TrTextContent("极坐标环"));
                            if (radialRing.floatValue != 0)
                            {
                                material.EnableKeyword("_RADIALRING_ON");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_InverseRadialRing"), "反转极坐标环");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_RadialRingIntensity"), "极坐标环强度");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_RingRadius"), "极坐标环半径");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_RingRange"), "极坐标环范围");
                            }
                            else
                                material.DisableKeyword("_RADIALRING_ON");
                        }
                    }
                    else
                        material.DisableKeyword("_RADIAL_ON");
                }
            }
            EditorGUILayout.EndVertical();
        }

        void CustomData(Material material)
        {
            EditorGUILayout.BeginVertical("Button");
            {
                MaterialProperty customData = FindMaterialProperty("_CustomData");
                if (customData != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("Custom Data", customData.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        customData.floatValue = nval;

                    if (customData.floatValue != 0)
                    {
                        showVerticalLabel("customData1.x -> texcoord1.z -> 主贴图u偏移");
                        showVerticalLabel("customData1.y -> texcoord1.w -> 主贴图v偏移");
                        showVerticalLabel("customData1.z -> texcoord2.x -> 第二贴图u偏移");
                        showVerticalLabel("customData1.w -> texcoord2.y -> 第二贴图v偏移");
                        showVerticalLabel("customData2.x -> texcoord2.z -> 遮罩u偏移");
                        showVerticalLabel("customData2.y -> texcoord2.w -> 遮罩v偏移");
                        showVerticalLabel("customData2.x -> texcoord3.x -> 扭曲强度");
                        showVerticalLabel("customData2.w -> texcoord3.y -> 溶解强度");
                    }
                }
            }
            EditorGUILayout.EndVertical();
        }

        void Dissolve(Material material)
        {
            EditorGUILayout.BeginVertical("Button");
            {
                MaterialProperty dissolve = FindMaterialProperty("_Dissolve");

                if (dissolve != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("溶解", dissolve.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        dissolve.floatValue = nval;

                    if (dissolve.floatValue != 0)
                    {

                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveTex"), "溶解贴图");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveChannel"), "溶解贴图通道");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveIntensity"), "溶解强度");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveSoft"), "溶解软度");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveEdgeWidth"), "描边宽度");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveEdgeColor"), "描边颜色");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveUVPanner"), "溶解UV速度");

                        EditorGUILayout.BeginHorizontal("box");
                        // if (radial != null && radial.floatValue != 0)
                        //     m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveRadial"), "溶解极坐标");

                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveUV"), "溶解UV");
                        m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveDistort"), "溶解扭曲");
                        EditorGUILayout.EndHorizontal();

                        // 轴向溶解
                        MaterialProperty gradientDissolve = FindMaterialProperty("_GradientDissolve");
                        if (gradientDissolve != null)
                        {
                            m_MaterialEditor.ShaderProperty(gradientDissolve, EditorGUIUtility.TrTextContent("开启轴向溶解"));

                            if (gradientDissolve.floatValue != 0)
                            {
                                material.DisableKeyword("_DISSOLVE_ON");
                                material.EnableKeyword("_GRADIENTDISSOLVE_ON");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_NoiseIntensity"), "边缘Noise强度");
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_ObjectScale"), "溶解比例");

                                // 球形溶解
                                m_MaterialEditor.ShaderProperty(FindMaterialProperty("_DissolveDirAndSphere"), "溶解方向(xyz)/球形溶解(w)");
                                if (FindMaterialProperty("_DissolveDirAndSphere").vectorValue.w != 0)
                                {
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_VertexOrigin"), "球形溶解位置");
                                    m_MaterialEditor.ShaderProperty(FindMaterialProperty("_InverseSphere"), "球形溶解反转");
                                }
                            }
                            else
                            {
                                material.EnableKeyword("_DISSOLVE_ON");
                                material.DisableKeyword("_GRADIENTDISSOLVE_ON");
                            }
                        }
                    }
                    else
                    {
                        FindMaterialProperty("_DissolveTex").textureValue = null;
                        FindMaterialProperty("_DissolveIntensity").floatValue = 0.0f;

                    }
                }
            }
            EditorGUILayout.EndVertical();
        }

        void Stencil(Material material, ref MaterialProperty colorMask, ref MaterialProperty zwrite, ref MaterialProperty ztest)
        {
            EditorGUILayout.BeginVertical("Button");
            {
                MaterialProperty stencil = FindMaterialProperty("_StencilOn");

                if (stencil != null)
                {
                    float nval;
                    EditorGUI.BeginChangeCheck();

                    nval = EditorGUILayout.ToggleLeft("模板测试", stencil.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
                    if (EditorGUI.EndChangeCheck())
                        stencil.floatValue = nval;

                    if (stencil.floatValue != 0)
                    {
                        EditorGUI.BeginChangeCheck();
                        MaterialProperty stencilEasy = FindMaterialProperty("_StencilEasy");
                        if (stencilEasy != null)
                        {
                            m_MaterialEditor.ShaderProperty(stencilEasy, "简易模式");
                            m_MaterialEditor.ShaderProperty(FindMaterialProperty("_StencilRef"), "模板值");

                            MaterialProperty stencilCom = FindMaterialProperty("_StencilComp");
                            MaterialProperty stencilPass = FindMaterialProperty("_StencilPass");

                            if (stencilEasy.floatValue != 0)
                            {
                                MaterialProperty stencilMode = FindMaterialProperty("_StencilMode");
                                m_MaterialEditor.ShaderProperty(stencilMode, "模板模式");

                                if (EditorGUI.EndChangeCheck())
                                {
                                    switch (stencilMode.floatValue)
                                    {
                                        case 0:    // Plane
                                            colorMask.floatValue = 1f;          // Off
                                            m_CullModeProp.floatValue = 2f;     // Front
                                            surfaceType.floatValue = 1;         // AlphaTest

                                            zwrite.floatValue = 0f;             // Off
                                            ztest.floatValue = 4f;              // LEqual/Default

                                            stencilCom.floatValue = 8f;         // Always
                                            stencilPass.floatValue = 2f;        // Replace

                                            queueID.floatValue = 1f;

                                            stencilComStr = "Always";
                                            stencilPassStr = "Replace";
                                            otherInfo = "模板值大于0才有效";
                                            break;
                                        case 1:    // Obj
                                            colorMask.floatValue = 15f;         // On
                                            m_CullModeProp.floatValue = 0f;     // Both
                                            surfaceType.floatValue = 1;         // AlphaTest(2450 + 20)/Transparent

                                            zwrite.floatValue = 1f;             // On/Default
                                            ztest.floatValue = 4f;              // LEqual/Default

                                            stencilCom.floatValue = 3f;         // Equal
                                            stencilPass.floatValue = 0f;        // Keep/Default

                                            queueID.floatValue = 10f;

                                            stencilComStr = "Equal";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值 = plane";
                                            break;
                                        case 2:    // Sky Box
                                            colorMask.floatValue = 15f;         // On
                                            m_CullModeProp.floatValue = 1f;     // Back
                                            surfaceType.floatValue = 1;         // AlphaTest

                                            zwrite.floatValue = 1f;             // On/Default
                                            ztest.floatValue = 8f;              // Always

                                            stencilCom.floatValue = 3f;         // Equal
                                            stencilPass.floatValue = 0f;        // Keep/Default

                                            queueID.floatValue = 5f;

                                            stencilComStr = "Equal";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值 = plane";
                                            break;
                                        case 3:    // Through
                                            colorMask.floatValue = 15f;         // On
                                            m_CullModeProp.floatValue = 1f;     // Back
                                            surfaceType.floatValue = 1;         // AlphaTest(2450 + 20)/Transparent

                                            zwrite.floatValue = 1f;             // On/Default
                                            ztest.floatValue = 4f;              // LEqual/Default

                                            stencilCom.floatValue = 5f;         // Greater
                                            stencilPass.floatValue = 0f;        // Keep/Default

                                            queueID.floatValue = 10f;

                                            stencilComStr = "Greater";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值需要大于Plane";
                                            break;
                                        case 4:    // Cull
                                            colorMask.floatValue = 1f;   // Off
                                            m_CullModeProp.floatValue = 0f;     // Both
                                            surfaceType.floatValue = 1;         // AlphaTest

                                            zwrite.floatValue = 0f;     // Off
                                            ztest.floatValue = 4f;      // LEqual/Default

                                            stencilCom.floatValue = 8f; // Always
                                            stencilPass.floatValue = 2f; // Replace

                                            queueID.floatValue = 0f;

                                            stencilComStr = "Always";
                                            stencilPassStr = "Replace";
                                            otherInfo = "模板值需要大于Through";
                                            break;
                                    }


                                    switch (stencilMode.floatValue)
                                    {
                                        case 0:    // Plane
                                            stencilComStr = "Always";
                                            stencilPassStr = "Replace";
                                            otherInfo = "模板值大于0才有效";
                                            break;
                                        case 1:    // Obj
                                            stencilComStr = "Equal";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值 = plane";
                                            break;
                                        case 2:    // Sky Box
                                            stencilComStr = "Equal";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值 = plane";
                                            break;
                                        case 3:    // Through
                                            stencilComStr = "Greater";
                                            stencilPassStr = "Keep";
                                            otherInfo = "模板值需要大于Plane";
                                            break;
                                        case 4:    // Cull
                                            stencilComStr = "Always";
                                            stencilPassStr = "Replace";
                                            otherInfo = "模板值需要大于Through";
                                            break;
                                    }
                                }

                                EditorGUILayout.LabelField(new GUIContent("模板比较应为：" + stencilComStr));
                                EditorGUILayout.LabelField(new GUIContent("模板通过应为：" + stencilPassStr));
                                EditorGUILayout.LabelField(new GUIContent(otherInfo));
                                EditorGUILayout.Space(20);
                            }
                            m_MaterialEditor.ShaderProperty(stencilCom, "模板比较");  // 0 - 8
                            m_MaterialEditor.ShaderProperty(stencilPass, "模板通过");  // 0 - 7
                        }

                    }
                    else
                    {
                        material.SetFloat("_StencilRef", 0);
                        material.SetFloat("_StencilComp", 8);
                        material.SetFloat("_StencilPass", 0);
                    }

                }
            }
            EditorGUILayout.EndVertical();
        }
    }
}

