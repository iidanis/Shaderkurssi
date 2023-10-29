Shader "Custom/TekstuuriShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SubTex ("Texture", 2D) = "white" {}
        _Blend ("Blend Value", Range(0,1)) = 0 
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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _SubTex_ST;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER (sampler_MainTex);
            TEXTURE2D (_SubTex);
            SAMPLER (sampler_SubTex);
            float _Blend;

            Varyings Vert(const Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                return output;
            }

            float4 Frag(const Varyings input) : SV_TARGET
            {
                
                float4 main = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float4 sub = SAMPLE_TEXTURE2D(_SubTex, sampler_SubTex, input.uv);

                float4 tex = lerp(main, sub, _Blend);
                return tex;
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
