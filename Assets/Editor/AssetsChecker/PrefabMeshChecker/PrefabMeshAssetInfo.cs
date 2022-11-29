
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 预制网格专有属性
/// </summary>
public class PrefabMeshAssetInfo : AssetInfoBase
{
    // 是否打开投射阴影
    public bool isOpenCastShadows;

    // 是否打开接收阴影
    public bool isOpenReceiveShadows;

    // 是否打开光照探针
    public bool isOpenLightProbes;

    // 是否打开反射探针
    public bool isOpenReflectionProbes;

    // 动态遮挡
    public bool isOpenDynamicOcclusion;

    public PrefabMeshAssetInfo()
    {
        isOpenCastShadows = false;
        isOpenReceiveShadows = false;
        isOpenLightProbes = false;
        isOpenReflectionProbes = false;
        isOpenDynamicOcclusion = false;
    }

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
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
        foreach (var child in obj.GetComponentsInChildren<Renderer>(true))
        {
            child.shadowCastingMode = ShadowCastingMode.Off;
            child.receiveShadows = false;
            child.lightProbeUsage = LightProbeUsage.Off;
            child.reflectionProbeUsage = ReflectionProbeUsage.Off;
            child.allowOcclusionWhenDynamic = false;

            EditorUtility.SetDirty(child);
        }

        isOpenCastShadows = false;
        isOpenReceiveShadows = false;
        isOpenLightProbes = false;
        isOpenReflectionProbes = false;
        isOpenDynamicOcclusion = false;

        EditorUtility.SetDirty(obj);
        PrefabUtility.SavePrefabAsset(obj.gameObject);
    }

    public override string GetErrorDes()
    {
        if (IsError() == false) return "";

        var desArr = new List<string>();

        if (isOpenCastShadows)
        {
            desArr.Add("未关闭阴影");
        }

        if (isOpenReceiveShadows)
        {
            desArr.Add("未关闭接收阴影");
        }

        if (isOpenLightProbes)
        {
            desArr.Add("未关闭光照探针");
        }

        if (isOpenReflectionProbes)
        {
            desArr.Add("未关闭反射探针");
        }

        if (isOpenDynamicOcclusion)
        {
            desArr.Add("未关闭动态遮挡");
        }

        return string.Join("；", desArr);
    }

    public override bool IsError()
    {
        if (isOpenCastShadows) return true;

        if (isOpenReceiveShadows) return true;

        if (isOpenLightProbes) return true;

        if (isOpenReflectionProbes) return true;

        if (isOpenDynamicOcclusion) return true;

        return false;
    }
}
