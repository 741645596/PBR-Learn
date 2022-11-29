
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

// 粒子信息
public class ParticleAssetInfo
{
    // 发射数量
    public int burstCount;

    // 纹理尺寸
    public Vector2 textureSize;

    // 纹理数量
    public int textureCount;

    // 网格面数，0表示没用网格
    public int trianglesCount;

    public override string ToString()
    {
        if (trianglesCount == 0)
            return $"纹理:{burstCount}x[{textureSize.x}x{textureSize.y}]x{textureCount}";
        return $"网格:{burstCount}x{trianglesCount}x[{textureSize.x}x{textureSize.y}]x{textureCount}";
    }
}

/// <summary>
/// 预制粒子专有属性
/// </summary>
public class PrefabParticleAssetInfo : AssetInfoBase
{
    // 是否打开投射阴影
    public bool isOpenCastShadows;

    // 是否打开接收阴影
    public bool isOpenReceiveShadows;

    // 是否打开光照探针
    public bool isOpenLightProbes;

    // 是否打开反射探针
    public bool isOpenReflectionProbes;

    // 是否需要将材质球关闭
    public bool isNeedSetMatNull;

    // 是否关闭了Prewarm
    public bool isOpenPrewarm;

    // 是否关闭了Collision
    public bool isOpenCollision;

    // 是否关闭了Trigger
    public bool isOpenTrigger;

    // 是否需要开启读写
    public bool isNeedRW;

    // 是否冗余Mesh引用
    public bool isRedundancyMesh;

    // 有问题粒子集合
    public List<ParticleAssetInfo> particleInfos;

    // 是否超过30个最大粒子数
    public bool isOver30MaxParticles
    {
        get
        {
            foreach (var info in particleInfos)
            {
                if (info.burstCount > PrefabParticleChecker.Max_Particles_Count)
                {
                    return true;
                }
            }
            return false;
        }
    }

    // 如果粒子类型是Mesh，是否超过5个粒子发射数
    public bool isOverMeshBurstsCount
    {
        get
        {
            foreach (var info in particleInfos)
            {
                if (info.trianglesCount !=0 &&
                    info.burstCount > PrefabParticleChecker.Max_Particles_Count)
                {
                    return true;
                }
            }
            return false;
        }
    }

    // 是否超过500面数
    public bool isOverTrianglesCount
    {
        get
        {
            foreach (var info in particleInfos)
            {
                if (info.trianglesCount != 0 &&
                    info.trianglesCount > PrefabParticleChecker.Max_Triangles_Count)
                {
                    return true;
                }
            }
            return false;
        }
    }

    // 是否超过总纹理尺寸大小
    public bool isOverMainTextureSize
    {
        get
        {
            foreach (var info in particleInfos)
            {
                var totalSize = info.burstCount * info.textureSize.x * info.textureSize.y;
                if (totalSize > PrefabParticleChecker.Max_Texture_Size)
                {
                    return true;
                }
            }
            return false;
        }
    }

    public PrefabParticleAssetInfo()
    {
        isOpenCastShadows = false;
        isOpenReceiveShadows = false; 
        isOpenLightProbes = false; 
        isOpenReflectionProbes = false; 
        isNeedSetMatNull = false; 
        isOpenPrewarm = false; 
        isOpenCollision = false; 
        isOpenTrigger = false; 
        isNeedRW = false; 

        particleInfos = new List<ParticleAssetInfo>();
    }

    public override bool CanFix()
    {
        // 碰撞器
        if (isOpenCollision || isOpenTrigger) return true;

        // R&W
        if (isNeedRW) return true;

        // 开启Prewarnm
        if (isOpenPrewarm) return true;

        // 需要关闭Renderer
        if (isNeedSetMatNull) return true;

        // 冗余Mesh引用
        if (isRedundancyMesh) return true;

        // 需要关闭阴影/探针
        if (isOpenCastShadows ||
            isOpenReceiveShadows ||
            isOpenLightProbes ||
            isOpenReflectionProbes)
        {
            return true;
        }
        return false;
    }

    public override void Fix()
    {
        FixNotRrefresh();
        AssetDatabase.Refresh();
    }

    public void FixNotRrefresh()
    {
        var obj = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
        var psArr = obj.GetComponentsInChildren<ParticleSystem>(true);

        // 碰撞器
        if (isOpenCollision || isOpenTrigger)
        {
            PrefabParticleLogic.FixCollisionAndTrigger(psArr);
            isOpenCollision = false;
            isOpenTrigger = false;
        }

        // R&W
        if (isNeedRW)
        {
            PrefabParticleLogic.FixRW(psArr);
            isNeedRW = false;
        }

        // 开启Prewarnm
        if (isOpenPrewarm)
        {
            PrefabParticleLogic.FixPrewarn(psArr);
            isOpenPrewarm = false;
        }

        // 需要关闭Renderer
        if (isNeedSetMatNull)
        {
            PrefabParticleLogic.FixNeedSetMatNull(psArr);
            isNeedSetMatNull = false;
        }

        // 需要关闭阴影/探针
        if (isOpenCastShadows ||
            isOpenReceiveShadows ||
            isOpenLightProbes ||
            isOpenReflectionProbes)
        {
            PrefabParticleLogic.FixShadowsAndProbes(psArr);
            isOpenCastShadows = false;
            isOpenReceiveShadows = false;
            isOpenLightProbes = false;
            isOpenReflectionProbes = false;
        }

        if (isRedundancyMesh)
        {
            PrefabParticleLogic.FixRedundancyMesh(psArr);
            isRedundancyMesh = false;
        }

        EditorUtility.SetDirty(obj);
        PrefabUtility.SavePrefabAsset(obj.gameObject);
    }

