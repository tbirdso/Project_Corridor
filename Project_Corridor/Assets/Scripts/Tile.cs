using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace MapTiling
{
    public enum CardinalDirection
    {
        NORTH,
        SOUTH,
        EAST,
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
        // SET IN EDITOR
        public TileType type;
        public Vector2 GridSize;
        public bool NorthEdge;
        public bool SouthEdge;
        public bool EastEdge;
        public bool WestEdge;
        public Dictionary<CardinalDirection, bool> EdgeOpenings = new Dictionary<CardinalDirection, bool>();

        // SET WITH ENGINE
        public Dictionary<CardinalDirection, Tile> EdgeAdjacency = new Dictionary<CardinalDirection, Tile>();
        public Vector2 coordinates;
        public int rotations;
        public bool assembled;

        // Start is called before the first frame update
        void Awake()
        {
            EdgeOpenings[CardinalDirection.NORTH] = NorthEdge;
            EdgeOpenings[CardinalDirection.SOUTH] = SouthEdge;
            EdgeOpenings[CardinalDirection.EAST] = EastEdge;
            EdgeOpenings[CardinalDirection.WEST] = WestEdge;
        }
    }
}
