Shader "Custom/IntersectionShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _IntersectionColor("Intersection Color", Color) = (0, 0, 1, 1)
    }
    SubShader
    {
        Tags
        { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "OmaTexturePass"
            
            Tags 
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            
            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment Frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _IntersectionColor;
            CBUFFER_END

            Varyings Vert(const Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                
                return output;
            }

            float4 Frag(Varyings input) : SV_TARGET
            {
                float2 screenspaceUV = GetNormalizedScreenSpaceUV(input.positionHCS);
                float4 sceneDepth = SampleSceneDepth(screenspaceUV);
                float4 linearEyeDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                float4 objectLinearEyeDepth = LinearEyeDepth(input.positionWS, UNITY_MATRIX_V);

                float4 lerpArvo = pow(1 - saturate(linearEyeDepth - objectLinearEyeDepth), 15);

                return lerp(_Color, _IntersectionColor, lerpArvo);
            }
            ENDHLSL
        }
    }
}
