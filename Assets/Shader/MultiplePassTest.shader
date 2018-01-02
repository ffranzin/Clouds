
Shader "MultiplePassTest"
{
	Properties
	{
		_WeatherTex("Weather Texture", 2D) = "white" {}
	}

	SubShader
	{
		//No culling or depth
		Cull Off ZWrite Off ZTest Always
		
		
		Pass
		{
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
			sampler2D _MainTex;

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

	
			int int_test;
			float float_test;

			//////////////////////////////////////////////////
			//////////    Fragment Program   /////////////////
			//////////////////////////////////////////////////
			float4 CloudVolumeHighPS(clouds_v2f Input) : SV_Target
			{
				float2 uv = Input.uv;
				if(uv.x > .5)
					return fixed4(1, 0,0,1);

				return tex2D(_MainTex, uv);
			}
			ENDCG
		}
		
		Pass
		{ 
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
			sampler2D _MainTex;

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

	
			int int_test;
			float float_test;

			//////////////////////////////////////////////////
			//////////    Fragment Program   /////////////////
			//////////////////////////////////////////////////
			float4 CloudVolumeHighPS(clouds_v2f Input) : SV_Target
			{
				float2 uv = Input.uv;
				if(uv.y < .5)
					return fixed4(1, 1,0,1);
				return tex2D(_MainTex, uv);
			}
			ENDCG
		}

	}
}


/*

	float4 GetHeightGradient(float cloudType)
	{
		static const float4 STRATUS_GRADIENT = float4(0.02, 0.05, 0.09, 0.11);
		static const float4 STRATOCUMULUS_GRADIENT = float4(0.02, 0.2, 0.48, 0.625);
		static const float4 CUMULUS_GRADIENT = float4(0.01, 0.0625, 0.78, 1.0);

		float stratus = 1.0 - saturate(cloudType * 2.0);
		float stratocumulus = 1.0 - abs(cloudType - 0.5) * 2.0;
		float cumulus = saturate(cloudType - 0.5) * 2.0;
		return STRATUS_GRADIENT * stratus +STRATOCUMULUS_GRADIENT * stratocumulus + CUMULUS_GRADIENT * cumulus;
	}


	float GradientStep(float a, float4 gradient)
	{
		return smoothstep(gradient.x, gradient.y, a) - smoothstep(gradient.z, gradient.w, a);
	}
	*/
	