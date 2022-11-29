using System;
using UnityEngine;

public class RepeatMeshData
{
    public string assetPath;

    // 网格名称
    public string name;

    public int vertexCount;

    public int triangle;

    public int normals;

    public int tangents;

    public int uv;

    public int subMeshCount;

    public Vector3 boundsCenter;

    public Vector3 boundsSize;

    public RepeatMeshData(Mesh mesh, string resPath)
    {
        assetPath = resPath;

        name = mesh.name;
        vertexCount = mesh.vertexCount;
        triangle = mesh.triangles.Length;
        normals = mesh.normals.Length;
        tangents = mesh.tangents.Length;
        uv = mesh.uv.Length;
        subMeshCount = mesh.subMeshCount;
        boundsCenter = mesh.bounds.center;
        boundsSize = mesh.bounds.size;
    }

    /// <summary>
    /// 用于当Mesh的唯一值
    /// </summary>
    /// <returns></returns>
    public string GetUniqueKey()
    {
        return $"vertexCount={vertexCount}, triangle={triangle}, bcx={boundsCenter.x}, bcy={boundsCenter.y}, bcz={boundsCenter.z}, boundsSize={boundsSize}, uv={uv}, normal={normals}, subMeshCount={subMeshCount}, tangents={tangents}";
    }

}
