Shader "FB/Charactor/SGameLaser"  
{
    Properties{
        _BaseColor("颜色", Color) = (1.0,1.0,1.0,1.0)
        _MainTexture("颜色贴图",2D) = "white"{}
        [normal]_NormalTex("法线贴图",2D) = "bump"{}
        _AOSmoothTex("PBR Mask",2D) = "white"{}
        _AOIntensity("AO 强度", Range(0,1)) = 1
        _LaserRampMap("镭射Ramp图", 2D) = "Black"{}
        _LaserTilling("镭射Tilling",Range(0.5, 3)) = 1
        _LaserIntensity("镭射强度", Range(0, 10)) = 1
       
    
        _LaserRampID("镭射ID", Range(0, 1)) = 1
        _LaserAngle("镭射角度", Range(0, 1)) = 1
        [Header(______________________________SPECULAR__________________________________)]
        [Space(10)]
        _SpecularLaserInt("高光镭射", Range(0,1)) = 0
        _SpecularAngle("高光角度", Range(0, 1)) = 1
        _SpecularWidth("高光范围", Range(1, 10)) = 3
        [Header(______________________________LASER_TINT__________________________________)]
        [Space(10)]
        _LaserColor("镭射染色颜色", Color) = (1.0,1.0,1.0,1.0)
        _TintIntensity("镭射染色强度", Range(0,1)) = 0.2
        
    }
    SubShader
    {
        Tags{
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"="Opaque"
        }
        pass
        {

            cull off 

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
      
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOW_SOFT

            sampler2D _ShiftTex;
            sampler2D _MainTexture;
            sampler2D _NormalTex;
            sampler2D _AOSmoothTex;
            sampler2D _LaserRampMap;
    
            sampler2D _LaserOffsetMask;

            CBUFFER_START(UnityPerMaterial) 

            half4 _BaseColor;
            half4 _LaserColor;
            half _TintIntensity;  
            half _LaserIntensity;
            float _LaserRampID;
            float _LaserTilling;
            float _LaserAngle;
            half _SpecularWidth;
            float _SpecularAngle;
            float _SpecularLaserInt;
            float _AOIntensity;

            CBUFFER_END

            struct a2v
            {
                float4 vertex:POSITION;
                float2 uv0 :TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
 
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv0: TEXCOORD0;
                float3 posWS: TEXCOORD1;
                float3 nDirWS: TEXCOORD2;
                float3 tDirWS: TEXCOORD3;
                float3 bDirWS: TEXCOORD4;
             
                
            };

            half HairSpecular(float3 hDirWS, float3 nDirWS,  half specularWidth){
                
                half hdotn = saturate(abs(dot(hDirWS, nDirWS)));
                half sinTH = sqrt(1- pow(hdotn,2));
                
                half dirAtten = smoothstep(-1, 0, hdotn);
                half specular =  dirAtten * saturate(pow(sinTH, specularWidth));
                specular = max(0, specular);
                
                return (specular);
            }

            half remap(half x, half t1, half t2, half s1, half s2)
            {
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            v2f vert(a2v i)
            {
                v2f o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.posWS = TransformObjectToWorld(i.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(i.normal);
                o.tDirWS = TransformObjectToWorldDir(i.tangent);
                o.bDirWS = normalize(cross(o.tDirWS, o.nDirWS) * i.tangent.w * unity_WorldTransformParams.w);
                o.uv0 = i.uv0;
               
                return o;
            }

            half4 frag(v2f i):SV_TARGET
            {
                // Vectors
                Light mainLight = GetMainLight();
                float shadow = mainLight.shadowAttenuation;
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirTS = UnpackNormal(tex2D(_NormalTex, i.uv0));
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 lDirWS = normalize(mainLight.direction);
                float3 vDirWS = normalize(i.posWS - _WorldSpaceCameraPos.xyz);
                float3 hDirWS = normalize(-vDirWS + lDirWS);
                half3 lightColor = mainLight.color;

                half ndotl = dot(lDirWS, nDirWS);
                half ndotv = max(0, dot(nDirWS, -vDirWS));
                half ndoth = max(0, dot(nDirWS, hDirWS));

                float3 bDirWS =  cross(i.tDirWS, nDirWS);

                float2 var_AOSmoothTex = tex2D(_AOSmoothTex, i.uv0).gb; 
                float smoothness = var_AOSmoothTex.y;
                float occlusion = lerp(1, var_AOSmoothTex.x, _AOIntensity);
              

                half BlinnPhong = pow(ndoth, smoothness * 52) ;
                
                half Aspec = HairSpecular(hDirWS, lerp(bDirWS ,i.tDirWS,_SpecularAngle), _SpecularWidth * _SpecularWidth * smoothness);
                
                // Ramp Laser
                half LaserIntensity =  _LaserIntensity ;
                float2 laserSampleUV =  float2((dot(lerp(bDirWS, i.tDirWS, _LaserAngle ), vDirWS)) * _LaserTilling, _LaserRampID);
                half3 laserColor = lerp(tex2D(_LaserRampMap, laserSampleUV) , _LaserColor, _TintIntensity * 0.9);
                laserColor *= LaserIntensity * lerp(1, Aspec, _SpecularLaserInt) * (1 - pow(1 - ndotv, 1) * 0.7);
                laserColor *= occlusion;
                

                // Mix Diffuse
                half3 var_MainTexture = tex2D(_MainTexture, i.uv0) * _BaseColor;
                half3 color = var_MainTexture * clamp( ndotl * (0.9 - LaserIntensity * 0.0), LaserIntensity * 0.2 + 0.1 ,1); 
                color += laserColor;//* max(ndotv * 0.8 + 0.2, 0.2) * ((ndotl * 0.5 + 0.5) ) * lightColor  * (3 * LaserIntensity) * max(BlinnPhong + Aspec, 0.0) ;

                // Add Specular
                color += ( saturate(BlinnPhong * 0.2 + Aspec * 0.2) * lerp(lightColor, var_MainTexture, saturate(  LaserIntensity * 2)) ) *( LaserIntensity );
              
                // Return
                return half4(color * shadow, 1);
            }
            ENDHLSL
        }
        UsePass "FB/Standard/SGamePBR/ShadowBeforePost"
        UsePass "FB/Standard/SGamePBR/DepthOnly"
        UsePass "FB/Standard/SGamePBR/ShadowCaster"
    }
}