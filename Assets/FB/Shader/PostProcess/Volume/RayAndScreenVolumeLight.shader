//体积光在管线中区分为两种 第一种：为光追体积光，比较高性能，高配用 第二种：屏幕径向体积光，中配用
//射线步进屏幕空间体积光
//性能消耗比较严重
//适用于高性能设备,全屏体积光
//需要DepthTexture拷贝勾选,需要开启Unity阴影

Shader "FB/PostProcessing/RayAndScreenVolumeLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        
        //光追体积光 比较消耗性能

        Pass //0 光追算法
        {
            Tags { "LightMode" = "Ray Volume Light Pass" }
            ZTest Always 
            ZWrite Off
            Blend One Zero
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile ENABLE_SCREENRAY_CS ENABLE_SCREENRAY_SHADER //像素摄像的计算方式 ENABLE_SCREENRAY_CS:从CS传入矩阵，效率能好一些  ENABLE_SCREENRAY_SHADER:在Shader计算，效率差一些，每个像素都会算矩阵
            #pragma multi_compile _ ENABLE_CREATENOISE_TEX //开启随机噪点
            #pragma multi_compile _ ENABLE_GAUSSIONBLUR //开启高斯模糊
            #pragma multi_compile _ ENABLE_ADDLIGHTRAYLIGHT //开启附加灯光

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 rayDir:TEXCOORD1;//相机到屏幕像素的射线方向
                float3 posWS:TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _RayVolumeLightMainTex;
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            float4x4 _RayVolumeLightArray;//存放了相机空间下屏幕4个点的向量
            float4x4 _RayVolumeLightCamToWorldMatr;//脚本传入 
            int _RayVolumeLightLength;
            float _RayVolumeLightAttenStrength;
            int _RayVolumeLightStepCount;
            float _RayVolumeLightMieScatteringG;
            float _RayVolumeLightExtingction;

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.uv = i.uv;
                o.posWS = TransformObjectToWorld(i.positionOS.xyz);
                #if defined(ENABLE_SCREENRAY_CS)
                    //根据UV计算屏幕4个点向量对应的数组索引
                    int index=(int)dot(o.uv,float2(1,2));
                    o.rayDir= _RayVolumeLightArray[index].xyz;
                    //转换为世界空间，在片元着色器差值获得屏幕像素对应的像素与相机的射线方向
                    o.rayDir = mul(_RayVolumeLightCamToWorldMatr,o.rayDir);
                    i.positionOS.z=0;
                    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                    return o;
                #elif defined(ENABLE_SCREENRAY_SHADER)
                    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                    return o;
                #endif
                
            }

            #define UNITY_PI     3.14159265359f

            //散射算法1
            //Mie Scattering (Henyey-Greenstein phase function)
            //计算颗粒散射衰减
            //lightDir:相机到灯光方向 灯光-相机
            //rayDir:射线方向  像素-相机
            //mieScatteringG:散射衰减系数 0-1 0:各个方向平均衰减 0到0.1范围比较合适
            float MieScatteringFunc(float3 lightDir,float3 rayDir,float mieScatteringG=0.5){
                float g2 = mieScatteringG * mieScatteringG;
                float x = (1 - mieScatteringG) * (1 - mieScatteringG) * 0.25f / UNITY_PI;
                float y = 1 + g2;
                float z = 2 * mieScatteringG;
                //MieScattering. Henyey-Greenstein近似方法
                // (1 - g)^2 / (4 * pi * (1 + g ^2 - 2 * g * cosθ) ^ 1.5 )
                // 变动范围（-1，1） 到 （-1，0）
                //float lightCos = 0.5*dot(lightDir, -rayDir)-0.5;
                float lightCos = dot(-lightDir, -rayDir);
                
                float res = x / pow(abs(y - z * lightCos), 1.5);
                return res;
            }

            //散射算法2
            //Rayleigh Scattering
            float RayleighScattering(float3 lightDir,float3 rayDir){
                float lightCos = dot(-lightDir, -rayDir);
                return (3/(16*UNITY_PI)) * (1+lightCos*lightCos);
            }

            //颗粒吸收
            //stepLength:步长
            //extinction:首次传入0
            //exDensity:灰尘密度 0-1
            float ExtingctionFunc(float stepLength, inout float extinction,float exDensity = 0.2)
            {
                extinction += stepLength * abs(1-exDensity);
                return exp(-extinction);
            }

            #define random(seed) sin(seed * 641.5467987313875 + 1.943856175)

            //_RandomNumber:由脚本传入的随机数 
            //[-1,1]
            float RandScreen(float2 uv, float _RandomNumber){
                float seed = random((_ScreenParams.y * uv.y + uv.x) * _ScreenParams.x + _RandomNumber);
                return seed;
            }

            float GetShadowAtten(float3 curWorldPos){
                float4 shadowCoord = TransformWorldToShadowCoord(curWorldPos);
                float shadowAtten =  SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture,shadowCoord);
                shadowAtten=max(shadowAtten,0);
                return shadowAtten;
            }

            //射线步进计算体积光强度
            //linearDepth:此处的深度
            //rayOriginWS:射线起始点
            //rayDir:射线步进方向   像素-相机
            //rayLength:射线长度 每一米对应rayMarchingStepCount效果比较好
            //rayMarchingStepCount:步进数量
            //lightDirWS:灯光方向  灯光-相机
            //tintColor:灯光颜色
            //attenStrength:灯光强度 >0 0到0.1范围比较合适
            //mieScatteringG:散射衰减系数 0-1 0:各个方向平均衰减 0到0.1范围比较合适
            //exDensity:灰尘密度 0-1
            half4 RayMarching(float linearDepth,float2 uv,float3 rayOriginWS,float3 rayDir, float rayLength,int rayMarchingStepCount,float3 lightDirWS,half3 tintColor,
            half attenStrength=1,float mieScatteringG=0.05,float exDensity = 0.4)
            {
                float stepLength = rayLength / rayMarchingStepCount;
                float3 stepVec = rayDir * stepLength;
                float3 curWorldPos = rayOriginWS.xyz;
                float3 totalAtten = 0;
                float extinction = 0;
                #if defined(ENABLE_CREATENOISE_TEX)
                    //随机噪点
                    float seed = RandScreen(uv, 0.1);
                #endif
                UNITY_LOOP
                for (int i = 0; i < rayMarchingStepCount; ++i)
                {
                    #if defined(ENABLE_CREATENOISE_TEX)
                        seed=random(seed);
                    #endif
                    //计算裁剪
                    float rayLenght = length(curWorldPos.xyz - rayOriginWS.xyz);
                    float clipValue=max(sign(linearDepth-rayLenght),0);
                    if(clipValue<=0){
                        break;
                    }
                    //光源衰减
                    float shadowAtten = GetShadowAtten(curWorldPos);
                    float3 atten=shadowAtten*attenStrength*clipValue;
                    //Mie散射
                    atten *= MieScatteringFunc(normalize(lightDirWS), rayDir,mieScatteringG);
                    //atten *= RayleighScattering(normalize(lightDirWS), rayDir);

                    //传播过程中吸收
                    atten *= ExtingctionFunc(stepLength, extinction,exDensity);//相机距离衰减
                    atten *=atten;//灯光距离衰减
                    totalAtten += atten;
                    curWorldPos +=stepVec;

                    #if defined(ENABLE_CREATENOISE_TEX)
                        //随机噪点
                        curWorldPos=lerp(rayOriginWS,curWorldPos,1+seed*0.3);
                    #endif
                }
                half4 finalColor = half4(totalAtten.xyz, 1);
                tintColor=saturate(tintColor);
                finalColor.rgb=finalColor.rgb*tintColor;
                return finalColor;
            }

            half4 RayMarchingAddLights(uint lightIndex,float linearDepth,float2 uv,float3 rayOriginWS,float3 rayDir, float rayLength,int rayMarchingStepCount,
            half attenStrength=1,float mieScatteringG=0.05,float exDensity = 0.4){
                float stepLength = rayLength / rayMarchingStepCount;
                float3 stepVec = rayDir * stepLength;
                float3 curWorldPos = rayOriginWS.xyz;
                float3 totalAtten = 0;
                float extinction = 0;
                #if defined(ENABLE_CREATENOISE_TEX)
                    //随机噪点
                    float seed = RandScreen(uv, 0.1);
                #endif
                UNITY_LOOP

                Light light = GetAdditionalLight(lightIndex, curWorldPos, half4(1, 1, 1, 1));
                half3 tintColor=light.color;
                float3 lightDirWS=light.direction;
                for (int i = 0; i < rayMarchingStepCount; ++i)
                {
                    #if defined(ENABLE_CREATENOISE_TEX)
                        seed=random(seed);
                    #endif
                    //计算裁剪
                    float rayLenght = length(curWorldPos.xyz - rayOriginWS.xyz);
                    float clipValue=max(sign(linearDepth-rayLenght),0);

                    //光源衰减
                    float3 atten = attenStrength*clipValue*light.distanceAttenuation * light.shadowAttenuation;
                    //Mie散射
                    atten *= MieScatteringFunc(normalize(lightDirWS), rayDir,mieScatteringG);
                    //atten *= RayleighScattering(normalize(lightDirWS), rayDir);

                    //传播过程中吸收
                    atten *= ExtingctionFunc(stepLength, extinction,exDensity);//相机距离衰减
                    atten *=atten;//灯光距离衰减
                    totalAtten += atten;
                    curWorldPos +=stepVec;
                    light = GetAdditionalLight(lightIndex, curWorldPos, half4(1, 1, 1, 1));
                    lightDirWS=light.direction;

                    #if defined(ENABLE_CREATENOISE_TEX)
                        //随机噪点
                        curWorldPos=lerp(rayOriginWS,curWorldPos,1+seed*0.3);
                    #endif
                }
                half4 finalColor = half4(totalAtten.xyz, 1);
                tintColor=saturate(tintColor);
                finalColor.rgb=finalColor.rgb*tintColor;
                return finalColor;
            }

            half4 RayMarchingAddLights(float linearDepth,float2 uv,float3 rayOriginWS,float3 rayDir, float rayLength,int rayMarchingStepCount,
            half attenStrength=1,float mieScatteringG=0.05,float exDensity = 0.4){
                half4 resColor=half4(0,0,0,0);
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    resColor=resColor+RayMarchingAddLights( lightIndex, linearDepth, uv, rayOriginWS, rayDir,  rayLength, rayMarchingStepCount,attenStrength, mieScatteringG,exDensity);
                }
                resColor=clamp(resColor,0,8);
                return resColor;
            }

            //需要放在片元着色器
            //计算屏幕像素的世界空间射线
            //rayOriginWS:射线世界坐标起点
            //rayDirectionWS:射线世界坐标方向
            void GetScreenCameraRay(float2 uv,out float3 rayOriginWS,out float3 rayDirectionWS){
                float2 p=uv.xy*2.0f-1.0f;
                //内置的矩阵unity_CameraToWorld 左右手坐标系需要切换，所以要修改一下,Z轴需要翻转
                //tips：外部传入的_camera.cameraToWorldMatrix就是反的
                float4x4 negativeMat=float4x4(
                1,0,0,0,
                0,1,0,0,
                0,0,-1,0,
                0,0,0,1
                );
                float4x4 n_CameraToWorld=mul(unity_CameraToWorld,negativeMat);
                rayOriginWS=mul(n_CameraToWorld,float4(0.0f,0.0f,0.0f,1.0f)).xyz;//第四维是相机的世界位置
                rayDirectionWS=mul(unity_CameraInvProjection,float4(p.xy,1.0f,1.0f)).xyz;//远切面UV转换为相机空间，是相机空间下的像素射线方向
                rayDirectionWS=mul(n_CameraToWorld,float4(rayDirectionWS,0.0f)).xyz;//像素射线方向转换为世界空间
                rayDirectionWS=normalize(rayDirectionWS);
            }

            float3 ACESToneMapping(float3 color) {
                color = color * 0.8;
                float3 A = 2.51;
                float3 B = 0.03;
                float3 C = 2.43;
                float3 D = 0.59;
                float3 E = 0.14;

                return (color*(A*color+B)) / (color*(C*color+D)+E);
            }

            half4 Frag (Varyings i) : SV_Target
            {

                #if defined(ENABLE_SCREENRAY_CS)
                    float3 camPosWS=_WorldSpaceCameraPos.xyz;
                    //射线方向
                    float3 rayDir=i.rayDir;
                #elif defined(ENABLE_SCREENRAY_SHADER)
                    float3 camPosWS=float3(0,0,0);
                    //射线方向
                    float3 rayDir=float3(0,0,0);
                    //GetScreenCameraRay(i.uv.xy,out camPosWS,out rayDir);
                #endif

                float linearDepth = LinearEyeDepth(SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture, i.uv.xy),_ZBufferParams);

                //射线长度 >1
                //int _RayVolumeLightLength=15;
                //int _RayVolumeLightAttenStrength=4;
                //步进次数 10-40 
                //int _RayVolumeLightStepCount=10;
                //float _RayVolumeLightMieScatteringG=0.05;
                //float _RayVolumeLightExtingction=0.8;
                Light mainLight=GetMainLight();
                half4 res = RayMarching(linearDepth,i.uv.xy,camPosWS,rayDir, _RayVolumeLightLength,_RayVolumeLightStepCount,mainLight.direction,mainLight.color,
                _RayVolumeLightAttenStrength,_RayVolumeLightMieScatteringG,_RayVolumeLightExtingction);

                #if defined(ENABLE_ADDLIGHTRAYLIGHT)
                    res = res+RayMarchingAddLights( linearDepth,i.uv.xy,camPosWS,rayDir,_RayVolumeLightLength,_RayVolumeLightStepCount,_RayVolumeLightAttenStrength,_RayVolumeLightMieScatteringG,_RayVolumeLightExtingction);
                #endif

                //res.rgb=ACESToneMapping(res.rgb);

                #if defined(ENABLE_GAUSSIONBLUR)
                    return res;
                #else
                    half4 mainColor = tex2D(_MainTex, i.uv);
                    mainColor.rgb=mainColor.rgb+res.rgb;
                    return mainColor;
                #endif
            }
            ENDHLSL
        }

        Pass //1 光追高斯模糊
        {
            Tags { "LightMode" = "Gaussion Blur Pass" }
            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex BloomDownSampleVertex
            #pragma fragment BloomDownSampleFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 uv01         : TEXCOORD0;
                float4 uv23         : TEXCOORD1;
                float4 uv45         : TEXCOORD2;
                float4 uv67         : TEXCOORD3;
                float2 uv8         : TEXCOORD4;

            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _TurnBlurTex;
            half _BlurLerp;
            half _RayVolumeLightGaussionBlurSize;

            Varyings BloomDownSampleVertex (Attritubes i)
            {
                Varyings o;
                
                // Position
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //_RayVolumeLightGaussionBlurSize=1;
                float f = _RayVolumeLightGaussionBlurSize;
                // UV
                float2 offset = _MainTex_TexelSize.xy * f;
                o.uv01.xy = i.uv +float2(-offset.x,offset.y);
                o.uv01.zw = i.uv +float2(0,offset.y);
                o.uv23.xy = i.uv +float2(offset.x,offset.y);
                o.uv23.zw = i.uv +float2(-offset.x,0);
                o.uv45.xy = i.uv;
                o.uv45.zw = i.uv +float2(offset.x,0);
                o.uv67.xy = i.uv +float2(-offset.x,-offset.y);
                o.uv67.zw = i.uv +float2(0,-offset.y);
                o.uv8  = i.uv +float2(offset.x,-offset.y);

                return o;
            }

            half4 BloomDownSampleFrag (Varyings i) : SV_Target
            {
                half3 s = 0;
                s += tex2D(_MainTex, i.uv01.xy).rgb;
                s += tex2D(_MainTex, i.uv01.zw).rgb*2;
                s += tex2D(_MainTex, i.uv23.xy).rgb;
                s += tex2D(_MainTex, i.uv23.zw).rgb*2;

                s += tex2D(_MainTex, i.uv45.xy).rgb*4;
                s += tex2D(_MainTex, i.uv45.zw).rgb*2;

                s += tex2D(_MainTex, i.uv67.xy).rgb;
                s += tex2D(_MainTex, i.uv67.zw).rgb*2;

                s += tex2D(_MainTex, i.uv8.xy).rgb;
                //
                return half4(s/16, 1);

            }
            ENDHLSL
        }

        Pass //2 光追结果合成
        {
            Tags { "LightMode" = "Finish Pass" }

            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag

            #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
            
            sampler2D _MainTex;
            sampler2D _RayVolumeLightBlurTexture;

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                half4 color = tex2D(_MainTex, i.uv);
                half4 rayColor = tex2D(_RayVolumeLightBlurTexture, i.uv);
                color.rgb=color.rgb+rayColor.rgb;

                return color;
            }
            ENDHLSL
        }

        //屏幕径向体积光  SunShaft容积光
        Pass //3 容积光取亮
        {
            Tags { "LightMode" = "ScreenDirection GodLight Prefilter" }
            ZTest Always 
            ZWrite Off 
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles

            #pragma vertex SceneEffectVertex
            #pragma fragment SceneEffectFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../PostProcess.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            half _SunShafeLenght;//容积光的屏幕长度范围
            half3 _SunShafeThreshold;//容积光取色
            float _SunShafeDepthThreshold;//容积光深度范围 值越小，范围越广

            struct BloomAttritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BloomVaryings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float2 sunUV : TEXCOORD1;
                half4 screenPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            BloomVaryings SceneEffectVertex (BloomAttritubes i)
            {
                BloomVaryings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.screenPos = ComputeScreenPos(o.positionCS);
                //o.lightUV = RenderPass_WorldToScreenPosition(_MainLightPosition.xyz).xy;
                o.sunUV = RenderPass_WorldToScreenPosition(_MainLightPosition.xyz+_WorldSpaceCameraPos).xy;

                o.uv = UnityStereoTransformScreenSpaceTex(i.uv);
                #if UNITY_UV_STARTS_AT_TOP
                    if (_MainTex_TexelSize.y < 0)
                    {
                        o.uv.y = 1 - o.uv.y;
                    }
                #endif	

                return o;
            }

            half TransformColor(half4 skyboxValue, half3 sunThreshold)
            {
                return dot(max(skyboxValue.rgb - sunThreshold, 0), 1); // threshold and convert to greyscale
            }

            half4 SceneEffectFrag (BloomVaryings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half depthSample = SampleSceneDepth(input.screenPos.xy / input.screenPos.w);
                depthSample = Linear01Depth(depthSample, _ZBufferParams);
                half4 tex = tex2D(_MainTex, input.uv.xy);
                half2 vec = input.sunUV.xy - input.uv.xy;		
                half dist = saturate(_SunShafeLenght - length(vec.xy));	
                half4 outColor = 0;
                float halfPos = _SunShafeDepthThreshold/2.0;
                float st = smoothstep(halfPos, _SunShafeDepthThreshold, depthSample);
                outColor = TransformColor(tex, _SunShafeThreshold.rgb) * dist*st;
                return outColor;
            }
            ENDHLSL
        }

        Pass //4  容积光径向模糊
        {
            Tags { "LightMode" = "ScreenDirection GodLight Blur Pass" }
            ZTest Always 
            ZWrite Off
            BlendOp Add
            Blend One Zero
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../PostProcess.hlsl"

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float2 uvOffset : TEXCOORD1;
                float2 sunUV : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            half2 _SunShafeBlurRadius;
            
            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.sunUV = RenderPass_WorldToScreenPosition(_MainLightPosition.xyz+_WorldSpaceCameraPos).xy;
                o.uv = UnityStereoTransformScreenSpaceTex(i.uv);
                return o;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                i.uvOffset=(i.sunUV.xy - i.uv.xy) * _SunShafeBlurRadius.xy;	
                
                float weight=2;
                float weightStepStart=0.5;
                float weightStep=0.95;
                half4 color = tex2D(_MainTex, i.uv.xy)*2;
                for(int j = 0; j < 6; j++)   
                {	
                    weightStepStart=weightStepStart*weightStep;
                    half4 tmpColor =tex2D(_MainTex, i.uv.xy)*weightStepStart;
                    weight=weight+weightStepStart;
                    color += tmpColor;
                    i.uv.xy += i.uvOffset;	
                }
                return saturate(color / weight);

            }
            ENDHLSL
        }

        Pass //5  容积光最终合成
        {
            Tags { "LightMode" = "Sun Shaft Pass" }

            ZTest Always 
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag

            #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"
            
            sampler2D _MainTex;
            sampler2D _SunShaftBlurTex;
            float4 _MainTex_TexelSize;
            half _SunShaftBlurStrength;

            struct Attritubes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = UnityStereoTransformScreenSpaceTex(i.uv);
                #if UNITY_UV_STARTS_AT_TOP
                    if (_MainTex_TexelSize.y < 0)
                    {
                        o.uv.y = 1 - o.uv.y;
                    }
                #endif	
                return o;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                half4 mainTex = tex2D(_MainTex, i.uv);
                half4 sunShaftBlurTex = tex2D(_SunShaftBlurTex, i.uv);

                mainTex.rgb=mainTex.rgb+sunShaftBlurTex.rgb*_SunShaftBlurStrength;

                return mainTex;
            }
            ENDHLSL
        }

    }
}

