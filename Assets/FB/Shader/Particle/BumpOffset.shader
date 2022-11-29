//视差映射材质
Shader "FB/Particle/BumpOffset"
{
    Properties
	{
        //BaseMap相关
        _BaseMap("Albedo(底色)", 2D) = "white" {}
        [HDR][MainColor] _BaseColor("Color(底色)", Color) = (1,1,1,1)
        _BaseMap_TilingOffset("_BaseMapTilingOffset", Vector) = (1,1,0,0)
        [Space(25)]
        _NormalMap("法线贴图",2D) = "bump"{}
        [Space(25)]
        _DepthMap("_DepthMap", 2D) = "white" {}
        _DepthBias("深度控制", Range(-1,1)) = 0.1
        _DepthMapSample("深度贴图采样(8)的倍数即可",Vector) = (16,24,0,0)
        //溶解相关
        [Space(25)]
        [MaterialToggle(USINGDISSOLVE)]_DissolveEnable("是否启用溶解", int) = 0
        _DissolveMap("溶解贴图",2D) = "black"{}
        _DissolveMap_TilingOffset("TilingOffset", Vector) = (1,1,0,0)
        _DissolveStrength("溶解强度",Range(0.0,1.0)) = 0.5
        _DissolveEdgeWidth("溶解边宽",Range(0.0,0.1)) = 0.03
        [Space(10)]
        //极坐标相关
        _FlowSpeed("流动速度",Range(0,1)) = 0.5
        [HDR] _EdgeEmission("边界自发光颜色",Color) = (1,1,1,1)
        [HideInInspector]_Opacity ("Opacity", float) = 1
    }
    SubShader
    {
        Tags {  
            "RenderPipeline" = "UniversalPipline"
            "Queue" = "Transparent"
        }
        pass
        {
            BlendOp[_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/Renders/Shaders/ShaderLibrary/Effect/ParticleFunction.hlsl"
            #pragma multi_compile _ USINGDISSOLVE
            //TEXTURE2D_X(_DepthMap);
            sampler _DepthMap;
            //TEXTURE2D_X(_DepthMap);
            TEXTURE2D_X(_BaseMap);
            TEXTURE2D_X(_NormalMap);
            TEXTURE2D_X(_DissolveMap);
            //Texture2D _DepthMap;
            SAMPLER(sampler_DissolveMap);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_DepthMap);
            SAMPLER(sampler_NormalMap);
            //SamplerState sampler_DepthMap;
            CBUFFER_START(UnityPerMaterial)
                half _DepthBias;
                float4 _DepthMap_ST;
                half4 _DepthMapSample;
                half4 _BaseMap_TilingOffset;
                half4 _BaseColor;
                half _FlowSpeed;
                //溶解参数
                half _DissolveEnable;
                half _DissolveStrength;
                half _DissolveEdgeWidth;
                half4 _EdgeEmission;
                half4 _DissolveMap_TilingOffset;
                half _Opacity;
            CBUFFER_END

            struct appdata
            {
                float4 vertex           :POSITION;
                float4 uv               :TEXCOORD0;
                float3 normal           :NORMAL;
                float4 tangent          :TANGENT;
            };

            struct v2f
            {
                float4 vertex           :SV_POSITION;
                float4 uv               :TEXCOORD0;
                float3 world_pos        :TEXCOORD1;
                float3 world_normal     :TEXCOORD2;
                float3 world_tangent    :TEXCOORD3;
                float3 world_binormal   :TEXCOORD4;

                float4 TtoW0 : TEXCOORD5;
				float4 TtoW1 : TEXCOORD6;
				float4 TtoW2 : TEXCOORD7;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;

                o.uv.xy = UVTilingOffset(v.uv.xy, _BaseMap_TilingOffset);
                o.uv.zw = 0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                
                o.world_pos = TransformObjectToWorld(v.vertex.xyz);
                o.world_normal = TransformObjectToWorldNormal(v.normal);
                o.world_tangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.world_binormal = cross(o.world_normal,o.world_tangent) * v.tangent.w;


                o.TtoW0 = float4(o.world_tangent.x, o.world_binormal.x, o.world_normal.x, o.world_pos.x);
				o.TtoW1 = float4(o.world_tangent.y, o.world_binormal.y, o.world_normal.y, o.world_pos.y);
				o.TtoW2 = float4(o.world_tangent.z, o.world_binormal.z, o.world_normal.z, o.world_pos.z);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                half3 normal_dir = normalize(i.world_normal);
                half3 tangent_dir = normalize(i.world_tangent);
                half3 binormal_dir = normalize(i.world_binormal);
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);

                float3 view_tangentSpace = normalize(mul(TBN,view_dir));
                half2 pomUV = 0;

                //视差算法  陡峭算法优化版本        
                pomUV = POM_Level1(_DepthMap,i.uv.xy, ddx(i.uv.xy),
                                        ddy(i.uv.xy), normal_dir, view_dir,
                                        view_tangentSpace,_DepthMapSample.x,_DepthMapSample.y, _DepthBias);
                //视差遮蔽算法
                //pomUV = ParallaxOcclusionMapping(_DepthMap,sampler_DepthMap,view_tangentSpace,-5,tempFloatuv);
                
                //pomUV = ParallaxOcclusionMapping(_DepthMap,sampler_DepthMap,view_tangentSpace,_DepthBias,tempFloatuv);
                //视差算法 正常算法
                /*
                for(int j = 0;j<10;j++){
                    float height_map = SAMPLE_TEXTURE2D(_DepthMap,sampler_DepthMap,pomUV).r;
                    pomUV = i.uv - (1 - height_map ) * view_tangentSpace.xy / view_tangentSpace.z * _DepthBias * 0.01;
                }*/

                //基础贴图颜色
                half4 BaseMapCd = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,pomUV) * _BaseColor;
                half4 NormalCd = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,pomUV);

                float3 tangentNormal;
				tangentNormal = UnpackNormal(NormalCd);

				//兰伯特光照

                normal_dir = normalize(mul(tangentNormal,TBN));

                //float lambert = saturate(dot(normal_dir, lightDir));
                //float lambert =dot(normal_dir, lightDir)*0.5+0.5;
                //return  lambert;

				//最终输出颜色为lambert光强*材质diffuse颜色*光颜色
				//float3 diffuse = lambert * light.color.rgb;

                //half3 diffuse =  light.color.rgb * BaseMapCd * max(0, dot(normal_dir, view_dir));
                
                //half3 specular = light.color.rgb * pow(max(0, dot(tangentNormal, view_dir)),5);

                half vDotN = dot(view_dir,normal_dir);
                vDotN=vDotN*0.5+0.5;
                //return half4(vDotN,vDotN,vDotN,1);

                float2 polarCenter = pomUV-float2(0.5,0.5);
                //极坐标UV
                float2 polarUV = float2( length(polarCenter) + _Time.g * _FlowSpeed , atan2(polarCenter.x,polarCenter.y) * (1/(2*3.1415926)));
               
                half3 resultColor;
                
                #if defined(USINGDISSOLVE)
                    half4 DissolveColor = SAMPLE_TEXTURE2D(_DissolveMap,sampler_DissolveMap,polarUV);
                    //求溶解裁切Alpha
                    half DissolveAlpha = step(DissolveColor.x,_DissolveStrength);
                    //求溶解边宽
                    half EdgeWidth = step(DissolveColor.x,_DissolveStrength-_DissolveEdgeWidth);
                    //得到边界颜色
                    half4 emissionCd = (DissolveAlpha-EdgeWidth) * _EdgeEmission;
                    
                    resultColor = emissionCd.rgb + BaseMapCd.rgb * vDotN;

                    return half4(resultColor,DissolveAlpha * BaseMapCd.a * _Opacity);

                #endif

                //resultColor = BaseMapCd.rgb * diffuse;
                resultColor = BaseMapCd.rgb*vDotN;
                // return half4(BaseMapCd.rgb, 1);

                return half4(resultColor,BaseMapCd.a);
                
            }
            ENDHLSL
        }
    }
    CustomEditor "FBShaderGUI.ParticleShaderGUI"
}