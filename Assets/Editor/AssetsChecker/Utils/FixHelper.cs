using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    /// <summary>
    /// 修复帮助类
    /// </summary>
    public static class FixHelper
    {
        public static readonly DateTime Utc_Date_Time = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
        public static long GetThousandMilliSeconds()
        {
            return (DateTime.UtcNow.Ticks - Utc_Date_Time.Ticks);
        }

        /// <summary>
        /// 异步收集问题信息
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="files"> 需要收集的资源文件集合 </param>
        /// <param name="stepFileCB"> 检查资源文件回调，返回null表示无问题，否则返回模板T </param>
        /// <param name="finishCB"> 检查结束回调 </param>
        public static void AsyncCollect<T>(List<string> files,
            Func<string, T> stepFileCB,
            Action<List<T>> finishCB)
        {
            var infos = new List<T>();
            if (files.Count == 0)
            {
                finishCB(infos);
                return;
            }

            int startIndex = 0;
            EditorApplication.update = delegate ()
            {
                // 用完每帧32ms
                long elpaseTime = 0;
                while (elpaseTime < 320000)
                {
                    var startTime = GetThousandMilliSeconds();

                    string file = files[startIndex];
                    startIndex++;

                    var info = stepFileCB(file);
                    if (info != null)
                    {
                        infos.Add(info);
                    }

                    bool isCancel = EditorUtility.DisplayCancelableProgressBar("匹配资源中", file, (float)startIndex / (float)files.Count);
                    if (isCancel || startIndex >= files.Count)
                    {
                        EditorUtility.ClearProgressBar();
                        EditorApplication.update = null;
                        startIndex = 0;
                        finishCB(infos);
                        return;
                    }

                    var endTime = GetThousandMilliSeconds();
                    elpaseTime += endTime - startTime;
                }
            };
        }

        /// <summary>
        /// 显示取消框的一键修复接口
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="infos"> 继承AssetInfoBase的数据集合 </param>
        /// <param name="stepCB"> 单步修复回调 </param>
        /// <param name="finishCB"> 结束回调，参数表示是否取消 </param>
        public static void FixStep<T>(List<T> infos, Action<T> stepCB, Action<bool> finishCB)
            where T : AssetInfoBase
        {
            if (infos.Count == 0)
            {
                finishCB(false);
                return;
            }

            int startIndex = 0;
            EditorApplication.update = delegate ()
            {
                var info = infos[startIndex];
                stepCB(info);

                startIndex++;
                bool isCancel = EditorUtility.DisplayCancelableProgressBar("修复进行中",
                    info.assetPath,
                    (float)startIndex / (float)infos.Count);
                if (isCancel || startIndex >= infos.Count)
                {
                    EditorUtility.ClearProgressBar();
                    EditorApplication.update = null;
                    startIndex = 0;

                    finishCB(isCancel);
                }
            };
        }

        /// <summary>
        /// 可取消的遍历搜集信息 
        /// </summary>
        /// <param name="paths"> 分析的目标文件 </param>
        /// <param name="stepCB"> 回调目标文件 </param>
        public static void ForeachCollect(List<string> paths, Action<string> stepCB)
        {
            for (int i = 0; i < paths.Count; i++)
            {
                var path = paths[i];
                bool isCancel = EditorUtility.DisplayCancelableProgressBar("正在搜集数据",
                    string.Format($"正在分析：{path}"), (float)i / paths.Count);
                if (isCancel)
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }

                stepCB(path);
            }

            EditorUtility.ClearProgressBar();
        }
    }
}

