
using System.Collections.Generic;
using EditerUtils;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 动画资源信息
/// </summary>
public class AnimAssetInfo : AssetInfoBase
{
    // 是否可以删除冗余数据
    public bool canDelete;

    // 是否可以压缩成float3
    public bool canFloat3;

    public bool isFbx;

    public override bool CanFix()
    {
        return IsError();
    }

    public override void Fix()
    {
        AnimAssetHelper.Zip(assetPath);
        canDelete = false;
        canFloat3 = false;

        AssetDatabase.SaveAssets();
    }

    public override string GetErrorDes()
    {
        if (isFbx)
        {
            return "fbx压了也没用";
        }

        if (IsError() == false) return "";

        var desArr = new List<string>();
        if (canDelete) desArr.Add("包含冗余数据");
        if (canFloat3) desArr.Add("非3位精度");
        return string.Join("；", desArr);
    }

    public override bool IsError()
    {
        return canDelete || canFloat3;
    }
}
