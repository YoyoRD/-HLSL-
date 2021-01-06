Shader "Custom/逐顶点漫反射光照"
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
            float3 color : TEXCOORD;
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
                Light light = GetMainLight();
                // C(diffuse) = C(light) * m(diffuse) max(0,n dot l)
                // n是法线 l 光照方向 m(diffuse) 材质表面漫反射颜色 C(light) 光源颜色
                // 注意n 是世界坐标下的法线
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                o.color = light.color * _Diffuse.rgb * saturate(dot(TransformObjectToWorldNormal(i.normal), light.direction));
                return o;
            }

            float3 FRAG(v2f i) :SV_TARGET
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}
