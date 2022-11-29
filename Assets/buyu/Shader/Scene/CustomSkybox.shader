// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
//https://blog.csdn.net/chenggong2dm/article/details/123506670
Shader "WB/CustomSkybox" {
Properties {
    _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
    [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
    _Rotation ("Rotation", Range(0, 360)) = 0
    [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
    _SkyDirection("SkyDirection", Vector) = (0,0,1,1)
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    Pass {
        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
    CBUFFER_START(UnityPerMaterial)
        half _Exposure;
        half _Rotation;
        half3 _SkyDirection;
        half4 _Tex_HDR;
        half4 _Tint;
    CBUFFER_END
        samplerCUBE _Tex;
        // 计算函数 
        half4x4 rotationMatrix(half3 axis, half angle)
        {
            axis = normalize(axis);
            half s = sin(angle);
            half c = cos(angle);
            half oc = 1.0 - c;

            return half4x4(oc * axis.x * axis.x + c,
                oc * axis.x * axis.y - axis.z * s,
                oc * axis.z * axis.x + axis.y * s,
                0.0,
                oc * axis.x * axis.y + axis.z * s,
                oc * axis.y * axis.y + c,
                oc * axis.y * axis.z - axis.x * s,
                0.0,
                oc * axis.z * axis.x - axis.y * s,
                oc * axis.y * axis.z + axis.x * s,
                oc * axis.z * axis.z + c,
                0.0,
                0.0, 0.0, 0.0, 1.0);
        }

#define unity_ColorSpaceDouble half4(4.59479380, 4.59479380, 4.59479380, 2.0)
        inline half3 DecodeHDR(half4 data, half4 decodeInstructions)
        {
            // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
            half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;
#   if defined(UNITY_USE_NATIVE_HDR)
            return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
#   else
            return (decodeInstructions.x * pow(abs(alpha), decodeInstructions.y)) * data.rgb;
#   endif
        }


        struct appdata_t {
            half4 vertex : POSITION;
        };

        struct v2f {
            half4 vertex : SV_POSITION;
            half3 texcoord : TEXCOORD0;
        };

        v2f vert (appdata_t v)
        {
            v2f o;
            half3 rotated = mul(rotationMatrix(normalize(_SkyDirection.xyz), _Rotation * 3.14159265359f / 180.0), v.vertex).xyz;
            half3 positionWS = TransformObjectToWorld(rotated);
            o.vertex = TransformWorldToHClip(positionWS);
            o.texcoord = v.vertex.xyz;
            return o;
        }

        half4 frag (v2f i) : SV_Target
        {
            half4 tex = texCUBE (_Tex, i.texcoord);
            half3 c = DecodeHDR (tex, _Tex_HDR);
            c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
            c *= _Exposure;
            return half4(c, 1);
        }
        ENDHLSL
    }
}
Fallback Off
}
