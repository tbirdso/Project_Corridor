using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace MapTiling
{
    public class TileGenerator : MonoBehaviour
    {

        public int NumTiles;

        public Tile StartPrefab;
        public Tile GoalPrefab;

        public List<Tile> Prefabs;
        public List<float> Weights; // Should always total to 1.0

        public void Awake()
        {
            Debug.Assert(Prefabs.Count == Weights.Count);
            Debug.Assert(Weights.Sum() == 1.0f);
        }

        public List<Tile> GenerateTiles()
        {
            int index;
            float randNum;
            Tile t;
            List<Tile> tileList = new List<Tile>();

            t = Instantiate(StartPrefab);
            t.name = StartPrefab.name;
            tileList.Add(t);

            t = Instantiate(GoalPrefab);
            t.name = GoalPrefab.name;
            tileList.Add(t);

            for(int count = 0; count < NumTiles; count++)
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

                t = Instantiate(Prefabs[index]);
                t.name = Prefabs[index].name + "_" + randNum.ToString();

                tileList.Add(t);

            }

            return tileList;
        }
    }

}