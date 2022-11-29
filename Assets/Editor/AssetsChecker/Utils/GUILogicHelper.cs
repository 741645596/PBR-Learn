using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Experimental.SceneManagement;
using EditerUtils;
using UnityEngine;

public static class GUILogicHelper
{
    // 检视按钮宽度
    public const float Check_Button_Width = 70;
    public const float Check_Button_Height = 20;

    /// <summary>
    /// 显示第1栏资源小图标
    /// </summary>
    /// <param name="rowIndex"></param>
    /// <param name="rect"></param>
    /// <param name="assetPath"></param>
    public static void ShowOneContent(Rect rect, string assetPath)
    {
        var icon = AssetsHelper.GetPreviewMiniIcon(assetPath);
        if (icon != null)
        {
            rect.y += 1;
            rect.width -= 2;
            rect.height -= 2;
            GUI.DrawTexture(rect, icon, ScaleMode.ScaleToFit);
        }
    }

    /// <summary>
    /// 显示第2栏资源路径
    /// </summary>
    /// <param name="rowIndex"></param>
    /// <param name="rect"></param>
    /// <param name="assetPath"></param>
    public static void ShowSecondContent(Rect rect, string assetPath)
    {
        GUI.Label(rect, assetPath);
    }

    /// <summary>
    /// 显示第三栏错误描述
    /// </summary>
    /// <param name="rowIndex"></param>
    /// <param name="rect"></param>
    /// <param name="assetPath"></param>
    public static void ShowThirdContent(Rect rect, string assetPath)
    {
        GUI.Label(rect, assetPath);
    }

    /// <summary>
    /// 转为检视按钮显示的位置
    /// </summary>
    /// <param name="r"></param>
    /// <returns></returns>
    public static Rect GetCheckRect(Rect rect)
    {
        // 检视按钮默认排在右边第一个
        return GetButtonRect(rect, 0);
    }

    /// <summary>
    /// 获得第4行指定第几个按钮位置
    /// </summary>
    /// <param name="rect"></param>
    /// <param name="index"> 从0开始 </param>
    /// <returns></returns>
    public static Rect GetButtonRect(Rect rect, int index)
    {
        // 靠最右边显示
        const float space = 4;  // 按钮之间间隙
        var posx = rect.width - (index + 1) * Check_Button_Width - index * space;
        rect.x = rect.x + posx;
        rect.y += (rect.height - Check_Button_Height) * 0.5f;
        rect.width = Check_Button_Width;
        rect.height = Check_Button_Height;
        return rect;
    }

    /// <summary>
    /// 显示第列：检视按钮
    /// </summary>
    public static void ShowFourCheckBt(Rect rect, string assetPath)
    {
        var newRect = GetCheckRect(rect);
        GUI.color = Color.white;
        if (GUI.Button(newRect, "检视"))
        {
            var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(assetPath);
            Selection.activeObject = obj;
        }
    }

    public static void ShowFourCheckBt(Rect rect, string assetPath, Action callback)
    {
        var newRect = GetCheckRect(rect);
        GUI.color = Color.white;
        if (GUI.Button(newRect, "检视"))
        {
            callback();
        }
    }

    /// <summary>
    /// 在检视按钮前面显示修复按钮
    /// </summary>
    /// <param name="rowIndex"></param>
    /// <param name="rect"></param>
    /// <param name="fixCB"></param>
    public static void ShowFourFixBt(Rect rect,  Action fixCB)
    {
        GUI.color = Color.green;

        var newRect = GetButtonRect(rect, 1);
        if (GUI.Button(newRect, "修复"))
        {
            fixCB();
        }

        GUI.color = Color.white;
    }

    public static void ShowFixBt(Rect rect, Action fixCB)
    {
        GUI.color = Color.green;

        var newRect = GetButtonRect(rect, 0);
        if (GUI.Button(newRect, "修复"))
        {
            fixCB();
        }

        GUI.color = Color.white;
    }

    /// <summary>
    /// 显示修复按钮，通过index指定按钮位置
    /// </summary>
    /// <param name="rect"></param>
    /// <param name="index"> 从右往左第几个索引 </param>
    /// <param name="fixCB"></param>
    public static void ShowFourFixBt(Rect rect, int index, Action fixCB)
    {
        GUI.color = Color.green;

        var newRect = GetButtonRect(rect, index);
        if (GUI.Button(newRect, "修复"))
        {
            fixCB();
        }

        GUI.color = Color.white;
    }

    public static void ShowFourCustiomBt(string btName, Rect rect, Action fixCB)
    {
        var newRect = GetCheckRect(rect);
        newRect.x = newRect.x - Check_Button_Width - 4;
        if (GUI.Button(newRect, btName))
        {
            fixCB();
        }
    }

    /// <summary>
    /// 获取文件集合大小
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="infos"></param>
    /// <returns></returns>
    public static long GetFileSize<T>(List<T> infos) where T : AssetInfoBase
    {
        long size = 0;
        foreach (var info in infos)
        {
            size += info.filesize;
        }
        return size;
    }

    /// <summary>
    /// 获取文件大小描述
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="infos"></param>
    /// <returns></returns>
    public static string GetFileSizeDes<T>(List<T> infos) where T : AssetInfoBase
    {
        var size = GetFileSize<T>(infos);
        return $"文件数量：{infos.Count} | 总大小：{size / 1048576f:n2}MB";
    }

    /// <summary>
    /// 显示底部信息栏，文件数量和大小
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="infos"></param>
    /// <param name="rect"></param>
    public static void ShowBottomInfo<T>(List<T> infos, Rect rect) where T : AssetInfoBase
    {
        var des = GetFileSizeDes<T>(infos);
        GUI.Label(new Rect(0f, rect.height - 20f, rect.width, 20f), des);
    }

}
