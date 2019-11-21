using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Valve.VR.InteractionSystem;

public class Test_TeleportPoint : MonoBehaviour
{
    public bool test = false;
    public TeleportPoint tp;

    public void Update()
    {
        if(test)
        {
            tp.TeleportToScene();
            test = false;
        }
    }
}
