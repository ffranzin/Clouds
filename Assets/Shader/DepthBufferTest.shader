Shader "Custom/Shader" {
	Properties {
		
		_BaseShape ("Texture", 3D) = "white" {}
		_ShapeDetail ("Texture", 3D) = "white" {}
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always
		Blend One OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 3.0
			uniform sampler2D _CameraDepthTexture;
			uniform fixed _DepthLevel;


			#include	"UnityCG.cginc"
			
			struct appdata
			{
				float4 vert : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vert : SV_POSITION;
				float2 depth : TEXCOORD1;
			};


			v2f vert(appdata IN)
			{
				v2f OUT;
				OUT.vert = UnityObjectToClipPos(IN.vert);
				OUT.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, IN.uv);
				return OUT;
			}
			

			float4 frag(v2f IN) : SV_Target
			{
				float2 uv = IN.uv;

				float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uv));

				depth = LinearEyeDepth(depth);

				if(depth < 3)
					return fixed4(1, 0, 0, 1);
				
				if (depth < 10)
					return fixed4(0, 1, 0, 1);
				
				clip(-1);
			
				return fixed4(0,0,1, 1);
			}
		
			ENDCG
		}
	}
	
}

