Shader "WB/IceEffect" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(0.1, 10)) = 1
        _ReflectColor("ReflectColor", Color) = (1,1,1,0.5)
        _IceTex ("IceTex", 2D) = "white" {}
        _NormalMap("NormalMap", 2D) = "bump" {}
        _RefStrength ("RefStrength", Range(0, 0.3)) = 0.1
        _FrenelPower ("FrenelPower", Range(0, 2)) = 0.1
        _TexAlphaAdd ("TexAlphaAdd", Range(0, 1)) = 0.1
        _Cutoff ("Cutoff", Range(0, 1)) = 1
    }
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent+1"}
        Pass {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput {
                half4 vertex : POSITION;
                half3 ase_normal : NORMAL;
                half4 ase_tangent : TANGENT;
                half2 texcoord : TEXCOORD0;
            };
            struct VertexOutput {
                half4 clipPos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half4 tSpace0 : TEXCOORD2;
                half4 tSpace1 : TEXCOORD3;
                half4 tSpace2 : TEXCOORD4;
            };


            CBUFFER_START(UnityPerMaterial)
             half _Shininess;
             half4 _Color;
             half4 _ReflectColor;
             float _RefStrength;
             half _FrenelPower;
             half _TexAlphaAdd;
             half _Cutoff;
             half4 _NormalMap_ST;
             half4 _IceTex_ST;
            CBUFFER_END
             sampler2D _IceTex;
             sampler2D _NormalMap;


            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0;
                o.uv = v.texcoord;

                half3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                half3 positionVS = TransformWorldToView(positionWS);
                half4 positionCS = TransformWorldToHClip(positionWS);
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.ase_normal, v.ase_tangent);
                o.tSpace0 = half4(normalInput.normalWS, positionWS.x);
                o.tSpace1 = half4(normalInput.tangentWS, positionWS.y);
                o.tSpace2 = half4(normalInput.bitangentWS, positionWS.z);

                o.clipPos = positionCS;

                return o;
            }


            half4 frag(VertexOutput IN) : COLOR {
                half3 WorldNormal = normalize(IN.tSpace0.xyz);
                half3 WorldTangent = IN.tSpace1.xyz;
                half3 WorldBiTangent = IN.tSpace2.xyz;
                half3 WorldPosition = half3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                half3x3 tangentTransform = half3x3(WorldTangent, WorldBiTangent, WorldNormal);
                //----------------------
                half2 uv_NormalMap = IN.uv.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
                half2 uv_IceMap = IN.uv.xy * _IceTex_ST.xy + _IceTex_ST.zw;
                ///
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - WorldPosition);
                half3 Normal = UnpackNormal(tex2D(_NormalMap, uv_NormalMap));
                half3 normalLocal = Normal.rgb;
                half3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals

                half3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                half4 IceColor = tex2D(_IceTex, uv_IceMap);
                clip((IceColor.a+_Cutoff) - 0.5);
                half3 lightDirection = normalize(_MainLightPosition.xyz);
                half3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                half3 attenColor = _MainLightColor.xyz;
///////// Gloss:
                half gloss = IceColor.a;
                half specPow = exp2( gloss * 10.0 + 1.0 );
////// Specular:
                half NdotL = saturate(dot( normalDirection, lightDirection ));
                float3 directSpecular = attenColor * pow(max(0,dot(halfDirection,normalDirection)),specPow) * _Shininess;
                float3 specular = directSpecular;
/////// Diffuse:
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half3 directDiffuse = pow(max( 0.0, NdotL), IceColor.rgb) * attenColor;
                half3 diffuseColor = _Color.rgb;
                half3 diffuse = directDiffuse * diffuseColor;
////// Emissive:
                half3 _Cube_var = half3(1, 1, 1);
                half ddd = lerp(-1, 0, pow(max(0, 1.0 - max(0, dot(normalDirection, viewDirection))), 0.5 * dot(1.0, Normal.rgb) + 0.5));
                half3 ccc = lerp((IceColor.rgb * _Color.rgb), _Cube_var, pow(max(0, _FrenelPower), ddd));
                half3 bbb = ccc  * _RefStrength;
                half3 emissiveTT = (IceColor.rgb + bbb) *_ReflectColor.rgb;
/// Final Color:
                half3 finalColor = diffuse + specular + emissiveTT;
                //return fixed4(lerp(sceneColor.rgb, finalColor,(IceColor.a+_TexAlphaAdd)),1);
                return half4(finalColor, IceColor.a + _TexAlphaAdd);
            }
            ENDHLSL
        }
    }
}
