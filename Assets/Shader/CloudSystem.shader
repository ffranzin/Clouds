
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
			sampler2D _Gradient;
			sampler2D _WeatherTex;
			sampler3D _NoiseTex;
			sampler3D _DetailNoiseTex;

			uniform float4 _CloudBaseColor;
			uniform float4 _CloudTopColor;

			uniform int _MaxSteps;
			uniform int cloudType;
			uniform float4 _HorizonParams;	//0.0f, 0.0f, 0.0f, HorizonMaxDistance
			uniform float4 _CloudParams; //CloudRay_MaxStepscale, LightRay_MaxStepscale, InscatteringCoff, ExtinctionCoff;
			uniform float4 _CloudHeight; //BottomCloudHeight, TopCloudHeight, CloudThickness, EarthRadius

			uniform float _Hg;
			uniform float _erode;
			uniform float _BaseNoiseTexUVScale;
			uniform float _DetailNoiseTexUVScale;
			uniform float _WeatherTexUVScale;
			uniform float _BaseNoiseScale;
			uniform float _NoiseThreshold;
			uniform float _NoiseMax;
			uniform float _CloudDensityScale;

			uniform float _AmbientLightIntensity;
			uniform float _SunLightIntensity;
			float4 _LightColor;

			uniform float3 VIEWER_DIR;
			uniform float3 VIEWER_POS;
			uniform float3 PLANET_CENTER;
			uniform float PLANET_RADIUS;
			uniform float CLOUD_HEIGHT_TOP;
			uniform float CLOUD_HEIGHT_BOTTOM;
			uniform float CLOUD_TRICKNESS;
			
			uniform float circleRadiusTest;
			uniform float4 circleTest;

			float4 lightDir;

			const float INFINITY = 1e15;
			const float3 RandomUnitSphere[6] =
			{
				{ 0.3, -0.8, -0.5 },
				{ 0.9, -0.3, -0.2 },
				{ -0.9, -0.3, -0.1 },
				{ -0.5, 0.5, 0.7 },
				{ -1.0, 0.3, 0.0 },
				{ -0.3, 0.9, 0.4 }
			};
	
			int int_test;
			float float_test;


			float Remap(float org_val,float org_min,float org_max,float new_min,float new_max)
			{
				return new_min + saturate(((org_val - org_min) / (org_max - org_min))*(new_max - new_min));
				return new_min + ((org_val - org_min) / (org_max - org_min))*(new_max - new_min);
			}

			float2 raySphereIntersect(float3 pos, float radius, float3 rayDir)
			{
				float3 dir = pos - PLANET_CENTER;
				float b = dot(rayDir, dir);
				float c = dot(dir, dir) - radius * radius;

				float Delta = b * b - c;

				if (Delta < 0.0)
				{
					return float2(-INFINITY, INFINITY);
				}

				Delta = sqrt(Delta);
				return float2(-b - Delta, -b + Delta);
			}


			float RayPlaneIntersect(float3 ro, float planeHeight)
			{
				float3 planeNormal = float3(0, 1, 0);
				float3 planeOrigin = float3(0, planeHeight, 0);
				float3 rayDir = VIEWER_DIR;

				float d = dot(rayDir, planeNormal);

				if (abs(d) > 1e-6)
				{
					float t = (dot(planeNormal, planeOrigin - ro)) / dot(planeNormal, rayDir);

					if (t >= 0)
						return t;
				}
				return INFINITY;
			}


			float3 AmbientLighting(float height)
			{
				return lerp(_CloudBaseColor.rgb, _CloudTopColor.rgb, height);
			}


			float PhaseHenyeyGreenStein(float angle, float g)
			{
				float g2 = g * g;

				return ((1 - g2) / pow((1.0 + g2 - 2.0 * g * cos(angle)), 1.5)) * .25;
			}


			float Beer(float opticalDepth)
			{
				return exp(-_CloudParams.w * 0.01 * opticalDepth);
			}


			float3 SampleWeather(float3 pos)
			{
				float2 unit = pos.xz / (_WeatherTexUVScale * 100000.0);

				float2 uv = unit * 0.5 + 0.5;

				return tex2Dlod(_WeatherTex, float4(uv, 1.0, 1.0));
			}


			bool IsInsideSphere(float3 pos)
			{
				float d = distance(float3(25000, 3000, 1000), pos);
				return d < circleRadiusTest  ? .9 : 0; 
			}



			float2 GetHitPlanarDistance(float3 eyePosition)
			{
				float bottom = RayPlaneIntersect(eyePosition, CLOUD_HEIGHT_BOTTOM);
				float top = RayPlaneIntersect(eyePosition, CLOUD_HEIGHT_TOP);

				float ch = length(eyePosition - PLANET_CENTER) - PLANET_RADIUS;

				if (ch < CLOUD_HEIGHT_BOTTOM)
					return float2(bottom, top);
				else if(ch > CLOUD_HEIGHT_TOP)	
					return float2(top, bottom);

				return float2(top, bottom);
			}


			float2 GetHitSphericalDistance(float3 eyePosition, float3 eyeDirection)
			{
				float2 CloudHitDistanceBottom = raySphereIntersect(eyePosition, PLANET_RADIUS + CLOUD_HEIGHT_BOTTOM, eyeDirection);
				float2 CloudHitDistanceTop = raySphereIntersect(eyePosition, PLANET_RADIUS + CLOUD_HEIGHT_TOP, eyeDirection);

				float2 CloudHitDistance;
		
				/// ** height of CameraPos and earthCenter
				float ch = length(eyePosition - PLANET_CENTER) - PLANET_RADIUS; /// ** distance of cameraPos to earthBorder

																				//if (abs(ch) == INFINITY)
																				//	clip(-1);

				if (ch < CLOUD_HEIGHT_BOTTOM) ///  **abaixo das nuvens
				{
					CloudHitDistance = float2(CloudHitDistanceBottom.y, CloudHitDistanceTop.y);
			
					//float h = eyePosition.y + PLANET_RADIUS;
					//if (VIEWER_DIR.y < 0.0f)
					//	clip(h * h * (1.0 - VIEWER_DIR.y * VIEWER_DIR.y) - PLANET_RADIUS * PLANET_RADIUS);

				}
				else if (ch > CLOUD_HEIGHT_TOP) ///  **acima das nuvens
				{
					if (CloudHitDistanceBottom.x > -INFINITY)
						CloudHitDistance = float2(CloudHitDistanceTop.x, CloudHitDistanceBottom.x);
					else
						CloudHitDistance = float2(0.0, -1.0);//not hit
				}
				/*
				else /// **Position between bottom and top of clouds
				{
					if (CloudHitDistanceBottom.x < 0.0)
						CloudHitDistance = float2(0.0, CloudHitDistanceTop.y);  //hit top cloud only
					else
						CloudHitDistance = float2(0.0, CloudHitDistanceBottom.x);  //hit bottom cloud only
				}
				*/
				return CloudHitDistance;
			}

		
			float SampleCloud(float3 pos, float height, float3 weatherData, bool sampleDetail)
			{
				const float baseFreq = 1e-6;
				float4 coord = float4(pos * baseFreq * _BaseNoiseTexUVScale, 0.0);

				float4 baseNoise = tex3Dlod(_NoiseTex, coord);

				float baseFbm = dot(baseNoise.gba, float3(0.625, 0.25, 0.125));

				float cloudDensity = baseNoise.r;
		
				cloudDensity = Remap(cloudDensity, 1-baseFbm, 1.0, 0.0, 1.0);
		
				//cloudDensity = Remap(cloudDensity, weatherData.b, 1, 0, 1);

				float coverage = weatherData.b;
		
				coverage = pow(coverage, Remap(height, .7, 1, .8, lerp(1, .1, float_test)));

				cloudDensity *= coverage;

				float gradient = tex2Dlod(_Gradient, float4(((cloudType *.3)), height, 0, 0)).r;
		
				cloudDensity *= gradient;
		
				cloudDensity = Remap(cloudDensity, 0, _NoiseThreshold, 0.0, 1.0);
		
				if (sampleDetail && cloudDensity > 0)
				{
					coord = float4(pos * baseFreq * _erode * _DetailNoiseTexUVScale * 100, 0.0);

					float3 detailNoise = tex3Dlod(_DetailNoiseTex, coord).rgb;

					float detailFbm = dot(detailNoise, float3(0.625, 0.25, 0.125));
			
					float detailCloudDensity = lerp(detailFbm, 1.0 - detailFbm, saturate(height * 12.0));
			
					detailCloudDensity = 1.0 - detailFbm;
			
					cloudDensity = Remap(cloudDensity, detailCloudDensity, 1.0, 0.0, 1.0);
				}

				return saturate(_CloudDensityScale * cloudDensity);
			}


			//Retorna um valor entre 0-1, sendo 0 proximo a CLOUD_HEIGHT_BOTTOM e 1 CLOUD_HEIGHT_TOP
			float CalcHeight(float3 pos)
			{
				float distPos_Ground = distance(pos, PLANET_CENTER) - PLANET_RADIUS;

				float h = distPos_Ground - CLOUD_HEIGHT_BOTTOM; // distancia entre o pixel ate a borda inferior da nuvem

				return saturate(h / CLOUD_TRICKNESS);
			}



			float3 SampleLight(float3 pos, float3 LightDirection, float3 LightColor, float inScatteringAngle)
			{
				const int _MaxSteps = 6;
				float sunRayStepLength = (CLOUD_TRICKNESS * CLOUD_HEIGHT_TOP) / ((float)_MaxSteps);
				float3 sunRayStep = LightDirection * sunRayStepLength;
				pos += 0.5 * sunRayStep;

				float opticalDepth = 0.0;

				for (int i = 0; i < _MaxSteps; i++)
				{
					float3 randomOffset = RandomUnitSphere[i] * sunRayStepLength * 0.25 * ((float)(i + 1));

					float3 samplePos = pos + randomOffset;

					float height = CalcHeight(samplePos);

					float3 weatherData = SampleWeather(samplePos);

					float cloudDensity = SampleCloud(samplePos, height, weatherData, true);

					opticalDepth += cloudDensity * sunRayStepLength;

					pos += sunRayStep;
				}

				float hg = PhaseHenyeyGreenStein(inScatteringAngle, _Hg);

				float extinct = Beer(opticalDepth);

				return LightColor * extinct * hg;
			}



			float SampleShadow(float3 uvPos, float3 depth)
			{
				float _MaxSteps = 30;

				float3 dir = normalize(lightDir);

				float2 CloudHitDistance = GetHitSphericalDistance(uvPos, dir);

				float3 pos = uvPos + (CloudHitDistance.x * dir);
		
				float rayStepLength = abs((CloudHitDistance.y - CloudHitDistance.x) / _MaxSteps);

				float3 rayStep = dir * rayStepLength;

				float opticalDepth = 0;

				for (int i = 0; i < _MaxSteps; i++)
				{
					float height = CalcHeight(pos);

					float3 weatherData = SampleWeather(pos);

					float cloudDensity = SampleCloud(pos, height, weatherData, true);
					
					float currentOpticalDepth = cloudDensity * rayStepLength * _CloudParams.z;

					opticalDepth += currentOpticalDepth;

					pos += rayStep;
				}

				return opticalDepth;
			}



			bool IsBelowBottomCloud(float3 pos)
			{
				return true;
				float distPos_Ground = distance(pos, PLANET_CENTER)- PLANET_RADIUS;

				return distPos_Ground < CLOUD_HEIGHT_BOTTOM ? true : false;
			}



			inline float3 UvToWorld(float3 camPos, float3 interpolatedRay, float depth)
			{
				float3 wsDir = depth * interpolatedRay;
				float3 wsPos = camPos + wsDir;

				return wsPos;
			}

			
			//////////////////////////////////////////////////
			//////////    Fragment Program   /////////////////
			//////////////////////////////////////////////////
			float4 CloudVolumeHighPS(clouds_v2f Input) : SV_Target
			{
				float2 uv = Input.uv;
				float3 ray = Input.interpolatedRay;

				float depth01 = Linear01Depth(DecodeFloatRG(tex2D(_CameraDepthTexture, uv)));
				float depth =  LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv)));
		
				float3 uvWorldPos = UvToWorld(_WorldSpaceCameraPos, ray, depth01);
				float3 LightDirection	= -normalize(lightDir);
				float3 LightColor		= _LightColor.xyz;

				//return fixed4(LightDirection, 1);

				VIEWER_DIR = normalize(Input.ray);
				VIEWER_POS = _WorldSpaceCameraPos;

				CLOUD_HEIGHT_BOTTOM = _CloudHeight.x;
				CLOUD_HEIGHT_TOP	= _CloudHeight.y;
				CLOUD_TRICKNESS		= _CloudHeight.z;
				PLANET_RADIUS		= _CloudHeight.w;
				PLANET_CENTER		= float3(0, -PLANET_RADIUS, 0); //-Pl_radius to avoid high float

				float2 CloudHitDistance = GetHitSphericalDistance(VIEWER_POS, VIEWER_DIR);
				

				if(IsInsideSphere(uvWorldPos) > 0)
					return fixed4(1,0,0,1);



				//this is only to clouds, unused to shadows
				if((depth - CloudHitDistance.x < 0) && (uvWorldPos.y - CLOUD_HEIGHT_BOTTOM < 0))
					clip(-1);

				float inScatteringAngle = dot(VIEWER_DIR, LightDirection);

				float rayStepLength = abs((CloudHitDistance.y - CloudHitDistance.x) / _MaxSteps);

				float3 rayStep = VIEWER_DIR * rayStepLength;

				float3 pos = VIEWER_POS + (CloudHitDistance.x * VIEWER_DIR);	
		
				clip(pos.y);
		
				float extinct = 1.0;

				float opticalDepth = 0.0;

				float4 color = 0.0;
				float4 color1 = 0.0;

				if(IsBelowBottomCloud(uvWorldPos)) 
				{
					if(SampleShadow(uvWorldPos, depth) > 1)
						color1 = tex2D(_MainTex, uv) + float4(.2,0,0,.2);
				}
		
				for (int i = 0; i < _MaxSteps; i++)
				{
					float height = CalcHeight(pos);

					if (extinct < 0.01)	break;

					float3 weatherData = SampleWeather(pos);

					float cloudDensity = SampleCloud(pos, height, weatherData, true);
					
					if (cloudDensity > 0.01)
					{
						float transmittance = 1 - (opticalDepth * (1 / CLOUD_TRICKNESS));

						float3 ambientLight = AmbientLighting(height) * transmittance;

						float3 sunLight = SampleLight(pos, LightDirection, LightColor, inScatteringAngle);

						float currentOpticalDepth = cloudDensity * rayStepLength * _CloudParams.z;

						ambientLight *= _AmbientLightIntensity * 0.01 * currentOpticalDepth;
				
						sunLight *= _SunLightIntensity * currentOpticalDepth;

						opticalDepth += currentOpticalDepth;

						extinct = Beer(opticalDepth);

						color.rgb += (ambientLight + sunLight) * extinct;
					}

					pos += rayStep;
				}

				if(opticalDepth == 0 && depth01 < 1)
					return color1;
		
				color.a = 1.0 - Beer(opticalDepth);

				float horizonFade = (1 - saturate(5 / PLANET_RADIUS));
				color *= horizonFade;
				return fixed4(color);
			}
			ENDCG
		}
	}
}



/*


		Pass
		{
			Stencil {
			Ref 1
			Comp Equal
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment CloudVolumeHighPS
			#pragma enable_d3d11_debug_symbols

			#include "UnityCG.cginc"\

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

			float4 CloudVolumeHighPS(clouds_v2f Input) : SV_Target
			{
				return fixed4(1,0,0,1);
			}
		}
		ENDCG

*/



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
	