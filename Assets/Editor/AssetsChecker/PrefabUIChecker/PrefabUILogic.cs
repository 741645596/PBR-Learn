using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class PrefabUILogic
{
    private static readonly List<string> s_types = new List<string>()
    {
        "Image",
        "RawImage",
        "SKImage",
        "SKRawImage",
        "Text",
        "SKText"
    };

    /// <summary>
    /// 包含一些组件中的哪几个
    /// </summary>
    /// <param name="cell"> 要判定的节点 </param>
    /// <param name="list"> 一些组件的名称 </param>
    /// <returns></returns>
    public static List<Component> GetComponentList(Transform cell, List<string> list)
    {
        List<Component> components = new List<Component>();
        foreach (var type in list)
        {
            var r = cell.GetComponent(type);
            if (r != null)
            {
                components.Add(r);
            }
        }

        return components;
    }

    /// <summary>
    /// 设置UI组件的射线开关
    /// </summary>
    /// <param name="cell"> 所有子节点 </param>
    /// <param name="isOpen"> 是否打开射线 </param>
    /// <returns></returns>
    public static void SetRay(Transform cell, bool isOpen)
    {
        foreach (var comp in GetComponentList(cell, s_types) )
        {
            Graphic graphic = comp as Graphic;
            graphic.raycastTarget = isOpen;
        }
    }

    /// <summary>
    /// 是否打开射线
    /// </summary>
    /// <param name="cell"> 节点 </param>
    /// <returns></returns>
    public static bool IsOpenRay(Transform cell)
    {
        // 实际UI组件中带有射线的只剩 Image、Text、RawImage、SKText、SKImage、SKRawImage
        foreach (var comp in GetComponentList(cell, s_types) )
        {
            Graphic graphic = comp as Graphic;
            if (graphic.raycastTarget)
            {
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// 如果预制内有 Slider Toggle 组件，再查找内部
    /// </summary>
    /// <param name="cell"> 所有子节点 </param>
    /// <returns></returns>
    public static bool IsSliderType(Transform cell)
    {
        List<string> list = new List<string>()
        {
            "Slider",
            "Toggle"
        };
        return GetComponentList(cell, list).Count > 0;
    }

    /// <summary>
    /// 如果预制内有 Button InputField ScrollRect 组件，再查找内部
    /// </summary>
    /// <param name="cell"> 所有子节点 </param>
    /// <returns></returns>
    public static bool IsButtonType(Transform cell)
    {
        List<string> list = new List<string>()
        {
            "Button",
            "PressButton",
            "LongPressButton",
            "InputField",
            "ScrollRect"
        };
        return GetComponentList(cell, list).Count > 0;
    }
}
