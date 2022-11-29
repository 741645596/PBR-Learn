#ifndef VOLUMELIGHT_INCLUDE
#define VOLUMELIGHT_INCLUDE

    #include "MeshSpotVolumeLightInput.hlsl"
	#define UNITY_PI     3.14159265359f

    void ConeIntersect(float3 ro, float3 rd, float3 pa, float3 pb, float ra, float rb,
       out float4 frontResoult, out float4 backResoult,out bool resFront,out bool resBack){
        float3 ba = pb - pa;
        float3 oa = ro - pa;
        float3 ob = ro - pb;
        float m0 = dot(ba, ba);
        float m1 = dot(oa, ba);
        float m2 = dot(rd, ba);
        float m3 = dot(rd, oa);
        float m5 = dot(oa, oa);
        float m9 = dot(ob, ba);

        float3 retA=oa * m2 - rd * m1;
        if( m1<0.0 && dot(retA,retA)< (ra * ra * m2 * m2)){
            float3 v3 = -ba * (1.0/sqrt(m0));
            frontResoult= float4(-m1 / m2, v3.x, v3.y, v3.z);
            backResoult = frontResoult;
            resFront=true;
            resBack=true;
            return;
        }

        float ta = -m9 / m2;
        retA=ob + rd * ta;
        if( m9>0.0 && dot(retA,retA)<(rb * rb) ){
            float3 v3 = ba * (1.0/sqrt(m0));
            frontResoult = float4(ta, v3.x, v3.y, v3.z);
            backResoult = frontResoult;
            resFront=true;
            resBack=true;
            return;
        }

        // body
        float rr = ra - rb;
        float hy = m0 + rr * rr;
        float k2 = m0 * m0 - m2 * m2 * hy;
        float k1 = m0 * m0 * m3 - m1 * m2 * hy + m0 * ra * (rr * m2 * 1.0f);
        float k0 = m0 * m0 * m5 - m1 * m1 * hy + m0 * ra * (rr * m1 * 2.0f - m0 * ra);
        float h = k1 * k1 - k2 * k0;

        if (h < 0.0)
        {
            frontResoult = float4(-1.0, -1.0, -1.0, -1.0); //no intersection
            backResoult = frontResoult;
            resFront=false;
            resBack=false;
            return;
        }

        float t = (-k1 - sqrt(h)) / k2;
        float y = m1 + t * m2;
        if (y < 0.0 || y > m0)
        {
            frontResoult = float4(-1.0, -1.0, -1.0, -1.0); //no intersection
            resFront=false;
        }
        else
        {
            float3 resV3 = m0 * (m0 * (oa + t * rd) + rr * ba * ra) - ba * hy * y;
            resV3 = normalize(resV3);
            frontResoult = float4(t, resV3.x, resV3.y, resV3.z);
            resFront=true;
        }

        t= (sqrt(h) - k1) / k2;
        y = m1 - ra * rr + t * m2;
        if (y < 0.0 || y > m0)
        {
            backResoult= float4(-1.0f, -1.0f, -1.0f, -1.0f); //no intersection
            resBack=false;
        }
        else
        {
            float3 resV3 = m0 * (m0 * (oa + t * rd) + rr * ba * ra) - ba * hy * y;
            resV3 =normalize(resV3);
            backResoult = float4(t, resV3.x, resV3.y, resV3.z);
            resBack=true;
        }
    }

    float InScatter(float3 start, float3 rd, float3 lightPos, float d,float strenght)
    {
        float3 q = start - lightPos;
        float b = dot(rd, q);
        float c = dot(q, q);
        float iv = strenght / sqrt(c - b*b);
        float l = iv * (atan( (d + b) * iv) - atan( b*iv ));
        return l;
    }

    void PointPanelRelation(float3 posWS, float3 panel1, float3 panel2, float3 panel3){
        if(posWS.x==panel1.x && posWS.y==panel1.y && posWS.z==panel1.z){
            clip(-1);
        }
        float3 v1 = panel2 - panel1;
        float3 v2 = panel3 - panel1;
        float3 v3 = posWS - panel1;
        float3 panelNor = cross(v1, v2);
        float dotValue = dot(v3, panelNor);
        clip(dotValue);
    }

    float DisPointToPanel(float3 posWS, float3 panel1, float3 panel2, float3 panel3){
        float3 n1 =normalize(cross(panel2 - panel1, panel3 - panel1));
        float3 v3;
        if (posWS.x==panel1.x && posWS.y==panel1.y && posWS.z==panel1.z) { 
            v3 = posWS - panel2; 
        }
        else { 
            v3 = posWS - panel3; 
        }
        float dotValue = dot(v3, n1);
        return abs(dotValue);
    }

    Varyings Vertex (Attritubes i)
    {
        Varyings o=(Varyings)0;
        UNITY_SETUP_INSTANCE_ID(i);
	    UNITY_TRANSFER_INSTANCE_ID(i, o);
        o.uv = i.uv;
        o.posWS = TransformObjectToWorld(i.positionOS.xyz);
        o.positionCS = TransformWorldToHClip(o.posWS);
        o.projection = ComputeScreenPos(o.positionCS);
        o.projection.z = -TransformWorldToView(o.posWS.xyz).z;
        o.normal = TransformObjectToWorldDir(i.normal);
        return o;
    }

    half4 FragSpotVolumeLight (Varyings i,float dotCLLerp)
    {
        float lightRange = GET_PROP(_OffsetY);
        float3 lightWorldPos = GET_PROP(_LightWorldPos);
        float3 lightForDir = GET_PROP(_LightForDir);
        float meshAngCos = GET_PROP(_CosAnB);
        float3 camForDir = GET_PROP(_CamForDir);
        float depthEdge = GET_PROP(_DepthEdge);
        //
        float3 cullPlantPointA=GET_PROP(_CullPlantPointA);
        float3 cullPlantPointB=GET_PROP(_CullPlantPointB);
        float3 cullPlantPointC=GET_PROP(_CullPlantPointC);
        float3 depthPlantPointA=GET_PROP(_DepthPlantPointA);
        float3 depthPlantPointB=GET_PROP(_DepthPlantPointB);
        float3 depthPlantPointC=GET_PROP(_DepthPlantPointC);

        //平面剪裁
        #if defined(_ENBLE_CULLPLANT)
            PointPanelRelation(i.posWS, cullPlantPointA, cullPlantPointB, cullPlantPointC);
        #endif

        //顶点距离衰减
        float disVertexToLight =distance(lightWorldPos,i.posWS);
        half maxMeshLength=lightRange*GET_PROP(_LengthScale);
        disVertexToLight=clamp(disVertexToLight,0,maxMeshLength);
        i.lerpValue=1.0-disVertexToLight/maxMeshLength;
        i.lerpValue=i.lerpValue*i.lerpValue;

        //相机距离衰减
        float camDisAttenuation=distance(_WorldSpaceCameraPos,i.posWS);
        camDisAttenuation = smoothstep(_ProjectionParams.y, _ProjectionParams.y+1.0, camDisAttenuation);
        i.lerpValue=i.lerpValue*camDisAttenuation;

        //深度衰减部分
        float2 screenUV = i.projection.xy / i.projection.w; 
        float rawDepth=SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(screenUV)).r; 
        float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams) - _ProjectionParams.g;
        sceneZ = max(0, sceneZ);
        float partZ = max(0, i.projection.z - _ProjectionParams.g);
        float depthAttenuation =abs(sceneZ - partZ)*depthEdge;
        depthAttenuation=clamp(depthAttenuation,0,1);

        //平面剪裁衰减
        #if defined(_ENBLE_CULLPLANT)
            float cullPlantDis = DisPointToPanel(i.posWS, cullPlantPointA, cullPlantPointB, cullPlantPointC);
            cullPlantDis=abs(cullPlantDis)*depthEdge;
            cullPlantDis=clamp(cullPlantDis,0,1);
            depthAttenuation=min(depthAttenuation,cullPlantDis);
        #endif

        //平面衰减
        #if defined(_ENBLE_DEPTHPLANT)
            float depthPlantDis = DisPointToPanel(i.posWS, depthPlantPointA, depthPlantPointB, depthPlantPointC);
            depthPlantDis=abs(depthPlantDis)*depthEdge;
            depthPlantDis=clamp(depthPlantDis,0,1);
            depthAttenuation=min(depthAttenuation,depthPlantDis);
        #endif

        //half4 res = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

        //相机类型 正交：w=1.0 3D：w=0.0
        half cameraIsOrtho = unity_OrthoParams.w;

        //视线计算
        float3 camRayDirFirst = normalize(i.posWS- _WorldSpaceCameraPos);
        float3 camRayDir=lerp(camRayDirFirst,camForDir,cameraIsOrtho);
        float3 startPosWS=_WorldSpaceCameraPos;
        startPosWS=lerp(startPosWS,i.posWS-camForDir,cameraIsOrtho);

        //圆锥内部背面处理
        float3 lightToVertexDir=normalize(i.posWS-lightWorldPos);
        float camRayDotVertex=dot(camRayDir,lightToVertexDir);
        float rayDotLightToVertex=1.0-camRayDotVertex;
        rayDotLightToVertex=lerp(1.0,rayDotLightToVertex,dotCLLerp);
        i.lerpValue=i.lerpValue*rayDotLightToVertex;
        depthAttenuation=depthAttenuation*rayDotLightToVertex;

        //圆锥交点
        float4 frontResoult=float4(0.0,0.0,0.0,0.0);
        float4 backResoult=float4(0.0,0.0,0.0,0.0); //,out bool resFront,out bool resBack
        bool resFront = false;
        bool resBack = false;
        ConeIntersect(startPosWS, camRayDir, GET_PROP(_ConeIntersectPA), GET_PROP(_ConeIntersectPB), GET_PROP(_ConeIntersectRA), GET_PROP(_ConeIntersectRB),frontResoult, backResoult,resFront,resBack);
        if(!resFront && !resBack){
            return half4(0,0,0,0);
        }
        //第一个交点
        float3 frontPoint;
        float3 frontPointNormal;
        if(resFront){
            //第一个交点和法线
            frontPoint=startPosWS+camRayDir*frontResoult.x;
            frontPointNormal=frontResoult.yzw;
        }else{
            frontPoint = startPosWS.xyz;
            frontPointNormal=float3(0,0,1.0);
        }
        //第二个交点
        float3 backPoint;
        float3 backPointNormal;
        if(resBack){
            //第二个交点和法线
            float d = backResoult.x-distance(startPosWS,frontPoint);
            d=min(d,lightRange);
            d=max(0,d);
            backPoint=frontPoint+camRayDir*d;
            backPointNormal=backResoult.yzw;
        }else{
            backPoint=frontPoint+camRayDir*lightRange;
            backPointNormal=float3(0,0,1.0);
        }

        //光强积分
        float disFrontToBack=distance(frontPoint,backPoint);
        float dis=disFrontToBack*GET_PROP(_Density);
        float scatter = InScatter(frontPoint, camRayDir, lightWorldPos, dis,1);

        //边缘衰减
        float3 dirLightToFront=normalize(frontPoint-lightWorldPos);
        float centerAng=acos(dot(dirLightToFront,normalize(backPoint-lightWorldPos)))*0.5;
        float3 dirFrontToBack=normalize(backPoint-frontPoint);
        float cosOAB = dot(-dirLightToFront,dirFrontToBack);
        float cosOAB2=sqrt(1.0-cosOAB*cosOAB);
        float tan1=tan(centerAng);
        float tan2 = cosOAB2/cosOAB;
        float xc = tan1*distance(lightWorldPos,frontPoint);
        xc=xc/(1+tan1/tan2);
        float ac=xc/cosOAB2;
        ac=clamp(ac,0,disFrontToBack*0.5);
        float3 centorAB = frontPoint + dirFrontToBack*ac;
        float cosAnA=dot(normalize(centorAB-lightWorldPos),lightForDir);
        float edge = 1.0 - saturate((1.0 - cosAnA) / (1.0 - meshAngCos));


        //看向灯光处理
        //float nDotCamRay=dot(-i.normal,camRayDir);
        //nDotCamRay=clamp(nDotCamRay,0,1);
        float nDotCamRay = i.lerpValue;
        camRayDir = normalize(_WorldSpaceCameraPos - lightWorldPos);
        camRayDir=lerp(camRayDir,-camForDir,cameraIsOrtho);
        float lightDotCamRay=dot(lightForDir,camRayDir);
        float meshAngCosSmall = meshAngCos;
        meshAngCosSmall=meshAngCosSmall*0.985;
        meshAngCosSmall=clamp(meshAngCosSmall,0.0,1.0);
        float edgeBackLerp=smoothstep(meshAngCosSmall,meshAngCos, lightDotCamRay);
        edgeBackLerp=edgeBackLerp*edgeBackLerp;
        edgeBackLerp=edgeBackLerp*edgeBackLerp;

        float edgeBack =lerp(edge,nDotCamRay,edgeBackLerp);
        edge=lerp(edge,edgeBack,dotCLLerp);

        //看向灯光处理
        float backCos=-camRayDotVertex;
        backCos=smoothstep(0.0, 1.0, backCos);
        backCos=backCos*backCos;
        float scatterBack=lerp(scatter,1.0,edgeBackLerp)*i.lerpValue;
        scatter=lerp(scatter,scatterBack,dotCLLerp);

        //结果混合
        scatter=saturate(scatter*edge*i.lerpValue)*depthAttenuation;
        half4 resColor=half4(scatter,scatter,scatter,scatter);
        resColor = resColor*GET_PROP(_LightBlendColor)*GET_PROP(_LightColor)*GET_PROP(_LightIntensity)*GET_PROP(_Intensity);
        return resColor;
    }

    half4 FragSpotVolumeLightPlant (Varyings i){
        #if defined(_ENBLE_ANGOUTCLOSE)
            return half4(0,0,0,0);
        #endif

        float3 lightWorldPos=GET_PROP(_LightWorldPos);
        float lightRange = GET_PROP(_OffsetY);
        float3 lightForDir = GET_PROP(_LightForDir);
        float cosAngIn = GET_PROP(_CosAngIn);
        float cosAngOut = GET_PROP(_CosAngOut);
        half4 lightColor = GET_PROP(_LightColor);
        half lightIntensity = GET_PROP(_LightIntensity);

        float3 vertexDir = normalize(i.posWS-lightWorldPos);
        float disVertexToLight = distance(i.posWS,lightWorldPos);
        disVertexToLight=clamp(disVertexToLight,0,lightRange);
        float lerpValue=1.0-disVertexToLight/lightRange;
        lerpValue=pow(lerpValue,16);
        float vertexDotLight = dot(lightForDir,vertexDir);

        #if defined(_ENBLE_ANGOUT)
            float dotOut = smoothstep(cosAngOut, cosAngIn, vertexDotLight);
            dotOut=dotOut*dotOut;
            return dotOut*lerpValue*lightColor*lightIntensity;
        #elif defined(_ENBLE_ANGIN)
            float inOffset=min(0.1,(1.0-cosAngIn)*0.1);
            float dotIn = smoothstep(cosAngIn, cosAngIn+inOffset, vertexDotLight);
            return dotIn*lerpValue*lightColor*lightIntensity;
        #elif defined(_ENBLE_ANGOUTIN)
            float dotOut = smoothstep(cosAngOut, cosAngIn, vertexDotLight);
            dotOut=dotOut*dotOut;
            float inOffset=min(0.1,(1.0-cosAngIn)*0.1);
            float dotIn = smoothstep(cosAngIn, cosAngIn+inOffset, vertexDotLight);
            return max(dotIn,dotOut)*lerpValue*lightColor*lightIntensity;
        #else
            return half4(0,0,0,0);
        #endif
    }

    float3 PointToLineTarget(float3 pointInput, float3 linePoint1, float3 linePoint2)
    {
        float3 dir2ToPoint= pointInput-linePoint2;
        float3 dir1To2 = normalize(linePoint2-linePoint1);
        float dotValue=dot(dir2ToPoint,dir1To2);
        return linePoint2+dir1To2*dotValue;
    }

    #define Deg2Rad 0.0174532924

    #define Rad2Deg 57.29578

    bool GetPoint(float3 lineA1, float3 lineA2, float3 lineB1, float3 lineB2,out float3 pointOutPut,out float3 yyyy)
    {
        pointOutPut = float3(0,0,0);
        float3 nA = normalize(lineA2 - lineA1);
        float3 nB = normalize(lineB2 - lineB1);
        if (distance(nA,nB)==0 || distance(nA,-nB)==0 ) {
            return false;
        }
        else{
            float3 p1 = lineA1;
            float3 p2 = lineA2; 
            float3 p3 = lineB1;
            if(distance(p3,p1)==0 || distance(p3,p2)==0){
                p3 = lineB2;
            }
            float3 n1 = normalize(cross((p3 - p1), (p3 - p2)));

            //yyyy=distance(p3,p2);


            p1 = lineB1;
            p2 = lineB2;
            p3 = lineA1;
            if(distance(p3,p1)==0 || distance(p3,p2)==0){
                p3 = lineA2;
            }
            float3 n2 = normalize(cross((p3 - p1), (p3 - p2)));


            yyyy=0;
            //return true;

            float d =clamp(abs(dot(n1,n2)),0,1.0);
            if (d > 0.9999) {
                pointOutPut = PointToLineTarget(lineA1, lineB1, lineB2);
                if (distance(pointOutPut,lineA1)!=0){
                    p1 = lineA1;
                    p2 = PointToLineTarget(p1, lineB1, lineB2);
                    if (distance(p2,p1)){
                        p1 = lineA2;
                        nA = -nA;
                    }
                    float dis = distance(p2, p1);
                    float cosAng = dot((p2 - p1), nA);
                    float ang = acos(cosAng)*Rad2Deg;
                    if (ang == 180) {
                        //垂直
                        pointOutPut = p2;
                        return true;
                    }
                    else if (ang > 90){
                        nA = -nA;
                        ang = 180 - ang;
                    }
                    float len = dis / cos(ang * Deg2Rad);
                    pointOutPut = p1 + nA * len;
                    return true;
                }else{
                    return false;
                }
            }
            else {
                return false;
            }
        }
        return false;
    }

    half4 FragCylinderVolumeLightPlant (Varyings i){

        //光柱的面
        float3 cylinderPlantA =  GET_PROP(_CylinderPlantA);
        float3 cylinderPlantB =  GET_PROP(_CylinderPlantB);
        float3 cylinderPlantC =  GET_PROP(_CylinderPlantC);
        float cylinderRadius = GET_PROP(_CylinderRadius);
        float cylinderLength = GET_PROP(_CylinderLength);
        float3 cylinderForDir = GET_PROP(_CylinderForDir);
        float cylinderIntensity = GET_PROP(_CylinderIntensity);

        float attenuation;

        float3 startPoint=i.posWS+normalize(_WorldSpaceCameraPos-i.posWS);
        float3 endPoint=i.posWS-normalize(_WorldSpaceCameraPos-i.posWS);
        //计算交点
        float3 point1 = startPoint;
        float3 point2 =endPoint;
        float3 n1 = normalize(cross(cylinderPlantB-cylinderPlantA,cylinderPlantC-cylinderPlantA));
        float3 v3;
        float disPoint1=distance(point1,cylinderPlantA);

        if(disPoint1==0){
            v3=point1-cylinderPlantB;
        }else{
            v3=point1-cylinderPlantC;
        }
        float dotPoint=dot(v3,n1);
        point1 = point1 - dotPoint * n1;


        float disPoint2=distance(point2,cylinderPlantA);
        if(disPoint2==0){
            v3=point2-cylinderPlantB;
        }else{
            v3=point2-cylinderPlantC;
        }
        dotPoint=dot(v3,n1);
        point2 = point2 - dotPoint * n1;
        
        //边缘衰减
        float disRadius=0;
        float disPoint12 = distance(point1,point2);
        if(disPoint12==0){
            disRadius=distance(cylinderPlantA,point1);
        }else{
            float len = dot((cylinderPlantA - point1), normalize(point2 - point1));
            float len2 = distance(cylinderPlantA, point1);
            len=min(len2*0.9999,len);
            if(len==0){
                disRadius = len2;
            }else{
                disRadius = sqrt(len2 * len2 - len * len);
            }
        }

        ////计算交点
        //if(disRadius<cylinderRadius){
        //    //float3 pointX1=startPoint;
        //    //float3 pointX2=endPoint;
        //    float3 pointA1=point1;
        //    float3 pointA2=cylinderForDir+pointA1;
        //    float3 pointB1=point2;
        //    float3 pointB2=cylinderForDir+pointB1;

        //    float3 yyyy;
        //    float3 resPointA;
        //    bool resPointABl = GetPoint(pointA1, pointA2, startPoint, endPoint,resPointA,yyyy);

        //    float3 resPointB;
        //    bool resPointBBl = GetPoint(pointB1, pointB2, startPoint, endPoint,resPointB,yyyy);

        //    if(resPointABl && resPointBBl){
        //            return distance(resPointA,resPointB);
        //    } 
        //}

        disRadius=(cylinderRadius-disRadius);
        disRadius=clamp(disRadius,0,cylinderRadius)/cylinderRadius;

        //float d= abs(dot(normalize(i.posWS-_WorldSpaceCameraPos),cylinderForDir));
        //float scatter = InScatter(i.posWS, normalize(i.posWS-_WorldSpaceCameraPos), cylinderPlantA,lerp(disRadius,disRadius*10.0,d),1.0);
        //return scatter;

        float bc = 1.0-disRadius;
        float oc=sqrt(1.0+bc*bc);
        float cosAng=1.0/oc;
        float sinAng=bc/oc;
        float edge = 1.0 - saturate((1.0 - cosAng) / (1.0 - 1.0/sqrt(2.0)));
        edge=pow(edge,2);
        attenuation=edge;

        //距离衰减
        float disVertexToStart = distance(cylinderPlantA,i.posWS);
        disVertexToStart=clamp(disVertexToStart,0,cylinderLength);
        disVertexToStart=1.0-disVertexToStart/cylinderLength;
        float vertexDotDir=dot(normalize(i.posWS-cylinderPlantA),cylinderForDir);
        vertexDotDir=smoothstep(0.0, 0.5, vertexDotDir);
        vertexDotDir=vertexDotDir*vertexDotDir;
        disVertexToStart=disVertexToStart*vertexDotDir;
        attenuation=attenuation*disVertexToStart*cylinderIntensity;
        attenuation=attenuation*attenuation;

        return attenuation;
    }

#endif
