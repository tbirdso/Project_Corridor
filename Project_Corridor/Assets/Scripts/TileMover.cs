using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling {
    // Position Tiles in the scene based on their class properties
    public class TileMover : MonoBehaviour
    {
        #region Public Members
        // Translation of x/z side length from grid to transform; default is 1 grid unit : 10 meters
        public Vector2 sideLength = new Vector2(10, 10);

        // Transform offset for grid origin; default is 0
        public Vector3 Offset = new Vector3(0, 0, 0);
        #endregion

        /* Translate Tile instance to scene coordinates based on its x/z/r properties
         * Arguments:   tiles:  List of tiles to translate
         */
        public void MoveTile(List<Tile> tiles)
        {
            foreach(Tile t in tiles)
            {
                if (t.assembled)
                {
                    t.transform.position = new Vector3(t.coordinates.x * sideLength.x + Offset.x,
                                                        Offset.y,
                                                        t.coordinates.y * sideLength.y + Offset.y);
                    t.transform.Rotate(0, 90 * t.rotations, 0);
                } else
                {
                    // If a tile was not assembled remove it from the scene
                    Destroy(t);
                }
            }
        }

        /* Move an object on top of a specified tile. Typically used to recenter the Player on START.
         * Arguments:   obj:    Object to move
         *              t:      Destination tile
         */
        public void MoveToTile(GameObject obj, Tile t)
        {
            Vector3 destPos = t.transform.position;
            destPos.y += 0.5f * t.transform.localScale.y;
            obj.transform.position = destPos;
        }
    }
}
