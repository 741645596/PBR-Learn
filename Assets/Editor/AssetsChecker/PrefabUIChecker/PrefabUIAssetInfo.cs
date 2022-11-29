
using UnityEditor;
using UnityEngine;
/// <summary>
/// 预制UI专有属性
/// </summary>
public class PrefabUIAssetInfo : AssetInfoBase
{
    // 提示是否需要关闭射线
    public bool isNeedCloseRay;

    // 按钮需要打开射线
    public bool isNeedOpenRay;

    public override bool CanFix()
    {
        return IsError();
    }

    public override void Fix()
    {
        FixNotRefresh();
        AssetDatabase.Refresh();
    }

    public void FixNotRefresh()
    {
        var trans = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath).transform;

        if (isNeedCloseRay)
        {
            PrefabUIChecker.FixCloseRaycast(trans);
        }

        if (isNeedOpenRay)
        {
            PrefabUIChecker.FixOpenRaycast(trans);
        }

        EditorUtility.SetDirty(trans);
        PrefabUtility.SavePrefabAsset(trans.gameObject);

        isNeedCloseRay = false;
        isNeedOpenRay = false;
    }

    public override string GetErrorDes()
    {
        if (isNeedCloseRay &&
            isNeedOpenRay)
        {
            return "子节点可以关闭Raycast；按钮需要打开Raycast";
        }

        if (isNeedCloseRay)
        {
            return "子节点可以关闭Raycast";
        }

        if (isNeedOpenRay)
        {
            return "按钮需要打开Raycast；";
        }

        return "";
    }

    public override bool IsError()
    {
        if (isNeedCloseRay)
        {
            return true;
        }

        if (isNeedOpenRay)
        {
            return true;
        }

        return false;
    }
}
