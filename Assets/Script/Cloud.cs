using UnityEngine;
using System.Collections;


[ExecuteInEditMode]
public class Cloud : MonoBehaviour {

    //public Material mat;
    [SerializeField]
    public Shader _EffectShader;
    public Material EffectMaterial
    {
        get
        {
            if (!_EffectMaterial && _EffectShader)
            {
                _EffectMaterial = new Material(_EffectShader);
                _EffectMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _EffectMaterial;
        }
    }
    public Material _EffectMaterial;

    public GameObject light;

    public float EarthRadius = 58500.0f;
    public float BottomCloudHeight = 1700.0f;
    public float TopCloudHeight = 4300.0f;
    float HorizonMaxDistance = 30000.0f;
    
    public int MaxSteps = 512;
    [Range(1, 3)]
    public int cloudType = 2;
    
    public float CloudRayStepScale = 1.0f;
	public float LightRayStepScale = 1.0f;

	public float InscatteringCoff = 1.0f;
	public float ExtinctionCoff = 10.0f;
    [Range(-1,0)]
	public float Hg = -0.7f;

	public float BaseNoiseTexUVScale = 0.1f;
	public float DetailNoiseTexUVScale = 1.0f;
	public float WeatherTexUVScale = 1.0f;

	public float BaseNoiseScale = 1.0f;
    [Range(0, 1)] public float NoiseThreshold = 0.5f;
    [Range(0, 1)] public float erode = 0.5f;
	public float CloudDensityScale = 1.0f;	

	public Color CloudBaseColor = Color.black;
	public Color CloudTopColor = Color.black;

	public float AmbientLightIntensity = 1.0f;
	public float SunLightIntensity = 1.0f;
    
    Texture3D NoiseTex = null;
    Texture2D CurlTex = null;
    Texture3D DetailNoiseTex = null;

    public Texture2D coverage;
    public Texture2D _Gradient;

    private Matrix4x4 projection;
	private Matrix4x4 inverseRotation;
    private int test = 0;

    [Range(0, 1)]
    public int int_test;
    [Range(0, 1)]
    public float float_test;


    // Use this for initialization
    void Start () {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
        LoadTexture();
    }
	
	// Update is called once per frame
	void Update () {
        if (Input.GetKeyDown(KeyCode.F1))
            test = 1;
        else if (Input.GetKeyDown(KeyCode.F2))
            test = 2;
        else if (Input.GetKeyDown(KeyCode.F3))
            test = 3;
        else if (Input.GetKeyDown(KeyCode.F4))
            test = 4;
    }


	void LoadTexture()
	{
		if (NoiseTex == null)
			NoiseTex = Load3DTexture("noise", 128, TextureFormat.RGBA32);
		
		if (DetailNoiseTex == null)
			DetailNoiseTex = Load3DTexture("noise_detail", 32, TextureFormat.RGB24);
		
		if (CurlTex == null)
			CurlTex = Resources.Load("CurlNoise") as Texture2D;
	}


	Texture3D Load3DTexture(string name, int size, TextureFormat format)
	{
		int count = size * size * size;
		TextAsset asset = Resources.Load<TextAsset>( name);
		Color32[] colors = new Color32[ count];
		byte[] bytes = asset.bytes;
		int j=0;
		
		//skip dds header
		j += 128;

		for( int i=0; i<count; i++)
		{
			colors[i].b = bytes[j++];
			colors[i].g = bytes[j++];
			colors[i].r = bytes[j++];
			colors[i].a = format == TextureFormat.RGBA32 ? bytes[j++] : (byte)255;
		}
		
		Texture3D texture3D = new Texture3D( size, size, size, format, true);
		texture3D.hideFlags = HideFlags.HideAndDontSave;
		texture3D.wrapMode = TextureWrapMode.Repeat;
		texture3D.filterMode = FilterMode.Bilinear;
		texture3D.SetPixels32( colors, 0);
		texture3D.Apply();
		return texture3D;
	}


    //[ImageEffectOpaque]
    public void  OnRenderImage(RenderTexture src, RenderTexture dest)
	{
        if (EffectMaterial == null)
            return;
        
        SetParams();
        ///render cloud
        CustomGraphicsBlit(EffectMaterial, 0);
        //depth test
        Graphics.Blit(src, dest);

       //  Graphics.Blit(src, dest, _EffectMaterial);
    }



    private void SetParams()
    {
        projection = Camera.main.projectionMatrix;
        Matrix4x4 inverseProjection = projection.inverse;
        inverseRotation = Camera.main.cameraToWorldMatrix;

        EffectMaterial.SetVector("_CloudParams", new Vector4(CloudRayStepScale, LightRayStepScale, InscatteringCoff, ExtinctionCoff));
        EffectMaterial.SetFloat("_Hg", Hg);

        EffectMaterial.SetTexture("_NoiseTex", NoiseTex);
        EffectMaterial.SetTexture("_DetailNoiseTex", DetailNoiseTex);

        EffectMaterial.SetTexture("_Gradient", _Gradient);

        EffectMaterial.SetMatrix("_InverseProjection", inverseProjection);
        EffectMaterial.SetMatrix("_InverseRotation", inverseRotation);

        EffectMaterial.SetInt("_MaxSteps", MaxSteps);

        EffectMaterial.SetFloat("_BaseNoiseTexUVScale", BaseNoiseTexUVScale);
        EffectMaterial.SetFloat("_DetailNoiseTexUVScale", DetailNoiseTexUVScale);
        EffectMaterial.SetFloat("_WeatherTexUVScale", WeatherTexUVScale);

        EffectMaterial.SetFloat("_BaseNoiseScale", BaseNoiseScale);
        EffectMaterial.SetFloat("_NoiseThreshold", NoiseThreshold);
        EffectMaterial.SetFloat("_CloudDensityScale", CloudDensityScale);

        EffectMaterial.SetFloat("_AmbientLightIntensity", AmbientLightIntensity);
        EffectMaterial.SetFloat("_SunLightIntensity", SunLightIntensity);

        EffectMaterial.SetColor("_CloudBaseColor", CloudBaseColor);
        EffectMaterial.SetColor("_CloudTopColor", CloudTopColor);
        
        EffectMaterial.SetTexture("_BaseShape", NoiseTex);
        EffectMaterial.SetTexture("_ShapeDetail", DetailNoiseTex);

        EffectMaterial.SetFloat("_erode", erode);
        EffectMaterial.SetTexture("_WeatherTex", coverage);

        EffectMaterial.SetVector("lightDir", light.transform.forward);

        EffectMaterial.SetVector("_CloudHeight", new Vector4(BottomCloudHeight, TopCloudHeight, TopCloudHeight - BottomCloudHeight, EarthRadius));

        EffectMaterial.SetVector("_HorizonParams", new Vector4(0.0f, 0.0f, 0.0f, HorizonMaxDistance));
        
        EffectMaterial.SetInt("cloudType", cloudType);

        EffectMaterial.SetInt("test", test);
        EffectMaterial.SetFloat("float_test", float_test);
        EffectMaterial.SetInt("int_test", int_test);
    }

    
    //static void CustomGraphicsBlit( Material fxMaterial, int nPass)
    //{
    //    // RenderTexture.active = dest;
    //    // fxMaterial.SetTexture("_MainTex", source);

    //    GL.PushMatrix();
    //    GL.LoadOrtho();

    //    fxMaterial.SetPass(nPass);

    //    GL.Begin(GL.QUADS);

    //    GL.MultiTexCoord2(0, 0.0f, 0.0f);
    //    GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

    //    GL.MultiTexCoord2(0, 1.0f, 0.0f);
    //    GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

    //    GL.MultiTexCoord2(0, 1.0f, 1.0f);
    //    GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

    //    GL.MultiTexCoord2(0, 0.0f, 1.0f);
    //    GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

    //    GL.End();

    //    GL.PopMatrix();
    //}

    static void CustomGraphicsBlit(Material mat, int passNr)
    {
        //RenderTexture.active = dest;

        //mat.SetTexture("_MainTex", src);

        GL.PushMatrix();
        GL.LoadOrtho();

        mat.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.TexCoord2(0, 0);
        GL.Vertex3(0.0f, 0.0f, 0);
        GL.TexCoord2(0, 1);
        GL.Vertex3(0.0f, 1.0f, 0);
        GL.TexCoord2(1, 1);
        GL.Vertex3(1.0f, 1.0f, 0);
        GL.TexCoord2(1, 0);
        GL.Vertex3(1.0f, 0.0f, 0);


        GL.End();
        GL.PopMatrix();
    }
}
