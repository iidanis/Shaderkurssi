Shader "Custom/3010"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Texture", 2D) = "white" {}
        _Shininess ("Shininess", Float) = 1
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

            struct Attributes
            {
                float3 positionOS : POSITION;
                float4 tangentOS : TANGENT;
                float3 normalsOS : NORMAL;
                float4 bitangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 tangentWS : TEXCOORD1;
                float3 normalsWS : TEXCOORD2;
                float3 bitangentWS : TEXCOOD3;
                float2 uv : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float4 _Color;
            float _Shininess;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER (sampler_MainTex);
            TEXTURE2D (_NormalMap);
            SAMPLER (sampler_NormalMap);

            Varyings Vert(const Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS);

                const VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS);
                const VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalsOS, input.tangentOS);

                output.positionHCS = posInputs.positionCS;
                output.normalsWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;
                output.bitangentWS = normalInputs.bitangentWS;
                output.positionWS = posInputs.positionWS; // <--- ei tarvitse

                output.uv = input.uv;
                
                return output;
            }

            float4 BlinnPhong(const Varyings input, float4 color) : SV_TARGET
            {
                Light _Light = GetMainLight();

                half3 ambientLighting = _Light.color * 0.1f;
                half3 diffuseLighting = saturate(dot(input.normalsWS, _Light.direction)) * _Light.color;
                half3 puolivalisektori = normalize(_Light.direction + GetWorldSpaceViewDir(input.positionWS));
                half3 specularLighting = pow(saturate(dot(input.normalsWS, puolivalisektori)), _Shininess) * _Light.color;

                return float4((ambientLighting + diffuseLighting + specularLighting) * _Color, 1.f);
            }

            float4 Frag(const Varyings input) : SV_TARGET
            {
                Light _Light = GetMainLight();
                const float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(input.uv, _MainTex));
                const float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                const float3x3 tangentToWorld = float3x3(input.tangentWS, input.bitangentWS, input.normalsWS);
                
                const float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld, true);

                return kissa;
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
