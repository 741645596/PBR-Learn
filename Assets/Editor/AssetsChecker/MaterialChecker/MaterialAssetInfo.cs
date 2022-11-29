
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MaterialAssetInfo : AssetInfoBase
{
    // 包含空纹理采样
    public bool hasEmptyTexture;

    // 冗余关键字
    public List<string> redundanceKeywords;

    // 冗余引用
    public List<string> redundanceRes;

    public override bool CanFix()
    {
        if (redundanceKeywords.Count > 0) return true;

        if (redundanceRes.Count > 0) return true;

        return false;
    }

    public override void Fix()
    {
        FixNotRefresh();

        AssetDatabase.Refresh();
    }

    public void FixNotRefresh()
    {
        MaterialLogic.FixRedundanceKeywords(assetPath);
        MaterialLogic.DeleteRedunanceRes(assetPath);

        redundanceKeywords = new List<string>();
        redundanceRes = new List<string>();
    }

    public override string GetErrorDes()
    {
        if (IsError() == false) return "";

        var errorDes = new List<string>();
        if (hasEmptyTexture == true)
        {
            errorDes.Add("包含空纹理采样");
        }

        if (redundanceKeywords.Count > 0)
        {
            var dd = string.Join("、", redundanceKeywords);
            var des = $"冗余Keywords:{dd}";
            errorDes.Add(des);
        }

        if (redundanceRes.Count > 0)
        {
            var dd = string.Join("、", redundanceRes);
            var des = $"冗余引用:{dd}";
            errorDes.Add(des);
        }
        return string.Join("；", errorDes);
    }

    public override bool IsError()
    {
        if (redundanceKeywords.Count != 0) return true;

        if (redundanceRes.Count != 0) return true;

        if (hasEmptyTexture) return true;

        return false;
    }
}
