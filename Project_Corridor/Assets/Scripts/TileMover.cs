using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling {
    public class TileMover : MonoBehaviour
    {
        public Vector2 sideLength;
        public Vector3 Offset;

        public void MoveTile(List<Tile> tiles)
        {
            foreach(Tile t in tiles)
            {
                t.transform.position = new Vector3(t.coordinates.x * sideLength.x + Offset.x,
                                                    Offset.y,
                                                    t.coordinates.y * sideLength.y + Offset.y);
                t.transform.Rotate(0, 90 * t.rotations, 0);
            }
        }

        public void MoveToTile(GameObject obj, Tile t)
        {
            Vector3 destPos = t.transform.position;
            destPos.y += 0.5f * t.transform.localScale.y;
            obj.transform.position = destPos;
        }
    }
}
