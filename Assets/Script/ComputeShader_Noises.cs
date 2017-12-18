using UnityEngine;

public class ComputeShader_Noises : MonoBehaviour
{
    public ComputeShader computeShader;
    public RenderTexture renderTextureBase;
    public RenderTexture renderTextureDetail;

    void Awake()
    {   
        renderTextureBase = new RenderTexture(128, 128, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        renderTextureBase.volumeDepth = 4;
        renderTextureBase.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        renderTextureBase.enableRandomWrite = true;
        renderTextureBase.wrapMode = TextureWrapMode.Repeat;
        renderTextureBase.Create();

        renderTextureDetail = new RenderTexture(32, 32, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        renderTextureDetail.volumeDepth = 3;
        renderTextureDetail.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        renderTextureDetail.wrapMode = TextureWrapMode.Repeat;
        renderTextureDetail.enableRandomWrite = true;
        renderTextureDetail.Create();

        Dispatch();
    }


    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Space))
            Dispatch();
    }
    

    void Dispatch()
    {
        int kernel1 = computeShader.FindKernel("BaseShape");
        int kernel2 = computeShader.FindKernel("ShapeDetail");
        int ngroupsx, ngroupsy, ngroupsz;

        computeShader.SetTexture(kernel1, "_RenderTextureBase", renderTextureBase);
        computeShader.SetTexture(kernel2, "_RenderTextureDetail", renderTextureDetail);
        computeShader.SetVector("_RenderTextureBaseDim", new Vector4(renderTextureBase.width, renderTextureBase.height, renderTextureBase.volumeDepth, 0.0f));
        computeShader.SetVector("_RenderTextureDetailDim", new Vector4(renderTextureDetail.width, renderTextureDetail.height, renderTextureDetail.volumeDepth, 0.0f));

        ngroupsx = Mathf.CeilToInt(renderTextureBase.width / 8.0f);
        ngroupsy = Mathf.CeilToInt(renderTextureBase.height / 8.0f);
        ngroupsz = Mathf.CeilToInt(renderTextureBase.volumeDepth / 4.0f);
        computeShader.Dispatch(kernel1, ngroupsx, ngroupsy, ngroupsz);

        ngroupsx = Mathf.CeilToInt(renderTextureDetail.width / 8.0f);
        ngroupsy = Mathf.CeilToInt(renderTextureDetail.height / 8.0f);
        ngroupsz = Mathf.CeilToInt(renderTextureDetail.volumeDepth / 3.0f);
        computeShader.Dispatch(kernel2, ngroupsx, ngroupsy, ngroupsz);
    }
}
