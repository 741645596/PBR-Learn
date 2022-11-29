using System;
using System.Collections.Generic;

namespace EditerUtils
{
    public static class SortHelper
    {
        /// <summary>
        /// 优先按类型排序，然后类型在排序
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="datas"></param>
        /// <param name="typeCB"> 返回类型值，值越小排在越前面 </param>
        /// <param name="condition"> 类型之间的排序，返回true表示排前面 </param>
        public static void MultiSort<T>(List<T> datas,
            Func<T, int> typeCB,
            Func<T, T, bool> condition)
        {
            var muiltDic = new Dictionary<int, List<T>>();
            foreach (var data in datas)
            {
                var tp = typeCB(data);
                if (muiltDic.ContainsKey(tp) == false)
                {
                    muiltDic.Add(tp, new List<T>());
                }
                var tpArr = muiltDic[tp];
                var insertIndex = _GetInsertIndex(tpArr, data, condition);
                tpArr.Insert(insertIndex, data);
            }

            datas.Clear();
            var keys = new List<int>(muiltDic.Count);
            foreach (var k in muiltDic.Keys)
            {
                keys.Add(k);
            }
            keys.Sort();
            foreach (var key in keys)
            {
                datas.AddRange(muiltDic[key]);
            }
        }

        private static int _GetInsertIndex<T>(List<T> res, T newData, Func<T, T, bool> condition)
        {
            for (int i = 0; i < res.Count; i++)
            {
                if (condition(newData, res[i]))
                {
                    return i;
                }
            }
            return res.Count;
        }
    }
}




