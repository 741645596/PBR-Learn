

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using EditerUtils;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class PrefabParticleChecker
{
    public const int Max_Texture_Size = 1024 * 1024;
    public const int Max_Triangles_Count = 500;
    public const int Max_Particles_Default_Count = 1000;
    public const int Max_Particles_Count = 30;

    /// <summary>
    /// 搜集预设粒子信息
    /// </summary>
    /// <returns></returns>
    public static void CollectAssetInfo(Action<List<PrefabParticleAssetInfo>> finishCB)
    {
        var files = DirectoryHelper.GetAllFiles(AssetsCheckEditorWindow.Asset_Search_Path, ".prefab");
        FixHelper.AsyncCollect<PrefabParticleAssetInfo>(files, (file)=>
        {
            return GetAssetInfo(file);
        },
        (res)=>
        {
            finishCB(res);
        });
    }

    /// <summary>
    /// 获取预设带有粒子信息
    /// </summary>
    /// <param name="file"></param>
    /// <returns> 预设带粒子组件返回null </returns>
    public static PrefabParticleAssetInfo GetAssetInfo(string file)
    {
        GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
        if (obj == null)
        {
            if (file.Contains("~"))
            {
                return null;
            }
            Debug.LogWarning($"错误提示：读取{file}预设资源失败，请检查资源");
            return null;
        }

        // 排除非粒子预制
        var transform = obj.transform;
        var particles = transform.GetComponentsInChildren<ParticleSystem>(true);
        if (particles.Length == 0)
        {
            return null;
        }

        return _GetInitInfo(file, particles);
    }

    public static List<PrefabParticleAssetInfo> GetErrorAssetInfos(List<PrefabParticleAssetInfo> assetInfos)
    {
        var infos = new List<PrefabParticleAssetInfo>();
        foreach (var info in assetInfos)
        {
            if (info.IsError())
            {
                infos.Add(info);
            }
        }
        return infos;
    }

    public static void FixAll(List<PrefabParticleAssetInfo> infos, Action<bool> finishCB)
    {
        FixHelper.FixStep<PrefabParticleAssetInfo>(infos, (info) =>
        {
            info.FixNotRrefresh();
        },
        (isCancel) =>
        {
            AssetDatabase.Refresh();

            finishCB(isCancel);
        });
    }

    /// <summary>
    /// 获取有问题的obj的key集合，方便在Hierarchy面板提示用
    /// </summary>
    /// <param name="info"></param>
    /// <returns></returns>
    public static HashSet<string> GetErrorObjUniqueKeys(PrefabParticleAssetInfo info)
    {
        var keys = new HashSet<string>();

        GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(info.assetPath);
        var particles = obj.GetComponentsInChildren<ParticleSystem>(true);
        var dic = new Dictionary<Func<ParticleSystem[], List<GameObject>>, bool>()
        {
            { _GetOver30MaxParticles, info.isOver30MaxParticles },
            { _GetOpenPrewarm, info.isOpenPrewarm },
            { _GetOpenCollision, info.isOpenCollision },
            { _GetOpenTrigger, info.isOpenTrigger },
            { _GetNeedSetMatNull, info.isNeedSetMatNull },
            { _GetOpenCastShadows, info.isOpenCastShadows },
            { _GetOpenReceiveShadows, info.isOpenReceiveShadows },
            { _GetOpenLightProbes, info.isOpenLightProbes },
            { _GetOpenReflectionProbes, info.isOpenReflectionProbes },
            { _GetNeedRW, info.isNeedRW },
            { _GetOverMeshBurstsCount, info.isOverMeshBurstsCount },
            { _GetOverMainTextureSize, info.isOverMainTextureSize },
            { _GetOverTrianglesCount, info.isOverTrianglesCount },
            { _GetRedundancyMesh, info.isRedundancyMesh },

        };
        foreach (var func in dic)
        {
            if (func.Value)
            {
                var objs = func.Key(particles);
                _AddUniqueKey(keys, objs);
            }
        }

        return keys;
    }

    private static void _AddUniqueKey(HashSet<string> keys, List<GameObject> objs)
    {
        foreach (var obj in objs)
        {
            var key = AssetsCheckUILogic.GetTipsUniqueKey(obj);
            if (keys.Contains(key) == false)
            {
                keys.Add(key);
            }
        }
    }

    private static PrefabParticleAssetInfo _GetInitInfo(string file, ParticleSystem[] particles)
    {
        var info = new PrefabParticleAssetInfo();
        info.assetPath = file;
        info.filesize = EditerUtils.FileHelper.GetFileSize(file);

        info.particleInfos = _GetParticleInfos(particles);

        info.isOpenPrewarm = _IsOpenPrewarm(particles);
        info.isOpenCollision = _IsOpenCollision(particles);
        info.isOpenTrigger = _IsOpenTrigger(particles);
        info.isNeedSetMatNull = _IsNeedSetMatNull(particles);
        info.isOpenCastShadows = _IsOpenCastShadows(particles);
        info.isOpenReceiveShadows = _IsOpenReceiveShadows(particles);
        info.isOpenLightProbes = _IsOpenLightProbes(particles);
        info.isOpenReflectionProbes = _IsOpenReflectionProbes(particles);
        info.isNeedRW = _IsNeedRW(particles);
        info.isRedundancyMesh = _IsRedundancyMesh(particles);

        return info;
    }

    private static List<ParticleAssetInfo> _GetParticleInfos(ParticleSystem[] psArr)
    {
        var res = new List<ParticleAssetInfo>();
        foreach (var ps in psArr)
        {
            var material = _GetMaterial(ps);
            if (material == null)
            {
                continue;
            }

            var info = new ParticleAssetInfo();
            info.burstCount = GetBurstCount(ps);
            info.textureSize = MaterialLogic.GetMainTextureSize(material); ;
            info.textureCount = MaterialLogic.GetTextureCount(material); ;
            info.trianglesCount = _GetTrianglesCount(ps);

            res.Add(info);
        }

        // 优先显示mesh排序，在显示纹理排序
        EditerUtils.SortHelper.MultiSort<ParticleAssetInfo>(res, (data) =>
        {
            return data.trianglesCount == 0 ? 1 : 0;
        }, (d1, d2) =>
        {
            if (d1.trianglesCount == 0)
            {
                return d1.burstCount * d1.textureSize.x * d1.textureSize.y * d1.textureCount >
                 d2.burstCount * d2.textureSize.x * d2.textureSize.y * d2.textureCount;
            }
            return d1.burstCount * d1.trianglesCount > d2.burstCount * d2.trianglesCount;
        });
        return res;
    }

    private static int _GetTrianglesCount(ParticleSystem ps)
    {
        ParticleSystemRenderer renderComp = ps.GetComponent<ParticleSystemRenderer>();
        if (renderComp == null ||
            renderComp.enabled == false)
        {
            return 0;
        }

        // 如果有设置模型才继续
        if (renderComp.mesh == null)
        {
            return 0;
        }

        return renderComp.mesh.triangles.Length / 3;
    }

    private static Material _GetMaterial(ParticleSystem ps)
    {
        ParticleSystemRenderer renderComp = ps.GetComponent<ParticleSystemRenderer>();
        if (renderComp == null ||
            renderComp.enabled == false)
        {
            return null;
        }

        // 获取第一个材质球
        if (renderComp.sharedMaterials.Length == 0)
        {
            return null;
        }

        // 有可能为null
        return renderComp.sharedMaterials[0];
    }

    private static int _GetTextureCount(ParticleSystem ps)
    {
        var material = _GetMaterial(ps);
        if (material == null)
        {
            return 0;
        }
        return MaterialLogic.GetTextureCount(material);
    }

    private static Vector2 _GetMainTextureSize(ParticleSystem ps)
    {
        var material = _GetMaterial(ps);
        if (material == null)
        {
            return Vector2.zero;
        }
        return MaterialLogic.GetMainTextureSize(material);
    }

    private static List<GameObject> _GetOverMainTextureSize(ParticleSystem[] psArr)
    {
        var list = new List<GameObject>();
        foreach (var child in psArr)
        {
            var mainTextureSize = _GetMainTextureSize(child);
            if (mainTextureSize == Vector2.zero)
            {
                continue;
            }

            var brustCount = GetBurstCount(child);
            float areaCount = brustCount * mainTextureSize.x * mainTextureSize.y; // 所有第一个材质球的主贴图面积
            if (areaCount > Max_Texture_Size)
            {
                list.Add(child.gameObject);
            }
        }
        return list;
    }

    private static List<GameObject> _GetOverMeshBurstsCount(ParticleSystem[] psArr)
    {
        var list = new List<GameObject>();
        foreach (var child in psArr)
        {
            ParticleSystemRenderer renderComp = child.GetComponent<ParticleSystemRenderer>();
            if (!renderComp.enabled || renderComp.renderMode != ParticleSystemRenderMode.Mesh)
                continue;

            if (!child.emission.enabled)
                continue;

            int burstsCount = GetBurstCount(child);
            if (burstsCount > 5)
            {
                list.Add(child.gameObject);
            }
        }
        return list;
    }

    /// <summary>
    /// 获取发射粒子数量
    /// </summary>
    /// <param name="ps"></param>
    /// <returns></returns>
    public static int GetBurstCount(ParticleSystem ps)
    {
        return ps.main.maxParticles;
        //if (ps.emission.burstCount == 0)
        //{
        //    return ps.main.maxParticles;
        //}

        //int burstsCount = 0;
        //for (int i = 0; i < ps.emission.burstCount; i++)
        //{
        //    ParticleSystem.Burst bursts = ps.emission.GetBurst(i);
        //    burstsCount += (int)bursts.count.constant;
        //}
        //return burstsCount;
    }

    private static List<GameObject> _GetNeedRW(ParticleSystem[] psArr)
    {
        var list = new List<GameObject>();
        foreach (var child in psArr)
        {
            ParticleSystemRenderer renderComp = child.GetComponent<ParticleSystemRenderer>();
            ModelImporter modelImporter = MeshHelper.GetModelImporter(renderComp);
            if (modelImporter == null)
            {
                continue;
            }

            // Mesh读写关闭，需要提示开启
            if (modelImporter.isReadable == false)
            {
                list.Add(child.gameObject);
            }
        }
        return list;
    }

    private static bool _IsNeedRW(ParticleSystem[] psArr)
    {
        return _GetNeedRW(psArr).Count > 0;
    }

    private static List<GameObject> _GetOverTrianglesCount(ParticleSystem[] psArr)
    {
        return _GetParticlesRenderer(psArr, (renderComp) =>
        {
            var count = MeshHelper.GetTrianglesCount(renderComp);
            return count > Max_Triangles_Count;
        });
    }

    private static List<GameObject> _GetOpenReflectionProbes(ParticleSystem[] psArr)
    {
        return _GetParticlesRenderer(psArr, (renderComp) => renderComp.reflectionProbeUsage != ReflectionProbeUsage.Off);
    }

    private static bool _IsOpenReflectionProbes(ParticleSystem[] psArr)
    {
        return _GetOpenReflectionProbes(psArr).Count > 0;
    }

    private static List<GameObject> _GetOpenLightProbes(ParticleSystem[] psArr)
    {
        return _GetParticlesRenderer(psArr, (renderComp) => renderComp.lightProbeUsage != LightProbeUsage.Off);
    }

    private static bool _IsOpenLightProbes(ParticleSystem[] psArr)
    {
        return _GetOpenLightProbes(psArr).Count > 0;
    }

    private static List<GameObject> _GetOpenReceiveShadows(ParticleSystem[] psArr)
    {
        return _GetParticlesRenderer(psArr, (renderComp) => renderComp.receiveShadows);
    }

    private static bool _IsOpenReceiveShadows(ParticleSystem[] psArr)
    {
        return _GetOpenReceiveShadows(psArr).Count > 0;
    }

    private static List<GameObject> _GetOpenCastShadows(ParticleSystem[] psArr)
    {
        return _GetParticlesRenderer(psArr, (renderComp) => renderComp.shadowCastingMode != ShadowCastingMode.Off);
    }

    private static bool _IsOpenCastShadows(ParticleSystem[] psArr)
    {
        return _GetOpenCastShadows(psArr).Count > 0;
    }

    private static List<GameObject> _GetParticlesRenderer(ParticleSystem[] psArr, Func<ParticleSystemRenderer, bool> cb)
    {
        var list = new List<GameObject>();
        foreach (var child in psArr)
        {
            ParticleSystemRenderer renderComp = child.GetComponent<ParticleSystemRenderer>();
            if (cb(renderComp))
            {
                list.Add(child.gameObject);
            }
        }
        return list;
    }

    private static List<GameObject> _GetNeedSetMatNull(ParticleSystem[] psArr)
    {
        return PrefabParticleLogic.GetNeedCloseRenderersObjs(psArr);
    }

    private static bool _IsNeedSetMatNull(ParticleSystem[] psArr)
    {
        var needFixComps = PrefabParticleLogic.GetNeedCloseRenderers(psArr);
        return needFixComps.Count > 0;
    }

    private static List<GameObject> _GetOpenTrigger(ParticleSystem[] psArr)
    {
        return _GetParticles(psArr, (child) => child.trigger.enabled);
    }

    private static bool _IsOpenTrigger(ParticleSystem[] psArr)
    {
        return _GetOpenTrigger(psArr).Count > 0;
    }

    private static List<GameObject> _GetOpenCollision(ParticleSystem[] psArr)
    {
        return _GetParticles(psArr, (child) => child.collision.enabled);
    }

    private static bool _IsOpenCollision(ParticleSystem[] psArr)
    {
        return _GetOpenCollision(psArr).Count > 0;
    }

    private static List<GameObject> _GetParticles(ParticleSystem[] psArr, Func<ParticleSystem, bool> cb)
    {
        var list = new List<GameObject>();
        foreach (var child in psArr)
        {
            if (cb(child))
            {
                list.Add(child.gameObject);
            }
        }
        return list;
    }

    private static List<GameObject> _GetOver30MaxParticles(ParticleSystem[] psArr)
    {
        return _GetParticles(psArr, (child) => child.main.maxParticles > Max_Particles_Count);
    }

    private static List<GameObject> _GetOpenPrewarm(ParticleSystem[] psArr)
    {
        return _GetParticles(psArr, (child) => child.main.prewarm);
    }

    private static bool _IsOpenPrewarm(ParticleSystem[] psArr)
    {
        return _GetOpenPrewarm(psArr).Count > 0;
    }

    private static List<GameObject> _GetRedundancyMesh(ParticleSystem[] psArr)
    {
        return PrefabParticleLogic.GetRedundancyMeshRenderersObjs(psArr);
    }

    private static bool _IsRedundancyMesh(ParticleSystem[] psArr)
    {
        return _GetRedundancyMesh(psArr).Count > 0;
    }
}
