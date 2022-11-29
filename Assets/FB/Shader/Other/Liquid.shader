Shader "FB/Other/Liquid"
{
    Properties
    {
        [Header(Glass)]
        _GlassColor("Glass Color", Color) = (1,1,1,1)
        _GlassAlpha("Glass Alpha", Range(0,1)) = 1
        _GlassRimPower("Glass Rim Power",float) = 1
        _GlassRimColor("Glass Rim Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power",float) = 1
        _SpecularColor("Specular Color", Color) = (1,1,1,1)

        [Header(Base Params)]
        _LiquidSize("Liquid Size",Range(-1,0)) = 0
        _FillAmount ("Fill Amount", Range(-10,10)) = 0.0
        [HDR]_TopColor ("Top Color", Color) = (1,1,1,1)
        [HDR]_FoamColor ("Foam Line Color", Color) = (1,1,1,1)
        _Rim ("Foam Line Width", Range(0,0.1)) = 0.0    
        [HDR]_LiquidColor ("LiquidColor", Color) = (1,1,1,1)
        
        _RimPower ("Rim Power", Range(0,10)) = 0.0
        [HDR]_RimColor ("Rim Color", Color) = (1,1,1,1)

        [Header(Noise)]
        _NoiseMap("Noise Map", 2D) = "black" {}
        _TopNoiseDostort("Top Noise Dostort",Range(0,1)) = 0
        _NoiseFlowSpeed("Noise Flow Speed",vector) = (0,0,0,0)

        [Header(Bubble)]
        _BubbleMap("Bubble Map", 2D) = "black" {}
        _BubbleSpeed("BubbleSpeed(Y)",float) = 0
        _BubbleIntensity("BubbleIntensity",float) = 0

        [HideInInspector] _WobbleX ("WobbleX", Range(-1,1)) = 0.0
        [HideInInspector] _WobbleZ ("WobbleZ", Range(-1,1)) = 0.0
    }
    
    SubShader
    {
        Tags {"RenderPipeline"="UniversalRenderPipline" "Queue"="Transparent"}

        //液体
         Pass
        {
            Tags{ "LightMode" = "SRPDefaultUnlit"}
            Zwrite On
            Cull Off
            AlphaToMask On // transparency

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;	
            };
            
            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float4 uv       : TEXCOORD0;
                float3 normal   : TEXCOORD2;		
                float fillEdge  : TEXCOORD3;
                float3 world_pos:TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float _FillAmount;
                float4 _TopColor, _RimColor, _FoamColor, _LiquidColor;
                float _Rim, _RimPower;
                
                sampler2D _NoiseMap;
                float4 _NoiseMap_ST;
                half _TopNoiseDostort;
                half2 _NoiseFlowSpeed;

                sampler2D _BubbleMap;
                float4 _BubbleMap_ST;
                half _BubbleSpeed;
                half _BubbleIntensity;

                half _LiquidSize;
                half _WobbleX, _WobbleZ;
            CBUFFER_END


            #define UNITY_PI    3.14159

            float4 RotateAroundYInDegrees (float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, sina, -sina, cosa);
                return float4(vertex.yz , mul(m, vertex.xz)).xzyw ;				
            }

            v2f vert (appdata v)
            {
                v2f o;
                float3 pos = v.vertex.xyz + v.normal * _LiquidSize;
                o.vertex = TransformObjectToHClip(pos);
                o.world_pos = TransformObjectToWorld(v.vertex.xyz);

                float3 word_pos_center = TransformObjectToWorld(float3(0,0,0));
                float3 view_pos_center = TransformWorldToView(word_pos_center);

                float3 view_pos = TransformWorldToView(o.world_pos);
                half2 view_pos_uv = (view_pos - view_pos_center).xy;

                o.uv.xy = TRANSFORM_TEX(v.uv,_NoiseMap);
                o.uv.zw = TRANSFORM_TEX(view_pos_uv,_BubbleMap);

                float3 worldPosX = RotateAroundYInDegrees(v.vertex,360);
                float3 worldPosZ = float3(worldPosX.y, worldPosX.z, worldPosX.x);		
                float3 worldPosAdjusted = o.world_pos - word_pos_center + (worldPosX  * _WobbleX)+ (worldPosZ* _WobbleZ); 
                o.fillEdge = worldPosAdjusted.y + _FillAmount;
                o.normal = TransformObjectToWorldNormal(v.normal);
                return o;
            }
            
            float4 frag (v2f i, half facing : VFACE) : SV_Target
            {
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                half3 normal_dir = normalize(i.normal);

                float Rim = pow(1 - saturate(dot(normal_dir, view_dir)), _RimPower);
                float4 RimResult = smoothstep(0.5, 1.0, Rim);
                RimResult *= _RimColor;

                half noise = tex2D(_NoiseMap,i.uv.xy + _NoiseFlowSpeed * _Time.x).r;
                half noise_factor = noise * _TopNoiseDostort;

                half fillEdge = i.fillEdge + noise_factor;

                float foam = (step(fillEdge, 0.5) - step(fillEdge, (0.5 - _Rim)));
                float4 foamColored = foam * (_FoamColor * 0.9);

                float4 result = step(fillEdge, 0.5) - foam;
                float4 resultColored = result * _LiquidColor;
                
                half bubble = tex2D(_BubbleMap,i.uv.zw + float2(0,_BubbleSpeed) * _Time.x).r * pow(noise,4) * facing * _BubbleIntensity * (1 - foam);

                float4 finalResult = resultColored + foamColored;				
                finalResult.rgb += RimResult + half3(bubble,bubble,bubble);

                float4 topColor = _TopColor * (foam + result);
                return facing > 0 ? finalResult: topColor;
            }
            ENDHLSL
        }

        //罩子
        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            struct appdata
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : NORMAL;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float3 pos_world  : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _GlassColor;
                half _GlassAlpha;

                half _GlassRimPower;
                float4 _GlassRimColor;

                half _SpecularPower;
                float4 _SpecularColor;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.pos_world =TransformObjectToWorld(v.vertex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                Light light_data = GetMainLight();
                half3 dir_view = normalize(_WorldSpaceCameraPos - i.pos_world);
                half3 dir_light = normalize(light_data.direction);
                half3 dir_normal = normalize(i.normal);
                half3 dir_half = normalize(dir_view + dir_light);

                half4 rim = (pow(1 - saturate(dot(dir_normal, dir_view)), _GlassRimPower)) * _GlassRimColor;

                half4 specular = pow(max(dot(dir_half, dir_normal),0),_SpecularPower) * _SpecularColor;

                float4 final_color = rim + specular + _GlassColor;

                return float4(final_color.rgb,_GlassAlpha);
            }
            ENDHLSL

        }

       
        
    }
}