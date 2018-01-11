using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Tests1 : MonoBehaviour
{
    public Vector3 rayCenter = new Vector3(0, 0, 0);
    public Vector3 rayDir = Vector3.up;
    public float radius = 1;

    public float a;
    public float b;
    public float c;

    

    bool raySphereIntersect()
    {
        Vector3 l = (rayCenter - transform.position).normalized;
         a = Vector3.Dot(rayDir.normalized, rayDir.normalized);
         b = 2 * Vector3.Dot(rayDir, l);
         c = Vector3.Dot(l, l) - radius * radius;

        float delta = b * b - 4 * a * c;

        if (delta < 0)
            return false;

        return true;
    }


    void Update()
    {
        if(raySphereIntersect())
            Debug.DrawRay(rayCenter, rayDir * 100, Color.red);
        else
            Debug.DrawRay(rayCenter, rayDir * 100, Color.blue);
    }
}




