Shader "Hidden/Kronnect/SSR_URP" {
Properties {
    _BumpMap("Normal Map", 2D) = "bump" {}
    _SmoothnessMap("Smoothness Map", 2D) = "white" {}
    _Color("", Color) = (1,1,1)
    _NoiseTex("", any) = "" {}
    _SSRSettings("", Vector) = (1,1,1,1)
    _SSRSettings2("", Vector) = (1,1,1,1)
}

HLSLINCLUDE
    #pragma target 3.0
ENDHLSL


Subshader {	

    Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "DisableBatching"="True" "ForceNoShadowCasting"="True" }

    HLSLINCLUDE
    #pragma target 3.0
    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "SSR_Common.hlsl"
    ENDHLSL

  Pass { // 0: Copy exact
      ZWrite Off ZTest Always Cull Off
      HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragCopyExact
      #include "SSR_Blends.hlsl"
      ENDHLSL
  }

  Pass { // 1: Surface reflection
      HLSLPROGRAM
      #pragma vertex VertSSRSurf
      #pragma fragment FragSSRSurf
      #pragma multi_compile_local _ SSR_NORMALMAP
      #pragma multi_compile_local _ SSR_SMOOTHNESSMAP
      #pragma multi_compile_local _ SSR_JITTER
      #pragma multi_compile_local _ SSR_THICKNESS_FINE
      #include "SSR_Surface_Pass.hlsl"
      ENDHLSL
  }

  Pass { // 2 Resolve
      ZWrite Off ZTest Always Cull Off
      HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragResolve
      #include "SSR_Solve.hlsl"
      ENDHLSL
  }    

  Pass { // 3 Blur horizontally
      ZWrite Off ZTest Always Cull Off
      HLSLPROGRAM
      #pragma vertex VertBlur
      #pragma fragment FragBlur
      #pragma multi_compile_local _ SSR_DENOISE
      #define SSR_BLUR_HORIZ
      #include "SSR_Blur.hlsl"
      ENDHLSL
  }    
      
  Pass { // 4 Blur vertically
      ZWrite Off ZTest Always Cull Off
	  HLSLPROGRAM
      #pragma vertex VertBlur
      #pragma fragment FragBlur
      #pragma multi_compile_local _ SSR_DENOISE
      #include "SSR_Blur.hlsl"
      ENDHLSL
  }    

  Pass { // 5 Debug
      ZWrite Off ZTest Always Cull Off
      Blend One Zero
	  HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragCopyExact
      #include "SSR_Blends.hlsl"
      ENDHLSL
  }    

  Pass { // 6 Combine
      ZWrite Off ZTest Always Cull Off
      Blend One One // precomputed alpha in Resolve pass
	  HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragCombine
      #include "SSR_Blends.hlsl"
      ENDHLSL
  }

  Pass { // 7 Combine with compare
      ZWrite Off ZTest Always Cull Off
      Blend One One // precomputed alpha in Resolve pass
	  HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragCombineWithCompare
      #include "SSR_Blends.hlsl"
      ENDHLSL
  }

  Pass { // 8 Deferred pass
      ZWrite Off ZTest Always Cull Off
	  HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragSSR
      #pragma multi_compile_local _ SSR_JITTER
      #pragma multi_compile_local _ SSR_THICKNESS_FINE
      #pragma multi_compile _ _GBUFFER_NORMALS_OCT
      #include "SSR_GBuf_Pass.hlsl"
      ENDHLSL
  }

  Pass { // 9: Copy with bilinear filter
      ZWrite Off ZTest Always Cull Off
      HLSLPROGRAM
      #pragma vertex VertSSR
      #pragma fragment FragCopy
      #include "SSR_Blends.hlsl"
      ENDHLSL
  }

}
FallBack Off
}
