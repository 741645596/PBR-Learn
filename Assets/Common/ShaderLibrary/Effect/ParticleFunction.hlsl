#ifndef SGAME_PARTICLESFUN_INCLUDE
    #define SGAME_PARTICLESFUN_INCLUDE

    #include "Assets/Common/ShaderLibrary/Common/CommonFunction.hlsl"

    //UV按照中心旋转
    //uv:原UV坐标
    //rotatorAngle:旋转程度 (-1,1)
    //uvScale: uv缩放 x:X轴 y:Y轴
    inline float2 UvRotatorAngle(float2 uv, float rotatorAngle, float2 scale) {

        half rCos = cos(rotatorAngle * 3.2);
        half rSin = sin(rotatorAngle * 3.2);
        half2 rPiv = half2(0.5, 0.5);
        float2 rotator = mul(float2x2(rCos, -rSin, rSin, rCos), (uv - rPiv));
        rotator = rotator * scale;
        return rotator + rPiv;
    }

    inline float4 BlendColor(float BlendModel,float4 col,float4 col2)
    {
        if (BlendModel < 0.5)
        return  col2 * col2.a + col * (1 - col2.a);
        else if (BlendModel < 1.5)
        return  lerp(col,col + col2, col2.a);
        else
        return col * col2;
    }

    //获得屏幕UV
    //_hClipPos:HClip空间位置 由 TransformObjectToHClip(vertexPos) 函数获得
    inline float4 GetScreenUV(float4 _hClipPos) {
        float4 projPos = ComputeScreenPos(_hClipPos);
        projPos.xy = projPos.xy / projPos.w;
        return projPos;
    }

    inline float2 UVTilingOffset(float2 uv, float4 st) {
        return (uv * st.xy + st.zw);
    }

    inline float3 UILinearToSRGB(float3 c, half _IsInUICamera) {
        return lerp(c, LinearToSRGB(c), _IsInUICamera);
    }

    //根据噪音图获得坐标的偏移 根据中心点(0.5，0.5)向外偏移 返回结果：xy:新的UV z:alpha值
    //_noiseTexture:噪音图采样
    //_uv:uv
    //_intensity:偏移强度
    //_noiseTexture:噪音图
    inline half3 GetUVByNoiseTextureCenter(half4 _noiseTexture, float2 _uv, float _intensity) {
        float2 newUV = float2(_uv - 0.5) * 2;
        half2 offsetUVs = -_noiseTexture.a * _intensity * (half2(_noiseTexture.r * newUV.x, _noiseTexture.g * newUV.y));
        return half3(offsetUVs, _noiseTexture.a);
    }

    inline float2 ClampUV(float2 uv) {
        uv.x = max(uv.x, 0.001);
        uv.x = min(uv.x, 1);
        uv.y = max(uv.y, 0.001);
        uv.y = min(uv.y, 1);
        return uv;
    }

    inline half IsZeroOrOne(half x) {
        x = x - 0.5;
        return 1 - step(0.25 - (x * x), 0.005);
    }

    inline half UVIsZeroOrOne(float2 uv, float _repeatU, float _repeatV) {
        half x = IsZeroOrOne(uv.x) + _repeatU;
        x = 1 - step(x, 0.99999);
        half y = IsZeroOrOne(uv.y) + _repeatV;
        y = 1 - step(y, 0.99999);
        half res = x * y;
        return res;
    }

    inline half4 GetTextColor(half4 color, float2 uv, float _repeatU, float _repeatV) {
        half x = UVIsZeroOrOne(uv, _repeatU, _repeatV);
        return lerp(half4(0, 0, 0, 0), color, x);
    }

    //此函数根据传入参数重新计算纹理新的WrapMode的UV坐标 纹理原来的WrapMode将不在起作用
    //uv:原来的uv
    //clampValue (0 or 1):表明 纹理的WrapMode 当repeatU和repeatV任意一个为1 则clampValue=1 否则 clampValue=0
    //repeatU (0 or 1): 1:U方向的WrapMode=Repeat
    //repeatV (0 or 1): 1:V方向的WrapMode=Repeat
    inline half2 GetUV(float2 uv,float clampValue,float repeatU, float repeatV,float4 _Texture_ST) {
        float2 uvDistortClamp = ClampUV(uv);
        float2 uvDistortRepeat = frac(uv);
        uvDistortRepeat.x = lerp(uvDistortClamp.x, uvDistortRepeat.x, repeatU);
        uvDistortRepeat.y = lerp(uvDistortClamp.y, uvDistortRepeat.y, repeatV);
        return lerp(uvDistortClamp, uvDistortRepeat, clampValue);
    }

    //5.26 ->草莓新添加

    //构造旋转四元数 输入角度以及轴
    inline half4 Quaternion(half theta)
    {
        half sinThetaVal = sin(theta/2);
        half cosThetaVal = cos(theta/2);
        half3 Axis = half3(0,0,1);
        return half4(Axis.x*sinThetaVal,Axis.y*sinThetaVal,Axis.z*sinThetaVal,cosThetaVal);
    }

    inline half QModule(half4 q)
    {
        return sqrt(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
    }

    inline half4 QConjugate(half4 q){
        return half4(-q.x,-q.y,-q.z,q.w);
    }

    inline half4 QNormalize(half4 q)
    {
        return normalize(q);
    }

    inline half4 QInvert(half4 q)
    {
        return QConjugate(q)/QModule(q);
    }

    inline half4 QMultiply(half4 q0, half4 q1)
    {
        half3   v1 = half3(q0.x,q0.y,q0.z);
        half3   v2 = half3(q1.x,q1.y,q1.z);
        half    s1 = q0.w;
        half    s2 = q1.w;
        half w = s1 * s2 - dot(v1, v2);
        half3 v3 = s1 * v2 + s2 * v1 + cross(v1, v2);
        return half4(v3.x,v3.y,v3.z,w);
    }

    inline float3 QRotate3(half4 q, float3 v)
    {
        half4 q_Resualt =  QMultiply(QMultiply(q, half4(v.x,v.y,v.z, 0)), QInvert(q));
        return float3(q_Resualt.x,q_Resualt.y,q_Resualt.z);
    }

    inline float2 QRotate2(half4 q, float3 v)
    {
        half4 q_Resualt =  QMultiply(QMultiply(q, half4(v.x,v.y,v.z, 0)), QInvert(q));
        return float2(q_Resualt.x,q_Resualt.y);
    }

    inline float2 UvRotatByQuaternion(float2 uv, float rotatorAngle, float2 scale)
    {
        float2 rPiv = float2(0.5, 0.5);
        uv-=rPiv;
        float3 uvw = float3(uv.x,uv.y,0);
        half4 q = Quaternion(radians(rotatorAngle));
        float2 result = QRotate2(q,uvw) * scale + rPiv;
        /*
        float2 tmpUV = float2(result.x,result.y) * scale;
        tmpUV+=rPiv;*/
        return result;
    }
    inline float2 UvRotatByQuaternionForPolar(float2 uv, float rotatorAngle, float2 scale)
    {
        half3 uvw = float3(uv.x,uv.y,0);
        half4 q = Quaternion(radians(rotatorAngle));
        float2 result = QRotate2(q,uvw) * scale;
        return result;
    }

    inline float2 toPolar(float2 uv,half2 flowSpeed ,half m_angle,half usingPolar,half scale=1)
    {
        float2 norUV = uv;
        if(usingPolar==1){
            norUV -= float2(0.5,0.5);
            flowSpeed = half2(max(flowSpeed.x,flowSpeed.y),max(flowSpeed.x,flowSpeed.y));
        }
        float2 tempuv = UvRotatByQuaternionForPolar(norUV,m_angle*_Time.g,half2(scale,scale));
        half dis = length(tempuv);
        half xDir = frac(_Time.g * flowSpeed.x);
        half yDir = frac(_Time.g * flowSpeed.y);
        
        //half xflowSpeed =  frac(_Time.g * flowSpeed.x)+uv.x;
        //half yflowSpeed =  frac(_Time.g * flowSpeed.y)+uv.y;
        //将0-0.5放大到0-1
        
        dis *=2;
        dis += (xDir+yDir)/2;
        half loop=  1-dis;
        //conver to polar -PI-PI
        half angle = atan2(tempuv.x,tempuv.y);
        angle = angle / 3.1415926/2 + 0.5;
        half2 Polar  = float2(angle,loop);
        half2 uvflow = half2(norUV.x+xDir,norUV.y+yDir);
        return lerp(uvflow,Polar,usingPolar);
        

    }
    float2 POM( sampler2D heightMap, float2 uvs, float2 dx, float2 dy, 
    float3 normalWorld, float3 viewWorld, float3 viewDirTan, 
    int minSamples, int maxSamples, float parallax, 
    float refPlane, float2 tilling, float2 curv, int index )
    {
        float3 result = 0;
        int stepIndex = 0;
        int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
        float layerHeight = 1.0 / numSteps;
        float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
        uvs.xy += refPlane * plane;
        float2 deltaTex = -plane * layerHeight;
        float2 prevTexOffset = 0;
        float prevRayZ = 1.0f;
        float prevHeight = 0.0f;
        float2 currTexOffset = deltaTex;
        float currRayZ = 1.0f - layerHeight;
        float currHeight = 0.0f;
        float intersection = 0;
        float2 finalTexOffset = 0;
        while ( stepIndex < numSteps + 1 )
        {
            currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r;
            if ( currHeight > currRayZ )
            {
                stepIndex = numSteps + 1;
            }
            else
            {
                stepIndex++;
                prevTexOffset = currTexOffset;
                prevRayZ = currRayZ;
                prevHeight = currHeight;
                currTexOffset += deltaTex;
                currRayZ -= layerHeight;
            }
        }
        int sectionSteps = 10;
        int sectionIndex = 0;
        float newZ = 0;
        float newHeight = 0;
        while ( sectionIndex < sectionSteps )
        {
            intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
            finalTexOffset = prevTexOffset + intersection * deltaTex;
            newZ = prevRayZ - intersection * layerHeight;
            newHeight = tex2Dgrad( heightMap, uvs + finalTexOffset, dx, dy ).r;
            if ( newHeight > newZ )
            {
                currTexOffset = finalTexOffset;
                currHeight = newHeight;
                currRayZ = newZ;
                deltaTex = intersection * deltaTex;
                layerHeight = intersection * layerHeight;
            }
            else
            {
                prevTexOffset = finalTexOffset;
                prevHeight = newHeight;
                prevRayZ = newZ;
                deltaTex = ( 1 - intersection ) * deltaTex;
                layerHeight = ( 1 - intersection ) * layerHeight;
            }
            sectionIndex++;
        }
        return uvs.xy + finalTexOffset;
    }



    float2 ParallaxOcclusionMapping(Texture2D heightMap,SamplerState sampler_heightMap, 
    half3 viewDirTS,
    half scale, float2 uv)
    {
        // determine optimal number of layers
        const float minLayers = 10;
        const float maxLayers = 15;
        float numLayers = lerp(minLayers, maxLayers, abs(dot(half3(0, 0, 1), viewDirTS)));
        // height of each layer
        float layerHeight = 1.0 / numLayers;
        // current depth of the layer
        float currentLayerHeight = 0;
        // shift of texture coordinates for each layer
        half2 dtex = scale * viewDirTS.xy / viewDirTS.z / numLayers;
        // current texture coordinates
        float2 currentTextureCoords = uv;
        // depth from heightmap
        float heightFromTexture = 1 - SAMPLE_TEXTURE2D(heightMap, sampler_heightMap, currentTextureCoords).r;
        for(int i = 0; i < 150; i++)
        {
            if(heightFromTexture <= currentLayerHeight){
                break;
            }
            // to the next layer
            currentLayerHeight += layerHeight;
            // shift texture coordinates along vector viewDirTS
            currentTextureCoords -= dtex;
            // get new depth from heightmap
            heightFromTexture = 1 - SAMPLE_TEXTURE2D(heightMap, sampler_heightMap, currentTextureCoords).r;
        }


        // previous texture coordinates
        half2 prevTCoords = currentTextureCoords + dtex;
        // heights for linear interpolation
        float nextH  = heightFromTexture - currentLayerHeight;
        float prevH  = 1 - SAMPLE_TEXTURE2D(heightMap, sampler_heightMap, currentTextureCoords).r - currentLayerHeight + layerHeight;
        // proportions for linear interpolation
        float weight = nextH / (nextH - prevH);
        // interpolation of texture coordinates
        float2 finalTexCoords = prevTCoords * weight + currentTextureCoords * (1.0-weight);
        return finalTexCoords - uv;
    }

    inline float2 POM_Level1( sampler2D heightMap, float2 uvs, float2 dx, float2 dy, 
    float3 normalWorld, float3 viewWorld, float3 viewDirTan, 
    int minSamples, int maxSamples, float parallax)
    {
        int stepIndex = 0;
        int numSteps = ( int )lerp( minSamples, maxSamples, saturate( dot( normalWorld, viewWorld ) ) );
        half layerHeight = 1.0 / numSteps;
        half2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
        half2 deltaTex = -plane * layerHeight;
        half prevHeight = 0.0f;
        float2 currTexOffset = deltaTex;
        half currRayZ = 1.0f - layerHeight;
        half currHeight = 0.0f;
        while ( stepIndex < numSteps  )
        {
            currHeight = tex2Dgrad( heightMap, uvs + currTexOffset, dx, dy ).r;
            if ( currHeight > currRayZ )
            {
                stepIndex = numSteps ;
            }
            else
            {
                stepIndex++;
                prevHeight = currHeight;
                currTexOffset += deltaTex;
                currRayZ -= layerHeight;
            }
        }
        return uvs.xy + currTexOffset;
    }

    inline half3 Rejection(half3 dir1,half3 dir2)
    {
        return  dir1 - ( ( dot( dir1 , dir2 ) / dot( dir2 , dir2 ) ) * dir2 ) ;
    }

    //////////////////////// Effect //////////////////////
    float4 FresnelSimple(half3 N,half3 V,float4 fresnelColor,half fresnelPower,half facing,half cull)
    {
        half3 N_fix = lerp(-1,1,saturate(cull - 1)) * N;
        half fixFace = lerp((1-facing) * 0.5, 1, saturate(cull));

        half NoV = saturate(dot(N_fix,V));

        float4 col = pow(1 - NoV , fresnelPower) * fixFace * fresnelColor;

        return col;
    }

    float4 Fresnel(half3 N,half3 V,float4 fresnelColor,half _FresnelMin,half _FresnelMax,half facing,half cull)
    {
        half3 N_fix = lerp(-1,1,saturate(cull - 1)) * N;
        half fixFace = lerp((1-facing) * 0.5, 1, saturate(cull));

        half NoV = saturate(dot(N_fix,V));

        float4 col = smoothstep(_FresnelMin, _FresnelMax, 1 - NoV) * fixFace * fresnelColor;

        return col;
    }

    float4 DoubleFresnel(half3 N,half3 V,half fresnelPower1,float4 fresnelColor1,half fresnelPower2,float4 fresnelColor2,half facing,half cull)
    {
        half3 N_fix = lerp(-1,1,saturate(cull - 1)) * N;
        half fixFace = lerp((1-facing) * 0.5, 1, saturate(cull));

        half fresnelTerm1 = saturate(pow(1 - saturate(dot(N_fix,V)),fresnelPower1));
        half fresnelTerm2 = saturate(pow(1 - saturate(dot(N_fix,V)),fresnelPower2));

        float4 col1 = fresnelTerm1 * fresnelColor1;
        float4 col = lerp(col1,fresnelColor2,fresnelTerm2);

        return col;
    }

    void DissolveSimple(
    half dissolveMap,half dissolveIntensity,half dissolveSoft,half dissolveEdgeWidth,float3 dissolveEdgeColor,
    inout float3 color,inout half alpha)
    {
        half dissolve_ammount = Remap(dissolveIntensity , half2(0,2) , half2(-dissolveSoft , 1));

        half dissolve = ((dissolveMap - dissolve_ammount) / dissolveSoft) * 2;
        alpha *= saturate(dissolve);

        half edge_factor = saturate(1.0 - (distance(dissolve , 0.5) / dissolveEdgeWidth));
        color = lerp(color,dissolveEdgeColor,edge_factor);
        
    }

    void DissolveGradientSphere(
    half dissolveMap,half dissolveIntensity,half dissolveSoft,half dissolveEdgeWidth,float3 dissolveEdgeColor,
    half4 dissolveDirAndSphere,float3 positionWS,
    float3 worldPos_pivol,float3 vertexOrigin,half noiseIntensity,half objectScale,half inverseSphere,
    inout float3 color,inout half alpha)
    {
        half dissolve_ammount = Remap(dissolveIntensity , half2(0,2) , half2(-dissolveSoft , 1));

        half3 dissolveDir = positionWS - worldPos_pivol;
        dissolveDir = mul(dissolveDir,dissolveDirAndSphere.xyz);

        half dissolveType = (dissolveDir.x + dissolveDir.y + dissolveDir.z) * (1 - dissolveDirAndSphere.w);

        half dissolveSpherePos = saturate(length((positionWS + vertexOrigin) - worldPos_pivol));

        half dissolveDir_sphere = dissolveType + lerp(dissolveSpherePos, 1 - dissolveSpherePos,inverseSphere) * dissolveDirAndSphere.w;
        dissolveDir_sphere = saturate(dissolveDir_sphere / max(objectScale,0.1) + 0.5);

        half dissolve = ((dissolveDir_sphere - dissolve_ammount) / dissolveSoft * 2) - (dissolveMap * noiseIntensity);
        alpha *= step(0.5,dissolve);

        half edge_factor = saturate(1.0 - (distance(dissolve , 0.5) / dissolveEdgeWidth));
        color = lerp(color,dissolveEdgeColor,edge_factor);
    }

#endif
