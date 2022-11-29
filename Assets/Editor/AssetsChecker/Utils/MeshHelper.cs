using System;
using UnityEditor;
using UnityEngine;

namespace EditerUtils
{
    public static class MeshHelper
    {
        /// <summary>
        /// 查找引用粒子mesh的路径，找不要返回null
        /// </summary>
        /// <param name="render"></param>
        /// <returns></returns>
        public static string GetMeshAssetPath(ParticleSystemRenderer render)
        {
            // 如果渲染模式是网格类型
            if (render == null ||
                render.enabled == false ||
                render.renderMode != ParticleSystemRenderMode.Mesh)
            {
                return null;
            }

            // 如果有设置模型才继续
            if (render.mesh == null)
            {
                return null;
            }

            return AssetDatabase.GetAssetPath(render.mesh);
        }

        /// <summary>
        /// 通过ParticleSystemRenderer查找到引用的ModelImporter
        /// </summary>
        /// <param name="render"></param>
        /// <returns></returns>
        public static ModelImporter GetModelImporter(ParticleSystemRenderer render)
        {
            var path = GetMeshAssetPath(render);
            if (null == path)
            {
                return null;
            }

            return AssetImporter.GetAtPath(path) as ModelImporter;
        }

        /// <summary>
        /// 通过粒子组件找到原始资源fbx的所有三角面数
        /// </summary>
        /// <param name="render"></param>
        /// <returns></returns>
        public static int GetTrianglesCount(ParticleSystemRenderer render)
        {
            // 找到原始资源才能获取正确的三角面数
            string assetPath = GetMeshAssetPath(render);
            if (assetPath == null)
                return 0;

            var loadAssetPath = assetPath.Replace(Application.dataPath, "Assets");
            var gameObj = AssetDatabase.LoadAssetAtPath<GameObject>(loadAssetPath);
            if (gameObj == null)
                return 0;

            int count = 0;
            var meshs = RepeatMeshChecker.GetSharedMeshs(gameObj);
            foreach (var mesh in meshs)
            {
                count += mesh.triangles.Length / 3;
            }
            return count;
        }
    }

}
