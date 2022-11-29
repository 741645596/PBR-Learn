using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;

/// <summary>
/// 材质编辑器拓展
/// </summary>
[CustomEditor(typeof(Material))]
public class MaterialEditorExpand : MaterialEditor
{

    GUIStyle GetGUIStyle(string showName, int state)
    {
        GUIStyle fontStyle = new GUIStyle();
        fontStyle.alignment = TextAnchor.LowerLeft;
        switch (showName)
        {
            case "Clamp":
                {
                    if (state == 0)
                    {
                        fontStyle.normal.textColor = Color.red;
                    }
                    else
                    {
                        fontStyle.normal.textColor = Color.white;
                    }
                }
                break;
            case "RepeatUV":
                {
                    if (state == 1)
                    {
                        fontStyle.normal.textColor = Color.red;
                    }
                    else
                    {
                        fontStyle.normal.textColor = Color.white;
                    }
                }
                break;
            case "RepeatU":
                {
                    if (state == 2)
                    {
                        fontStyle.normal.textColor = Color.red;
                    }
                    else
                    {
                        fontStyle.normal.textColor = Color.white;
                    }
                }
                break;
            case "RepeatV":
                {
                    if (state == 3)
                    {
                        fontStyle.normal.textColor = Color.red;
                    }
                    else
                    {
                        fontStyle.normal.textColor = Color.white;
                    }
                }
                break;
        }
        fontStyle.hover.textColor = Color.yellow;
        return fontStyle;
    }

    void SetTextureClamp(Material targetMat, string proName, string proNameU, string proNameV, string showName)
    {
        int state = 0;//0:Clamp 1:RepeatUV 2:RepeatU 3:RepeatV
        float clamp = targetMat.GetFloat(proName);
        if (clamp == 0)
        {
            state = 0;
        }
        else
        {
            float clampU = targetMat.GetFloat(proNameU);
            float clampV = targetMat.GetFloat(proNameV);
            if (clampU == 0)
            {
                if (clampV == 0)
                {
                    state = 1;
                }
                else
                {
                    state = 3;
                }
            }
            else
            {
                if (clampV == 0)
                {
                    state = 2;
                }
                else
                {
                    state = 1;
                }
            }
        }
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label(showName);

        if (GUILayout.Button("Clamp", GetGUIStyle("Clamp", state)))
        {
            targetMat.SetFloat(proName, 0);
            targetMat.SetFloat(proNameU, 0);
            targetMat.SetFloat(proNameV, 0);
        }

        if (GUILayout.Button("RepeatUV", GetGUIStyle("RepeatUV", state)))
        {
            targetMat.SetFloat(proName, 1);
            targetMat.SetFloat(proNameU, 1);
            targetMat.SetFloat(proNameV, 1);
        }

        if (GUILayout.Button("RepeatU", GetGUIStyle("RepeatU", state)))
        {
            targetMat.SetFloat(proName, 1);
            targetMat.SetFloat(proNameU, 1);
            targetMat.SetFloat(proNameV, 0);
        }

        if (GUILayout.Button("RepeatV", GetGUIStyle("RepeatV", state)))
        {
            targetMat.SetFloat(proName, 1);
            targetMat.SetFloat(proNameU, 0);
            targetMat.SetFloat(proNameV, 1);
        }

        EditorGUILayout.EndHorizontal();
    }

