using System;
using System.Collections.Generic;
using UnityEngine;

namespace EditerUtils
{
    public static class ComponentExtension
    {
        /// <summary>
        /// 将组件集合转为GameObjet集合
        /// </summary>
        /// <param name="components"></param>
        public static List<GameObject> ToGameObjects(this Component[] components)
        {
            var objs = new List<GameObject>();
            foreach (var com in components)
            {
                objs.Add(com.gameObject);
            }
            return objs;
        }

        public static List<GameObject> ToGameObjects(this List<Component> components)
        {
            return ToGameObjects(components.ToArray());
        }
    }
}
