using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace MapTiling
{
    public class TileInputWriter : MonoBehaviour
    {
        public int min_dist;

        public void WriteToFile(string filePath, List<Tile> InputList)
        {
            using (StreamWriter writer = new StreamWriter(filePath))
            {
                writer.WriteLine("params " + min_dist);

                foreach (Tile t in InputList)
                {
                    writer.Write("tile ");
                    writer.Write(t.name + " ");
                    writer.Write(t.type + " ");
                    writer.Write(((t.GridSize.x > 0) ? t.GridSize.x : 1) + " ");
                    writer.Write(((t.GridSize.y > 0) ? t.GridSize.y : 1));

                    foreach (CardinalDirection c in System.Enum.GetValues(typeof(CardinalDirection)))
                    {
                        string open = (t.EdgeOpenings[c] ? "OPEN" : "CLOSED");
                        writer.Write(" " + open);
                    }

                    writer.WriteLine();

                }
            }
        }

    }

}