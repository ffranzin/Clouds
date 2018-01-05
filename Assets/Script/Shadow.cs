using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Shadow : MonoBehaviour {
   
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

    private Matrix4x4 projection;
    private Matrix4x4 inverseRotation;

    // Use this for initialization
    void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
 
    }
    
    //[ImageEffectOpaque]
    public void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (EffectMaterial == null)
            return;

        SetParams();

        CustomGraphicsBlit(src, dest, EffectMaterial, 0);
        
        Graphics.Blit(src, dest);
    }



    private void SetParams()
    {
        projection = Camera.main.projectionMatrix;
        Matrix4x4 inverseProjection = projection.inverse;
        inverseRotation = Camera.main.cameraToWorldMatrix;

        EffectMaterial.SetMatrix("_InverseProjection", inverseProjection);
        EffectMaterial.SetMatrix("_InverseRotation", inverseRotation);
    }


    static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material mat, int passNr)
    {
        Camera _camera = Camera.main;
        float camFar = _camera.farClipPlane;
        float camFov = _camera.fieldOfView;
        float camAspect = _camera.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = _camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = _camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (_camera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (_camera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (_camera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (_camera.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;
        
        mat.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        mat.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
}
