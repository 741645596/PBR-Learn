Shader "FB/Other/LocalReflection"
{
    Properties
    {
        _CubeMap("CubeMap", CUBE) = "white" {}
        _BoxSize("BoxSize", Vector) = (0,0,0,0)
        _BoxCenter("BoxCenter", Vector) = (0,0,0,0)
        _Smoothness("Smoothness", Range( 0 , 1)) = 0
        _Opacity("Opacity", Range( 0 , 1)) = 1
        _NormalMap("NormalMap", 2D) = "bump" {}
        _NormalIntensity("NormalIntensity", Float) = 0
        _NormalPanner("NormalPanner", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
        }
        
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _NormalMap_ST;
                half3 _BoxSize;
                half3 _BoxCenter;
                half _NormalIntensity;
                half _Smoothness;
                half _Opacity;
                half2 _NormalPanner;
            CBUFFER_END
            
            samplerCUBE _CubeMap;
            sampler2D _NormalMap;

            struct Attributes
            {
                float4 vertex           :POSITION;
                float2 uv               :TEXCOORD0;
                float3 normal           :NORMAL;
                float4 tangent          :TANGENT;
                
            };
            
            struct Varyings
            {
                float4 vertex           :SV_POSITION;
                float2 uv               :TEXCOORD0;
                float3 world_pos        :TEXCOORD1;
                float3 world_normal     :TEXCOORD2;
                float3 pos_vertex       :TEXCOORD3;
                float3 world_tangent    :TEXCOORD4;
                float3 world_binormal   :TEXCOORD5;
            };

            Varyings vert( Attributes v)
            {
                Varyings o;
                o.pos_vertex = v.vertex.xyz;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.world_pos = TransformObjectToWorld(v.vertex.xyz);
                o.world_normal = TransformObjectToWorldNormal(v.normal);
                o.world_tangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.world_binormal = cross(o.world_normal,o.world_tangent) * v.tangent.w;
                return o;
            }
            
            float4 frag(Varyings i):SV_TARGET
            {
                half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                half3 normal_dir = normalize(i.world_normal);
                half3 tangent_dir = normalize(i.world_tangent);
                half3 binormal_dir = normalize(i.world_binormal);
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);


                half3 normal_data = UnpackNormal(tex2D( _NormalMap, i.uv * _NormalMap_ST.xy + _NormalMap_ST.zw + _NormalPanner * _Time));
                half3 normal_map = normalize(mul(normal_data,TBN));
                
                half3 worldReflection = reflect(-worldViewDir, normal_dir);

                half3 temp_dir = max((-_BoxSize - i.pos_vertex) / worldReflection,(_BoxSize - i.pos_vertex) / worldReflection);
                half3 newReflection = min(min(temp_dir.x,temp_dir.y),temp_dir.z) * worldReflection;
                newReflection += i.pos_vertex + _BoxCenter + _NormalIntensity * normal_map;
                
                half mip = ( 1.7 - ( _Smoothness * 0.7 ) ) * _Smoothness * 6.0 ;
                half4 cube_map = texCUBElod(_CubeMap,float4(newReflection,mip));
                return half4(cube_map.rgb,_Opacity);
            }
            ENDHLSL 
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
