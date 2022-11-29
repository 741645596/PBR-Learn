Shader "FB/Particle/HiddenEffect" {
    Properties {


        [Header(Blend Mode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("混合层1 ，one one 是ADD",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend",int) = 1
        [HDR]_BaseColor ("基础色", Color) = (1,1,1,1)
        _BaseMap ("颜色贴图", 2D ) = "white"{} 
        [HDR]_TintColor ("染色颜色", Color) = (1,1,1,1)
        _AlphaMask("透明度遮罩", 2D) = "Black"{} 
      
        [HideInInspector]_Fresnelintensity ("Fresnel  intensity", Float ) = 1
        [HideInInspector]_EXP ("EXP", Float ) = 1
       
        _TintInt("染色强度", Range(0, 1)) = 0
        _TransInt("透明强度", Range(0, 1)) = 0


   
    

        _LightDir("LightDir",vector) = (1,0,0,0)

    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
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
            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _TintColor;
                float _Fresnelintensity;
                float _EXP;
                half _TintInt;
                half _TransInt;
                int _ToggleFresnel;
                sampler2D _BaseMap;
                sampler2D _AlphaMask;
                half _Opacity;
                int _Fresnel_VertexAlpha;
                float _MaskTexClamp, _MaskTexRepeatU, _MaskTexRepeatV;
                float _JianBianClamp, _JianBianRepeatU, _JianBianRepeatV;

                half3 _LightDir;
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
                float3 WorldNormal : TEXCOORD2;
                half4 vertexColor : COLOR;
             
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                //o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.WorldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                return o;
            }
            half4 frag(VertexOutput i) : COLOR { 
                
                float3 normalDirection = normalize(i.WorldNormal);
                float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);  
                float3 lightDir = normalize(_LightDir);
                
                half NoL = saturate(dot(normalDirection,lightDir));

                float fresnelValue = saturate(1.0 - max(0, dot(normalDirection, worldViewDir)));
                
                
                #if defined(USINGTOGGLEFRESNEL)
                    fresnelValue = saturate(dot(normalDirection, worldViewDir));
                #endif

      

                float fresnel = (pow(fresnelValue, _EXP) * _Fresnelintensity);

                
    
                half4 var_BaseMap = tex2D(_BaseMap, i.uv0).rgba * _BaseColor.rgba; 
                half3 var_AlphaMask = tex2D(_AlphaMask, i.uv0); 
                
                half3 color = lerp(var_BaseMap, _TintColor.rgb , _TintInt);

                half  alpha ;
                alpha = (fresnel * NoL);
                half halfLambert = dot(normalDirection,lightDir)*0.5+0.5;
                alpha = saturate( alpha + ((halfLambert-_TransInt)/_TransInt ) + var_AlphaMask *(1 -  _TransInt));
                alpha *= var_BaseMap.a * _BaseColor.a;

                return half4(color ,alpha);
                
                //return fresnel;
            }
            ENDHLSL
        }
    }
}
