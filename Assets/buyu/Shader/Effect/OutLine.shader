Shader "WB/OutLine"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("CullMode", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend("Source Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DestBlend("Dest Blend Mode", Float) = 1
        [Enum(Off, 0, On, 1)]_ZWriteMode("ZWriteMode", float) = 0

        [Foldout]_RimName("Rim Color control",Range(0,1)) = 0
        [FoldoutItem][HDR] _RimColor("RimColor",Color) = (0,0,0,0)
        [FoldoutItem] _RimOffset("_RimOffset",Range(0,0.1)) = 0.1
        [FoldoutItem] _RimSpread("_RimSpread",Range(1,10)) = 2
        [FoldoutItem] _RimPower("Transparency",Range(0,1)) = 1	
    }

    SubShader
    {
        Pass
        {
            Name "Forward"
            Tags{"RenderPipeline" = "UniversalPipeline"  "Queue" = "Transparent-299"}
            Cull[_CullMode]
            Blend[_SourceBlend][_DestBlend]
            ZWrite[_ZWriteMode]
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA
            
        //模板缓存区的值与1比较，不相同即测试失败，并保持模板缓存区的值不变
Stencil
{
    Ref 9
    Comp notequal
    Pass decrWrap
    Fail keep
    ZFail keep
}


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "ColorCore.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _RimColor;
            float _RimOffset;
            float _RimSpread;
            float _RimPower;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;
                float4 ase_tangent : TANGENT;
            };

            struct vertexOutput
            {
                float4 clipPos : SV_POSITION;
                float4 tSpace0 : TEXCOORD1;
                float4 tSpace1 : TEXCOORD2;
                float4 tSpace2 : TEXCOORD3;
            };


            vertexOutput vert(VertexInput v) {
                vertexOutput o;
                //顶点位置以法线方向向外延伸
                v.vertex.xyz += v.ase_normal * _RimOffset;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz /** _RimOffset*/);
                // 转到世界空间
                float3 positionVS = TransformWorldToView(positionWS);
                float4 positionCS = TransformWorldToHClip(positionWS);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.ase_normal, v.ase_tangent);
                o.tSpace0 = float4(normalInput.normalWS, positionWS.x);
                o.tSpace1 = float4(normalInput.tangentWS, positionWS.y);
                o.tSpace2 = float4(normalInput.bitangentWS, positionWS.z);
                o.clipPos = positionCS;
                return o;
            }

            float4 frag(vertexOutput i) : COLOR
            {
                float3 WorldNormal = normalize(i.tSpace0.xyz);
                float3 WorldTangent = i.tSpace1.xyz;
                float3 WorldBiTangent = i.tSpace2.xyz;
                float3 WorldPosition = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                float3 WorldViewDirection = SafeNormalize(_WorldSpaceCameraPos.xyz - WorldPosition);
                float ndv = abs(dot(WorldNormal, -WorldViewDirection));
                ndv = 1.0f - ndv;

                float4 color = _RimColor;
                color.a = pow(saturate(ndv), _RimSpread) * _RimPower;
                return color;
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}