/// <summary>
/// Shiny SSRR - Screen Space Reflections for URP - (c) 2021 Kronnect
/// </summary>

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ShinySSRR {

    public enum OutputMode {
        Final,
        OnlyReflections,
        SideBySideComparison
    }

    public enum RaytracingPreset {
        Fast = 10,
        Medium = 20,
        High = 30,
        Superb = 35,
        Ultra = 40
    }

    public class ShinySSRR : ScriptableRendererFeature {

        class SSRPass : ScriptableRenderPass {

            enum Pass {
                CopyExact = 0,
                SSRSurf = 1,
                Resolve = 2,
                BlurHoriz = 3,
                BlurVert = 4,
                Debug = 5,
                Combine = 6,
                CombineWithCompare = 7,
                GBuffPass = 8,
                Copy = 9
            }

            const string SHINY_CBUFNAME = "Shiny_SSRR";
            const float GOLDEN_RATIO = 0.618033989f;
            ScriptableRenderer renderer;
            Material sMat;
            Texture noiseTex;
            ShinySSRR settings;
            readonly Plane[] frustumPlanes = new Plane[6];
            const int MIP_COUNT = 5;
            int[] rtPyramid;

            public void Setup(ScriptableRenderer renderer, ShinySSRR settings) {
                this.renderer = renderer;
                this.settings = settings;
                this.renderPassEvent = settings.renderPassEvent;
                if (sMat == null) {
                    Shader shader = Shader.Find("Hidden/Kronnect/SSR_URP");
                    sMat = CoreUtils.CreateEngineMaterial(shader);
                }
                if (noiseTex == null) {
                    noiseTex = Resources.Load<Texture>("SSR/blueNoiseSSR64");
                }
                sMat.SetTexture(ShaderParams.NoiseTex, noiseTex);

                // set global settings
                sMat.SetVector(ShaderParams.SSRSettings2, new Vector4(settings.jitter, settings.contactHardening, settings.reflectionsMultiplier, settings.vignetteSize));
                sMat.SetVector(ShaderParams.SSRSettings4, new Vector4(settings.separationPos, settings.reflectionsMinIntensity, settings.reflectionsMaxIntensity, settings.specularSoftenPower));
                sMat.SetVector(ShaderParams.SSRBlurStrength, new Vector4(settings.blurStrength.x, settings.blurStrength.y, 0, 0));
                if (settings.specularControl) {
                    sMat.EnableKeyword(ShaderParams.SKW_DENOISE);
                } else {
                    sMat.DisableKeyword(ShaderParams.SKW_DENOISE);
                }
                sMat.SetFloat(ShaderParams.MinimumBlur, settings.minimumBlur);

                if (settings.useDeferred) {
                    if (settings.jitter > 0) {
                        sMat.EnableKeyword(ShaderParams.SKW_JITTER);
                    } else {
                        sMat.DisableKeyword(ShaderParams.SKW_JITTER);
                    }
                    if (settings.refineThickness) {
                        sMat.EnableKeyword(ShaderParams.SKW_REFINE_THICKNESS);
                        sMat.SetFloat(ShaderParams.SSRSettings5, settings.thicknessFine * settings.thickness);
                    } else {
                        sMat.DisableKeyword(ShaderParams.SKW_REFINE_THICKNESS);
                    }
                    sMat.SetVector(ShaderParams.SSRSettings, new Vector4(settings.thickness, settings.sampleCount, settings.binarySearchIterations, settings.maxRayLength));
                    sMat.SetVector(ShaderParams.MaterialData, new Vector4(0, settings.fresnel, settings.fuzzyness, settings.decay));
                }

                if (rtPyramid == null || rtPyramid.Length != MIP_COUNT) {
                    rtPyramid = new int[MIP_COUNT];
                    for (int k = 0; k < rtPyramid.Length; k++) {
                        rtPyramid[k] = Shader.PropertyToID("_BlurRTMip" + k);
                    }
                }
            }



            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {

                Camera cam = renderingData.cameraData.camera;

                // ignore SceneView depending on setting
                if (cam.cameraType == CameraType.SceneView) {
                    if (!settings.showInSceneView) return;
                } else {
                    // ignore any camera other than GameView
                    if (cam.cameraType != CameraType.Game) return;
                }

                RenderTextureDescriptor sourceDesc = renderingData.cameraData.cameraTargetDescriptor;
                sourceDesc.colorFormat = settings.lowPrecision ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGBHalf;
                sourceDesc.width /= settings.downsampling;
                sourceDesc.height /= settings.downsampling;
                sourceDesc.msaaSamples = 1;

                float goldenFactor = GOLDEN_RATIO;
                if (settings.animatedJitter) {
                    goldenFactor *= (Time.frameCount % 480);
                }
                Shader.SetGlobalVector(ShaderParams.SSRSettings3, new Vector4(sourceDesc.width, sourceDesc.height, goldenFactor, settings.depthBias));

                CommandBuffer cmd = null;
                RenderTargetIdentifier source = renderer.cameraColorTarget;

                if (settings.useDeferred) {
                    // init command buffer
                    cmd = CommandBufferPool.Get(SHINY_CBUFNAME);

                    // pass UNITY_MATRIX_V
                    sMat.SetMatrix(ShaderParams.WorldToViewDir, cam.worldToCameraMatrix);

                    // prepare ssr target
                    cmd.GetTemporaryRT(ShaderParams.RayCast, sourceDesc, FilterMode.Point);

                    // raytrace using gbuffers
                    FullScreenBlit(cmd, source, ShaderParams.RayCast, Pass.GBuffPass);

                } else {

                    // early exit if no reflection objects
                    int count = Reflections.instances.Count;
                    if (count == 0) return;

                    bool firstSSR = true;

                    GeometryUtility.CalculateFrustumPlanes(cam, frustumPlanes);

                    for (int k = 0; k < count; k++) {
                        Reflections go = Reflections.instances[k];
                        if (go == null) continue;
                        int rendererCount = go.ssrRenderers.Count;
                        for (int j = 0; j < rendererCount; j++) {
                            Reflections.SSR_Renderer ssrRenderer = go.ssrRenderers[j];
                            Renderer goRenderer = ssrRenderer.renderer;

                            if (goRenderer == null || !goRenderer.isVisible) continue;

                            // if object is part of static batch, check collider bounds (if existing)
                            if (goRenderer.isPartOfStaticBatch) {
                                if (ssrRenderer.hasStaticBounds) {
                                    // check artifically computed bounds
                                    if (!GeometryUtility.TestPlanesAABB(frustumPlanes, ssrRenderer.staticBounds)) continue;
                                } else if (ssrRenderer.collider != null) {
                                    // check if object is visible by current camera using collider bounds
                                    if (!GeometryUtility.TestPlanesAABB(frustumPlanes, ssrRenderer.collider.bounds)) continue;
                                }
                            } else {
                                // check if object is visible by current camera using renderer bounds
                                if (!GeometryUtility.TestPlanesAABB(frustumPlanes, goRenderer.bounds)) continue;
                            }

                            if (!ssrRenderer.isInitialized) {
                                ssrRenderer.Init(sMat);
                                ssrRenderer.UpdateMaterialProperties(go, settings);
                            }
#if UNITY_EDITOR
                        else if (!Application.isPlaying) {
                                ssrRenderer.UpdateMaterialProperties(go, settings);
                            }
#endif
                            if (ssrRenderer.exclude) continue;

                            if (firstSSR) {
                                firstSSR = false;

                                // init command buffer
                                cmd = CommandBufferPool.Get(SHINY_CBUFNAME);

                                // prepare ssr target
                                cmd.GetTemporaryRT(ShaderParams.RayCast, sourceDesc, FilterMode.Point);
                                cmd.SetRenderTarget(ShaderParams.RayCast, 0, CubemapFace.Unknown, -1);
                                cmd.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));
                            }
                            for (int s = 0; s < ssrRenderer.ssrMaterials.Length; s++) {
                                if (go.subMeshMask <= 0 || ((1 << s) & go.subMeshMask) != 0) {
                                    Material ssrMat = ssrRenderer.ssrMaterials[s];
                                    cmd.DrawRenderer(goRenderer, ssrMat, s, (int)Pass.SSRSurf);
                                }
                            }
                        }
                    }

                    if (firstSSR) return;
                }


                // Resolve reflections
                RenderTextureDescriptor copyDesc = sourceDesc;
                copyDesc.depthBufferBits = 0;

                cmd.GetTemporaryRT(ShaderParams.ReflectionsTex, copyDesc);
                FullScreenBlit(cmd, source, ShaderParams.ReflectionsTex, Pass.Resolve);
                RenderTargetIdentifier input = ShaderParams.ReflectionsTex;

                // Pyramid blur
                copyDesc.width /= settings.blurDownsampling;
                copyDesc.height /= settings.blurDownsampling;
                for (int k = 0; k < MIP_COUNT; k++) {
                    copyDesc.width = Mathf.Max(2, copyDesc.width / 2);
                    copyDesc.height = Mathf.Max(2, copyDesc.height / 2);
                    cmd.GetTemporaryRT(rtPyramid[k], copyDesc, FilterMode.Bilinear);
                    cmd.GetTemporaryRT(ShaderParams.BlurRT, copyDesc, FilterMode.Bilinear);
                    FullScreenBlit(cmd, input, ShaderParams.BlurRT, Pass.BlurHoriz);
                    FullScreenBlit(cmd, ShaderParams.BlurRT, rtPyramid[k], Pass.BlurVert);
                    cmd.ReleaseTemporaryRT(ShaderParams.BlurRT);
                    input = rtPyramid[k];
                }

                // Output
                int finalPass;
                if (settings.outputMode == OutputMode.Final) {
                    finalPass = (int)Pass.Combine;
                } else if (settings.outputMode == OutputMode.SideBySideComparison) {
                    finalPass = (int)Pass.CombineWithCompare;
                } else {
                    finalPass = (int)Pass.Debug;
                }
                FullScreenBlit(cmd, ShaderParams.ReflectionsTex, source, (Pass)finalPass);

                if (settings.stopNaN) {
                    RenderTextureDescriptor nanDesc = renderingData.cameraData.cameraTargetDescriptor;
                    nanDesc.depthBufferBits = 0;
                    nanDesc.msaaSamples = 1;
                    cmd.GetTemporaryRT(ShaderParams.NaNBuffer, nanDesc);
                    FullScreenBlit(cmd, source, ShaderParams.NaNBuffer, Pass.CopyExact);
                    FullScreenBlit(cmd, ShaderParams.NaNBuffer, source, Pass.CopyExact);
                }

                // Clean up
                for (int k = 0; k < rtPyramid.Length; k++) {
                    cmd.ReleaseTemporaryRT(rtPyramid[k]);
                }
                cmd.ReleaseTemporaryRT(ShaderParams.ReflectionsTex);
                cmd.ReleaseTemporaryRT(ShaderParams.RayCast);

                context.ExecuteCommandBuffer(cmd);

                CommandBufferPool.Release(cmd);
            }

            void FullScreenBlit(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier destination, Pass pass) {
                cmd.SetRenderTarget(destination, 0, CubemapFace.Unknown, -1);
                cmd.SetGlobalTexture(ShaderParams.MainTex, source);
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, sMat, 0, (int)pass);
            }

            /// Cleanup any allocated resources that were created during the execution of this render pass.
            public override void FrameCleanup(CommandBuffer cmd) {
            }


            public void Cleanup() {
                CoreUtils.Destroy(sMat);
            }
        }

        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        [Tooltip("Use deferred g-buffers (requires deferred rendering in URP 12 or later)")]
        public bool useDeferred;

        [Header("General Settings")]

        [Tooltip("Show reflections in SceneView window")]
        public bool showInSceneView = true;

        [Tooltip("Downsampling multiplier applied to the final blurred reflections")]
        [Range(1, 8)] public int downsampling = 1;

        [Tooltip("Bias applied to depth checking. Increase if reflections desappear at the distance when downsampling is used")]
        [Min(0)] public float depthBias = 0.01f;

        [Tooltip("Show final result / debug view or compare view")]
        public OutputMode outputMode = OutputMode.Final;

        [Tooltip("Position of the dividing line")]
        [Range(-0.01f, 1.01f)] public float separationPos = 0.5f;

        [Tooltip("HDR reflections")]
        public bool lowPrecision;

        [Tooltip("Prevents out of range colors when composing reflections in the destination buffer. This operation performs a ping-pong copy of the frame buffer which can be expensive. Use only if required.")]
        public bool stopNaN;

        [Tooltip("Max number of samples used during the raymarch loop")]
        [Range(4, 128)] public int sampleCount = 16;

        [HideInInspector]
        public float stepSize; // no longer used; kept for backward compatibility during upgrade

        [Tooltip("Maximum reflection distance")]
        public float maxRayLength;

        [Tooltip("Assumed thickness of geometry in the depth buffer before binary search")]
        public float thickness = 0.2f;

        [Tooltip("Number of refinements steps when a reflection hit is found")]
        [Range(0, 16)] public int binarySearchIterations = 6;

        [Tooltip("Increase accuracy of reflection hit after binary search by discarding points further than a reduced thickness.")]
        public bool refineThickness;

        [Tooltip("Assumed thickness of geometry in the depth buffer after binary search")]
        [Range(0.005f, 1f)]
        public float thicknessFine = 0.05f;

        [Tooltip("Jitter helps smoothing edges")]
        [Range(0, 1f)] public float jitter = 0.3f;

        [Tooltip("Animates jitter every frame")]
        public bool animatedJitter = true;

        [Header("Reflection Intensity")]

        [Tooltip("Reflection multiplier")]
        [Range(0, 2)]
        public float reflectionsMultiplier = 1f;

        [Tooltip("Reflection min intensity")]
        [Range(0, 1)]
        public float reflectionsMinIntensity;

        [Tooltip("Reflection max intensity")]
        [Range(0, 1)]
        public float reflectionsMaxIntensity = 1f;

        [Range(0, 1)]
        [Tooltip("Reduces reflection based on view angle")]
        public float fresnel = 0.75f;

        [Tooltip("Reflection decay with distance to reflective point")]
        public float decay = 2f;

        [Tooltip("Reduces intensity of specular reflections")]
        public bool specularControl;

        [Min(0), Tooltip("Power of the specular filter")]
        public float specularSoftenPower = 15f;

        [Tooltip("Controls the attenuation range of effect on screen borders")]
        [Range(0.5f, 2f)]
        public float vignetteSize = 1.1f;

        [Header("Reflection Sharpness")]

        [Min(0)]
        [Tooltip("Ray dispersion with distance")]
        public float fuzzyness;

        [Tooltip("Makes sharpen reflections near objects")]
        public float contactHardening;

        [Range(0, 4f)]
        [Tooltip("Produces sharper reflections based on distance")]
        public float minimumBlur = 0.25f;

        [Tooltip("Downsampling multiplier applied to the blur")]
        [Range(1, 8)] public int blurDownsampling = 1;

        [Tooltip("Custom directional blur strength")]
        public Vector2 blurStrength = Vector2.one;

        SSRPass renderPass;
        public static bool installed;

        public static bool isDeferredActive;

        public static bool isEnabled = true;


        void OnDisable() {
            installed = false;
            if (renderPass != null) {
                renderPass.Cleanup();
            }
        }

        public override void Create() {
            if (maxRayLength == 0) {
                maxRayLength = Mathf.Max(0.1f, stepSize * sampleCount);
            }
            if (renderPass == null) {
                renderPass = new SSRPass();
            }
            installed = true;
        }

        private void OnValidate() {
            decay = Mathf.Max(1f, decay);
            if (maxRayLength == 0) {
                maxRayLength = stepSize * sampleCount;
            }
            maxRayLength = Mathf.Max(0.1f, maxRayLength);
            fuzzyness = Mathf.Max(0, fuzzyness);
            thickness = Mathf.Max(0.01f, thickness);
            thicknessFine = Mathf.Max(0.01f, thicknessFine);
            contactHardening = Mathf.Max(0, contactHardening);
            reflectionsMaxIntensity = Mathf.Max(reflectionsMinIntensity, reflectionsMaxIntensity);
            blurStrength.x = Mathf.Max(blurStrength.x, 0f);
            blurStrength.y = Mathf.Max(blurStrength.y, 0f);
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
            if (!isEnabled) return;
            isDeferredActive = useDeferred;
            renderPass.Setup(renderer, this);
            renderer.EnqueuePass(renderPass);
            installed = true;
        }


        public void ApplyRaytracingPreset(RaytracingPreset preset) {
            switch (preset) {
                case RaytracingPreset.Fast:
                    sampleCount = 16;
                    maxRayLength = 6;
                    binarySearchIterations = 4;
                    downsampling = 3;
                    thickness = 0.5f;
                    refineThickness = false;
                    jitter = 0.3f;
                    break;
                case RaytracingPreset.Medium:
                    sampleCount = 24;
                    maxRayLength = 12;
                    binarySearchIterations = 5;
                    downsampling = 2;
                    refineThickness = false;
                    break;
                case RaytracingPreset.High:
                    sampleCount = 48;
                    maxRayLength = 24;
                    binarySearchIterations = 6;
                    downsampling = 1;
                    refineThickness = false;
                    thicknessFine = 0.05f;
                    break;
                case RaytracingPreset.Superb:
                    sampleCount = 88;
                    maxRayLength = 48;
                    binarySearchIterations = 7;
                    downsampling = 1;
                    refineThickness = true;
                    thicknessFine = 0.02f;
                    break;
                case RaytracingPreset.Ultra:
                    sampleCount = 128;
                    maxRayLength = 64;
                    binarySearchIterations = 8;
                    downsampling = 1;
                    refineThickness = true;
                    thicknessFine = 0.02f;
                    break;
            }
        }
    }

}