    public override void OnInspectorGUI()
    {
        if (!isVisible) return;
        Material targetMat = target as Material;
        if (!targetMat.HasProperty("_IsEffect"))
        {
            if (targetMat.shader.name.CompareTo("FB/Particle/CustomDataUV") == 0 || targetMat.shader.name.CompareTo("FB/Particle/CustomDataUV_MaskDistort") == 0
                || targetMat.shader.name.CompareTo("FB/UI/Fx/U_MaskDistort") == 0)//
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(主贴图)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(遮罩)");
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(扭曲)");
                SetTextureClamp(targetMat, "_DissolveTexClamp", "_DissolveTexRepeatU", "_DissolveTexRepeatV", "开启Repeat(溶解)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/CustomDataUV_MutiMask") == 0 || targetMat.shader.name.CompareTo("FB/Particle/U_MaskDistorntMutiMask") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(主贴图)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(遮罩)");
                SetTextureClamp(targetMat, "_Mask2TexClamp", "_Mask2TexRepeatU", "_Mask2TexRepeatV", "开启Repeat(遮罩2)");
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(扭曲)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/MaskDistort") == 0 || targetMat.shader.name.CompareTo("FB/Particle/ScreenView") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(Mask Tex)");
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(Distort Tex)");
            }
            else if (targetMat.shader.name.CompareTo("FB/UI/Fx/U_MaskDistort") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(主贴图)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(遮罩)");
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(扭曲)");
                SetTextureClamp(targetMat, "_DissolveTexClamp", "_DissolveTexRepeatU", "_DissolveTexRepeatV", "开启Repeat(溶解)");
                SetTextureClamp(targetMat, "_EmissionTexClamp", "_EmissionTexRepeatU", "_EmissionTexRepeatV", "开启Emission(自发光)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/DistortSHDissolveMask") == 0 || targetMat.shader.name.CompareTo("FB/Particle/DistortSHDissolveMaskAllTextureSpeed") == 0
                || targetMat.shader.name.CompareTo("FB/Particle/DistortDissolveAblend") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
                SetTextureClamp(targetMat, "_DissTexClamp", "_DissTexRepeatU", "_DissTexRepeatV", "开启Repeat(Diss tex)");
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(Distort Tex)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(Mask Tex)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/Add") == 0 || targetMat.shader.name.CompareTo("FB/Particle/AddAlphaBlend") == 0
                || targetMat.shader.name.CompareTo("FB/Particle/AddAlways") == 0 || targetMat.shader.name.CompareTo("FB/Particle/AddAlphaBlend") == 0
                || targetMat.shader.name.CompareTo("FB/Particle/HeatRefraction") == 0 || targetMat.shader.name.CompareTo("FB/Particle/AddSoftEdge") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/AddDistortAdditive") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
                SetTextureClamp(targetMat, "_NoiseTexClamp", "_NoiseTexRepeatU", "_NoiseTexRepeatV", "开启Repeat(Distort Texture (RG))");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/AlphaBlendAlways") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
                SetTextureClamp(targetMat, "_MaskRClamp", "_MaskRRepeatU", "_MaskRRepeatV", "开启Repeat Mask(R)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/Fresnel3") == 0 || targetMat.shader.name.CompareTo("FB/Particle/Fresnel") == 0
                || targetMat.shader.name.CompareTo("FB/Particle/FresnelCharactor") == 0 || targetMat.shader.name.CompareTo("FB/Particle/Fresnel3Translucent") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp", "_MainTexRepeatU", "_MainTexRepeatV", "开启Repeat(Main Tex)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(Mask tex)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/Fresnel2") == 0)
            {
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(Mask tex)");
                SetTextureClamp(targetMat, "_JianBianClamp", "_JianBianRepeatU", "_JianBianRepeatV", "开启Repeat(JianBian)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/2sideCustomData_MaskDistortDissolve") == 0)
            {
                SetTextureClamp(targetMat, "_MainTexClamp_Front", "_MainTexRepeatU_Front", "_MainTexRepeatV_Front", "开启Repeat(正面贴图)");
                SetTextureClamp(targetMat, "_MainTexClamp_Back", "_MainTexRepeatU_Back", "_MainTexRepeatV_Back", "开启Repeat(背面贴图)");
                SetTextureClamp(targetMat, "_NoiseTexClamp", "_NoiseTexRepeatU", "_NoiseTexRepeatV", "开启Repeat(扰动贴图)");
                SetTextureClamp(targetMat, "_MaskTexClamp", "_MaskTexRepeatU", "_MaskTexRepeatV", "开启Repeat(透明遮罩)");
                SetTextureClamp(targetMat, "_DissolveMapClamp", "_DissolveMapRepeatU", "_DissolveMapRepeatV", "开启Repeat(溶解贴图)");
            }
            else if (targetMat.shader.name.CompareTo("FB/Particle/Wrap") == 0)
            {
                SetTextureClamp(targetMat, "_DistortTexClamp", "_DistortTexRepeatU", "_DistortTexRepeatV", "开启Repeat(Distort Tex)");
            }
            base.OnInspectorGUI();
            return;
        }
        else
        {
            //EffectMaterialEditorSSFS.Run(targetMat);
            base.OnInspectorGUI();
            if (EditorGUI.EndChangeCheck())
            {

                EditorUtility.SetDirty(targetMat);
            }
        }
    }

    public class Fx_CustomDataUVData
    {

    }

    //public class EffectMaterialEditorSSFS
    //{
    //    static string m_blendKey;

    //    static bool _PointCache = false;
    //    static bool _MaskCache = true;
    //    static bool _FlowCache = true;
    //    static bool _Dissolve1 = false;
    //    static bool _Dissolve2 = false;

    //    public static void Run(Material targetMat)
    //    {
    //        m_blendKey = null;

    //        EditorGUI.BeginChangeCheck();

    //        DrawShaderSwitchButton(targetMat);
    //        DrawBlendModeButton(targetMat);
    //        DrawCullModeButton(targetMat);

    //        EditorGUILayout.Separator();
    //        targetMat.renderQueue = EditorGUILayout.IntField("渲染顺序(RenderQueue)", targetMat.renderQueue);
    //        DrawRenderQueueButton(targetMat);
    //        EditorGUILayout.Separator();
    //    }

    //    static Dictionary<string, int[]> blendModelDict = new Dictionary<string, int[]>
    //    {
    //      //  {"None",            new int[]{(int)BlendMode.One,(int)BlendMode.Zero}},
    //        {"Blend" ,          new int[]{(int)BlendMode.SrcAlpha,(int)BlendMode.OneMinusSrcAlpha}},
    //        {"Additive",        new int[]{(int)BlendMode.SrcAlpha,(int)BlendMode.One}},
    //        {"Screen",          new int[]{(int)BlendMode.One,(int)BlendMode.OneMinusSrcColor}},
    //        {"Multiply",        new int[]{(int)BlendMode.Zero,(int)BlendMode.SrcColor}}
    //    };

    //        static Dictionary<string, int[]> CullModelDict = new Dictionary<string, int[]>
    //    {
    //        {"双面显示" ,      new int[]{(int)CullMode.Off}},
    //        {"显示背面",     new int[]{(int)CullMode.Front}},
    //        {"显示正面",      new int[]{(int)CullMode.Back}}
    //    };

    //        static Dictionary<string, int> renderQueueData = new Dictionary<string, int>
    //    {
    //        { "背景",1000 },
    //        { "普通",2000 },
    //        { "镂空",2450 },
    //        { "透明",3000 },
    //        { "顶层",4000 },
    //        { "最顶层",5000 }
    //    };

    //    public static Shader[] fxShaders = new Shader[]
    //    {
    //            Shader.Find("M1Toolv5/Effect/Default"),
    //            Shader.Find("M1Toolv5/Effect/Refraction"),
    //            Shader.Find("M1Toolv5/Effect/Ghost"),
    //            Shader.Find("M1Toolv5/Effect/Rim"),
    //    };


    //    static void DrawShaderSwitchButton(Material target)
    //    {
    //        Material self = target as Material;
    //        if (self.shader.name.StartsWith("M1Toolv5/Effect/") == false) return;
    //        GUILayout.BeginHorizontal();
    //        GUILayout.Label("Shader切换:");
    //        foreach (Shader fxshader in fxShaders)
    //        {
    //            if (fxshader == null)
    //                continue;

    //            string shaderName = System.IO.Path.GetFileNameWithoutExtension(fxshader.name);

    //            if (shaderName == "Simple" || shaderName == "SimpleDefult") continue;

    //            bool selected = fxshader == self.shader;

    //            if (selected)
    //                GUI.contentColor = Color.green;

    //            if (GUILayout.Toggle(fxshader == self.shader, shaderName, "Button"))
    //            {
    //                if (self.shader != fxshader)
    //                    self.shader = fxshader;
    //            }
    //            GUI.contentColor = Color.white;

    //        }
    //        GUILayout.EndHorizontal();
    //    }

    //    static void DrawRenderQueueButton(Material target)
    //    {
    //        Material targetMat = target as Material;
    //        GUILayout.BeginHorizontal();
    //        GUILayout.Label("常用顺序:");
    //        foreach (string key in renderQueueData.Keys)
    //        {
    //            if (GUILayout.Button(key))
    //            {
    //                targetMat.renderQueue = renderQueueData[key];
    //            }
    //        }
    //        GUILayout.EndHorizontal();
    //    }

    //    static void DrawBlendModeButton(Material target)
    //    {
    //        Material targetMat = target as Material;

    //        GUILayout.BeginHorizontal();
    //        if (targetMat.HasProperty("_SrcFactor") && targetMat.HasProperty("_DstFactor"))
    //        {
    //            GUILayout.Label("透明模式:");
    //            foreach (string key in blendModelDict.Keys)
    //            {
    //                GUI.contentColor = Color.white;
    //                bool selected = false;
    //                if (targetMat.GetInt("_SrcFactor") == blendModelDict[key][0] && targetMat.GetInt("_DstFactor") == blendModelDict[key][1])
    //                {
    //                    GUI.contentColor = Color.green;
    //                    selected = true;
    //                }

    //                if (!GUILayout.Toggle(selected, key, "Button"))
    //                    continue;
    //                m_blendKey = key;

    //                if (!selected)
    //                {
    //                    targetMat.SetInt("_SrcFactor", blendModelDict[key][0]);
    //                    targetMat.SetInt("_DstFactor", blendModelDict[key][1]);
    //                }
    //            }
    //            GUI.contentColor = Color.white;
    //        }

    //        GUILayout.EndHorizontal();
    //    }

    //    static void DrawCullModeButton(Material target)
    //    {
    //        Material targetMat = target as Material;

    //        GUILayout.BeginHorizontal();
    //        if (targetMat.HasProperty("_CullMode"))
    //        {
    //            GUILayout.Label("消隐模式:");
    //            foreach (string key in CullModelDict.Keys)
    //            {
    //                GUI.contentColor = Color.white;
    //                bool selected = false;
    //                if (targetMat.GetInt("_CullMode") == CullModelDict[key][0])
    //                {
    //                    GUI.contentColor = Color.green;
    //                    selected = true;
    //                }

    //                if (!GUILayout.Toggle(selected, key, "Button"))
    //                    continue;
    //                m_blendKey = key;

    //                if (!selected)
    //                {
    //                    targetMat.SetInt("_CullMode", CullModelDict[key][0]);

    //                }
    //            }
    //            GUI.contentColor = Color.white;
    //        }

    //        GUILayout.EndHorizontal();
    //    }
    //}

}
