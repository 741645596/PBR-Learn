Shader "WB/Fresnel2" {
    Properties {
        _Fresnel("Fresnel", Range( 0 , 1)) = 0.1943072
        [HDR]_Color0("Color 0", Color) = (0.9811321,0.9811321,0.9811321,1)
    }

    SubShader {
        LOD 0

        Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"}

        Cull Back
        HLSLINCLUDE
        #pragma target 3.0
        ENDHLSL


        Pass {
            Name "Forward"
            Tags {"LightMode"="UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha , One OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA

            HLSLPROGRAM
            #define ASE_SRP_VERSION 999999

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _Color0;
            float _Fresnel;
            CBUFFER_END


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;
                float4 ase_color : COLOR;
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float4 ase_color : COLOR;
                float fresnel : TEXCOORD1;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;

                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                float3 viewDirectionWS = (_WorldSpaceCameraPos.xyz - positionWS);
                viewDirectionWS = normalize(viewDirectionWS);
                float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

                float NdotV = dot(viewDirectionWS, normalWS);
                float fresnel = smoothstep(_Fresnel, 1.0, (1.0 - max(NdotV, 0.0)));

                o.fresnel = fresnel;

                o.ase_color = v.ase_color;

                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.ase_normal = v.ase_normal;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.clipPos = vertexInput.positionCS;
                return o;
            }

            float4 frag(VertexOutput IN) : SV_Target
            {
                float fresnel = IN.fresnel;

                float4 FresnelColor = _Color0;

                float3 Color = FresnelColor.rgb;
                float Alpha = saturate(IN.ase_color.a * FresnelColor.a * fresnel);
                return float4(Color, Alpha);
            }
            ENDHLSL
        }
    }
    CustomEditor "FoldoutShaderGUI"
}