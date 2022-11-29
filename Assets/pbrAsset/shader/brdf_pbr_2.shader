Shader "pbr/pbr with smoothmap" {
// 　　　　　　D(h) F(v,h) G(l,v,h)
//f(l,v) = ---------------------------
// 　　　　　　4(n·l)(n·v)
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RoughnessTex("SpecularMap (RGB)", 2D) = "white" {}
        _NormalTex("NormalMap (RGB)", 2D) = "bump" {}
        _Roughness ("Roughness", Range(0,1)) = 0
        _Metallic("Metallicness",Range(0,1)) = 0
        _F0 ("Fresnel coefficient", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            #define PI 3.14159265359

            sampler2D _MainTex;
            sampler2D _RoughnessTex;
            sampler2D _NormalTex;
            float _Roughness;
            float _Metallic;
            fixed4 _F0;

            struct appdata
            {
                half4 vertex : POSITION;
                half4 color : COLOR;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                float4 tangent	: TANGENT;
            };

            struct VSOut
            {
                half4 pos		: SV_POSITION;
                half4 color     : COLOR;
                half2 uv : TEXCOORD0;
                half3 normalWorld : TEXCOORD1;
                half3 posWorld : TEXCOORD2;
                half3 tangentWorld : TEXCOORD3;
                half3 binormalWorld : TEXCOORD4;
            };

            //F(v,h)公式 cosTheta = v dot h
            half3 fresnelSchlick(float cosTheta, half3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }

            half3 DiffuseLambert(half3 diffuse)
            {
                return diffuse / PI;
            }

            //D(h)GGX公式，计算法线分布
            //alpha = roughness * roughness
            float normalDistribution_GGX(float ndh, float alpha)
            {
                float alphaPow = alpha * alpha;
                float t = ndh * ndh * (alphaPow - 1) + 1;
                return alphaPow / (PI * t * t);
            }

            float BeckmannNormalDistribution(float roughness, float NdotH)
            {
                float roughnessSqr = roughness * roughness;
                float NdotHSqr = NdotH * NdotH;
                return max(0.000001, (1.0 / (3.1415926535 * roughnessSqr * NdotHSqr*NdotHSqr)) * exp((NdotHSqr - 1) / (roughnessSqr*NdotHSqr)));
            }

            //G(l,v,h)
            float smith_schilck(float roughness, float ndv, float ndl)
            {
                float k = (roughness + 1) * (roughness + 1) / 8;
                float Gv = ndv / (ndv * (1 - k) + k);
                float Gl = ndl / (ndl * (1 - k) + k);
                return Gv * Gl;
            }

            half3 brdf(half3 fresnel, float D, float G, float ndv, float ndl)
            {
                return fresnel * D * G / (4 * ndv * ndl + 0.0001);
            }

            VSOut vert(appdata v)
            {
                VSOut o;
                o.color = v.color;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normalWorld = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
                o.binormalWorld = cross(normalize(o.normalWorld), normalize(o.tangentWorld.xyz)) * v.tangent.w;
                return o;
            }


            half4 frag(VSOut i) : COLOR
            {
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

                fixed3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
                float3x3 mTangentToWorld = transpose(float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld));
                fixed3 normalDirection = normalize(mul(mTangentToWorld, tangentNormal));  //法线贴图的世界坐标
                //fixed3 normalDirection = normalize(i.normalWorld); //UnpackNormal(tex2D(_NormalTex, i.uv));
                //微表面法线
                fixed3 h = normalize(lightDirection + viewDirection);

                fixed3 attenColor = _LightColor0.xyz;
                

                float NdL = max(dot(normalDirection, lightDirection), 0);
                float NdV = max(dot(normalDirection, viewDirection), 0);
                float VdH = max(dot(viewDirection, h), 0);
                float NdH = max(dot(normalDirection, h), 0);
                float LdH = max(dot(lightDirection, h), 0);

                
                fixed4 albedo = i.color * tex2D(_MainTex, i.uv);
                fixed4 ctrlMap = tex2D(_RoughnessTex, i.uv);
                float specularFactor = (1 - ctrlMap.r);
                _Metallic *= ctrlMap.g;
                fixed3 lambert = max(0.0, dot(normalDirection, lightDirection)) * attenColor;
                fixed3 totalLightColor = UNITY_LIGHTMODEL_AMBIENT.xyz + attenColor;
                fixed3 diffuseLambert = max(0, (totalLightColor - UNITY_LIGHTMODEL_AMBIENT.xyz) * lambert + UNITY_LIGHTMODEL_AMBIENT.xyz);
                //fixed3 diffuseLambert = lambert * attenColor;
                fixed3 directDiffuse = diffuseLambert * albedo.rgb * (1.0 - _Metallic);
                fixed3 specularColor = lerp(diffuseLambert * albedo.rgb, _F0.rgb, _Metallic);
                
                half3 fresnel = fresnelSchlick(VdH, specularColor.rgb);
                float D = BeckmannNormalDistribution(_Roughness, NdH);
                float G = smith_schilck(_Roughness, NdV, NdH);
                fixed3 specular = brdf(fresnel, D, G, NdV, NdL); // *_LightColor0.xyz;
                fixed4 DF;
                DF.rgb = directDiffuse + NdL * specular * specularFactor;

                DF.a = 1.0f;
                return DF;
            }
            ENDCG
        }
	}
}