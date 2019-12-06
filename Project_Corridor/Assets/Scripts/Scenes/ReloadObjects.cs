using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReloadObjects : MonoBehaviour
{
    public string UniqueTag;

    // Update is called once per frame
    void Update()
    {
        GameObject[] objects;
        if((objects = GameObject.FindGameObjectsWithTag(UniqueTag)).Length > 1)
        {
            // Remove duplicate player objects
            for(int i = 1; i < objects.Length; i++)
            {
                Destroy(objects[i]);
            }
        }
    }
}
