Shader "FB/Gem/Cristal"
{
    Properties
    {
        _BaseColor("Base Color",Color) = (0,0,0,0)

        _RefractMap ("Refract Map", Cube) = "white" {}
        _RefractIntensity("Refract Intensity",float) = 1
        _ReflectMap ("Reflect Map", Cube) = "white" {}
        _ReflectIntensity("Reflect Intensity",float) = 1

        _RimPower("RimPower", Float) = 2
        _RimScale("RimScale", Float) = 1
        _RimBias("RimBias", Float) = 0

        [Normal]_NormalMap("NormalMap",2D) = "Bump" {}
        _NormalIntensity("NormalIntensity",Float) = 1

        _InnerAlpha("InnerAlpha",Range(0,1)) = 1
        _OuterAlpha("OuterAlpha",Range(0,1)) = 1

    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    struct appdata
    {
        float4 vertex   : POSITION;
        float2 uv       : TEXCOORD0;
        float3 normal   : NORMAL;
        float4 tangent  : TANGENT;
    };

    struct v2f
    {
        float4 vertex       : SV_POSITION;
        float2 uv           : TEXCOORD0;
        float3 normal       : TEXCOORD1;
        float3 pos_world    : TEXCOORD2;
        float3 world_tangent    :TEXCOORD3;
        float3 world_binormal   :TEXCOORD4;
    };

    CBUFFER_START(UnityPerMaterial)
        half _RefractIntensity;
        half _ReflectIntensity;
        float4 _BaseColor;
        
        half _RimPower;
        half _RimScale;
        half _RimBias;
        half _NormalIntensity;
        half _InnerAlpha;
        half _OuterAlpha;
    CBUFFER_END

    TEXTURE2D(_NormalMap);
    SAMPLER(sampler_NormalMap);
    samplerCUBE _RefractMap;
    samplerCUBE _ReflectMap;

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = TransformObjectToHClip(v.vertex.xyz);
        o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
        o.uv = v.uv;
        o.normal = TransformObjectToWorldNormal(v.normal);
        o.world_tangent = TransformObjectToWorldDir(v.tangent.xyz);
        o.world_binormal = cross(o.normal,o.world_tangent) * v.tangent.w;
        return o;
    }

    ENDHLSL

    SubShader
    {
        Tags {"Queue" = "Transparent"}

        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit"}
            Blend SrcAlpha OneMinusSrcAlpha

            ZWrite On
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag (v2f i) : SV_Target
            {
                Light light = GetMainLight();

                half3 normal_dir = normalize(i.normal);
                half3 tangent_dir = normalize(i.world_tangent);
                half3 binormal_dir = normalize(i.world_binormal);
                half3 view_dir = normalize(_WorldSpaceCameraPos - i.pos_world);
                half3 reflect_dir = normalize(reflect(-view_dir,normal_dir)) + light.direction;

                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);

                float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv);
                float3 normal_data = UnpackNormal(normal_map);
                normal_data.xy *= _NormalIntensity;
                normal_dir = normalize(mul(normal_data,TBN));

                half NdotV = saturate(dot(view_dir,normal_dir));

                half rim = 1 - NdotV;
                float4 reflect_color = texCUBE(_ReflectMap,reflect_dir);
                float4 refract_color = texCUBE(_RefractMap,reflect_dir) * reflect_color * _BaseColor * _RefractIntensity;

                reflect_color *= _ReflectIntensity * rim;

                rim = pow(rim,_RimPower) * _RimScale + _RimBias;

                float4 final_color = refract_color + reflect_color;
                final_color += final_color * rim;

                return float4(final_color.rgb,_InnerAlpha);
            }
            ENDHLSL
        }


        Pass
        {
            Tags { "LightMode" = "UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            float4 frag (v2f i) : SV_Target
            {
                Light light = GetMainLight();
                half3 normal_dir = normalize(i.normal);
                half3 tangent_dir = normalize(i.world_tangent);
                half3 binormal_dir = normalize(i.world_binormal);
                half3 view_dir = normalize(_WorldSpaceCameraPos - i.pos_world);
                half3 reflect_dir = normalize(reflect(-view_dir,normal_dir)) + light.direction;

                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);

                float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv);
                float3 normal_data = UnpackNormal(normal_map);
                normal_data.xy *= _NormalIntensity;
                normal_dir = normalize(mul(normal_data,TBN));

                half NdotV = saturate(dot(view_dir,normal_dir));

                half rim = 1 - NdotV;
                float4 reflect_color = texCUBE(_ReflectMap,reflect_dir);
                float4 refract_color = texCUBE(_RefractMap,reflect_dir) * reflect_color * _BaseColor * _RefractIntensity;

                reflect_color *= _ReflectIntensity * rim;

                rim = pow(rim,_RimPower) * _RimScale + _RimBias;

                float4 final_color = refract_color + reflect_color;
                final_color += final_color * rim;

                return float4(final_color.rgb,_OuterAlpha);
            }
            ENDHLSL
        }

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
