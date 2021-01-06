Shader "Custom/半兰伯特漫反射光照"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
    }

        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        half4 _Diffuse;

        struct a2v
        {
            float4 positionOS   : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 WorldNormal : NORMAL;
        };

        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.WorldNormal = TransformObjectToWorldNormal(i.normal);
                return o;
            }

            float3 FRAG(v2f i) :SV_TARGET
            {
                Light light = GetMainLight();
                // C(diffuse) = C(light) * m(diffuse)(0.5 (n dot l ) +0.5)
                // n是法线 l 光照方向 m(diffuse) 材质表面漫反射颜色 C(light) 光源颜色
                // 注意n 是世界坐标下的法线
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                half4 halfLamber = dot(i.WorldNormal, light.direction) * 0.5 + 0.5;

                return light.color * _Diffuse.rgb * halfLamber;
        }
        ENDHLSL
    }
    }
}
