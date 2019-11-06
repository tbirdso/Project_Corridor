using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling {
    public class TileMover : MonoBehaviour
    {
        public Vector2 sideLength;
        public Vector3 Offset;

        public void Move(List<Tile> tiles)
        {
            foreach(Tile t in tiles)
            {
                t.transform.position = new Vector3(t.coordinates.x * sideLength.x + Offset.x,
                                                    Offset.y,
                                                    t.coordinates.y * sideLength.y + Offset.y);
                t.transform.Rotate(0, 90 * t.rotations, 0);
            }
        }
    }
}
