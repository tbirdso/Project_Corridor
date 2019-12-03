using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace MapTiling
{
    public class TileGenerator : MonoBehaviour
    {
        #region Public Members
        // Total number of tiles to generate and attempt to assemble into a map
        public int NumTiles;

        // Starting point for map assembly
        public Tile StartPrefab;
        // Ending point for map assembly
        public Tile GoalPrefab;

        // List of prefabs to choose from in instantiating tiles
        public List<Tile> Prefabs;

        // 1:1 list for weights : prefabs to inform random selection
        // List must always total to 1.0
        public List<float> Weights;
        #endregion

        #region Public Methods
        /* Generate the list of tiles that will be assembled into a traversable map.
         * Return: List of Tile instances (null if preconditions not met)
         */
        public List<Tile> GenerateTiles()
        {
            Debug.Assert(Prefabs.Count == Weights.Count, "[MapTiling] Number of prefabs and weights must be equal");
            if (Prefabs.Count != Weights.Count) return null;

            Debug.Assert(Weights.Sum() == 1.0f, "[MapTiling] Prefab weights must sum to 1.0");
            if (Weights.Sum() != 1.0f) return null;

            int index;
            float randNum;
            Tile t;
            List<Tile> tileList = new List<Tile>();

            // Instantiate start and goal instances

            t = Instantiate(StartPrefab);
            t.name = StartPrefab.name;
            tileList.Add(t);

            t = Instantiate(GoalPrefab);
            t.name = GoalPrefab.name;
            tileList.Add(t);

            // Randomly select and instantiate remaining tiles

            for(int count = 0; count < NumTiles - 2; count++)
            {
                float baseWeight = 0.0f;

                randNum = Random.Range(0.0f, 1.0f);

                for(index = 0; index < Weights.Count; index++)
                {
                    baseWeight += Weights[index];
                    if(baseWeight >= randNum)
                    {
                        break;
                    } else
                    {
                        continue;
                    }
                }

                // Note that each tile must have a unique name with no parentheses for procedural assembly
                t = Instantiate(Prefabs[index]);
                t.name = Prefabs[index].name + "_" + randNum.ToString();

                tileList.Add(t);

            }

            return tileList;
        }
        #endregion
    }
}