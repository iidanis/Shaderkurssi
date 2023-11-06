Shader "Custom/oikeaunityshader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [MainTexture] _BaseMap("Base Map", 2D) = "white" { }
        [NoScaleOffset] [Normal] _NormalMap("Normal Map", 2D) = "bump" { }
        [NoScaleOffset] _RoughnessMap("Roughness Map", 2D) = "white" { }
        [NoScaleOffset] _OcclusionMap("Ambient Occlusion Map", 2D) = "white" { }
        [NoScaleOffset] _MetallicMap("Metallic Map", 2D) = "black" { }
        [NoScaleOffset] _ParallaxMap ("Parallax Map", 2D) = "black" { }
        _Shininess ("Shininess", Float) = 1
        _ParallaxStrength ("Parallax Strength", Range(0, 5)) = 0
        _BaseColor("Base Color", Color) = (1, 1, 1, 1) 
    }
    SubShader
    {
        Tags
        { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "OmaTexturePass"
            
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment Frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv0 :TEXCOORD0;
                float2 uv1 :TEXCOORD1;
                float2 uv2 :TEXCOORD2;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                half  fogFactor : TEXCOORD4;
                half3 viewDirTS : TEXCOORD5;
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, sh, 6);
                #if defined(DYNAMICLIGHTMAP_ON)
                float2  dynamicLightmapUV : TEXCOORD7;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float4 _BaseMap_ST;
            float4 _ParallaxMap_ST;
            float4 _BaseColor;
            float _Shininess;
            float _ParallaxStrength;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER (sampler_MainTex);
            TEXTURE2D (_NormalMap);
            SAMPLER (sampler_NormalMap);
            TEXTURE2D (_BaseMap);
            SAMPLER (sampler_BaseMap);
            TEXTURE2D (_ParallaxMap);
            SAMPLER (sampler_ParallaxMap);

            TEXTURE2D (_MetallicMap);
            SAMPLER (sampler_MetallicMap);

            TEXTURE2D (_OcclusionMap);
            SAMPLER (sampler_OcclusionMap);

            TEXTURE2D (_RoughnessMap);
            SAMPLER (sampler_RoughnessMap);

            Varyings Vert(const Attributes input)
            {
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                VertexPositionInputs vertPos = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs vertNormals = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionHCS = vertPos.positionCS;
                output.positionWS = vertPos.positionWS;
                output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);

                output.normalWS = vertNormals.normalWS;
                output.tangentWS = float4(vertNormals.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());

                half fogFactor = 0;
                #if !defined(_FOG_FRAGMENT)
                fogFactor = ComputeFogFactor(input.positionHCS.z);
                #endif
                
                const half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertPos.positionWS);
                const half3 viewDirTS = GetViewDirectionTangentSpace(output.tangentWS, output.normalWS, viewDirWS);
                output.viewDirTS = viewDirTS;
                
                OUTPUT_LIGHTMAP_UV(input.uv1, unity_LightmapST, output.staticLightmapUV);
                #if defined(DYNAMICLIGHTMAP_ON)
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                OUTPUT_SH(output.normalWS.xyz, output.sh);
                output.fogFactor = fogFactor;
                return output;
            }

            // Perus tekstuurin sämpläys
            half4 SampleColor(const float2 uv) {
                return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
            }

            // Normaalin sämpläys
            half3 SampleNormal(const float2 uv) {
                return UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv));
            }

            half3 SampleMetallic(const float2 uv) {
                return SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, uv);
            }

            half3 SampleRoughness(const float2 uv) {
                return SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, uv);
            }

            half3 SampleOcclusion(const float2 uv) {
                return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv);
            }

            // Parallax offsetin funktio
            void ApplyPerPixelDisplacement(const half3 viewDirTS, inout float2 uv) {
                uv += ParallaxOffset1Step(SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, uv).r, _ParallaxStrength * 0.1, viewDirTS);
            }

            void InitializeInputData(const Varyings input, const half3 normalTS, out InputData inputData) {
                inputData = (InputData)0;
                inputData.positionWS = input.positionWS;

                const half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                const float sgn = input.tangentWS.w;      // should be either +1 or -1
                const float3 bitangentWS = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                const half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangentWS.xyz, input.normalWS.xyz);
                inputData.tangentToWorld = tangentToWorld;
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = viewDirWS;

                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);

                #if defined(DYNAMICLIGHTMAP_ON)
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
                #else
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.sh, inputData.normalWS);
                #endif

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionHCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
            }

            void InitializeSurfaceData(const float2 uv, out SurfaceData surfaceData) {
                surfaceData = (SurfaceData)0;
                half4 albedo = SampleColor(uv);
                surfaceData.alpha = albedo.a * _BaseColor.a;
                surfaceData.albedo = albedo.rgb * _BaseColor.rgb;
                surfaceData.albedo = AlphaModulate(surfaceData.albedo, surfaceData.alpha);
                surfaceData.metallic = SampleMetallic(uv);
                surfaceData.smoothness = 1 - SampleRoughness(uv);
                surfaceData.normalTS = SampleNormal(uv);
                surfaceData.occlusion = SampleOcclusion(uv);
            }

            half4 Frag(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                ApplyPerPixelDisplacement(input.viewDirTS, input.uv);

                SurfaceData surfaceData;
                InitializeSurfaceData(input.uv, surfaceData);

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                color.a = OutputAlpha(color.a, false);
                
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Depth"
            Tags { "LightMode" = "DepthOnly" }
            
            Cull Back
            ZTest LEqual
            ZWrite On
            ColorMask R
            
            HLSLPROGRAM
            
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
             // PITÄÄ OLLA RELATIVE PATH TIEDOSTOON!!!
             #include "DepthPass.hlsl"
             ENDHLSL
        }

        Pass
        {
            Name "Normals"
            Tags { "LightMode" = "DepthNormalsOnly" }
            
            Cull Back
            ZTest LEqual
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex DepthNormalsVert
            #pragma fragment DepthNormalsFrag

            #include "DepthNormalsPass.hlsl"
            
            ENDHLSL
        }
    }
}

