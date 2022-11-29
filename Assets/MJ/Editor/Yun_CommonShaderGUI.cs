using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Yun_FBShaderGUI
{
    public class Yun_CommonShaderGUI : ShaderGUI
    {

        protected MaterialEditor m_MaterialEditor;

        public virtual void ShaderPropertiesGUI(Material material)
        {

        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            if (materialEditor == null)
            {
                throw new ArgumentNullException("Material Editor is null.");
            }
            m_MaterialEditor = materialEditor;
            Material material = m_MaterialEditor.target as Material;
            AllPropertys(material);
            FindProperties(materialProperties);
            foreach (Material mat in m_MaterialEditor.targets)
            {
                SetupMaterialKeywords(mat);
            }
        }

        public virtual void SetupMaterialKeywords(Material material)
        {
            //material.shaderKeywords = null;
            if (FindMaterialProperty("_AlphaClip") != null)
            {
                if (FindMaterialProperty("_AlphaClip").floatValue != 0.0f)
                {
                    material.EnableKeyword("_ALPHATEST_ON");
                }
                else
                {
                    material.DisableKeyword("_ALPHATEST_ON");
                }
            }
            if (FindMaterialProperty("_ReceiveShadows") != null)
            {
                if (FindMaterialProperty("_ReceiveShadows").floatValue == 0.0f)
                {
                    material.EnableKeyword("_RECEIVE_SHADOWS_OFF");
                }
                else
                {
                    material.DisableKeyword("_RECEIVE_SHADOWS_OFF");
                }
            }
        }

        public virtual void FindProperties(MaterialProperty[] properties)
        {

        }

        #region//Common  选择性启用

        #region//Surface

        protected enum SurfaceType
        {
            Opaque,
            Transparent
        }

        // Surface type
        protected static GUIContent m_surfaceOptionsText = new GUIContent("Surface Options", "表面参数设置");
        protected MaterialProperty m_SurfaceTypeProp;
        protected static GUIContent m_SurfaceTypeText = new GUIContent("渲染模式", "实体/透明");

        protected SurfaceType DrawSurfaceTypeProp(Material material)
        {
            m_SurfaceTypeProp = FindMaterialProperty("_Surface");
            //Surface type
            DoPopup(m_SurfaceTypeText, m_SurfaceTypeProp, Enum.GetNames(typeof(SurfaceType)));

            return (SurfaceType)material.GetFloat("_Surface");
            //// Blend mode if type == transparent
            //if ((SurfaceType)material.GetFloat("_Surface") == SurfaceType.Transparent)
            //{
            //    DoPopup(m_BlendModeText, m_BlendModeProp, Enum.GetNames(typeof(BlendMode)));
            //}
        }

        #endregion

        #region//Blend mode
        // Blend mode
        protected MaterialProperty m_BlendOpProp;
        protected static GUIContent m_BlendOpText = new GUIContent("BlendOp(混合算法)", "");

        protected MaterialProperty m_SrcBlendProp;
        protected static GUIContent m_SrcBlendText = new GUIContent("BlendModeSrc(混合模式Src)", "设置前景混合方式");

        protected MaterialProperty m_DstBlendProp;
        protected static GUIContent m_DstBlendText = new GUIContent("BlendModeDst(混合模式Dst)", "设置背景混合方式");

        protected void DrawBlendProp(Material material)
        {
            m_BlendOpProp= FindMaterialProperty("_BlendOp");
            if (m_BlendOpProp!=null)
            {
                DoPopup(m_BlendOpText, m_BlendOpProp, Enum.GetNames(typeof(BlendOp)));
            }
            m_SrcBlendProp = FindMaterialProperty("_SrcBlend");
            m_DstBlendProp = FindMaterialProperty("_DstBlend");
            if (m_SrcBlendProp!=null && m_DstBlendProp!=null)
            {
                DoPopup(m_SrcBlendText, m_SrcBlendProp, Enum.GetNames(typeof(BlendMode)));
                DoPopup(m_DstBlendText, m_DstBlendProp, Enum.GetNames(typeof(BlendMode)));
            }
        }

        #endregion

        #region//Cull

        protected enum RenderFace
        {
            Front = 2,
            Back = 1,
            Both = 0
        }

        // Render face (Cull front/back/none)
        protected MaterialProperty m_CullModeProp;
        protected static GUIContent m_CullModeText = new GUIContent("剔除模式", "剔除背面/剔除正面/双面渲染");

        protected void DrawCullModeProp(Material material)
        {
            m_CullModeProp = FindMaterialProperty("_Cull");
            if (m_CullModeProp!=null)
            {
                // Render face
                DoPopup(m_CullModeText, m_CullModeProp, Enum.GetNames(typeof(RenderFace)));
            }
        }

        #endregion

        #region//Alpha clip

        // Alpha clip
        protected MaterialProperty m_AlphaClipProp;
        protected static GUIContent m_AlphaClipText = new GUIContent("裁剪", "开启/关闭裁剪");
        protected MaterialProperty m_AlphaClipThresholdProp;
        protected static GUIContent m_AlphaClipThresholdText = new GUIContent("裁剪阈值", "裁剪阈值");

        protected void DrawAlphaClipProp(Material material)
        {
            m_AlphaClipProp = FindMaterialProperty("_AlphaClip");
            m_AlphaClipThresholdProp = FindMaterialProperty("_Cutoff");
            // Alpha clip
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = m_AlphaClipProp.hasMixedValue;
            var alphaClipEnabled = EditorGUILayout.Toggle(m_AlphaClipText, m_AlphaClipProp.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                m_AlphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
            }
            if (m_AlphaClipProp.floatValue == 1)
            {
                m_MaterialEditor.ShaderProperty(m_AlphaClipThresholdProp, m_AlphaClipThresholdText, 1);
            }
        }

        #endregion

        #region//ReceiveShadows

        // Shadows
        protected MaterialProperty m_ReceiveShadowsProp;
        protected static GUIContent m_ReceiveShadowsText = new GUIContent("接受阴影", "是否接受阴影");

        protected void DrawReceiveShadows(Material material)
        {
            m_ReceiveShadowsProp = FindMaterialProperty("_ReceiveShadows");
            // Receive shadow
            if (m_ReceiveShadowsProp != null)
            {
                EditorGUI.BeginChangeCheck();
                var receiveShadows = EditorGUILayout.Toggle(m_ReceiveShadowsText, m_ReceiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck())
                {
                    m_ReceiveShadowsProp.floatValue = receiveShadows ? 1 : 0;
                }
            }
        }

        #endregion

        #region//Queue

        protected void DrawQueueOnGUI(MaterialEditor materialEditor)
        {
            materialEditor.RenderQueueField();
        }

        #endregion

        #region//Instancing

        protected void DrawInstancingOnGUI(MaterialEditor materialEditor)
        {
            materialEditor.EnableInstancingField();
        }

        #endregion

        #region //Stencil

        protected MaterialProperty m_StencilToggleProp;

        protected MaterialProperty m_StencilProp;
        protected static GUIContent m_StencilText = new GUIContent("Stencil ID Ref 0-255", "");

        protected MaterialProperty m_StencilCompProp;
        protected static GUIContent m_StencilCompText = new GUIContent("StencilComparisonOP", ""); // Never:1 Less:2 Equal:3 LEqual:4 Greater:5 NotEqual:6 GEqual:7 Always:8

        protected MaterialProperty m_PassStencilOpProp;
        protected static GUIContent m_PassStencilOpText = new GUIContent("StencilOP Pass", "");

        protected MaterialProperty m_FailPassStencilOpProp;
        protected static GUIContent m_FailPassStencilOpText = new GUIContent("StencilOP Fail", "");

        protected MaterialProperty m_ZFailPassStencilOpProp;
        protected static GUIContent m_ZFailPassStencilOpText = new GUIContent("StencilOP ZFail", "");

        protected MaterialProperty m_StencilReadMaskProp;
        protected static GUIContent m_StencilReadMaskText = new GUIContent("ReadMask", "");

        protected MaterialProperty m_StencilWriteMaskProp;
        protected static GUIContent m_StencilWriteMaskText = new GUIContent("WriteMask", "");

        protected void DrawStencil(Material material)
        {
            m_StencilToggleProp= FindMaterialProperty("_StencilToggle");
            if (m_StencilToggleProp != null)
            {
                m_StencilProp = FindMaterialProperty("_Stencil");
                m_StencilCompProp = FindMaterialProperty("_StencilComp");
                m_PassStencilOpProp = FindMaterialProperty("_PassStencilOp");
                m_FailPassStencilOpProp = FindMaterialProperty("_FailPassStencilOp");
                m_ZFailPassStencilOpProp = FindMaterialProperty("_ZFailPassStencilOp");
                m_StencilReadMaskProp = FindMaterialProperty("_StencilReadMask");
                m_StencilWriteMaskProp = FindMaterialProperty("_StencilWriteMask");

                EditorGUILayout.Space();
                bool open = (m_StencilToggleProp.floatValue == 0) ? false : true;
                open = EditorGUILayout.Toggle("Stencil 显示/隐藏", open);
                if (open)
                {
                    m_StencilToggleProp.floatValue = 1;
                }
                else
                {
                    m_StencilToggleProp.floatValue = 0;
                }
                if (open)
                {

                    DrawProperty(m_StencilProp, m_StencilText);
                    DoPopup(m_StencilCompText, m_StencilCompProp, Enum.GetNames(typeof(CompareFunction)));
                    DoPopup(m_PassStencilOpText, m_PassStencilOpProp, Enum.GetNames(typeof(UnityEngine.Rendering.StencilOp)));
                    DoPopup(m_FailPassStencilOpText, m_FailPassStencilOpProp, Enum.GetNames(typeof(UnityEngine.Rendering.StencilOp)));
                    DoPopup(m_ZFailPassStencilOpText, m_ZFailPassStencilOpProp, Enum.GetNames(typeof(UnityEngine.Rendering.StencilOp)));
                    DrawProperty(m_StencilReadMaskProp, m_StencilReadMaskText);
                    DrawProperty(m_StencilWriteMaskProp, m_StencilWriteMaskText);
                }
            }
        }

        #endregion

        public void DoPopup(GUIContent label, MaterialProperty property, string[] options, int enumOffset = 0)
        {
            DoPopup(label, property, options, m_MaterialEditor, enumOffset);
        }

        public static void DoPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor,int enumOffset = 0)
        {
            if (property == null)
                throw new ArgumentNullException("property");

            EditorGUI.showMixedValue = property.hasMixedValue;

            var mode = property.floatValue;
            EditorGUI.BeginChangeCheck();
            mode = EditorGUILayout.Popup(label, (int)(mode+ enumOffset), options)- enumOffset;
            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(label.text);
                property.floatValue = mode;
            }

            EditorGUI.showMixedValue = false;
        }

        #endregion

        #region//Property

        Dictionary<string, MaterialProperty> propertys;

        void AllPropertys(Material material)
        {
            if (propertys != null)
            {
                propertys.Clear();
            }
            else
            {
                propertys = new Dictionary<string, MaterialProperty>();
            }
            MaterialProperty[] res = MaterialEditor.GetMaterialProperties(new Material[] { material });
            for (int i = 0, listCount = res.Length; i < listCount; ++i)
            {
                MaterialProperty materialProperty = res[i];
                propertys.Add(materialProperty.name, materialProperty);
            }
        }

        public MaterialProperty FindMaterialProperty(string proName)
        {
            if (propertys == null) return null;
            MaterialProperty res;
            propertys.TryGetValue(proName, out res);
            return res;
        }

        #endregion

        #region//Draw

        public void DrawProperty(MaterialProperty materialProperty, GUIContent guiContent)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.ShaderProperty(materialProperty, guiContent);
        }

        public void DrawProperty(MaterialProperty materialProperty, string text)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.ShaderProperty(materialProperty, text);
        }

        public void DrawProperty(MaterialProperty materialProperty, string text, string tooltip)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.ShaderProperty(materialProperty, new GUIContent(text, tooltip));
        }

        public void DrawProperty(string materialPropertyName, string text)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawProperty(p, text);
        }

        public void DrawProperty(string materialPropertyName, string text, string tooltip)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawProperty(p, text, tooltip);
        }

        static GUIContent staticLabel = new GUIContent();

        static GUIContent MakeLabel(string text, string tooltip = null)
        {
            staticLabel.text = text;
            staticLabel.tooltip = tooltip;
            return staticLabel;
        }

        public void DrawPropertyTexture(MaterialProperty materialProperty, string text,bool tillingOffset=false)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.TexturePropertySingleLine(MakeLabel(text), materialProperty);
            if (tillingOffset)
            {
                if (materialProperty.textureValue != null)
                {
                    m_MaterialEditor.TextureScaleOffsetProperty(materialProperty);
                }
            }
        }

        public void DrawPropertyTexture(MaterialProperty materialProperty, MaterialProperty colorProperty, string text, bool tillingOffset = false)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.TexturePropertySingleLine(MakeLabel(text), materialProperty, colorProperty);
            if (tillingOffset)
            {
                if (materialProperty.textureValue != null)
                {
                    m_MaterialEditor.TextureScaleOffsetProperty(materialProperty);
                }
            }
        }

        public void DrawPropertyTexture(MaterialProperty materialProperty, string text, string tooltip, bool tillingOffset = false)
        {
           
            if (materialProperty == null) return;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent (text, tooltip), materialProperty);
            if (tillingOffset)
            {
                if (materialProperty.textureValue != null)
                {
                    m_MaterialEditor.TextureScaleOffsetProperty(materialProperty);
                }
            }
        }

        public void DrawPropertyTexture(MaterialProperty materialProperty, MaterialProperty colorProperty, string text, string tooltip, bool tillingOffset = false)
        {
            if (materialProperty == null) return;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent(text, tooltip), materialProperty, colorProperty);
            if (tillingOffset)
            {
                if (materialProperty.textureValue != null)
                {
                    m_MaterialEditor.TextureScaleOffsetProperty(materialProperty);
                }
            }
        }

        public void DrawPropertyTexture(string materialPropertyName, string text, bool tillingOffset = false)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawPropertyTexture(p, text, tillingOffset);
        }

        public void DrawPropertyTexture(string materialPropertyName, MaterialProperty colorProperty, string text, bool tillingOffset = false)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawPropertyTexture(p, colorProperty, text, tillingOffset);
        }

        public void DrawPropertyTexture(string materialPropertyName, MaterialProperty colorProperty, string text, string tooltip, bool tillingOffset = false)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawPropertyTexture(p, colorProperty, text, tooltip, tillingOffset);
        }

        public void DrawPropertyTexture(string materialPropertyName, string text, string tooltip, bool tillingOffset = false)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawPropertyTexture(p, text, tooltip, tillingOffset);
        }

        public void DrawDoubleVector2FromVector4(MaterialProperty prop, string newNameA, string newNameB)
        {
            if (prop == null) return;
            Vector4 vectorValues = prop.vectorValue;
            Vector2 vectorA = new Vector2(vectorValues.x, vectorValues.y);
            Vector2 vectorB = new Vector2(vectorValues.z, vectorValues.w);

            Vector2 a = EditorGUILayout.Vector2Field(newNameA, vectorA);
            Vector2 b = EditorGUILayout.Vector2Field(newNameB, vectorB);

            prop.vectorValue = new Vector4(a.x, a.y, b.x, b.y);
        }

        public void DrawDoubleVector2FromVector4(string materialPropertyName, string newNameA, string newNameB)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawDoubleVector2FromVector4(p, newNameA, newNameB);
        }

        public void DrawVector2FromVector4(MaterialProperty prop, string newName, bool ZW = false)
        {
            if (prop == null) return;
            Vector4 vectorValues = prop.vectorValue;

            Vector2 vectorA = ZW ? new Vector2(vectorValues.z, vectorValues.w) : new Vector2(vectorValues.x, vectorValues.y);

            Vector2 a = EditorGUILayout.Vector2Field(newName, vectorA);

            prop.vectorValue = ZW ? new Vector4(vectorValues.x, vectorValues.y, a.x, a.y) : new Vector4(a.x, a.y, vectorValues.z, vectorValues.w);
        }

        public void DrawVector2FromVector4(string materialPropertyName, string newName, bool ZW = false)
        {
            MaterialProperty p = FindMaterialProperty(materialPropertyName);
            DrawVector2FromVector4(p, newName, ZW);
        }

        #endregion

    }
}

