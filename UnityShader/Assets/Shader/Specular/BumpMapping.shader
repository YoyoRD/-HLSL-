Shader "Custom/BumpMapping 法线贴图"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BumpTex("Bump", 2D) = "white" {}

        _BaseColor("Color",Color) = (1,1,1,1)
        _SpecularRange("SpecularRange",Range(10,300)) = 10
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;

        real4 _BaseColor;

        float _SpecularRange;

        real4 _SpecularColor;
        float4 _BumpTex_ST;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_BumpTex);
        SAMPLER(sampler_BumpTex);


        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float2 uv_MainTex:TEXCOORD0;
            float2 uv_BumpTex:TEXCOORD1;
            float4 tangent:TANGENT;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 normalWS:NORMAL;
            float2 uv_MainTex:TEXCOORD0;
            float2 uv_BumpTex:TEXCOORD1;
            float4 TW1:TEXCOORD2;
            float4 TW2:TEXCOORD3;
            float4 TW3:TEXCOORD4;
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
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS,true);
                float3 worldTrangent = TransformObjectToWorldDir(i.tangent.xyz);
                //副法线
                float3 worldBinormal = cross(o.normalWS, worldTrangent) * i.tangent.w;
                //o.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(i.positionOS.xyz));//得到世界空间的视图方向
                o.uv_MainTex = TRANSFORM_TEX(i.uv_MainTex, _MainTex);
                o.uv_BumpTex = TRANSFORM_TEX(i.uv_BumpTex, _BumpTex);

                o.TW1 = float4(worldTrangent.x, worldBinormal.x, o.normalWS.x, o.positionCS.x);
                o.TW2 = float4(worldTrangent.y, worldBinormal.y, o.normalWS.y, o.positionCS.y);
                o.TW3 = float4(worldTrangent.z, worldBinormal.z, o.normalWS.z, o.positionCS.z);
                return o;
            }

            half4 FRAG(v2f i) : SV_TARGET
            {
                /* 提取在顶点着色器中的数据 */
                float3x3 TW = float3x3(i.TW1.xyz,i.TW2.xyz,i.TW3.xyz);
                float3 worldPos = half3(i.TW1.w,i.TW2.w,i.TW3.w);

                /* 进行纹理采样 */
                float4 normalTex = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, i.uv_BumpTex);
                float3 bump = UnpackNormal(normalTex);
                bump = mul(TW, bump);             //将切线空间中的法线转换到世界空间中

                //float3 bumpW = normalize(half3(dot(i.TW1.xyz, bump), half3(dot(i.TW2.xyz, bump), half3(dot(i.TW3.xyz, bump)));
                //float3X3 rotation = float3X3(tangent.xyz,binormal ,normal);//变换矩阵   

                Light light = GetMainLight();
                float3 LightDirWS = normalize(light.direction);
                half3 albedo = _BaseColor.xyz * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv_MainTex).xyz * light.color.xyz;
                /*计算漫反射光照*/
                half3 lightDir = TransformObjectToWorldDir(light.direction);
                half3 diffuse = albedo * saturate(dot(lightDir, bump));

                /*计算Blinn-Phong高光*/
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                half3 halfDir = normalize(viewDir + lightDir);
                half3 specular = saturate(dot(halfDir, bump)) * albedo;

                return half4(diffuse + UNITY_LIGHTMODEL_AMBIENT.xyz * albedo + specular, 1);
            }
            ENDHLSL
        }
    }
}
