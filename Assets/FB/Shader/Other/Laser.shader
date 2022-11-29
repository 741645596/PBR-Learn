Shader "FB/Other/ClothLaser"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _AmbientCol("AmbientCol", Color) = (.75, .75, .75,1)

        [Normal]_NormalMap("NormalMap",2D) = "bump" {}
        _NormalIntensity("NormalIntensity",Float) = 1

        _FilmStrengthMap("FilmStrengthMap",2D) = "white" {}
        _FilmIOR("FilmIOR",Float) = .3
        _FilmStrength("FilmStrength",Float) = 1
        _FilmThickness("FilmThickness",Float) = 0.137
        _FilmSpread("FilmSpread",Range(0.5,3)) = 1

        _MetallicGlossMap("MetallicGlossMap",2D)  = "black" {}
        _GlossMapScale("GlossMapScale",Range(0,1)) = 1
        _Anisotropy("Anisotropy",Range(-1,1)) = 0
    }

    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalRenderPipline"
            "RenderType"="Opaque" 
        }
        
        
        Pass{
            
            Tags{ "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;

                float4 _AmbientCol;

                float _NormalIntensity;

                float _FilmIOR;
                float _FilmStrength;
                float _FilmThickness;
                float _FilmSpread;
                
                float _GlossMapScale;
                float _Anisotropy;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);
            
            TEXTURE2D(_FilmStrengthMap);
            SAMPLER(sampler_FilmStrengthMap);

            struct Attributes
            {
                float4 vertex           :POSITION;
                float2 uv               :TEXCOORD0;
                float3 normal           :NORMAL;
                float4 tangent_dir          :TANGENT;
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
                o.world_tangent = TransformObjectToWorldDir(v.tangent_dir.xyz);
                o.world_binormal = cross(o.world_normal,o.world_tangent) * v.tangent_dir.w;
                
                return o;
            }
            
            float4 frag(Varyings i):SV_TARGET
            {
                // sample map
                float3 base_color = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb * _Color.rgb;
                float2 pbr_map = SAMPLE_TEXTURE2D(_MetallicGlossMap,sampler_MetallicGlossMap,i.uv).xy;
                float4 normal_map = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv);
                float film_map = SAMPLE_TEXTURE2D(_FilmStrengthMap,sampler_FilmStrengthMap,i.uv).r;

                // get light
                Light light_data = GetMainLight();

                // get dir
                float3 light_dir = SafeNormalize(light_data.direction);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                float3 normal_dir = normalize(i.world_normal);
                float3 tangent_dir = normalize(i.world_tangent);
                float3 binormal_dir = normalize(i.world_binormal);
                
                float3x3 TBN = float3x3(tangent_dir,binormal_dir,normal_dir);
                
                float3 normal_data = UnpackNormal(normal_map);
                normal_data.xy *= _NormalIntensity;
                normal_dir = normalize(mul(normal_data,TBN));

                float3 binormal_negative = cross(-normal_dir,tangent_dir);

                // get data from dir
                float NdotV = saturate(dot(normal_dir, view_dir));
                float NdotV2 = NdotV * NdotV;

                float NdotL = saturate(dot(normal_dir,light_dir));
                
                float TdotL = dot(tangent_dir, light_dir);
                float TdotV = dot(tangent_dir, view_dir);
                float TdotV2 = TdotV * TdotV;

                float BdotL = dot(binormal_negative, light_dir);
                float BdotV = dot(binormal_negative, view_dir);
                float BdotV2 = BdotV * BdotV;

                float LdotV = saturate(dot(light_dir, view_dir));
                float oneMinusLdotV = 1.0 - LdotV;
                
                float oneMinusLdotV5 = pow(oneMinusLdotV,5);    // or be 0
                float ultraLdotV = 1.0 - oneMinusLdotV5;

                float radiance = NdotL * light_data.color;

                // get data from map
                float metallic = pbr_map.x;
                float oneMinusMetallic = (1.0 - metallic) * 0.95999998;

                float smoothness = (1.0 - pbr_map.y * _GlossMapScale);
                smoothness = max((smoothness * smoothness), 0.001);

                // anisotropy
                float anisotropy1 = 1 -_Anisotropy;
                anisotropy1 = (anisotropy1 * smoothness);

                float anisotropy2 = _Anisotropy + 1.0;
                anisotropy2 = (anisotropy2 * smoothness);

                float2 final_anisotropy = 0;
                final_anisotropy.x = max(anisotropy1, 0.0099999998);
                final_anisotropy.y = max(anisotropy2, 0.0099999998);

                // ----------------                
                float BoL_mul_A = BdotL * final_anisotropy.x;
                float ToL_mul_A = TdotL * final_anisotropy.y;
                float anisotropy_length1 = length(float3(ToL_mul_A,BoL_mul_A,0)) * NdotV;
                
                float ToV_mul_A = TdotV * final_anisotropy.y;
                float BoV_mul_A = BdotV * final_anisotropy.x;
                float anisotropy_length2 = length(float3(ToV_mul_A,BoV_mul_A,0));

                float final_anisotropy_length = NdotL * (anisotropy_length1 + anisotropy_length2);    // NdotL * anisotropy_length1 + anisotropy_length2
                final_anisotropy_length = 0.5 / final_anisotropy_length;
                final_anisotropy_length = min(final_anisotropy_length, 1.0);

                float2 final_anisotropy2 = final_anisotropy.yx * final_anisotropy.yx;
                float ToV_div_A2 = TdotV2 / final_anisotropy2.x;
                float BoV_div_A2 = BdotV2 / final_anisotropy2.y;
                
                half BTN = BoV_div_A2 + ToV_div_A2 + NdotV2;

                // caculate albedo and light_dir_color
                half3 albedo = base_color.xyz * 0.30530602 + float3(0.68217111, 0.68217111, 0.68217111);
                albedo = base_color.xyz * albedo + float3(0.012522878, 0.012522878, 0.012522878);

                half3 light_dir_color = base_color.xyz * albedo + float3(-0.039999999, -0.039999999, -0.039999999);
                light_dir_color = metallic * light_dir_color + float3(0.039999999, 0.039999999, 0.039999999);
                light_dir_color = light_dir_color * ultraLdotV + oneMinusLdotV5;

                float3 final_albedo = base_color.xyz * albedo;

                // caculate hight light mask
                half3 hight_light_factor = (BTN * BTN * final_anisotropy.x * final_anisotropy.y * PI).xxx;
                hight_light_factor = 1.0 / hight_light_factor;
                
                hight_light_factor = hight_light_factor * final_anisotropy_length * light_dir_color;
                hight_light_factor = pow(hight_light_factor , 1.0 / _FilmSpread);

                // caculate film color
                half BoV_lerp_ToV = lerp(BdotV,TdotV,_Anisotropy);
                half filmThickness = abs(BoV_lerp_ToV) * _FilmThickness - _FilmIOR;

                float3 film_color = cos(filmThickness * float3(24.849998, 30.450001, 35.0));
                film_color = film_color * -0.5 + float3(0.5, 0.5, 0.5);
                film_color = lerp(film_color,0.5,filmThickness);
                film_color = film_color * film_color * _FilmStrength.x * 2;
                film_color = film_map * hight_light_factor * film_color ;
                film_color = film_color + float3(-9.9999997e-05, -9.9999997e-05, -9.9999997e-05);
                film_color = min(max(film_color, 0), 100) + final_albedo * oneMinusMetallic;

                // caculate ambient color
                float3 ambient_color = oneMinusMetallic * final_albedo * _AmbientCol.xyz;

                // combine color
                float3 final_color = max(film_color * radiance + ambient_color,0);
                final_color = pow(final_color, 0.41666666) * 1.0549999 + float3(-0.055, -0.055, -0.055);
                final_color = max(final_color.xyz,0);

                return float4(final_color,1);
                
            }
            ENDHLSL 
        }

        UsePass "FB/Standard/SGamePBR/ShadowBeforePost"
        UsePass "FB/Standard/SGamePBR/DepthOnly"
        UsePass "FB/Standard/SGamePBR/ShadowCaster"
        //UsePass "FB/Standard/SGamePBR/SGameMeta"
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
