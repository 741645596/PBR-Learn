#ifndef C_PBRLIGHTING_INCLUDE
#define C_PBRLIGHTING_INCLUDE

    #include "CPBRInput.hlsl"
    #include "CFunction.hlsl"
// 闪点计算
// 1.计算闪点密度布局等===》通过uv空间算法。
// 2.比较闪点强度进行算法。
// 3.根据光照模型确定闪点是否可见。
half3 GetSparkleColor(InputData_SGame inputData, Light MainLight, half2 uv)
{
    half3 sparkleCol = half3(0, 0, 0);
    // 计算闪点布局及密度在uv空间计算
    float4 sparkleUV = uv.xyxy * _SparkleSize.xyxy;
    float4 fractionalUV = frac(sparkleUV); // 小数部分
    float3 integerUV = floor(sparkleUV.zwz); // 向下取整
    //
    float3 beDiscardedUV = fractionalUV.wzw - 0.5;
    half3 checkboardVec1 = beDiscardedUV.zyz < half3(0, 0, 0) ? half3(1, 1, 1) : half3(0, 0, 0);
    half3 checkboardVec2 = beDiscardedUV.xyz > half3(0, 0, 0) ? half3(1, 1, 1) : half3(0, 0, 0);
    checkboardVec2 = checkboardVec2 - checkboardVec1;

    float4 checkboardVec3 = float4(0.0, checkboardVec2);// 确定单个格子划分象限
    // uv2 XYX坐标， UV3:XXY
    float3 sparkleUV2 = integerUV + checkboardVec3.xyz;
    sparkleUV2 = sparkleUV2 * _SparkleSize.zwz;
    float3 sparkleUV3 = integerUV.zyz + checkboardVec3.xxz;
    sparkleUV3 = sparkleUV3 * _SparkleSize.zwz;

    // 看起来像随机种子
    float4 sparkleUVCombine = checkBoardFunction(sparkleUV2);
    float4 sparkleUVCombine2 = checkBoardFunction(sparkleUV3);
    // 算出来的核心数据
    float4 mixSparkleCombine = float4(sparkleUVCombine2.xz, sparkleUVCombine.xz);

    // 计算缩放
    float4 sparkleScale = lerp(_SparkleScaleMin, 1.0, mixSparkleCombine);
    sparkleScale = 1.0 / (sparkleScale + 0.001);

    float4 sparkleParam = checkboardVec3.xxzx + sparkleUVCombine2;
    checkboardVec3 = checkboardVec3 + sparkleUVCombine;
    sparkleUVCombine2.xz = sparkleUVCombine.yw;
    checkboardVec3 = fractionalUV - checkboardVec3;
    fractionalUV = fractionalUV.zwzw - sparkleParam;
    fractionalUV = sparkleScale.xxyy * abs(fractionalUV);
    sparkleScale = sparkleScale.zzww * abs(checkboardVec3);
    // 闪烁向量，
    float4 sparkleVec = float4(dot(fractionalUV.xy, fractionalUV.xy), 
                               dot(fractionalUV.zw, fractionalUV.zw), 
                               dot(sparkleScale.xy, sparkleScale.xy), 
                               dot(sparkleScale.zw, sparkleScale.zw));
    sparkleVec = 1.0 - 4.0 * sparkleVec;
    sparkleVec = max(sparkleVec, 0.0); // 确定第一象限> 0, 其他 0

    // 从纹理取得闪点强度。a 通道
    float SparkleDensityTex = SAMPLE_TEXTURE2D(_SparkleTex, sampler_SparkleTex, uv).a;
    float sparkleDensity = SparkleDensityTex * _SparkleDensity;

    // 采样的uv
    float2 sparkleSampleUv;
    sparkleSampleUv.x = mixSparkleCombine.x / (sparkleDensity + 0.01);
    sparkleSampleUv.y = 0.5;

    // 确定闪点显不显示的核心数据结构。
    bool4 boolVector = step(mixSparkleCombine, sparkleDensity);// b >=a ? 1: 0
    float4 sparkleParam2;
    sparkleParam2.x = boolVector.x ? 1.0 : 0.0;
    sparkleParam2.y = boolVector.y ? 1.0 : 0.0;
    sparkleParam2.z = boolVector.z ? 1.0 : 0.0;
    sparkleParam2.w = boolVector.w ? 1.0 : 0.0;
    // float4 sparkleParam3 = sparkleVec * sparkleParam2;
    // float dotParam = dot(float4(1.0, 1.0, 1.0, 1.0), sparkleParam3);
    // dotParam = dotParam <= 0.01 ? 1.0 : 0.0;

    Light mainLight = MainLight;

    half NdotL = dot(inputData.normalWS, mainLight.direction);
    // GGX 部分只负责强度
    sparkleVec = sparkleVec * SparkleGGX(inputData.normalWS, mainLight.direction, inputData.viewDirWS, 1.0 - _SparkleRoughness, sparkleUVCombine2.ywxz * _SparkleDependency);
    sparkleVec = sparkleParam2 * sparkleVec;
    float sparkleDot = dot(float4(1.0, 1.0, 1.0, 1.0), sparkleVec) * SAMPLE_TEXTURE2D(_SparkleMaskTex, sampler_SparkleMaskTex, uv).r; //决定当前像素是不是亮点

    // 采样闪点数据
    sparkleCol = SAMPLE_TEXTURE2D(_SparkleTex, sampler_SparkleTex, sparkleSampleUv).rgb;
    sparkleCol = sparkleCol * sparkleDot ;
    sparkleCol = sparkleCol * _SparkleColor.xyz;
    sparkleCol = abs(NdotL) * sparkleCol;
    //
    return sparkleCol;
}

    void SGamePhysicallyBased(SurfaceData_SGame surfaceData,BRDFData_PBR brdfData, Light light, InputData_SGame inputData,half3 energyCompensation,inout half3 DirectDiffuse,inout half3 DirectSpecular)
    {
        half NoV = saturate(dot(inputData.normalWS,inputData.viewDirWS));
        half NoL = dot(inputData.normalWS,light.direction);

        half3 Distort_L = light.direction;


        #if !defined(_ANISOTROPY_ON)
            half3 SpecularTerm = UnitySpecular(inputData.normalWS, Distort_L, inputData.viewDirWS,brdfData.roughness2MinusOne,brdfData.roughness2,brdfData.normalizationTerm) 
            * energyCompensation;
        #else
            half3 SpecularTerm = UE4_Aniso(brdfData.perceptualRoughness,brdfData.roughness,surfaceData.anisotropy, inputData.normalWS,inputData.viewDirWS, Distort_L,inputData.TBN[0],inputData.TBN[1],brdfData.specular) * PI;
        #endif

        DirectDiffuse = brdfData.diffuse;
        DirectSpecular = brdfData.specular * SpecularTerm;
    }

    void DirectLighting(SurfaceData_SGame surfaceData,BRDFData_PBR brdfData, Light mainLight, InputData_SGame inputData,out half3 DirectDiffuse,out half3 DirectSpecular)
    {
        // Energy Compensation
        half multiscatterDFGX = brdfData.envBRDF.x + brdfData.envBRDF.y;
        half3 EnergyCompensation = 1.0 + brdfData.specular * (rcp(multiscatterDFGX) - 1.0);

        uint meshRenderingLayers = GetMeshRenderingLightLayer();
        if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
        {
            SGamePhysicallyBased(surfaceData,brdfData,mainLight, inputData,EnergyCompensation,DirectDiffuse,DirectSpecular);
        }
        

        // Radiance
        half3 MainRadiance = Radiance(mainLight,inputData.normalWS);

        DirectDiffuse *= MainRadiance;
        DirectSpecular *= MainRadiance;

        #if defined(_ADDITIONAL_LIGHTS)
            uint pixelLightCount = GetAdditionalLightsCount();
            half3 AdditionalDiffuse,AdditionalSpecular;
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS, unity_ProbesOcclusion /*float4(1, 1, 1, 1) */);
                half3 AdditionalRadiance = Radiance(light,inputData.normalWS);
                SGamePhysicallyBased(surfaceData,brdfData,light, inputData,EnergyCompensation,AdditionalDiffuse,AdditionalSpecular);
                DirectDiffuse += AdditionalDiffuse * AdditionalRadiance;
                DirectSpecular += AdditionalSpecular * AdditionalRadiance;
            }
        #endif
    }

    void IndirectLighting(BRDFData_PBR brdfData, InputData_SGame inputData, SurfaceData_SGame surfaceData,Light mainLight,out half3 indirectDiffuse,out half3 IndirectSpecular)
    {
        half3 Irradiance = inputData.Irradiance;
        // #if defined(LIGHTMAP_ON)
        //     Irradiance = SubtractDirectMainLightFromLightmap(mainLight, inputData.normalWS, Irradiance);
        // #endif
        indirectDiffuse = Irradiance * brdfData.diffuse;

        half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
        half NoV = saturate(dot(inputData.normalWS, inputData.viewDirWS));

        #if !defined(_ANISOTROPY_ON)
            IndirectSpecular = UEIBL(reflectVector,inputData.positionWS, brdfData.perceptualRoughness,brdfData.specular,NoV,surfaceData.occlusion,brdfData.envBRDF);
            // IndirectSpecular = UnityIBL(brdfData.specular,brdfData.grazingTerm,brdfData.perceptualRoughness,brdfData.roughness2,inputData.positionWS,NoV,reflectVector,surfaceData.occlusion);
        #else
            IndirectSpecular = AnisotropyIBL(inputData.positionWS,_Anisotropy,inputData.normalWS,inputData.viewDirWS,inputData.TBN[0],inputData.TBN[1],brdfData.perceptualRoughness,brdfData.specular,surfaceData.occlusion,NoV);
        #endif

        
        indirectDiffuse *= surfaceData.occlusion;
        IndirectSpecular *= surfaceData.occlusion;
    }

    ////////// Core Function Start //////////////
    half4 PBRFragment(Varyings_SGame input) : SV_Target
    {
        SurfaceData_SGame surfaceData;
        InputData_SGame inputData;
        BRDFData_PBR brdfData;
        Light MainLight;

        PrepareData(input,inputData,surfaceData,brdfData,MainLight);

        // Direct Color / Additional Color
        half3 DirectDiffuse,DirectSpecular;
        DirectLighting(surfaceData,brdfData,MainLight,inputData,DirectDiffuse,DirectSpecular);

        // Indirect Color
        half3 IndirectDiffuse,IndirectSpecular;
        IndirectLighting(brdfData, inputData,surfaceData,MainLight,IndirectDiffuse,IndirectSpecular);
        
        // Combine
        half3 color = DirectDiffuse + DirectSpecular + IndirectDiffuse + IndirectSpecular;
        

        color.rgb += GetSparkleColor(inputData, MainLight, input.uv);
        // Emission / Fog Color / Additional Vertex Color
        ApplyOtherColor(surfaceData,inputData,brdfData,color);

        return half4(color,surfaceData.alpha);
    }
    ////////// Core Function End //////////////

#endif  //C_PBRLIGHTING_INCLUDE
