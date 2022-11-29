

using System.Collections.Generic;
using UnityEngine;

public class RepeatResourceAssetInfo : AssetInfoBase
{
    // 重复资源路径列表
    public List<string> repeatList;

    public RepeatResourceAssetInfo Copy()
    {
        var data = new RepeatResourceAssetInfo();
        data.assetPath = this.assetPath;
        data.filesize = this.filesize;
        data.repeatList = this.repeatList;
        return data;
    }

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要手动处理，防止删错");
    }

    public override string GetErrorDes()
    {
        var size = EditerUtils.FileHelper.GetFileSizeDes(filesize);
        return $"总共{repeatList.Count}个资源相同；{size}";
    }

    public override bool IsError()
    {
        return true;
    }
}
