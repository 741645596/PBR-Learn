

using System.Collections.Generic;
using UnityEngine;

public class ShaderAssetInfo : AssetInfoBase
{
    // 规定纹理采样数量不能超过该值
    public const int Texture_Count = 5;

    // 规定变体数量不能超过这个
    public const int Variant_Count = 33;

    // 纹理数量
    public int textureCount;

    // 是否支持SRP
    public bool isSRP;

    // 变体数量
    public int variantCount;

    // 引用路径
    public List<List<string>> references;

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要程序员人工修改shader代码");
    }

    public override string GetErrorDes()
    {
        var desArr = new List<string>();

        desArr.Add($"引用计数{references.Count}");

        desArr.Add($"纹理采样数量{textureCount}张");

        desArr.Add($"变体数量{variantCount}个");

        if (isSRP == false)
        {
            desArr.Add("不支持SRP Batcher");
        }

        return string.Join("；", desArr);
    }

    public override bool IsError()
    {
        if (textureCount >= Texture_Count)
        {
            return true;
        }

        if (isSRP == false)
        {
            return true;
        }

        if (variantCount >= Variant_Count)
        {
            return false;
        }

        return false;
    }
}
