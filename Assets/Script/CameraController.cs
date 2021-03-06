﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour {

    private Vector2 mouseLastPosition;
    public float maxSpeed = 1000;
    public float minSpeed = 7;

    float speed = 7000;
    private float mouseSpeed = 5;
    bool cameraEnabled = false;


    // Use this for initialization
    void Start () {
		
	}

    long Remap(long x, long in_min, long in_max, long out_min, long out_max)
    {
        return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
    }
    public long dist = 10;

    // Update is called once per frame
    void Update () {

        SetCameraToPosition();

        if (Input.GetKeyDown(KeyCode.C))
            cameraEnabled = !cameraEnabled;
        if (!cameraEnabled)
            return;

        Vector2 mousePosition = new Vector2(Input.mousePosition.x, Input.mousePosition.y) ;
        Vector2 rot = mouseLastPosition - mousePosition;

        rot *= Time.deltaTime * mouseSpeed;

        if (Input.GetMouseButton(1))
            transform.Rotate(rot.y, 0, 0);

        if (Input.GetMouseButton(0))     
            transform.Rotate(0, -rot.x, 0);


        if (Input.GetKey(KeyCode.LeftShift))
        {
            speed = maxSpeed;
            mouseSpeed = 10;
        }
        if (Input.GetKey(KeyCode.LeftControl))
        {
            speed = 100;
            mouseSpeed = 10;
        }


        //maxSpeed += Input.mouseScrollDelta.y * 500;

        if (Input.GetKey(KeyCode.W))
            transform.position += transform.forward * speed * Time.deltaTime;
        if (Input.GetKey(KeyCode.S))
            transform.position -= transform.forward * speed * Time.deltaTime;
        if (Input.GetKey(KeyCode.A))
            transform.position -= transform.right * speed * Time.deltaTime;
        if (Input.GetKey(KeyCode.D))
            transform.position += transform.right * speed * Time.deltaTime;

            
         mouseLastPosition = mousePosition;
	}



    void SetCameraToPosition()
    {
        if(Input.GetKeyDown(KeyCode.Alpha1))
        {
            transform.position = new Vector3(0, 0, 0);
            transform.rotation = Quaternion.Euler(0, 0, 0);
            cameraEnabled = true;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            transform.position = new Vector3(-14883, 900, 25797);
            transform.rotation = Quaternion.Euler(-20, -160, 0);
            cameraEnabled = true;
            speed = 30;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            transform.position = new Vector3(668, 23769, -66980);
            transform.rotation = Quaternion.Euler(16, -10, 0);
            cameraEnabled = true;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            transform.position = new Vector3(45223, 5357, -6667);
            transform.rotation = Quaternion.Euler(24, -10, 0);
            cameraEnabled = true;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha5))
        {
            transform.position = new Vector3(190000, 60000, 39000);
            transform.rotation = Quaternion.Euler(36, -86, 0);
            cameraEnabled = true;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha6))
        {
            transform.position = new Vector3(65000, 310000, -420000);
            transform.rotation = Quaternion.Euler(45, -370, 0);
            cameraEnabled = true;
        }
    }






}
