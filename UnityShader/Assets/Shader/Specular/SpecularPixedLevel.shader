Shader "Custom/逐像素高光反射光照"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1) //控制高光反射颜色
        _Gloss("Gloss",Range(10,300)) = 20 //高光区域大小
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
        half4 _Specular;
        float _Gloss;

        struct a2v
        {
            float4 positionOS   : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
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
                o.worldNormal = TransformObjectToWorldNormal(i.normal);
                o.worldPos = TransformObjectToWorld(i.positionOS);
                return o;
            }

            float3 FRAG(v2f i) :SV_TARGET
            {
                Light light = GetMainLight();
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldDir = normalize(light.direction);

                // C(diffuse) = C(light) * m(diffuse) max(0,n dot l)
                // n是法线 l 光照方向 m(diffuse) 材质表面漫反射颜色 C(light) 光源颜色
                // 注意n 是世界坐标下的法线
                float3 diffuseColor = light.color * _Diffuse.rgb * saturate(dot(worldNormal, light.direction));

                // C(spscular) = (C(light) * m(spscular))max(0,v dot r) m(gloss)
                // m(gloss) 是材质的反光度 越大 亮点越小
                // m(spscular) 高光反射颜色
                float3 reflectDir = normalize(reflect(-light.direction, worldNormal));

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(i.worldPos));

                // phong 模型
                //float3 spscularColor = light.color * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                // blinn-phong
                float3 halfDir = normalize(light.direction + viewDir);
                float3 spscularColor = light.color * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)), _Gloss);


                return diffuseColor + spscularColor;
            }
            ENDHLSL
        }
    }
}
