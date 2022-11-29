
using UnityEngine;

public class PrefabInstantiateTimeAssetInfo : AssetInfoBase
{
    public const float Filter_Time = 10.0f;

    // 实例化耗时
    public float instantiateTime;

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("修改人工手动优化");
    }

    public override string GetErrorDes()
    {
        return $"耗时:{instantiateTime}ms";
    }

    public override bool IsError()
    {
        return instantiateTime > Filter_Time;
    }
}
