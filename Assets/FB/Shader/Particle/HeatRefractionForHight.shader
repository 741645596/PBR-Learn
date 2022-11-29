Shader "FB/Particle/HeatRefractionForHight"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("混合层1 ，one one 是ADD", int) = 6
        [Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("混合层2 ，SrcAlpha    OneMinusSrcAlpha 是alphaBlend", int) = 1
        [MainTexture] _MainTex ("NoiseTex", 2D) = "white" {}

        [HideInInspector]_MainTexClamp("MainTexClamp(纹理WrapMode)",float) = 0  //0:Clamp 1:RepeatUV
        [HideInInspector]_MainTexRepeatU("MainTexRepeatU(纹理WrapMode)",float) = 0 // 1:RepeatU
        [HideInInspector]_MainTexRepeatV("MainTexRepeatV(纹理WrapMode)",float) = 0 // 1:RepeatV

        _Intensity("Intensity ", Range(0,1)) = 1
        [Toggle]_Tips("   此 shader 不 建 议 过 多 使 用 ! ",int) = 0
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags {  "RenderPipeline" = "UniversalPipline" 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }
        LOD 100
        Pass
        {
            Tags {
                "LightMode" = "UniversalForward"
            }

            //Blend SrcAlpha OneMinusSrcAlpha
             Blend[_SrcBlend][_DestBlend]
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define REQUIRE_OPAQUE_TEXTURE

            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            //URP的渲染截屏采样 需要添加一个Overlay的Camera，CullingMask设置Nothing，并把这个Camera添加到主Camera的Stack里面
            //sampler2D _AfterPostProcessTexture;

            CBUFFER_START(UnityPerMaterial)

                TEXTURE2D_X(_MainTex);
                SAMPLER(sampler_MainTex);
                float4 _MainTex_ST;
                float _Intensity;
                half _Opacity;
                float _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV;

            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 vertexColor : COLOR;
            };

            struct v2f
            {

                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                half4 vertexColor: COLOR;
                float4 projPos : TEXCOORD1;
            };
			
			#define GET_OPAQUE_TEXTURE(screenUV) \
                float3 sceneColor = SampleSceneColor(screenUV);

            v2f vert(appdata v)
            {

                v2f o;
                o.uv = v.uv;
                o.vertexColor = v.vertexColor;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.projPos = GetScreenUV(o.positionCS);
                //计算偏移强度
                o.projPos.w = _Intensity * v.vertexColor.a;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uvMain = GetUV(i.uv.xy, _MainTexClamp, _MainTexRepeatU, _MainTexRepeatV,_MainTex_ST);
                half4 _noiseTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                //_noiseTexture = GetTextColor(_noiseTexture, uvMain, _MainTexRepeatU, _MainTexRepeatV);

                half3 res=GetUVByNoiseTextureCenter(_noiseTexture,i.uv,i.projPos.w);
                half2 sceneUVs = i.projPos.xy+res.xy;
				
				GET_OPAQUE_TEXTURE(sceneUVs)
                //half4 sceneColor = tex2D(_AfterPostProcessTexture, sceneUVs);
                return half4(sceneColor.rgb, res.z* i.vertexColor.a*_Opacity);

                // // sample the texture
                // half4 mainTex = tex2D(_MainTex, i.uv);
                // float2 screenUV = (i.positionCS.xy / _ScaledScreenParams.xy);
                // float2 screenUVs =  screenUV + (float2(mainTex.r , mainTex.g) * mainTex.a * _Intensity * i.vertexColor.a);
                // //half4 sceneColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUVs );
                // half3 opaqueMap = SampleSceneColor(screenUVs); //引用内部定义简写上面
                // half3 finalC = lerp(opaqueMap , 0 , 0);
                // half alpha = mainTex.a * i.vertexColor.a*_Opacity;
                // return half4(finalC,alpha);
            }
            ENDHLSL
        }
    }
}
