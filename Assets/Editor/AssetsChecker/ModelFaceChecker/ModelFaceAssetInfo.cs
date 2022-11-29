
using UnityEngine;

public class ModelFaceAssetInfo : AssetInfoBase
{
    public bool isMeshMiss;             // 是否未配置mesh
    public int nodeCount;               // 总节点数
    public int renderCount;             // 总渲染数量
    public int vertexCount;             // 总顶点数量
    public int faceCount;               // 总三角面数
    public int materialCount;           // 总材质球数量
    public int boneCount;               // 骨骼数量
    public Vector2 textureSizeCount;    // 总贴图尺寸大小

    public override bool CanFix()
    {
        return false;
    }

    public override void Fix()
    {
        Debug.Log("需要美术人员修改模型");
    }

    public override string GetErrorDes()
    {
        var des = isMeshMiss ? "Mesh丢失；" : "";
        return des + $"总面数:{faceCount}、" +
            $"总顶点数{vertexCount}、" +
            $"总尺寸{textureSizeCount.x}x{textureSizeCount.y}、" +
            $"总渲染{renderCount}个、" +
            $"总材质球{materialCount}、" +
            $"总节点{nodeCount}、" +
            $"bone数量{boneCount}";
    }

    public override bool IsError()
    {
        return false;
    }
}
