using System;
using System.Collections.Generic;

namespace EditerUtils
{
    public static class HashSetExtension
    {
        /// <summary>
        /// 将newSet数据插入到set内
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="set"></param>
        /// <param name="newSet"></param>
        public static void Append(this HashSet<string> set, HashSet<string> newSet)
        {
            foreach (var value in newSet)
            {
                if (set.Contains(value) == false)
                {
                    set.Add(value);
                }
            }
        }
    }
}
