

Shader "FB/PostProcessing/RayVolumeCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass 
        {
            Tags { "LightMode" = "Ray Volume Cloud Pass A" }
            ZTest Always 
            ZWrite Off
            //Blend One Zero
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Frag
            #pragma multi_compile _ VOLUMECLOUD_USE_EARTH
            #pragma multi_compile DISTINGUISH_OFF DISTINGUISH_2X2 DISTINGUISH_4X4

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
                float3 posWS:TEXCOORD1;
            };

            
            #define Earth_Radius 6371000
            #define UNITY_PI     3.14159265359f

            int _DistinguishWidth;
            int _DistinguishHeight;
            int _DistinguishIndex;

            sampler2D _VolumeCloudWeatherAndSpeedMap;
            float _VolumeCloudWeatherAndSpeedMapScale;
            sampler2D _VolumeCloudBlueNoiseMap;
            float4 _VolumeCloudBlueNoiseCoords;
            float _VolumeCloudBlueNoiseTexScale;
            sampler3D _VolumeCloudNoise3DTex;
            sampler3D _VolumeCloudDetailNoise3DTex;
            sampler2D _MainTex;
            sampler2D _RayVolumeLightMainTex;
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D_X_FLOAT(_VolumeDepthTexture);
            SAMPLER(sampler_VolumeDepthTexture);

            float4x4 _VolumeInverseProjectionMatrix;
            float4x4 _VolumeCameraToWorldMatrix;
            int _RayVolumeCloudCubeCount;
            float4x4 _RayVolumeCloudCubeWorldToLocal[8];
            float4x4 _RayVolumeCloudCubeLocalToWorld[8];
            float4 _RayVolumeCloudCubeMin[8];
            float4 _RayVolumeCloudCubeMax[8];
            float4 _RayVolumeCloudCubeScale[8];
            int _RayVolumeCloudSphereCount;
            float4 _RayVolumeCloudSphereCenter[8];
            float _RayVolumeCloudSphereRadius[8]; 
            float4 _ColliderWindInfo[8];
            float4 _WeatherSetData[8];
            float2 _WeatherCloudSetData[8];
            float3 _StratusCloudRangeData[8];
            float3 _CumulusCloudRangeData[8];
            sampler2D _WeatherMapDatas0;
            sampler2D _WeatherMapDatas1;
            sampler2D _WeatherMapDatas2;
            sampler2D _WeatherMapDatas3;
            sampler2D _WeatherMapDatas4;
            sampler2D _WeatherMapDatas5;
            sampler2D _WeatherMapDatas6;
            sampler2D _WeatherMapDatas7;
            float4 _CloudWindSetData[8];
            float4 _ShapeNoiseWeights[8];
            float4 _FBMSetDatas[8];
            float4 _CloudUVscale[8];
            float4 _CloudBaseFBMs[8];
            float4 _CloudDetailFBMs[8];
            float _CloudGBA[8];
            float4 _CloudMaxIterationAndStep[8];
            float4 _CloudLightData[8];
            float4 _CloudColorDatas[8];
            float4 _CloudColorDarkDatas[8];
            float4 _CloudColorCentralDatas[8];
            float4 _CloudColorBrightDatas[8];
            float4 _VolumeCloudPhaseParamsDatas[8];
            float _VolumeCloudPhaseBaseDatas[8];
            float _VolumeCloudPhaseWeightDatas[8];
            int _VolumeCloudMaxIteration;
            float _VolumeCloudStepCountPerMeter;
            float4 _VolumeCloudPhaseParams;
            float _VolumeCloudRayAbsorptionScale;
            float _VolumeCloudLightAbsorptionScale;
            float _VolumeCloudDetailWeights;
            float _VolumeCloudDensityMultiplier;
            float _VolumeCloudLightStrength;
            float _VolumeCloudLightmarchLerp;
            float _CloudColorCentralOffset;
            float _CloudDarknessThreshold;
            float4 _CloudColorDark;
            float4 _CloudColorCentral;
            float4 _CloudColorBright;
            float3 _VolumeCloudBaseFBM;
            float3 _VolumeCloudDetailFBM;
            float  _BaseShapeDetailEffect;
            float  _BaseShapeDetailEffectEdge;
            float  _CircleBaseShapeTiling;
            float  _CircleDetailTiling;
            float _DensityDifferenceValue;
            float _ThicknessDifferenceValue;
            float3 _StratusCloudRange;
            float3 _CumulusCloudRange;
            float _WeatherWindSpeed;
            float _CloudAbsorbAdjust;
            float4 _VolumeCloudWindInfo;
            float _VolumeCloudPhaseBase;
            float _VolumeCloudPhaseWeight;

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.uv = i.uv;
                o.posWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

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

            float RayleighScattering(float3 lightDir,float3 rayDir){
                float lightCos = dot(-lightDir, -rayDir);
                return (3/(16*UNITY_PI)) * (1+lightCos*lightCos);
            }

            float ExtingctionFunc(float stepLength, inout float extinction,float exDensity = 0.2)
            {
	            extinction += stepLength * abs(1-exDensity);
	            return exp(-extinction);
            }

            float GetShadowAtten(float3 curWorldPos){
                float4 shadowCoord = TransformWorldToShadowCoord(curWorldPos);
                float shadowAtten =  SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture,shadowCoord);
                shadowAtten=max(shadowAtten,0);
                return shadowAtten;
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

            int GetIndex2x2(float2 uv, int width, int height)
            {
                int FrameOrder_2x2[] = {
                    0, 2, 3, 1
                };
                int x = floor(uv.x * width / 8) % 2;
                int y = floor(uv.y * height / 8) % 2;
                int index = x + y * 2;
                index = FrameOrder_2x2[index];
                return index;
            }

            int GetIndex4x4(float2 uv, int width, int height)
            {
                int FrameOrder_4x4[] = {
                    0, 8, 2, 10,
                    12, 4, 14, 6,
                    3, 11, 1, 9,
                    15, 7, 13, 5
                };
                int x = floor(uv.x * width / 8) % 4;
                int y = floor(uv.y * height / 8) % 4;
                int index = x + y * 4;
                index = FrameOrder_4x4[index];
                return index;
            }

            float4 GetWorldSpacePosition(float depth, float2 uv)
            {
                 float4 view_vector = mul(_VolumeInverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                 view_vector.xyz /= view_vector.w;
                 float4 world_vector = mul(_VolumeCameraToWorldMatrix, float4(view_vector.xyz, 1));
                 return world_vector;
             }

            float2 RayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRaydir) 
            {
                float3 t0 = (boundsMin - rayOrigin) * invRaydir;
                float3 t1 = (boundsMax - rayOrigin) * invRaydir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z); //进入点
                float dstB = min(tmax.x, min(tmax.y, tmax.z)); //出去点

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float2 RaySphereDst(float3 sphereCenter, float sphereRadius, float3 pos, float3 rayDir)
            {
                float3 oc = pos - sphereCenter;
                float b = dot(rayDir, oc);
                float c = dot(oc, oc) - sphereRadius * sphereRadius;
                float t = b * b - c;//t > 0有两个交点, = 0 相切， < 0 不相交
    
                float delta = sqrt(max(t, 0));
                float dstToSphere = max(-b - delta, 0);
                float dstInSphere = max(-b + delta - dstToSphere, 0);
                return float2(dstToSphere, dstInSphere);
            }

            float2 RayCloudLayerDst(float3 sphereCenter, float earthRadius, float heightMin, float heightMax, float3 pos, float3 rayDir)
            {
                float2 cloudDstMin = RaySphereDst(sphereCenter, heightMin + earthRadius, pos, rayDir);
                float2 cloudDstMax = RaySphereDst(sphereCenter, heightMax + earthRadius, pos, rayDir);
    
                //射线到云层的最近距离
                float dstToCloudLayer = 0;
                //射线穿过云层的距离
                float dstInCloudLayer = 0;

                float dis=distance(pos,sphereCenter);
                if (dis <= (earthRadius+heightMin))
                {
                    float3 startPos = pos + rayDir * cloudDstMin.y;
                    dstToCloudLayer = cloudDstMin.y;
                    dstInCloudLayer = cloudDstMax.y - cloudDstMin.y;
                    return float2(dstToCloudLayer, dstInCloudLayer);
                }
        
                //在云层内
                if (dis > (earthRadius+heightMin) && dis <= (earthRadius+heightMax))
                {
                    dstToCloudLayer = 0;
                    dstInCloudLayer = cloudDstMin.y > 0 ? cloudDstMin.x: cloudDstMax.y;
                    return float2(dstToCloudLayer, dstInCloudLayer);
                }
        
                //在云层外
                dstToCloudLayer = cloudDstMax.x;
                dstInCloudLayer = cloudDstMin.y > 0 ? cloudDstMin.x - dstToCloudLayer: cloudDstMax.y;
    
                return float2(dstToCloudLayer, dstInCloudLayer);
            }

            //void ToCirclePos(float earthSizeScale, float3 posWS,float3 rayDirWS,out float3 circlePos, out float3 rayDirWSToCircle){
            //    float earthRadius=Earth_Radius*earthSizeScale+posWS.y;
            //    float radius = abs(earthRadius);

            //    //float4x4 transMtra={
            //    //    1,0,0,0,
            //    //    0,1,0,radius,
            //    //    0,0,1,0,
            //    //    0,0,0,1
            //    //};

            //    //circlePos.z=radius;
            //    float circlePerimeter=2.0*UNITY_PI*radius;
            //    float disWS = length(float2(posWS.x,posWS.z));
            //    float remainder =frac(disWS/circlePerimeter);
            //    float radian = lerp(0.0,radians(360.0),remainder);
            //    float cosValue=cos(radian);
            //    float sinValue=sin(radian);

            //    float3x3 rotatesMtra={
            //        cosValue,-sinValue,0,
            //        sinValue,cosValue,0,
            //        0,0,1
            //    };
            //    posWS.xz=float2(0,0);
            //    posWS.y=radius;
            //    circlePos=mul(rotatesMtra,posWS.xyz);
            //    circlePos.z=radius;
                
            //    rayDirWSToCircle = normalize(rayDirWS);
            //    rayDirWSToCircle=mul(rotatesMtra,rayDirWSToCircle);



            //    //circlePos.y=cos(radian)*radius;
            //    //circlePos.x=sqrt(radius*radius-circlePos.y*circlePos.y);
            //    //float xPar = step(0.5,remainder);
            //    //circlePos.x = lerp(circlePos.x,-circlePos.x,xPar);

            //    //rayDirWS = normalize(rayDirWS);
            //    //float angRay=asin(rayDirWS.y);

            //    //return circlePos;
            //}

            //float3 GetCircle3DUV(float earthSizeScale,float3 circlePos){
            //    float3 normalizePos =  normalize(circlePos);

            //    //
            //    float dotY = dot(normalizePos,float3(0.0,1.0,0.0));
            //    float ang=acos(dotY);
            //    float uv3d_X = ang/UNITY_PI;

            //    //
            //    float dotX = dot(normalizePos,float3(1.0,0.0,0.0));
            //    ang=acos(dotX);
            //    float uv3d_Z = ang/UNITY_PI;

            //    //
            //    float earthRadius=Earth_Radius*earthSizeScale;
            //    float circlePerimeter=2.0*UNITY_PI*earthRadius;
            //    float disY =abs(length(circlePos)-earthRadius);
            //    float uv3d_Y = 2.0*(disY/circlePerimeter);

            //    return float3(uv3d_X,uv3d_Y,uv3d_Z);
            //}

            //float2 GetCircle2DUV(float earthSizeScale,float3 circlePos){
            //    float3 uv3d = GetCircle3DUV( earthSizeScale, circlePos);
            //    return  float2(uv3d.x,uv3d.z);
            //}

            //float2 RayCloudLayerDst(float earthSizeScale,float cloudHeightMin,float cloudHeightMax,float3 posWS,float3 rayDirWS,out float3 startPos,out float3 endPos, out float3 rayDirWSToCircle){
            //    float3 circlePos;
            //    ToCirclePos(earthSizeScale,posWS,rayDirWS,circlePos, rayDirWSToCircle);

            //    float earthRadius=Earth_Radius*earthSizeScale;
            //    float3 pos=float3(circlePos.x,circlePos.y,0);
            //    float minHeight=cloudHeightMin + earthRadius;
            //    float maxHeight=cloudHeightMax + earthRadius;
            //    float2 cloudDstMin = RaySphereDst(float3(0,0,0), minHeight, pos, rayDirWSToCircle);
            //    float2 cloudDstMax = RaySphereDst(float3(0,0,0), maxHeight, pos, rayDirWSToCircle);

            //    float dstToCloudLayer = 0;
            //    float dstInCloudLayer = 0;
                
            //    if( circlePos.z<= minHeight){
            //        //在地表上
            //        startPos = pos + rayDirWSToCircle * cloudDstMin.y;
            //        dstToCloudLayer = cloudDstMin.y;
            //        dstInCloudLayer = cloudDstMax.y - cloudDstMin.y;
            //        endPos=startPos+rayDirWSToCircle*dstInCloudLayer;
            //        return float2(dstToCloudLayer,dstInCloudLayer);
            //    }

            //    if(circlePos.z>minHeight && circlePos.z<=maxHeight){
            //        startPos=pos;
            //        dstToCloudLayer = 0;
            //        dstInCloudLayer = cloudDstMin.y > 0 ? cloudDstMin.x: cloudDstMax.y;
            //        endPos=startPos+rayDirWSToCircle*dstInCloudLayer;
            //        return float2(dstToCloudLayer,dstInCloudLayer);
            //    }

            //    startPos = pos + rayDirWSToCircle * cloudDstMax.x;
            //    dstToCloudLayer = cloudDstMax.x;
            //    dstInCloudLayer = cloudDstMin.y > 0 ? cloudDstMin.x - dstToCloudLayer: cloudDstMax.y;
            //    endPos=startPos+rayDirWSToCircle*dstInCloudLayer;
            //    return float2(dstToCloudLayer,dstInCloudLayer);
            //}

            float3 PointToLineTarget(float3 pointInput, float3 linePoint1, float3 linePoint2)
            {
                float3 dir2ToPoint= pointInput-linePoint2;
                float3 dir1To2 = normalize(linePoint2-linePoint1);
                float dotValue=dot(dir2ToPoint,dir1To2);
                return linePoint2+dir1To2*dotValue;
            }

            float remap(float original_value, float original_min, float original_max, float new_min, float new_max)
            {
                return new_min + (((original_value - original_min) / (original_max - original_min)) * (new_max - new_min));
            }

            struct WeatherData
            {
                float density;
                float absorptivity;
                float offsetmask;
            };

            float Interpolation3(float value1, float value2, float value3, float x, float offset = 0.5)
            {
                offset = clamp(offset, 0.0001, 0.9999);
                return lerp(lerp(value1, value2, min(x, offset) / offset), value3, max(0, x - offset) / (1.0 - offset));
            }

            float3 Interpolation3(float3 value1, float3 value2, float3 value3, float x, float offset = 0.5)
            {
                offset = clamp(offset, 0.0001, 0.9999);
                return lerp(lerp(value1, value2, min(x, offset) / offset), value3, max(0, x - offset) / (1.0 - offset));
            }

            float GetCloudTypeDensity(float heightFraction, float cloud_min, float cloud_max, float feather)
            {
                return saturate(remap(heightFraction, cloud_min, cloud_min + feather * 0.5, 0, 1)) * saturate(remap(heightFraction, cloud_max - feather, cloud_max, 1, 0));
            }

            float BeerPowder(float density, float absorptivity = 1)
            {
                return 2.0 * exp(-density * absorptivity) * (1.0 - exp(-2.0 * density));
            }

            WeatherData GetGetWeatherData(sampler2D volumeCloudWeatherAndSpeedMap,  float3 stratusCloudRange,float3 cumulusCloudRange,float densityDifferenceValue, float thicknessDifferenceValue, float cloudAbsorbAdjust, float weatherWindSpeed, float3 windOffset,float2 uv2D,float heightPercent,float edgeWeight=1.0){
                WeatherData res;
                half4 weatherMap = tex2Dlod(volumeCloudWeatherAndSpeedMap, float4(uv2D+windOffset.xz*weatherWindSpeed,0,0));
                weatherMap.r = Interpolation3(0, weatherMap.r, 1, densityDifferenceValue);
                weatherMap.b = Interpolation3(0, weatherMap.b, 1, thicknessDifferenceValue);
                if (weatherMap.r <= 0)
                {
                    res.density = 0;
                    res.absorptivity = 1;
                    res.offsetmask = weatherMap.a;
                    return res;
                }

                //float gMin = remap(weatherMap.x, 0, 1, _VolumeCloudThicknessLow, _VolumeCloudThicknessMid);
                //float gMax = remap(weatherMap.x, 0, 1, gMin, _VolumeCloudThicknessHigh);
                //float heightGradient = saturate(remap(heightPercent, 0.0, gMin, 0, _VolumeCloudThicknessStrength)) * saturate(remap(heightPercent, 1, gMax, 0, _VolumeCloudThicknessStrength));
                //float heightGradient2 = saturate(remap(heightPercent, 0.0, weatherMap.r, _VolumeCloudThicknessStrength, 0)) * saturate(remap(heightPercent, 0.0, gMin, 0, _VolumeCloudThicknessStrength));
                //heightGradient = saturate(lerp(heightGradient, heightGradient2,_VolumeCloudThicknessBlendStrength));
                //heightGradient=heightGradient*edgeWeight;
                //res.density=heightGradient;
                //res.absorptivity=1;
                //res.offsetmask = weatherMap.a;

                //层云 与 积云 分布
                float stratusDensity = GetCloudTypeDensity(heightPercent, stratusCloudRange.x, stratusCloudRange.y, stratusCloudRange.z);//层云
                float cumulusDensity = GetCloudTypeDensity(heightPercent, cumulusCloudRange.x, cumulusCloudRange.y, cumulusCloudRange.z);//积云
                float cloudTypeDensity = lerp(stratusDensity, cumulusDensity, weatherMap.b);
                if (cloudTypeDensity <= 0)
                {
                    res.density = 0;
                    res.absorptivity = 1;
                    res.offsetmask = weatherMap.a;
                    return res;
                }

                //云吸收率
                float cloudAbsorptivity = Interpolation3(0, weatherMap.g, 1, cloudAbsorbAdjust);

                res.density=weatherMap.r*cloudTypeDensity;
                res.absorptivity=cloudAbsorptivity;
                res.offsetmask = weatherMap.a;
                return res;
            }

            WeatherData GetWeatherHeightGradient(int cubeIndex,float3 windOffset,float3 posLocalScale,float3 boxMinLocalScale,float3 boxMaxLocalScale){
                WeatherData res;
                float4 weatherSetData=_WeatherSetData[cubeIndex];
                float2 weatherCloudSetData=_WeatherCloudSetData[cubeIndex];
                float3 stratusCloudRange=_StratusCloudRangeData[cubeIndex];
                float3 cumulusCloudRange=_CumulusCloudRangeData[cubeIndex];

                const float containerEdgeFadeDst = 10;
                float dstFromEdgeX = min(containerEdgeFadeDst, min(posLocalScale.x - boxMinLocalScale.x, boxMaxLocalScale.x - posLocalScale.x));
                float dstFromEdgeZ = min(containerEdgeFadeDst, min(posLocalScale.z - boxMinLocalScale.z, boxMaxLocalScale.z - posLocalScale.z));
                float edgeWeight = min(dstFromEdgeZ, dstFromEdgeX) / containerEdgeFadeDst;
                float3 boxSize = boxMaxLocalScale - boxMinLocalScale;
                float heightPercent = (posLocalScale.y - boxMinLocalScale.y) / boxSize.y;
                float2 uv2D = posLocalScale.xz * (1.0/weatherSetData.x)* 0.0001;

                if(cubeIndex==0){
                    res = GetGetWeatherData(_WeatherMapDatas0,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==1){
                    res = GetGetWeatherData(_WeatherMapDatas1,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==2){
                    res = GetGetWeatherData(_WeatherMapDatas2,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==3){
                    res = GetGetWeatherData(_WeatherMapDatas3,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==4){
                    res = GetGetWeatherData(_WeatherMapDatas4,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==5){
                    res = GetGetWeatherData(_WeatherMapDatas5,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==6){
                    res = GetGetWeatherData(_WeatherMapDatas6,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                if(cubeIndex==7){
                    res = GetGetWeatherData(_WeatherMapDatas7,stratusCloudRange,cumulusCloudRange,weatherCloudSetData.x,weatherCloudSetData.y,  weatherSetData.z,weatherSetData.y,windOffset, uv2D, heightPercent, edgeWeight);
                }
                return res;
            }

            WeatherData SampleDensityCube(int cubeIndex,WeatherData data,float heightGradient,float3 windOffset,float3 pos) 
            {
                float cloudGBA = _CloudGBA[cubeIndex];
                float4 cloudUVscale = _CloudUVscale[cubeIndex];
                float volumeCloudNoise3DTexScale = cloudUVscale.x;
                float volumeCloudDetailNoise3DTexScale = cloudUVscale.y;
                float4 cloudWindSetData=_CloudWindSetData[cubeIndex];

                if(cloudGBA==0){
                    //Mask
                    float3 uvwShape  = pos*volumeCloudNoise3DTexScale + windOffset*cloudWindSetData.x+(data.offsetmask * cloudWindSetData.z);
                    float4 shapeNoise = tex3Dlod(_VolumeCloudNoise3DTex, float4(uvwShape, 0));


                    float3 uvwDetail = pos * volumeCloudDetailNoise3DTexScale + windOffset*cloudWindSetData.y+ float3(0,(shapeNoise.r * cloudWindSetData.w * 0.1),0);
                    float4 detailNoise = tex3Dlod(_VolumeCloudDetailNoise3DTex, float4(uvwDetail, 0));

                    float4 fbmSetDatas = _FBMSetDatas[cubeIndex];
                    float volumeCloudDetailWeights = fbmSetDatas.x;
                    float volumeCloudFBMOffset = fbmSetDatas.y;
                    float volumeCloudDensityMultiplier = fbmSetDatas.z;
                    float volumeCloudDetailNoiseWeight = fbmSetDatas.w;

                    float4 normalizedShapeWeights= _ShapeNoiseWeights[cubeIndex]*10;
                    float shapeFBM = dot(shapeNoise, normalizedShapeWeights) * heightGradient;
                    float baseShapeDensity=shapeFBM-volumeCloudFBMOffset;
                    if (baseShapeDensity > 0)
                    {
                        float detailFBM = pow(detailNoise.r, volumeCloudDetailWeights);
                        float oneMinusShape = 1 - baseShapeDensity;
                        float detailErodeWeight = oneMinusShape * oneMinusShape * oneMinusShape;
                        float cloudDensity = baseShapeDensity - detailFBM * detailErodeWeight * volumeCloudDetailNoiseWeight;
   
                        data.density = saturate(cloudDensity * volumeCloudDensityMultiplier)*data.absorptivity;
                        return data;
                    }

                   data.density = 0;
                   return data;
                    
                }else{

                    //Mask
                    float3 uvwShape  = pos*volumeCloudNoise3DTexScale + windOffset*cloudWindSetData.x+(data.offsetmask * cloudWindSetData.z);
                    float4 shapeNoise = tex3Dlod(_VolumeCloudNoise3DTex, float4(uvwShape, 0));

                    float3 uvwDetail = pos * volumeCloudDetailNoise3DTexScale + windOffset*cloudWindSetData.y+ float3(0,(shapeNoise.r * cloudWindSetData.w * 0.1),0);
                    float4 detailNoise = tex3Dlod(_VolumeCloudDetailNoise3DTex, float4(uvwDetail, 0));

                    float4 fbmSetDatas = _FBMSetDatas[cubeIndex];
                    float volumeCloudDensityMultiplier = fbmSetDatas.z;

                    float3 volumeCloudBaseFBM = _CloudBaseFBMs[cubeIndex].xyz;
                    //构建基础纹理的FBM
                    float baseTexFBM = dot(shapeNoise.gba, volumeCloudBaseFBM);

                    //主体 GBA 布朗分布 衰减
                    float baseShape = remap(shapeNoise.r, saturate((1.0 - baseTexFBM) * _BaseShapeDetailEffect), 1.0, 0, 1.0);
                    float cloudDensity = baseShape * data.density;

                    if (cloudDensity > 0){

                   float3 volumeCloudDetailFBM =  _CloudDetailFBMs[cubeIndex].xyz;
                        float detailTexFBM = dot(detailNoise.rgb, volumeCloudDetailFBM);

                        //细节高度变化
                        float detailNoise = lerp(detailTexFBM, 1.0 - detailTexFBM,saturate(heightGradient * 1.0));
                        //通过使用remap映射细节噪声，可以保留基本形状，在边缘进行变化
                        cloudDensity = remap(cloudDensity, detailNoise * _BaseShapeDetailEffectEdge, 1.0, 0.0, 1.0);
                    }
                    data.density = cloudDensity * volumeCloudDensityMultiplier;
                    return data;

                }
            }

            WeatherData SampleDensityCubeCircle(WeatherData data,float heightGradient,float3 windOffset,float3 pos) 
            {

                //采样基础纹理
                float baseShapeTiling=_CircleBaseShapeTiling* 0.0001;
                float4 shapeNoise = tex3Dlod(_VolumeCloudNoise3DTex, float4(pos*baseShapeTiling+windOffset*1+data.offsetmask*0.3, 0));

                //构建基础纹理的FBM
                float shapeNoiseFBM =saturate(dot(shapeNoise.gba, _VolumeCloudBaseFBM));

                //主体 GBA 布朗 衰减
                float shapeNoiseRPow = pow(shapeNoise.r, _VolumeCloudDetailWeights);
                float baseShape = remap(shapeNoiseRPow, saturate((1.0 - shapeNoiseFBM) * _BaseShapeDetailEffect), 1.0, 0, 1.0);
                float cloudDensity = baseShape * data.density;

                if (cloudDensity > 0){

                    float detailShapeTiling=_CircleDetailTiling* 0.0001;
                    float3 detailTex = tex3Dlod(_VolumeCloudDetailNoise3DTex, float4(pos*detailShapeTiling+windOffset*2+shapeNoise.r*0.1, 0)).rgb;
                    float detailTexFBM = saturate(dot(detailTex, _VolumeCloudDetailFBM));

                    //细节高度变化
                    float detailNoise = lerp(detailTexFBM, 1.0 - detailTexFBM,saturate(heightGradient * 1.0));
                    //通过使用remap映射细节噪声，可以保留基本形状，在边缘进行变化
                    cloudDensity = remap(cloudDensity, detailNoise * _BaseShapeDetailEffectEdge, 1.0, 0.0, 1.0);
                }
                data.density =saturate(cloudDensity * _VolumeCloudDensityMultiplier*0.25*data.absorptivity);
                return data;
            }

            float3 Lightmarch(float3 windOffset, float startDis,int cubeIndex,float3 curPos,float3 lightDir,float3 boxMinLocalScale,float3 boxMaxLocalScale){
                float4 cloudLightData=_CloudLightData[cubeIndex];
                float volumeCloudLightStrength=cloudLightData.x;
                float volumeCloudLightmarchLerp=cloudLightData.w;
                float3 cubeScale = _RayVolumeCloudCubeScale[cubeIndex],xyz;
                float4x4 cubeLocalToWorld = _RayVolumeCloudCubeLocalToWorld[cubeIndex];
                //
                float3 curPosWS=curPos/cubeScale;
                curPosWS=mul(cubeLocalToWorld,float4(curPosWS,1));
                float3 entryPosWS = curPosWS;

                float3 entryPos = curPos;

                float dstInsideBox = RayBoxDst(boxMinLocalScale, boxMaxLocalScale, curPos, 1.0 / lightDir).y;

                float totalDensity = 0;
                float expLight=0;
                const float sizeLightLoop = 4;
                if(dstInsideBox>0.01){
                     float stepSize = dstInsideBox / sizeLightLoop;
                     float dis=startDis;

                     for (int step = 0; step < sizeLightLoop; step++) {

                        curPos =entryPos + lightDir * dis;
                        curPosWS =entryPosWS + _MainLightPosition.xyz * dis;

                        WeatherData res = GetWeatherHeightGradient(cubeIndex,windOffset,curPos,boxMinLocalScale,boxMaxLocalScale);
                        float estimateDensity = res.density;
                        if(estimateDensity>0.0001){
                            WeatherData res2=SampleDensityCube(cubeIndex,res,estimateDensity,windOffset,curPos);
                            float posDensity = res2.density;
                            totalDensity=totalDensity+posDensity*stepSize;
                        }
                        dis=dis+stepSize;
                      }
                      //totalDensity=totalDensity/dstInsideBox;
                      expLight=exp(-totalDensity*cloudLightData.z);
                      //expLight=BeerPowder(totalDensity*dstInsideBox,cloudLightData.z);
                }

                float4 cloudColorDatas = _CloudColorDatas[cubeIndex];

                float currentLum=expLight;
                currentLum = cloudColorDatas.y + currentLum * (1.0 - cloudColorDatas.y);
                //云层颜色
                float3 cloudColorDark=_CloudColorDarkDatas[cubeIndex].xyz;
                float3 cloudColorCentral=_CloudColorCentralDatas[cubeIndex].xyz;
                float3 cloudColorBright=_CloudColorBrightDatas[cubeIndex].xyz;

                float3 cloudColor = cloudLightData.x*Interpolation3(cloudColorDark.rgb, cloudColorCentral.rgb, cloudColorBright.rgb, saturate(currentLum), cloudColorDatas.x) * _MainLightColor.rgb;
                return lerp(_MainLightColor.rgb*cloudLightData.x*currentLum,cloudColor,cloudLightData.w);

            }

            WeatherData GetWeatherHeightGradientCircle(float3 windOffset,float3 posWS, float3 sphereCenter, float earthRadiusScale, float heightMin, float heightMax){
                
                WeatherData res;

                float2 uv2D=posWS.xz *10* 0.000001*_VolumeCloudWeatherAndSpeedMapScale;

                float earthRadius = Earth_Radius*earthRadiusScale;
                float dis = length(posWS-sphereCenter);
                float heightPercent= (dis-(earthRadius+heightMin)) /(heightMax-heightMin);
                heightPercent=clamp(heightPercent,0.0,1.0);

                res = GetGetWeatherData(_VolumeCloudWeatherAndSpeedMap,_StratusCloudRange,_CumulusCloudRange,_DensityDifferenceValue,_ThicknessDifferenceValue,_CloudAbsorbAdjust,_WeatherWindSpeed, windOffset, uv2D, heightPercent);
                return res;
            }

            float3 LightmarchCircle(float absorptivity,float earthRadiusScale, float3 sphereCenter,float earthRadius,float heightMin,float heightMax, float3 windOffset, float startDis,float3 curPos,float3 lightDir){

                //
                float3 curPosWS = curPos;
                float3 entryPosWS = curPosWS;

                float dstInsideBox = RayCloudLayerDst(sphereCenter, earthRadius, heightMin, heightMax, curPosWS, lightDir).y;

                float lightAttenuation = 1.0;
                float totalDensity = 0;
                float expLight=0;
                const float sizeLightLoop = 4;
                if(dstInsideBox>0.01){
                     float stepSize = dstInsideBox / sizeLightLoop;
                     float dis=startDis;

                     for (int step = 0; step < sizeLightLoop; step++) {

                        curPosWS =entryPosWS + _MainLightPosition.xyz * dis;

                        WeatherData weatherData  = GetWeatherHeightGradientCircle(windOffset,curPosWS,sphereCenter,earthRadiusScale,heightMin,heightMax);
                        float estimateDensity = weatherData.density;
                        if(estimateDensity>0.0001){
                             WeatherData weatherData2 = SampleDensityCubeCircle(weatherData,estimateDensity,windOffset,curPosWS);
                             float posDensity=weatherData2.density;
                             totalDensity=totalDensity+posDensity*stepSize;
                        }
                        dis=dis+stepSize;
                      }
                      //totalDensity=totalDensity/dstInsideBox;
                      //expLight=exp(-totalDensity*dstInsideBox*_VolumeCloudLightAbsorptionScale);
                      expLight = BeerPowder(totalDensity, _VolumeCloudLightAbsorptionScale*absorptivity);
                }

                float currentLum=expLight;
                currentLum = _CloudDarknessThreshold + currentLum * (1.0 - _CloudDarknessThreshold);
                float3 cloudColor = _VolumeCloudLightStrength*Interpolation3(_CloudColorDark.rgb, _CloudColorCentral.rgb, _CloudColorBright.rgb, saturate(currentLum), _CloudColorCentralOffset) * _MainLightColor.rgb;
                return lerp(_MainLightColor.rgb*_VolumeCloudLightStrength*expLight,cloudColor,_VolumeCloudLightmarchLerp);
            }

            void CloudRayMarchingCircle(float phaseVal,float stepDis,float limitDisLocalScale,float3 windOffset,float3 sphereCenter,float earthRadiusScale,float heightMin, 
                float heightMax,float startDis,float3 rayDirWS, float3 rayStartPos,inout float densityDecay,inout float3 lightEnergy){
                float dis=startDis;
                float3 curPosWS;
                float3 entryPos=rayStartPos;
                const float sizeLoop = 64;
                float earthRadius = Earth_Radius*earthRadiusScale;
                for (int i = 0; i < sizeLoop; i++){
                    curPosWS = entryPos + dis*rayDirWS;
                    WeatherData weatherData  = GetWeatherHeightGradientCircle(windOffset,curPosWS,  sphereCenter, earthRadiusScale,  heightMin,  heightMax);
                    float estimateDensity = weatherData.density;
                    if(estimateDensity>0.0001){
                        WeatherData weatherData2=SampleDensityCubeCircle(weatherData,estimateDensity,windOffset,curPosWS);
                        float density=weatherData2.density;
                        if(density>0.001){
                               float3 lightEn = LightmarchCircle(weatherData2.absorptivity,earthRadiusScale,sphereCenter,earthRadius,heightMin,heightMax, windOffset,startDis,curPosWS,_MainLightPosition.xyz);
                               lightEnergy += density * stepDis * densityDecay * lightEn * phaseVal;

                               densityDecay *= exp(-density * stepDis * _VolumeCloudRayAbsorptionScale);
                               if (densityDecay < 0.01){
                                   break;
                               }   
                        }
                        dis=dis+stepDis;
                    }else{
                        dis=dis+stepDis*1.5;
                    }
                    if(dis >= limitDisLocalScale || i>=_VolumeCloudMaxIteration){
                            break;
                    }
                }
            }

            void CloudRayMarchingCube(float volumeCloudMaxIteration, float3 windOffset,float phaseVal, float startDis,int cubeIndex, float limitDisLocalScale, float3 rayStartLocalScale, float3 rayEndLocalScale, float3 rayStartLocal, float3 rayEndLocal,float stepDis,
                inout float densityDecay,inout float3 lightEnergy) 
            {
                    float4 cloudLightData=_CloudLightData[cubeIndex];
                   //
                   float3 cubeScale = _RayVolumeCloudCubeScale[cubeIndex],xyz;
                   float4x4 cubeWorldToLocal = _RayVolumeCloudCubeWorldToLocal[cubeIndex];
                   //float4x4 cubeLocalToWorld = _RayVolumeCloudCubeLocalToWorld[cubeIndex];
                   //float3 curPosWS=mul(cubeLocalToWorld,float4(rayStartLocal,1.0)).xyz;
                   //float3 entryPosWS=curPosWS;
                   //float3 endposWS=mul(cubeLocalToWorld,float4(rayEndLocal,1.0)).xyz;
                   //float3 dirWS=normalize(endposWS.xyz-curPosWS.xyz);
                   //Light
                   float3 mainLightDirLocal =mul(cubeWorldToLocal,float4(_MainLightPosition.xyz,0));
                   float3 mainLightDirLocalScale = mainLightDirLocal*cubeScale;
                   //
                   float3 cubeMin = _RayVolumeCloudCubeMin[cubeIndex].xyz;
                   float3 cubeMax = _RayVolumeCloudCubeMax[cubeIndex].xyz;
                   float3 cubeMinScale=cubeMin*cubeScale;
                   float3 cubeMaxScale=cubeMax*cubeScale;
                   float3 curPosLocalScale = rayStartLocalScale;
                   float3 entryPosLocalScale=curPosLocalScale;
                   float3 dirLocalScale=normalize(rayEndLocalScale.xyz-curPosLocalScale.xyz);
                   float disLocalScale=startDis;
                   const float sizeLoop = 64;

                   for (int i = 0; i < sizeLoop; i++){
                       curPosLocalScale = entryPosLocalScale + disLocalScale*dirLocalScale;
                       WeatherData weatherData=GetWeatherHeightGradient(cubeIndex,windOffset,curPosLocalScale,cubeMinScale,cubeMaxScale);
                       float estimateDensity = weatherData.density;
                       if(estimateDensity>0.0001){
                           WeatherData weatherData2=SampleDensityCube(cubeIndex,weatherData,estimateDensity,windOffset,curPosLocalScale);
                           float density=weatherData2.density;
                           if(density>0.001){
                                float3 lightEn = Lightmarch(windOffset,startDis,cubeIndex,curPosLocalScale,mainLightDirLocalScale,cubeMinScale,cubeMaxScale);
                               lightEnergy += density * stepDis * densityDecay * lightEn * phaseVal;
                               densityDecay *= exp(-density * stepDis * cloudLightData.y);
                               if (densityDecay < 0.01){
                                   break;
                               }   
                           }
                           disLocalScale=disLocalScale+stepDis;
                       }else{
                           disLocalScale=disLocalScale+stepDis*1.5;
                       }
                       if(disLocalScale >= limitDisLocalScale || i>=volumeCloudMaxIteration){
                            break;
                       }
                   }
            }

            float LightScattering(float a) {
                float blend = 0.5;
                float parA=4.0*UNITY_PI;
                float parB=2.0 *a;
                float hgBlendA=_VolumeCloudPhaseParams.x*_VolumeCloudPhaseParams.x;
                hgBlendA = (1.0 - hgBlendA) / (parA * pow(1.0 + hgBlendA - parB * _VolumeCloudPhaseParams.x, 1.5));
                hgBlendA=hgBlendA*(1.0-blend);
                float hgBlendB=_VolumeCloudPhaseParams.y*_VolumeCloudPhaseParams.y;
                hgBlendB=(1.0 - hgBlendB) / (parA * pow(1.0 + hgBlendB - parB * _VolumeCloudPhaseParams.y, 1.5));
                hgBlendB=hgBlendB*blend;
                float hgBlend = hgBlendA + hgBlendB;
                return _VolumeCloudPhaseParams.z + hgBlend * _VolumeCloudPhaseParams.w;
            }

            float HenyeyGreenstein(float angle, float g)
            {
                float g2 = g * g;
                return(1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * angle, 1.5));
            }

            float HGScatterMax(float angle, float g_1, float intensity_1, float g_2, float intensity_2)
            {
                return max(intensity_1 * HenyeyGreenstein(angle, g_1), intensity_2 * HenyeyGreenstein(angle, g_2));
            }

            half4 Frag (Varyings i) : SV_Target
            {
                #if defined(DISTINGUISH_2X2)
                    int frameIndex = GetIndex2x2(i.uv, _DistinguishWidth, _DistinguishHeight);
                    if (frameIndex != _DistinguishIndex)
                    {
                        float4 mainTexColor = tex2D(_MainTex, i.uv);
                        return mainTexColor;
                    }
                #elif defined(DISTINGUISH_4X4)
                    int frameIndex = GetIndex4x4(i.uv, _DistinguishWidth, _DistinguishHeight);
                    if (frameIndex != _DistinguishIndex)
                    {
                        float4 mainTexColor = tex2D(_MainTex, i.uv);
                        return mainTexColor;
                    }
                #endif
                //_VolumeDepthTexture
                float depthCam = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).x;
                float depth = SAMPLE_DEPTH_TEXTURE(_VolumeDepthTexture, sampler_VolumeDepthTexture, i.uv).x;
                float4 worldPos = GetWorldSpacePosition(depth, i.uv);
                float depthDis=distance(worldPos.xyz,_WorldSpaceCameraPos.xyz);
                float blueNoise = tex2D(_VolumeCloudBlueNoiseMap, i.uv * _VolumeCloudBlueNoiseCoords.xy+ _VolumeCloudBlueNoiseCoords.zw).r;

                float3 rayDirWS=normalize(worldPos.xyz-_WorldSpaceCameraPos.xyz);
                float cosAngle = dot(rayDirWS, _MainLightPosition.xyz);

                float3 lastLightColor = float3(0,0,0);
                float lastDecay=1;

                #if defined(VOLUMECLOUD_USE_EARTH)
                    float dstToObj = LinearEyeDepth(depth, _ZBufferParams);
                    float earthRadiusScale=0.1;
                    float earthRadius = Earth_Radius*earthRadiusScale;
                    float heightMin=1500;
                    float heightMax=2500;
                    float3 sphereCenter=  float3(_WorldSpaceCameraPos.x,-earthRadius,_WorldSpaceCameraPos.z);
                    float2 rayCloudRes = RayCloudLayerDst(sphereCenter, earthRadius, heightMin, heightMax, _WorldSpaceCameraPos.xyz, rayDirWS);

                    float dotValue=dot(rayDirWS,float3(0.0,1.0,0.0));
                    dotValue=clamp(dotValue,0,1);
                    dotValue=sqrt(sqrt(dotValue));
                    rayCloudRes.y=rayCloudRes.y*dotValue;

                    float limitDis = min(dstToObj-rayCloudRes.x,rayCloudRes.y);
       
                    if(depthCam == 0){
                        limitDis=rayCloudRes.y;
                    }
                    if(rayCloudRes.y > 0.01 && limitDis>0.001){

                        float stepDis = 1.0f/_VolumeCloudStepCountPerMeter;
                        float blueNoiseScale=blueNoise*_VolumeCloudBlueNoiseTexScale;
                        float3 windOffset=_VolumeCloudWindInfo.xyz*_VolumeCloudWindInfo.w*_Time.y;
                        float3 lightEnergy = 0.0;
                        float densityDecay = 1.0;
                        float3 rayStart = _WorldSpaceCameraPos.xyz+rayDirWS*rayCloudRes.x;

                        float phaseVal = HGScatterMax(cosAngle, _VolumeCloudPhaseParams.x, _VolumeCloudPhaseParams.y, _VolumeCloudPhaseParams.z, _VolumeCloudPhaseParams.w);
                        phaseVal = _VolumeCloudPhaseBase + phaseVal * _VolumeCloudPhaseWeight;
                        CloudRayMarchingCircle(phaseVal,stepDis*5,limitDis,windOffset,sphereCenter,earthRadiusScale,heightMin,heightMax,blueNoiseScale,rayDirWS,rayStart,densityDecay,lightEnergy);
                        lastDecay=lastDecay*densityDecay;
                        lastLightColor=lightEnergy+densityDecay*lastLightColor;
                    }
                #endif

                const float sizeLoop = 8;

                for(int j=0;j<sizeLoop;j++){
                    if(j>=_RayVolumeCloudCubeCount){
                        break;
                    }
                    float4 cloudMaxIterationAndStep=_CloudMaxIterationAndStep[j];
                    float stepDis = 1.0f/cloudMaxIterationAndStep.y;
                    float4 cloudUVscale = _CloudUVscale[j];
                    float3 cubeScale = _RayVolumeCloudCubeScale[j],xyz;
                    float4x4 cubeWorldToLocal = _RayVolumeCloudCubeWorldToLocal[j];
                    float4x4 cubeLocalToWorld = _RayVolumeCloudCubeLocalToWorld[j];
                    float3  cubeMin = _RayVolumeCloudCubeMin[j].xyz;
                    float3  cubeMax = _RayVolumeCloudCubeMax[j].xyz;
                    float4 camLocalPos = mul(cubeWorldToLocal,float4(_WorldSpaceCameraPos.xyz,1) );
                    float4 worldToLocalPos = mul(cubeWorldToLocal,float4(worldPos.xyz,1));
                    float3 rayDirLocal = normalize(worldToLocalPos.xyz-camLocalPos.xyz);
                    float2 cubeRes = RayBoxDst(cubeMin, cubeMax, camLocalPos.xyz, 1.0/rayDirLocal);
                    float4 windInfo=_ColliderWindInfo[j];
                    float3 windOffset=windInfo.xyz*windInfo.w*_Time.y;

                    if(cubeRes.y>0.01){

                        float3 rayStartLocal = camLocalPos.xyz+rayDirLocal*cubeRes.x;
                        float3 rayEndLocal = rayStartLocal.xyz+rayDirLocal*cubeRes.y;

                        float3 rayStartLocalScale=rayStartLocal*cubeScale;
                        float3 rayEndLocalScale=rayEndLocal*cubeScale;

                        float3 camPosLocalScale=camLocalPos*cubeScale;
                        cubeRes.x=distance(rayStartLocalScale.xyz,camPosLocalScale.xyz);
                        cubeRes.y=distance(rayStartLocalScale.xyz,rayEndLocalScale.xyz);
                        float limitDis = min(depthDis-cubeRes.x,cubeRes.y);

                        if(limitDis>0.0001){
                            float blueNoiseScale=blueNoise*cloudUVscale.z;
                            float3 lightEnergy = 0.0;
                            float densityDecay = 1.0;

                            float4 volumeCloudPhaseParams=_VolumeCloudPhaseParamsDatas[j];
                            float volumeCloudPhaseBase=_VolumeCloudPhaseBaseDatas[j];
                            float volumeCloudPhaseWeight=_VolumeCloudPhaseWeightDatas[j];
                            float phaseVal = HGScatterMax(cosAngle, volumeCloudPhaseParams.x, volumeCloudPhaseParams.y, volumeCloudPhaseParams.z, volumeCloudPhaseParams.w);
                            phaseVal = volumeCloudPhaseBase + phaseVal * volumeCloudPhaseWeight;

                            CloudRayMarchingCube(cloudMaxIterationAndStep.x,windOffset,phaseVal,blueNoiseScale,j,limitDis,rayStartLocalScale.xyz,rayEndLocalScale.xyz,rayStartLocal.xyz,rayEndLocal.xyz,stepDis,densityDecay,lightEnergy);

                            lastDecay=lastDecay*densityDecay;
                            lastLightColor=lightEnergy+densityDecay*lastLightColor;
                        }
                    }
                }
                return half4(lastLightColor,lastDecay);
            }
            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode" = "Ray Volume Cloud Pass B" }
            Cull Off 
            ZWrite Off 
            ZTest Always

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Frag

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
                float3 posWS:TEXCOORD1;
            };

            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            float4 _CameraDepthTexture_TexelSize;

            sampler2D _MainTex;

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.uv = i.uv;
                o.posWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 Frag (Varyings i) : SV_Target{

                float2 texelSize = 0.5 * _CameraDepthTexture_TexelSize.xy;
                float2 taps[4] = { 	float2(i.uv + float2(-1,-1) * texelSize),
                                    float2(i.uv + float2(-1,1) * texelSize),
                                    float2(i.uv + float2(1,-1) * texelSize),
                                    float2(i.uv + float2(1,1) * texelSize)
                                };
                float depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, taps[0]);
                float depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, taps[1]);
                float depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, taps[2]);
                float depth4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, taps[3]);

                float result = min(depth1, min(depth2, min(depth3, depth4)));

                return result;
            }

            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode" = "Ray Volume Cloud Pass C" }
            Cull Off 
            ZWrite Off 
            ZTest Always

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Frag

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
                float3 posWS:TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _VolumeCloudResColor;

            Varyings Vertex (Attritubes i)
            {
                Varyings o;
                o.uv = i.uv;
                o.posWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 Frag (Varyings i) : SV_Target{

                float4 color = tex2D(_MainTex, i.uv);
                float4 cloudColor = tex2D(_VolumeCloudResColor, i.uv);

                color.rgb *= cloudColor.a;
                color.rgb += cloudColor.rgb;
                return color;
            }

            ENDHLSL
        }
    }
}

