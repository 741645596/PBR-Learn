


using UnityEngine;

public class UnreferencedResourceInfo : AssetInfoBase
{
    // 是否被脚本引用
    public bool isScriptReferenced;

    // 是否是预制类型
    public bool isPrefabType;


    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要手动处理");
    }

    public override string GetErrorDes()
    {
        return EditerUtils.FileHelper.GetFileSizeDes(filesize);
    }

    public override bool IsError()
    {
        return true;
    }
}
