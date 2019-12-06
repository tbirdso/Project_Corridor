using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReloadObjects : MonoBehaviour
{
    public GameObject uniqueObject;

    // Update is called once per frame
    void Awake()
    {
        GameObject[] objects;
        if((objects = GameObject.FindGameObjectsWithTag(uniqueObject.tag)).Length == 0)
        {
            uniqueObject.SetActive(true);

            /*
            // Remove duplicate player objects
            for(int i = 0; i < objects.Length - 1; i++)
            {
                //Destroy(objects[i]);
            }
            */
        }
    }
}
