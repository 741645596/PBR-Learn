Shader "FB/Particle/CubeMapRefract"
{
    
    Properties
    {
        [HDR][MainColor] _BaseColor("Color(底色)", Color) = (1,1,1,1)
        _AlphaControl("Alpha",Range(0,1)) = 0.9
        [Space(25)]
        //CubeMap折反射
        _CubeMap("CubeMap", CUBE) = ""{}
        _RefractRatio("Refract Ratio", Range(0,1)) = 0.5
        _FresnelAmount("菲涅尔系数", Range(0,100)) = 0.5
        [HDR]_FresnelColor("菲涅尔颜色",Color) = (1,0,0,1)
        //溶解相关
        [Space(25)]
        [MaterialToggle(USINGDISSOLVE)]_DissolveEnable("是否启用溶解", int) = 0
        _DissolveMap("溶解贴图",2D) = "black"{}
        _DissolveMap_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _DissolveStrength("溶解强度",Range(0.0,1.0)) = 0.5
        _DissolveEdgeWidth("溶解边宽",Range(0.0,0.1)) = 0.03
        [HDR] _EdgeEmission("边界自发光颜色",Color) = (1,1,1,1)
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags {  
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }
        Pass
        {
            BlendOp[_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            //Cull[_Cull]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ USINGDISSOLVE

            #include "Assets/Common/ShaderLibrary/Effect/ParticleFunction.hlsl"
            samplerCUBE _CubeMap;
            TEXTURE2D_X(_DissolveMap);
            SAMPLER(sampler_DissolveMap);
            CBUFFER_START(UnityPerMaterial)

                
                half _DissolveEnable;
                half _DissolveStrength;
                half _DissolveEdgeWidth;
                half4 _EdgeEmission;
                half4 _DissolveMap_TilingOffset;
                half _RefractRatio;
                half _FresnelAmount;
                half4 _BaseColor;
                half _FresnelPow;
                half _AlphaControl;
                half4 _FresnelColor;
                half _Opacity;


            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;           
                float3 normal : NORMAL;
                float2 uv : TEXCOORD4;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldRef : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
                float2 uv : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = UVTilingOffset(v.uv, _DissolveMap_TilingOffset);
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldViewDir =  normalize(_WorldSpaceCameraPos.xyz - o.worldPos.xyz);
                
                return o;
            }

            
            half4 frag (v2f i) : SV_Target
            {
                i.worldRef = refract(-i.worldViewDir,normalize(i.worldNormal),_RefractRatio);
                //half4 BaseMapCd = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uvMain) * _BaseColor;
                
                half4 reflect  = texCUBE(_CubeMap, i.worldRef);

                float fresnel = pow((1 - dot(i.worldViewDir , i.worldNormal)), _FresnelAmount);

                half3 resultColor;

                #if defined(USINGDISSOLVE)
                    half4 DissolveColor = SAMPLE_TEXTURE2D(_DissolveMap,sampler_DissolveMap,i.uv);
                    //求溶解裁切Alpha
                    half DissolveAlpha = step(DissolveColor.x,_DissolveStrength);
                    //求溶解边宽
                    half EdgeWidth = step(DissolveColor.x,_DissolveStrength-_DissolveEdgeWidth);
                    //得到边界颜色
                    half4 emissionCd = (DissolveAlpha-EdgeWidth) * _EdgeEmission;
                    if(_DissolveStrength>0.998){
                         emissionCd = half4(0,0,0,0);   
                    }
                    resultColor = emissionCd.rgb + _FresnelColor.rgb*fresnel + reflect.rgb;
                    
                    return half4(resultColor*_BaseColor,DissolveAlpha * _AlphaControl * _Opacity);
                #endif

                resultColor = _FresnelColor.rgb*fresnel + reflect.rgb;

                return half4(resultColor*_BaseColor,1*_AlphaControl*_Opacity);

            }
            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.ParticleShaderGUI"
}
