using UnityEngine;
using System.Collections;

public class GenerateWeatherTexture : MonoBehaviour {

	public Material mat;
	public Vector3 WindDirection = new Vector3(1.0f, 0.0f, 0.0f);
	public float WindSpeed = 10.0f;
	public Vector4 CloudParams = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}


	public void  OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		mat.SetVector("WindDirection", WindDirection);
		mat.SetFloat("WindSpeed", WindSpeed);
		mat.SetVector("CloudParams", CloudParams);

		Graphics.Blit(src, dest, mat);
	}
}
