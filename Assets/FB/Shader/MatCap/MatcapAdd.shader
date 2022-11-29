Shader "FB/Matcap/MatcapAdd"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Matcap("Matcap", 2D) = "white" {}
        [HDR]_MatcapColor("MatcapColor", Color) = (0,0,0,0)
        _MatcapAdd("MatcapAdd", 2D) = "white" {}
        [HDR]_MatcapAddColor("MatcapAddColor", Color) = (0,0,0,1)
        _NormalMap("NormalMap", 2D) = "white" {}
        _NormalIntensity("NormalIntensity", Float) = 0
        _Opacity("Opacity", Range( 0 , 1)) = 1
    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
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
                float4 _MatcapAddColor;
                float4 _NormalMap_ST;
                float4 _MatcapColor;
                float4 _MainTex_ST;
                float _NormalIntensity;
                float _Opacity;
            CBUFFER_END

            sampler2D _MatcapAdd;
            sampler2D _NormalMap;
            sampler2D _Matcap;
            sampler2D _MainTex;
            
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
                float3 world_tangent    :TEXCOORD3;
                float3 world_binormal   :TEXCOORD4;
            };

            Varyings vert( Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.world_pos = TransformObjectToWorld(v.vertex.xyz);
                o.world_normal = TransformObjectToWorldNormal(v.normal);
                o.world_tangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.world_binormal = cross(o.world_normal,o.world_tangent) * v.tangent.w;
                
                return o;
            }

            float4 frag(Varyings i):SV_TARGET
            {
                Light light_data = GetMainLight();

                half3 light_dir = normalize(light_data.direction);
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                half3 half_dir = normalize(light_dir + view_dir);

                half3 normal_dir = normalize(i.world_normal);
                half3 tangent_dir = normalize(i.world_tangent);
                half3 binormal_dir = normalize(i.world_binormal);
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);

                float4 base_color = tex2D(_MainTex,i.uv);

                float4 normal_map = tex2D(_NormalMap,i.uv);
                float3 normal_data = UnpackNormal(normal_map);
                normal_data.xy *= _NormalIntensity;
                normal_dir = normalize(mul(normal_data,TBN));

                half3 normalViewDir = TransformWorldToViewDir(normal_dir);

                half2 matcapUV = (normalViewDir.xy + 1) * 0.5;

                half3 matcapColor = tex2D(_Matcap,matcapUV).rgb * _MatcapColor.rgb;

                half opcaity = _MatcapColor.a * base_color.a * _MatcapAddColor.a * _Opacity;

                return half4(matcapColor,opcaity);
                
            }
            ENDHLSL 
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
