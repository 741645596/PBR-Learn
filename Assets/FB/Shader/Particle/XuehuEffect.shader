Shader "FB/Particals/XuehuEffect" {
    Properties {
        [Space(20)]
        _Course("溶解进程 _Course", Range(-0.1,2 )) = 0
        [Space(10)][Header(_________________________SHAPE__________________________________________________________________________)][Space(10)]
        _Alpha("透明度 _Alpha", Range(0,1)) = 0.5
        _Scale("网格缩放 _Scale", Range(0, 200)) = 80

        [HDR]_BackgroundColor("背景颜色 _BackgroundColor", color) = (0.0,0.0,0.0,0.0)
        [HDR]_MeshColor("静态网格颜色 _MeshColor", Color) = (0.1,0.0,0.3,1.0)
        _StaticMeshStrength("静态网格粗细 _StaticMeshStrength", Range(0,1)) = 0.6
        [HDR]_DynamicMeshColor("动态网格颜色 _DynamicMeshColor", Color) = (2.0,1.0,0.0,1.0)
        _DynamicMeshStrength("动态网格粗细 _DynamicMeshStrength", Range(0,1)) = 0.6
        [Toggle]_QuadDir("网格动态翻转 _QuadDir", Range(0, 1)) = 0
        [Space(10)][Header(________________________LIGHTING________________________________________________________________________)][Space(10)]
        [HDR]_FloorEmission("地光颜色 _FloorEmission", Color ) = (0.1,0.1,0.1,1.0)


        [Space(10)]
        _RefCube("环境球 _RefCube", Cube) = "black"{}
        [HDR]_RefColor("反射颜色 _RefColor", Color) = (0.1,0.1,0.1,1.0)


        [Space(10)][Header(________________________EMISSION________________________________________________________________________)][Space(10)]
        [HDR]_EmissionColor("自发光颜色 _EmissionColor",Color) =  (0.3,1.7,0.8,1.0)
        _Emission("自发光 _Emission   Offset = Flow", 2D) = "white"{}
        _EmissionMask("自发光遮罩 _EmissionMask  Offset = Flow", 2D) = "white"{}
        
        
        [Space(10)][Header(________________________FRESNEL________________________________________________________________________)][Space(10)]
        [HDR]_FresnelColor("Fresnel颜色 _FresnelColor", Color) = (0.0,0.15,0.3,1.0)
        
        _FresnelMin("Fresnel Min", Range(0, 1)) = 0.03
        _FresnelMax("Fresnel Max", Range(0, 1)) = 0.63

        [Space(10)][Header(_________________________SLICE__________________________________________________________________________)][Space(10)]
        // [Toggle]_InvertColorR("顶点色R翻转", Range(0,1 ) ) = 0
        [HDR]_RemovingColor("消解颜色 _RemovingColor", Color ) = (0.0,0.5,1.0,1.0)
        [HDR]_SliceHiddenEdge("消解边缘 _SliceHiddenEdge", Color) = (0.2,0.5,0.2,1.0)
        _Volusity("扩散速度 _Volusity",Range(0,1)) = 0.05
        _HiddenSpeed("消解速度 _HiddenSpeed", Range(0,1)) = 0.6
        _AlphaEnhance("透明度增强 _AlphaEnhance", Range(0,1)) = 1
        // _Hidden("寿命",Range(0,1)) = 0.6
        // _NormalDirection("消散跟随法线方向", Range(0,1)) = 0.3
        // _RatioOfChange("参与消散比例", Range(0, 1)) = 0.5
        // _Direction("消散方向", vector) = (0.0,1.0,0.0,0.0)
        [Space(10)][Header(_________________________SCAN__________________________________________________________________________)][Space(10)]
        _ScanDistance_1("扫描线1间隔 _ScanDistance_1", Range(1, 10)) = 3
        [HDR]_ScanColor_1("扫描线1颜色 _ScanColor_1", Color) = (0.0,0.3,0.15,1.0)
        _ScanDistance_2("扫描线2间隔 _ScanDistance_2", Range(1, 300)) = 70
        [HDR]_ScanColor_2("扫描线2颜色 _ScanColor_2", Color) = (0.2,0.5,0.2,1.0)


        [Space(30)] 
        [Toggle]_Expand("包裹模型 _Expand", Range(0, 1)) = 1

    }
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 

    CBUFFER_START(UnityPerMaterial)
        float _Scale;
        float4 _EmissionMask_ST;
        float4 _Emission_ST;
        half _Course;
        float4 _Direction;
        // half _InvertColorR;
        float _NormalDirection;
        float _Expand;
        half _AlphaEnhance;
        half _RatioOfChange;
        half3 _BackgroundColor;
        half3 _FresnelColor;
        half3 _RemovingColor;
        half3 _FloorEmission;
        half _Alpha;
        float _Volusity;
        float _Hidden;
        float _FresnelPow;
        half3 _EmissionColor;
        float _HiddenSpeed;
        half4 _ScanColor_1;
        half4 _ScanColor_2;
        half3 _DynamicMeshColor;
        half3 _SliceHiddenEdge;
        half3 _MeshColor;
        half3 _RefColor;
        half _FresnelMin;
        half _FresnelMax;
        half _ScanDistance_1;
        half _ScanDistance_2;
        half _StaticMeshStrength;
        half _DynamicMeshStrength;
        half _QuadDir;
    CBUFFER_END

    sampler2D _EmissionMask;
    sampler2D _Emission;
    samplerCUBE _RefCube;
    sampler2D _VertexColorMap; 

    struct VertexInput {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float2 texcoord0 : TEXCOORD0;
        float2 texcoord1 : TEXCOORD1;
        float3 vertexColor : COLOR;
    };
    struct VertexOutput {
        float4 positionCS : SV_POSITION;
        float2 uv0 : TEXCOORD0;
        float3 positionWS : TEXCOORD1;
        float3 normalWS : TEXCOORD2;
        float Show : TEXCOORD3;
        float course : TEXCOORD5;
        float3 positionOS:TEXCOORD6;
        float2 positionSS : TEXCOORD7;
        float index : TEXCOORD8;
        
    };
    VertexOutput vert (VertexInput v) {
        VertexOutput o = (VertexOutput)0;
        o.positionOS = v.positionOS;
        o.uv0 = v.texcoord0;
        float3 vertexColor = v.texcoord1.xyx;//.vertexColor;
        o.index = vertexColor.r;
        // vertexColor.r = lerp(vertexColor.r, 1-vertexColor.r, _InvertColorR);
        
        o.positionWS = TransformObjectToWorld(v.positionOS + v.normalOS * _Expand * 0.0001);
        
        o.course = _Course  - vertexColor.r;
        float weight = max(0.0000,  _Course  - vertexColor.r);
        float intensity = weight;
        float threshold = 0.1;
        intensity = saturate(intensity / threshold);

        o.Show = vertexColor.r - _Course ;
        intensity = pow(intensity, 1) ; //(1 + vertexColor.g * 5);
        o.normalWS = TransformObjectToWorldNormal(v.normalOS);  
        float3 direction = o.normalWS;//lerp(normalize(_Direction) ,o.normalWS, _NormalDirection );
        o.positionWS += intensity * direction * weight * 10 * _Volusity * (1 + vertexColor.g) * 0.5;
        o.positionCS = TransformWorldToHClip(o.positionWS);
        o.positionSS = (o.positionCS.xy/o.positionCS.w) * 0.5 + 0.5 ;

        return o;
    }
    ENDHLSL

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            
            "RenderType"="Transparent"
            // "Queue"="Transparent"
        }

        Pass
        {
            Name "ForwardPrePass"
            Cull Off
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag_PreZ

            half4 frag_PreZ(VertexOutput i) : COLOR {
                clip(i.Show+ 0.1); 
                float DistanceToCenter;
                float2 uv = i.uv0 *_Scale ;
                float MeshLine ;
                float2 DistanceOfBaseUVToCenter = abs(0.5 - frac(uv)) * 2; 
                DistanceToCenter = max(DistanceOfBaseUVToCenter.x, DistanceOfBaseUVToCenter.y);
                MeshLine = pow(DistanceToCenter , 9);    
                uint2 randomUV = uint2(uv) % 128 ;
                int index = randomUV.x + randomUV.y * 128;
                float var_RandomMap = (sin(index * 7.7777777) );
                float course = 1 - i.course * 25 * _HiddenSpeed + 0.5 * (var_RandomMap);
                float alpha =  step( DistanceToCenter, pow(course, 0.7));

                alpha =  100000.0 * (alpha - 0.1 );
                clip(alpha - 0.02);
                return 0;
            }

            ENDHLSL

        }

        Pass {
            Name "Forward"
            Tags {
                "LightMode" = "UniversalForwardOnly" 
                "RenderType"="Transparent"
            }
            Blend SrcAlpha OneMinusSrcAlpha 
            Cull Off
            ZWrite Off
            ZTest Equal
            
            HLSLPROGRAM

            //菲涅尔是否收到顶点Alpha影响
            #pragma multi_compile _ _FRESNEL_VERTEXALPHA_ON
            #pragma multi_compile _ USINGTOGGLEFRESNEL
            #pragma vertex vert
            #pragma fragment frag

            half4 frag(VertexOutput i) : COLOR {  //, half vface:VFACE

                


                // clip(i.Show+ 0.1); 
                float3 vDirWS = normalize(i.positionWS - _WorldSpaceCameraPos.xyz);
                float3 nDirWS = normalize(i.normalWS);
                float ndotv = saturate (dot(-vDirWS, nDirWS));
                
                // 基础颜色
                float DistanceToCenter;
                float2 uv = i.uv0 *_Scale ;
                float MeshLine ;
                float2 DistanceToCenter2 = abs(0.5 - frac(uv)) * 2; 
                DistanceToCenter = max(DistanceToCenter2.x, DistanceToCenter2.y);
                MeshLine = pow(DistanceToCenter , 100 * (1-_StaticMeshStrength) * (1-_StaticMeshStrength));    
                // int2 randomUV = int2(uv)%8 ;
                // int index = randomUV.x + randomUV.y * 8;
                // float var_RandomMap = (sin(index * 16) * 0.5 + 0.5);


                half var_Emission = tex2D(_Emission, (i.uv0) * _Emission_ST.xy + _Time.x * _Emission_ST.zw).r;
                half var_EmissionMask = tex2D(_EmissionMask, ((i.uv0 )  * _EmissionMask_ST.xy + _Time.x * _EmissionMask_ST.zw)).r;
                half3 emission = var_Emission * var_EmissionMask * _EmissionColor;
                
                //
                float3 color = _BackgroundColor.rgb;
                color += MeshLine.r  * _MeshColor; // * saturate(vface)
                
                // Fresnel
                // color += pow(1 - ndotv, _FresnelPow * 10) * _FresnelColor;
                color += smoothstep(_FresnelMin, _FresnelMax, 1 - ndotv) * _FresnelColor;
                // 底光
                color += saturate(-nDirWS.y) * _FloorEmission;
                
                // 面片唤醒颜色
                color +=  pow(10 *saturate(0.05 - abs(i.course)),2) * _RemovingColor; 
                
                // 面片消散颜色
                color += saturate(i.course* 10) * _RemovingColor;

                // 自发光
                color += emission ;
                float course = 1 - i.course * 25 * _HiddenSpeed;// + 0.5 * (var_RandomMap - 0.5);
                color += saturate(i.course * 20 - (1-DistanceToCenter)* 1  ) * _SliceHiddenEdge; 

                
                // 反射
                float3 vPosWS = _WorldSpaceCameraPos.xyz;
                
                float3 rDirWS = reflect(vDirWS, nDirWS);
                half3 var_RefCube = texCUBE(_RefCube, rDirWS).rgb;
                color += var_RefCube * _RefColor;
                
                half nvPow3 = ndotv * ndotv * ndotv;
                // 扫描线
                float y1 = abs(frac(i.positionSS.y * _ScanDistance_1 + _Time.y * 2) - 0.5);
                float y2 = frac(i.positionSS.y * _ScanDistance_2 + _Time.y * 1  );
                color += (y1.xxx * y2.xxx) * nvPow3.xxx * _ScanColor_1.rgb;
                color += abs(frac(i.positionSS.y *(abs(sin(_Time.yyy)) + 0.5) * 130+ _Time.x) - 0.5) * _ScanColor_2.rgb * nvPow3.xxx ;
                

                color += saturate(0.3 * _DynamicMeshStrength - abs((_Time.y * 1 - lerp(1-DistanceToCenter, DistanceToCenter, _QuadDir) - i.index * 3) % 1 - 0.5)) * _DynamicMeshColor * nvPow3;

                half alpha = (_Alpha + saturate(i.course * _AlphaEnhance * 20));
                

                return half4(color, alpha);
                //return fresnel;
            }
            ENDHLSL
        }
    }
}
