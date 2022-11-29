Shader "FeiYun/Scene/MaJiangZi_Shadow"
{
    Properties
    {
        _GroundHeight("阴影高度", Float) = 0
        _ShadowColor("RGB=阴影颜色 A=透明度", Color) = (0,0,0,1)
        _ShadowFalloff("阴影渐变", Range(0,50)) = 0.05
        //_LightOffset("灯光位移",vector) = (0,0,-0.5,0)
        //_LightRotation("灯光旋转",Range(0,360)) = 0
        _LightRotation1("灯光旋转",vector) = (0,0,0,0)

        _PlanStenciValue("_Pana Shadow Stencil",Float) = 1

        //_SrcBlend("__src", Float) = 1.0
        //_DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"
        }


        // Planar Shadows平面阴影
        Pass
        {
            Name "PlanarShadow"
            Tags{ "LightMode" = "UniversalForward" }

            //用使用模板测试以保证alpha显示正确
            // Stencil
            // {
                //     Ref 0
                //     Comp equal
                //     Pass incrWrap
                //     Fail keep
                //     ZFail keep
            // }

            Stencil
            {
                Ref [_PlanStenciValue]
                Comp NotEqual // 不相等
                Pass Replace//如果模板测试（和深度测试）通过，如何处理缓冲区的内容  替换模板缓冲区中的数据为1
                Fail Keep
            }

            Cull Off

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与地面穿插
            Offset -1 , 0

            ColorMask RGB

            HLSLPROGRAM


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
                float _GroundHeight;
                float4 _ShadowColor;
                float _ShadowFalloff;
                half4 _LightOffset;
                half _LightRotation;
                half3 _LightRotation1;
            CBUFFER_END

            #define UNITY_PI    3.14159

            float4 RotateAroundYInDegrees (float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                vertex.xz = mul(vertex.xz,m);
                return vertex;
            }

            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                vertex.xz = mul(vertex.xz,m);
                return vertex;
            }



            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float3 shadowPos1 : TEXCOORD1;
            };

            float3 ShadowProjectPos(float4 vertPos)
            {
                float3 shadowPos;

                //得到顶点的世界空间坐标
                float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;
                // worldPos = RotateAroundYInDegrees(worldPos, _LightRotation);


                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(float3(0,1,0));
                lightDir += normalize(_LightRotation1);
                //lightDir.xz += _LightRotation;
                //lightDir = RotateAroundYInDegrees(lightDir, _LightRotation).xyz;

                //阴影的世界空间坐标（低于地面的部分不做改变）
                //shadowPos.y = min(worldPos.y, _GroundHeight);
                shadowPos.y = _GroundHeight;
                shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - _GroundHeight) / lightDir.y;


                return shadowPos;
            }



            Varyings vert (Attributes v)
            {
                Varyings o= (Varyings)0;;

                
                //得到阴影的世界空间坐标
                o.shadowPos1 = ShadowProjectPos(v.vertex);
                //转换到裁切空间
                // o.vertex = UnityWorldToClipPos(shadowPos);
                o.vertex = TransformWorldToHClip(o.shadowPos1);

                //得到中心点世界坐标
                // float3 center = float3(unity_ObjectToWorld[0].w , _GroundHeight , unity_ObjectToWorld[2].w);
                // //计算阴影衰减
                // float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFalloff);

                //阴影颜色
                // o.color = _ShadowColor;
                // o.color.a *= falloff;



                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {

                float3 center = float3(unity_ObjectToWorld[0].w , _GroundHeight , unity_ObjectToWorld[2].w);


                float falloff = 1-saturate(distance(i.shadowPos1, center) * _ShadowFalloff);

                //i.color = _ShadowColor;
                //i.color.a *= falloff;

                i.color = _ShadowColor;
                i.color.a *= _ShadowFalloff;
                

                return i.color;
            }
            ENDHLSL
        }
    }
}