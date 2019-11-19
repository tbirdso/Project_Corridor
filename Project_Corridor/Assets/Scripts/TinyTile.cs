using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling {
    public class TinyTile : MonoBehaviour
    {
        private Tile ParentTile;

        // Start is called before the first frame update
        void Start()
        {
            Tile pTile = GetComponentInParent<Tile>();
            ParentTile = (pTile == null) ? null : pTile;
        }

        // Update is called once per frame
        void Update()
        {

        }

    }
}
