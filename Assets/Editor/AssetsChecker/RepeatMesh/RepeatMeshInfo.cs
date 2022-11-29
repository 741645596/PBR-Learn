using System;
using System.Collections.Generic;
using UnityEngine;

public class RepeatMeshInfo : AssetInfoBase
{
    // 重复资源路径列表
    public List<RepeatMeshData> repeatDatas;

    public RepeatMeshInfo Copy()
    {
        var newData = new RepeatMeshInfo();
        newData.assetPath = this.assetPath;
        newData.filesize = this.filesize;
        newData.repeatDatas = this.repeatDatas;
        return newData;
    }

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要美术人员重新导出模型");
    }

    public override string GetErrorDes()
    {
        //var size = EditerUtils.FileHelper.GetFileSizeDes(filesize);
        var data = repeatDatas[0];
        return $"顶点数{data.vertexCount}；面数{data.triangle}；";
    }

    public override bool IsError()
    {
        return true;
    }
}
