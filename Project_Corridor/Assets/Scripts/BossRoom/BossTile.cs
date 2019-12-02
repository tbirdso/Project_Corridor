using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BossRoomTiling
{
    public class BossTile : MonoBehaviour
    {
        public Vector2 gridPosition;
        public TileColor color;
        public TileVariant variant;

        public BossTile(int x, int z, TileColor c)
        {
            gridPosition = new Vector2(x, z);
            color = c;
        }
    }
}
