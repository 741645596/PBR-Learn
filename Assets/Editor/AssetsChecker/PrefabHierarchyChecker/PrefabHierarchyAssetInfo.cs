

using System.Collections.Generic;
using UnityEngine;

public class PrefabHierarchyAssetInfo : AssetInfoBase
{
    // 建议最大层级数
    public const int Max_Hierarchy_Count = 7;

    // 非活跃节点占比
    public const float No_Active_Ratio = 0.3f;

    // 最大深度
    public int maxHierarchyCount;

    // 所有节点
    public int allNodeCount;

    // 非激活节点数
    public int notActiveNodeCount;

    // 非激活节点比例
    public float notActiveRatio;

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要人工手动修复");
    }

    public override string GetErrorDes()
    {
        if (IsError() == false) return $"最大层级{maxHierarchyCount}；非活跃节点比:{notActiveNodeCount}/{allNodeCount}";

        var errorDes = new List<string>();
        if (maxHierarchyCount >= Max_Hierarchy_Count)
        {
            errorDes.Add($"最大层级{maxHierarchyCount}");
        }

        if (notActiveRatio > No_Active_Ratio)
        {
            errorDes.Add($"非活跃节点比:{notActiveNodeCount}/{allNodeCount}");
        }
        return string.Join("；", errorDes);
    }

    public override bool IsError()
    {
        if (maxHierarchyCount >= Max_Hierarchy_Count)
        {
            return true;
        }

        if (notActiveRatio > No_Active_Ratio)
        {
            return true;
        }

        return false;
    }
}
