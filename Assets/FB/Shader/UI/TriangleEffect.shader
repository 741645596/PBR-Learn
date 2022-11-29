Shader "FB/UI/TriangleEffect" {
    Properties {


        [Header(Blend Mode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层1 ，one one 是ADD",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 1
        _BackgroundColor("背景颜色", color) = (0.0,0.0,0.0,0.0)
        _Color1("形状颜色", color) = (1.0,1.0,1.0,1.0)
  
        _BaseMap ("颜色贴图", 2D ) = "white"{} 
        _Angle("角度", Range(0,1)) = 0.5
        _Speed("速度", Range(0,1)) = 0.3
        _ChangeRate("变化比例", Range(0,1)) = 0.5
        //[Toggle]_SoftEdge("柔边",Range(0,1)) = 0
        _SoftEdgeWeight("柔边强度", Range(0, 1)) = 0
        _MaskMap("遮罩", 2D) = "white"


   

   
    

    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Tags {"LightMode"="Default UI RP"}
            Blend [_SrcBlend] [_DestBlend]
            Cull Back
            ZWrite ON
            //ZTest [_Zalways]
            
            HLSLPROGRAM

            //菲涅尔是否收到顶点Alpha影响
            #pragma multi_compile _ _FRESNEL_VERTEXALPHA_ON
            #pragma multi_compile _ USINGTOGGLEFRESNEL
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 


            CBUFFER_START(UnityPerMaterial)
    
                sampler2D _BaseMap; float4 _BaseMap_ST;
                sampler2D _MaskMap; float4 _MaskMap_ST;
                half4 _BackgroundColor;
                half4 _Color1;
                float _Speed;
                float _Angle;
                float _ChangeRate;
                half _SoftEdge;
                half _SoftEdgeWeight;
         
            CBUFFER_END

            struct VertexInput {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                half4 vertexColor : COLOR;
            };
            
            struct VertexOutput {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            
              
             
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
          

               
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                return o;
            }
            half4 frag(VertexOutput i) : COLOR { 
                

                
                float3 color  = _BackgroundColor.xyz;

                float alpha =  1;



                float2 uv = i.uv0 * _BaseMap_ST.xy;
                
                int2 uvInt = floor(uv);
                uv.y += uvInt.x % 2 * 0.5; 
                uvInt = floor(uv);
                float2 uvCenter = uvInt ;
                
                half4 BaseMap = tex2Dlod(_BaseMap, float4(uv.x ,uv.y ,0,0)).rgba;


                float t =(frac(uvCenter.x * 0.1* (_Angle) + uvCenter.y * (_Angle)* 0.1 + _Time.y * _Speed));
                // t = frac(_Time.x * 5);
                t = saturate((t / _ChangeRate - (1/_ChangeRate * (1 - _ChangeRate))));
                
                float t1 = t < 0.5 ? 1 : max(0, t * 2 - 1);
                float t2 = t < 0.5 ? min(1, t*2) : 0;
                t2 = t2 < 0.98 ? t2 : 1;
                float color1 = BaseMap < t1 ? 1 : 0;
                color1 = lerp(0, 1, color1);
                float color2 = BaseMap < t2 ? 1 : 0;
                float colorValue =  lerp(color1 , 0, color2);




                float2 uv1 = i.uv0 * _BaseMap_ST.xy + float2(0,0.5);
                int2 uv1Int = uv1;
                uv1.y += uv1Int.x % 2 * 0.5; 
                uv1Int = floor(uv1);
                float2 uv1Center = uv1Int ;
                
                half4 BaseMap2 = tex2Dlod(_BaseMap, float4(-uv1.x,-uv1.y,0,0)).rgba;


                float T =(frac(uv1Center.x * 0.1* (_Angle) + uv1Center.y * 0.1* (1 - _Angle) + _Time.y * _Speed));
                T = saturate((T / _ChangeRate - (1/_ChangeRate * (1 - _ChangeRate))));
        
                float T1 = T < 0.5 ? 1 : max(0, T * 2 - 1);
                float T2 = T < 0.5 ? min(1, T * 2) : 0;
                T2 = T2 < 0.98 ? T2 : 1;
            
                float color3 = BaseMap2 < T1 ? 1 : 0;
                color3 = lerp(colorValue, 1, color3);
                float color4 = BaseMap2 < T2 ? 1 : 0;
                
                colorValue = lerp(color3 , 0, color4 );
                colorValue *= lerp(1, pow(saturate((max((1-BaseMap2),(1-BaseMap)))*(2)), (_SoftEdgeWeight)), _SoftEdgeWeight);
                half2 Var_MaskMap = tex2D(_MaskMap, i.uv0 * _MaskMap_ST.xy + _MaskMap_ST.zw).ra;
                colorValue *= Var_MaskMap.g * Var_MaskMap.r;
             
                color = lerp(_BackgroundColor, _Color1, colorValue);
  
               



                
                // color = color2;
                return half4(color ,alpha);

                




                
                //return fresnel;
            }
            ENDHLSL
        }
    }
}
