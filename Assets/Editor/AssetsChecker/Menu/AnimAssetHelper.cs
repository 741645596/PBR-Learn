
using System.Collections.Generic;
using System.IO;
using EditerUtils;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 动画压缩接口
/// </summary>
public class AnimAssetHelper
{
    // 包含动画的文件
    private static readonly string[] Anim_Suffixs = { ".anim", ".fbx" };

    //[MenuItem("Assets/压缩Anim", true)]
    static private bool vZipAni()
    {
        return SelectionHelper.IsSuffixExist(Anim_Suffixs);
    }

    // 需要该功能在打开
    //[MenuItem("Assets/压缩Anim", false, 0)]
    static private void ZipAni()
    {
        var guids = Selection.assetGUIDs;
        foreach (var guid in guids)
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            Zip(path);
        }

        AssetDatabase.SaveAssets();

        Debug.Log("压缩结束!!!");
    }

    /// <summary>
    /// 获取资源是否包含的AnimationClip对象
    /// </summary>
    /// <param name="fbxPath"></param>
    /// <returns></returns>
    public static List<AnimationClip> GetAnimClips(string assetPath)
    {
        var res = new List<AnimationClip>();
        var objs = AssetDatabase.LoadAllAssetsAtPath(assetPath);
        foreach (var obj in objs)
        {
            if (obj.GetType() == typeof(AnimationClip))
            {
                res.Add(obj as AnimationClip);
            }
        }
        return res;
    }

    /// <summary>
    /// 该方法只能用于监听导入地方
    /// </summary>
    /// <param name="fbxObj"></param>
    /// <returns></returns>
    public static List<AnimationClip> GetAnimClips(GameObject fbxObj)
    {
        List<AnimationClip> clips = new List<AnimationClip>(AnimationUtility.GetAnimationClips(fbxObj));
        if (clips.Count == 0)
        {
            AnimationClip[] objectList = Object.FindObjectsOfType(typeof(AnimationClip)) as AnimationClip[];
            if (objectList != null)
            {
                clips.AddRange(objectList);
            }
        }
        return clips;
    }

    /// <summary>
    /// 压缩anim或fbx的动画
    /// </summary>
    /// <param name="assetPath"></param>
    public static void Zip(string assetPath)
    {
        if (PathHelper.IsSuffixExist(assetPath, ".anim"))
        {
            ZipAnim(assetPath);
            return;
        }

        if (PathHelper.IsSuffixExist(assetPath, ".fbx"))
        {
            ZipFbxAnim(assetPath);
            return;
        }
    }

    /// <summary>
    /// 压缩fbx模型下的动画
    /// </summary>
    /// <param name="fbxObj"></param>
    public static void ZipFbxAnim(GameObject fbxObj)
    {
        var clips = GetAnimClips(fbxObj);
        for (int i = 0; i < clips.Count; i++)
        {
            // 删除多余数据
            ReduceCanDeleteData(clips[i]);

            // 降低精度
            ReduceFloatPrecision(clips[i]);
        }
    }

    /// <summary>
    /// 压缩动画
    /// </summary>
    /// <param name="fbxPath"></param>
    public static void ZipFbxAnim(string fbxPath)
    {
        var clips = GetAnimClips(fbxPath);
        for (int i = 0; i < clips.Count; i++)
        {
            // 删除多余数据
            ReduceCanDeleteData(clips[i]);

            // 降低精度
            ReduceFloatPrecision(clips[i]);
        }
    }

    /// <summary>
    /// 删除冗余数据
    /// </summary>
    /// <param name="clip"></param>
    public static void ReduceCanDeleteData(AnimationClip clip)
    {
        EditorCurveBinding[] curves = AnimationUtility.GetCurveBindings(clip);
        for (int j = 0; j < curves.Length; j++)
        {
            EditorCurveBinding curveBinding = curves[j];
            AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, curveBinding);
            if (curve == null || curve.keys == null)
            {
                continue;
            }

            if (_CanDelete(curve.keys, curveBinding))
            {
                AnimationUtility.SetEditorCurve(clip, curveBinding, null);
            }
        }
    }

    /// <summary>
    /// 获取浮点数value小数点后有几位
    /// </summary>
    /// <param name="value"></param>
    /// <param name="num"></param>
    /// <returns></returns>
    public static int GetDecimalNum(float value)
    {
        var res = value.ToString();
        var arr = res.Split('.');
        if (arr.Length != 2) return 0;

        return arr[1].Length;
    }

    /// <summary>
    /// 是否有多余数据可以删除
    /// </summary>
    /// <param name="clip"></param>
    /// <returns></returns>
    public static bool CanDeleteData(AnimationClip clip)
    {
        var curves = AnimationUtility.GetCurveBindings(clip);
        for (int j = 0; j < curves.Length; j++)
        {
            var curveBinding = curves[j];
            var curve = AnimationUtility.GetEditorCurve(clip, curveBinding);
            if (curve == null || curve.keys == null)
            {
                continue;
            }

            if (_CanDelete(curve.keys, curveBinding))
            {
                return true;
            }
        }
        return false;
    }

    private static bool _CanDelete(Keyframe[] keys, EditorCurveBinding curveBinding)
    {
        // 只能是scale曲线
        string name = curveBinding.propertyName.ToLower();
        if (name.Contains("localscale") == false)
        {
            return false;
        }

        // 确保scale曲线是默认值，才可以删除
        if (keys.Length == 2)
        {
            var key1 = keys[0];
            var key2 = keys[1];
            if (key1.time == 0 &&
                key1.value == 1f &&
                key1.value == key2.value &&
                key1.inTangent == key2.inTangent &&
                key1.outTangent == key2.outTangent)
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 动画文件是否有多余数据可删除
    /// </summary>
    /// <param name="animPath"></param>
    /// <returns></returns>
    public static bool CanDeleteData(string animPath)
    {
        var clips = GetAnimClips(animPath);
        foreach (var clip in clips)
        {
            if (CanDeleteData(clip))
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 是否可以压缩为float3精度
    /// </summary>
    /// <param name="animPath"></param>
    /// <returns></returns>
    public static bool CanFloat3(string animPath)
    {
        var clips = GetAnimClips(animPath);
        foreach (var clip in clips)
        {
            if (CanFloat3(clip))
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 缩减精度
    /// </summary>
    /// <param name="clip"></param>
    public static void ReduceFloatPrecision(AnimationClip clip)
    {
        if (CanFloat3(clip) == false)
        {
            var path = AssetDatabase.GetAssetPath(clip);
            Debug.Log($"{path} 精度已经是float3不需要压缩");
            return;
        }

        EditorCurveBinding[] bindings = AnimationUtility.GetCurveBindings(clip);
        for (int j = 0; j < bindings.Length; j++)
        {
            EditorCurveBinding curveBinding = bindings[j];
            AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, curveBinding);
            if (curve == null || curve.keys == null)
            {
                continue;
            }

            Keyframe[] keys = curve.keys;
            for (int k = 0; k < keys.Length; k++)
            {
                Keyframe key = keys[k];
                key.value = float.Parse(key.value.ToString("f3"));
                key.inTangent = float.Parse(key.inTangent.ToString("f3"));
                key.outTangent = float.Parse(key.outTangent.ToString("f3"));
                keys[k] = key;
            }
            curve.keys = keys;

            AnimationUtility.SetEditorCurve(clip, curveBinding, curve);
        }
    }

    /// <summary>
    /// 压缩.anim动画文件
    /// </summary>
    /// <param name="animPath"></param>
    public static void ZipAnim(string animPath)
    {
        var aniClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(animPath);
        if (null == aniClip)
        {
            Debug.LogWarning($"{animPath}加载为AnimationClip失败");
            return;
        }

        // 删除多余数据
        ReduceCanDeleteData(aniClip);

        // 降低精度
        ReduceFloatPrecision(aniClip);
    }

    // 是否需要压缩精度
    private static bool CanFloat3(AnimationClip clip)
    {
        // 如果前面10个数据都是3位小数点，则表示不需要压缩
        var index = 0;
        var bindings = AnimationUtility.GetCurveBindings(clip);
        for (int j = 0; j < bindings.Length; j++)
        {
            var curve = AnimationUtility.GetEditorCurve(clip, bindings[j]);
            if (curve == null || curve.keys == null)
            {
                continue;
            }

            var keys = curve.keys;
            for (int k = 0; k < keys.Length; k++)
            {
                var key = keys[k];
                if (GetDecimalNum(key.value) > 3)
                    return true;
                if (GetDecimalNum(key.inTangent) > 3)
                    return true;
                if (GetDecimalNum(key.outTangent) > 3)
                    return true;

                index++;
                if (index == 10)
                    return false;
            }
        }
        return false;
    }
}
