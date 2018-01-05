
/*
					TODO

	-Shadow (see shadow texture )
	-Height map
	-UI


*/



Shader "CloudSystem"
{
	Properties
	{
		_WeatherTex("Weather Texture", 2D) = "white" {}
	}

	SubShader
	{
		//No culling or depth
		Cull Off ZWrite Off ZTest Always
		Blend One OneMinusSrcAlpha

		Pass
		{
			Stencil {
			Ref 0
			Comp Equal
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment CloudVolumeHighPS
			#pragma enable_d3d11_debug_symbols

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			struct clouds_v2f
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
				float3 interpolatedRay : TEXCOORD2;
			};

			float4x4 _InverseProjection;
			float4x4 _InverseRotation;

			inline float3 UVToCameraRay(float2 uv)
			{
				float4 cameraRay = float4(uv * 2.0 - 1.0, 1.0, 1.0);
				cameraRay = mul(_InverseProjection, cameraRay);
				cameraRay = cameraRay / cameraRay.w;

				return mul((float3x3)_InverseRotation, cameraRay.xyz);
			}

			clouds_v2f vert(appdata v)
			{
				clouds_v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				o.ray = UVToCameraRay(o.uv);
				o.interpolatedRay = v.ray.xyz;
				return o;
			}


			uniform sampler2D _CameraDepthTexture;

			sampler2D _MainTex;
			uniform float3 VIEWER_DIR;
			uniform float3 VIEWER_POS;

			float4 lightDir;


			inline float3 UvToWorld(float3 camPos, float3 interpolatedRay, float depth)
			{
				float3 wsDir = depth * interpolatedRay;
				float3 wsPos = camPos + wsDir;

				return wsPos;
			}


			bool IsinsideSphere(float3 pos, float3 center,float3 dir, float radius)
			{
				int steps = 1400;
				
				for(int i=0; i<steps; i++)
				{
					pos -= dir/4;
					if(distance(pos, center) < radius)
						return true;
				}

				return false;
			}

			bool test(float3 pos, float radius, float3 rayDir, float3 center)
			{
				return distance(pos, center) < radius * radius ? true : false;
			}



			float4 CloudVolumeHighPS(clouds_v2f Input) : SV_Target
			{
				float2 uv = Input.uv;
				float3 ray = Input.interpolatedRay;

				float depth01 = Linear01Depth(DecodeFloatRG(tex2D(_CameraDepthTexture, uv)));
				float depth =  LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv)));
				
				float3 uvWorldPos = UvToWorld(_WorldSpaceCameraPos, ray, depth01);
				float3 LightDirection	= -normalize(lightDir);


				VIEWER_DIR = normalize(Input.ray);
				VIEWER_POS = _WorldSpaceCameraPos;


				if(IsinsideSphere(uvWorldPos, float3(0,1,0), VIEWER_DIR, 1))
					return fixed4(1,0,0,1);

				
				if(depth01 < 1 && test(uvWorldPos, 1, LightDirection, float3(0,1,0)))
					return fixed4(0,0,1,1);
				

				float4 color = 0.0;
				return fixed4(color);
			}
			ENDCG
		}


	}
}
