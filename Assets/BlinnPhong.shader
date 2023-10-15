Shader "Custom/BlinnPhong"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
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
            Name "OmaLightPass"
            
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
                float3 normalsOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD01;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _Shininess;
            CBUFFER_END


            Varyings Vert(const Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.normalWS = normalize(mul(input.normalsOS, unity_ObjectToWorld).xyz);
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS);
                
                return output;
            }

            float4 BlinnPhong(const Varyings input) : SV_TARGET
            {
                Light _Light = GetMainLight();

                half3 ambientLighting = _Light.color * 0.1f;
                half3 diffuseLighting = saturate(dot(input.normalWS, _Light.direction)) * _Light.color;
                half3 puolivalisektori = normalize(_Light.direction + GetWorldSpaceViewDir(input.positionWS));
                half3 specularLighting = pow(saturate(dot(input.normalWS, puolivalisektori)), _Shininess) * _Light.color;

                return float4((ambientLighting + diffuseLighting + specularLighting) * _Color, 1.f);
            }

            float4 Frag(const Varyings input) : SV_TARGET
            {
                return BlinnPhong(input);
            }
            
            ENDHLSL
        }
    }
}