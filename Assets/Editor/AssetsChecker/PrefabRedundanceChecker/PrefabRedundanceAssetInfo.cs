
using System.Collections.Generic;
using UnityEngine;

public class PrefabRedundanceAssetInfo : AssetInfoBase
{
    // 冗余文件名
    public string redundanceFileName;

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要人工手动优化");
    }

    public override string GetErrorDes()
    {
        return redundanceFileName;
    }

    public override bool IsError()
    {
        return true;
    }
}
