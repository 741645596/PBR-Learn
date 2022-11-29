

Shader "FB/Texture/Common" {

    Properties{
        [Header(Cull Mode)]
        [Space(5)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("剔除模式 : Off是双面显示，否则一般用 Back", int) = 0

        [MainTexture] _BaseMap("MainTexture", 2D) = "white" {}
        [MainColor]_Color("MainColor", Color) = (1,1,1,1)

        _BaseMapTilingOffset("MainTexTilingOffset", Vector) = (1,1,0,0)
    }

    SubShader{

        Tags {
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass {
            Tags{"LightMode" = "UniversalForward"}

            Lighting Off
            ZTest On
            ZWrite On

            Cull[_CullMode]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMapTilingOffset)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)


            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #if defined(UNITY_INSTANCING_ENABLED)
                    float3 vertexSH : TEXCOORD1;
                    float3  normalWS : TEXCOORD2;
                #endif
            };

            float2 GetUv(float2 uv, float4 st) {
                return (uv * st.xy + st.zw);
            }

            half3 InverseTonemapping(half3 color){
                half3 x = saturate(color);
                half3 a = -10127.0*x*x+13702.0*x+9.0;
                half3 b = 5.0*pow(a,0.5)+295.0*x-15.0;
                half3 c = b/(2008.0-1994*x);
                return c;
            }

            float3 AcesTonemapInverse_unity(float3 ldr){


                float3 y =  clamp(ldr,float3(0,0,0),0.945);
                // aces曲线方程 = f(x)
                // float3 aces_curve(x)
                // {
                //   x = c*x;
                //   ldr = (a*x*x + b * x) /(d*x*x + e*x + f)
                //   return ldr
                // }
                // 拟合出来的aces曲线参数
                float a = 2.1578064435521975;
                float b = 0.06290410615784145;
                float c = 0.6899121666852728;
                float d = 2.276728334038969;
                float e = 0.48014411094238746;
                float f = 0.27965527436078697;
                // 带入到反函数表达式中，用sympy求解。
                //from sympy import
                //def inversACES2():
                //x, y,a,b,c,d,e,f = symbols('x,y,a,b,c,d,e,f')
                //invers_func = solve( ( a*x*x*c*c + b*x*c)/(d*x*x*c*c + e*x*c+f)-y,    x)
                //return invers_func

                float3 sqrtA=4*a*f*y + b*b - 2*b*e*y - 4*d*f*y*y + e*e*y*y;
                sqrtA=sqrt(sqrtA)+e*y-b;
                
                return sqrtA/(2*c*(a - d*y));
            }

//            float3 AcesTonemapInverse_unity(float3 ldr)
//            {
//                float3 y =  clamp(ldr,float3(0,0,0),0.945);
//                //float3 y = clamp(ldr,0,0.945);
//                //float3 y=clamp(ldr,0,0.945);
////                // aces曲线方程 = f(x)
////                /*
////                    *   float3 aces_curve(x)
////                    *   {
////                    *      x = c*x;
////                    *      ldr = (a*x*x + b * x) /(d*x*x + e*x + f)
////                    *      return ldr
////                    *   }
////                    */
////                // 拟合出来的aces曲线参数
////                float a = 2.1578064435521975;
////                float b = 0.06290410615784145;
////                float c = 0.6899121666852728;
////                float d = 2.276728334038969;
////                float e = 0.48014411094238746;
////                float f = 0.27965527436078697;
////                // 带入到反函数表达式中，用sympy求解。
////                /*
////                    from sympy import *
////                    def inversACES2():
////                        x, y,a,b,c,d,e,f = symbols('x,y,a,b,c,d,e,f')
////                        invers_func = solve( ( a*x*x*c*c + b*x*c)/(d*x*x*c*c + e*x*c+f)-y,    x)
////                        return invers_func
////                    */
////                return  (-b + e*y + sqrt(4*a*f*y + b*b - 2*b*e*y - 4*d*f*y*y + e*e*y*y))/(2*c*(a - d*y));

//return float3(1,1,1);
//            }

            VertexOutput vert(VertexInput v) {
                    VertexOutput o = (VertexOutput)0;
                    UNITY_SETUP_INSTANCE_ID(v); 
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    o.uv0 = GetUv(v.texcoord0, UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMapTilingOffset));

                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    #if defined(UNITY_INSTANCING_ENABLED)
                        o.vertexSH.xyz = SampleSHVertex(o.normalWS.xyz);
                    #endif
                    return o;
            }

            half4 frag(VertexOutput i) : SV_Target{
               UNITY_SETUP_INSTANCE_ID(i);
               half4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0)* UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);

               //c.rgb=InverseTonemapping(c.rgb);
               //c.rgb=AcesTonemapInverse_unity(c.rgb);

               return c;
            }

            ENDHLSL

        }
    }
    FallBack off
}
