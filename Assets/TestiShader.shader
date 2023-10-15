Shader "Custom/TestiShader"
{
    Properties
    {
        [KeywordEnum(object space, world space, view space)]
        _SpaceKeyword("Space", Float) = 0
        _Color("Color", Color) = (1, 1, 1, 1) 
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
            Name "OmaPass"
            
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma shader_feature_local _SPACEKEYWORD_OBJECT_SPACE _SPACEKEYWORD_WORLD_SPACE _SPACEKEYWORD_VIEW_SPACE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalsSO : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normals : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            CBUFFER_END


            Varyings Vert(const Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);

                #if _SPACEKEYWORD_OBJECT_SPACE
                output.positionHCS = TransformObjectToHClip(input.positionOS + float3(0.f,1.f,0.f));
                #elif _SPACEKEYWORD_WORLD_SPACE
                const float3 positionWS = TransformObjectToWorld(input.positionOS) + float3(0.f,1.f,0.f);
                output.positionHCS = TransformWorldToHClip(positionWS);
                #elif _SPACEKEYWORD_VIEW_SPACE
                const float3 positionVS = TransformWorldToView(TransformObjectToWorld(input.positionOS));
                output.positionHCS = TransformWViewToHClip(positionVS + float4(0.f,1.f,0.f,1));
                #endif
                
                output.normals = input.normalsSO;
                
                return output;
            }

            float4 Frag(const Varyings input) : SV_TARGET
            {
                //return _Color * clamp(0, 1, input.positionWS.x);
                return float4( input.normals, 1);
            }
            
            ENDHLSL
        }
    }
}
