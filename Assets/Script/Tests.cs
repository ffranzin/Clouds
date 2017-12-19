using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Tests : MonoBehaviour
{
    Vector3[] mainFrustumCorners = new Vector3[4];
    static Vector3[,] frustumCorners = new Vector3[5, 5];

    void Start()
    {
        MyFrunstumCorner();
        StartCoroutine(VerifyFOV());
    }

    
    void Update()
    {
        RayPlaneIntersect();
        //ShowCorners();
    }
    

    void UnityFrustumCornes()
    {
        Camera.main.CalculateFrustumCorners(new Rect(0, 0, 1, 1), Camera.main.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, mainFrustumCorners);

        for (int i = 0; i < 4; i++)
            Camera.main.transform.TransformVector(mainFrustumCorners[i]);
    }

    void MyFrunstumCorner()
    {
        Debug.Log("Calculate FrustumCorners");
        UnityFrustumCornes();

        frustumCorners[4, 0] = mainFrustumCorners[0].normalized;
        frustumCorners[0, 0] = mainFrustumCorners[1].normalized;
        frustumCorners[0, 4] = mainFrustumCorners[2].normalized;
        frustumCorners[4, 4] = mainFrustumCorners[3].normalized;


        //Fill horizontal corners
        for (int i = 1; i < 4; i++)
        {
            frustumCorners[0, i] = Vector3.Lerp(frustumCorners[0, 0], frustumCorners[0, 4], (1.0f / 4.0f) * i).normalized;
            frustumCorners[4, i] = Vector3.Lerp(frustumCorners[4, 0], frustumCorners[4, 4], (1.0f / 4.0f) * i).normalized;
        }

        ///Fill vertical corners from horizontal corners
        for (int i = 0; i < 5; i++)
            for (int j = 1; j < 5; j++)
                frustumCorners[j, i] = Vector3.Lerp(frustumCorners[0, i], frustumCorners[4, i], (1.0f / 4.0f) * j).normalized;


        for (int i = 0; i < 4; i++)
            Debug.Log(Vector3.Angle(frustumCorners[0, i], frustumCorners[0, i + 1]));



    }


    IEnumerator VerifyFOV()
    {
        int fov = Mathf.FloorToInt(Camera.main.fieldOfView);

        while(true)
        {
            if (Mathf.FloorToInt(Camera.main.fieldOfView) != fov)
            {
                fov = Mathf.FloorToInt(Camera.main.fieldOfView);
                MyFrunstumCorner();
            }
                
            
            yield return null;
        }
        
    }

    

    void ShowCorners()
    {
        for (int i = 0; i < 1; i++)
            for (int j = 0; j < 5; j++)
                Debug.DrawRay(Camera.main.transform.position, frustumCorners[i, j] * 3, Color.red);
    }




    void RayPlaneIntersect()
    {
        Transform camera = Camera.main.transform;
        Vector3 planeNormal = new Vector3(0, 1, 0);
        Vector3 planeOrigin = new Vector3(0, 0, 0);
        Vector3 ro = camera.position;
        Vector3 rayDir = camera.forward;
        
        
        float d = Vector3.Dot(rayDir, planeNormal);

        if (Mathf.Abs(d) > 1e-6)
        {
            float t = (Vector3.Dot(planeNormal, planeOrigin - ro)) / Vector3.Dot(planeNormal, rayDir);

            if (t >= 0)
                Debug.DrawRay(camera.position, rayDir * t, Color.blue);
        }
        Debug.Log("No collision");
    }




}




