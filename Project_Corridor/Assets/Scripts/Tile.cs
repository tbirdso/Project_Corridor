using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling
{
    public enum CardinalDirection
    {
        NORTH,
        EAST,
        SOUTH,
        WEST
    }

    public enum TileType
    {
        START,
        GOAL,
        ROOM,
        SPECIAL
    }

    public class Tile : MonoBehaviour
    {
        public TileType type;
        public Vector2 GridSize;
        public bool NorthEdge;
        public bool SouthEdge;
        public bool EastEdge;
        public bool WestEdge;
        public Dictionary<CardinalDirection, bool> EdgeOpenings = new Dictionary<CardinalDirection, bool>();

        private Dictionary<CardinalDirection, Tile> EdgeAdjacency;
        private Vector2 coordinates;
        private int rotations;
        private bool assembled;

        // Start is called before the first frame update
        void Start()
        {
            EdgeOpenings[CardinalDirection.NORTH] = NorthEdge;
            EdgeOpenings[CardinalDirection.SOUTH] = SouthEdge;
            EdgeOpenings[CardinalDirection.EAST] = EastEdge;
            EdgeOpenings[CardinalDirection.WEST] = WestEdge;
        }
        
    }
}