    public bool IsDefaultMaxParticles()
    {
        foreach (var info in particleInfos)
        {
            if (info.burstCount >= PrefabParticleChecker.Max_Particles_Default_Count)
            {
                return true;
            }
        }
        return false;
    }

    private void _SetDefaultMaxParticles30()
    {
        foreach (var info in particleInfos)
        {
            if (info.burstCount >= PrefabParticleChecker.Max_Particles_Default_Count)
            {
                info.burstCount = PrefabParticleChecker.Max_Particles_Count;
            }
        }
    }

    /// <summary>
    /// 将默认粒子数改为30
    /// </summary>
    public void SetDefaultMaxParticles30()
    {
        if (IsDefaultMaxParticles())
        {
            PrefabParticleLogic.FixDefaultMaxParticles(assetPath);

            _SetDefaultMaxParticles30();
        }
    }

    public override string GetErrorDes()
    {
        var desArr = new List<string>();
        if (isOpenCollision || isOpenTrigger) desArr.Add("Collision和Trigger开启");
        if (isOpenCastShadows || isOpenReceiveShadows) desArr.Add("阴影开启");
        if (isOpenLightProbes || isOpenReflectionProbes) desArr.Add("光照探针开启");
        if (isNeedRW) desArr.Add("Mesh粒子需打开RW");

        if (isOpenPrewarm) desArr.Add("Prewarm开启");
        if (isNeedSetMatNull) desArr.Add("Renderer关闭Material未置空");
        if (isRedundancyMesh) desArr.Add("Mesh引用冗余");

        var des = GetParticleInfo();
        if (string.IsNullOrEmpty(des) == false)
        {
            desArr.Add(des);
        }
        
        return string.Join("；", desArr);
    }

    public string GetParticleInfo()
    {
        var res = _GetErrorInfos();
        if (res.Count > 0)
        {
            return $"[{particleInfos.Count}] " + string.Join("，", particleInfos);
        }
        return "";
    }

    private List<ParticleAssetInfo> _GetErrorInfos()
    {
        var res = new List<ParticleAssetInfo>();
        foreach (var info in particleInfos)
        {
            var totalSize = info.burstCount * info.textureSize.x * info.textureSize.y;
            if (info.burstCount > PrefabParticleChecker.Max_Particles_Count ||
                info.trianglesCount > PrefabParticleChecker.Max_Triangles_Count ||
                totalSize > PrefabParticleChecker.Max_Texture_Size)
            {
                res.Add(info);
            }
        }
        return res;
    }

    public override bool IsError()
    {
        if (isOver30MaxParticles) return true;
        if (isOpenPrewarm) return true;
        if (isOpenCollision) return true;
        if (isOpenTrigger) return true;
        if (isNeedSetMatNull) return true;
        if (isOpenCastShadows) return true;
        if (isOpenReceiveShadows) return true;

        if (isOpenLightProbes) return true;
        if (isOpenReflectionProbes) return true;
        if (isNeedRW) return true;
        if (isOverMainTextureSize) return true;
        if (isOverTrianglesCount) return true;
        if (isOverMeshBurstsCount) return true;
        if (isRedundancyMesh) return true;

        return false;
    }

    /// <summary>
    /// 获取总发射数量
    /// </summary>
    /// <returns></returns>
    public int GetTotalBurstCount()
    {
        int count = 0;
        foreach (var info in particleInfos)
        {
            count += info.burstCount;
        }
        return count;
    }

    //else if (_sortIndex == 2)
    //    des = "排序：发射数x网格数";
    //else
    //    des = "排序：发射数x网格数x尺寸";

    /// <summary>
    /// 发射数x纹理尺寸
    /// </summary>
    /// <returns></returns>
    public int GetTotalTextureSize()
    {
        int count = 0;
        foreach (var info in particleInfos)
        {
            count += (int)(info.burstCount * info.textureSize.x * info.textureSize.y);
        }
        return count;
    }

    /// <summary>
    /// 发射数x三角面数
    /// </summary>
    /// <returns></returns>
    public int GetTotalMeshTriangles()
    {
        int count = 0;
        foreach (var info in particleInfos)
        {
            count += info.burstCount * info.trianglesCount;
        }
        return count;
    }

    /// <summary>
    /// 发射数x三角面数x纹理尺寸x纹理数量
    /// </summary>
    /// <returns></returns>
    public int GetTotalAll()
    {
        int count = 0;
        foreach (var info in particleInfos)
        {
            var triang = Mathf.Max(1, info.trianglesCount);
            count += (int)(info.burstCount * info.textureSize.x * info.textureSize.y * info.textureCount * triang);
        }
        return count;
    }
    
}
