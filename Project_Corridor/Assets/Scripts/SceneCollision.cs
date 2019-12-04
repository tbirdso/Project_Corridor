using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SceneCollision : MonoBehaviour
{
    public string sceneToTransition;

    void OnTriggerEnter(Collider collision)
    {
        if (collision.gameObject.name == "HeadCollider")
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(sceneToTransition);
        }
        else
        {
            Debug.Log("Collided with " + collision.gameObject.name);
        }
    }
}
