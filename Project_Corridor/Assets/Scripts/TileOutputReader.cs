using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace MapTiling {
    public class TileOutputReader : MonoBehaviour
    {
        const int NUM_FIELDS = 9;

        public void ReadFromFile(string file, List<Tile> tiles)
        {
            using (StreamReader reader = new StreamReader(file))
            {
                string line = null;
                Tile match = null, adj = null;
                string id = null;
                while(!reader.EndOfStream)
                {
                    // Sample line:
                    // tile,backfill-N-gen2,0,2,0,nil,Tile4,nil,nil
                    if ((line = reader.ReadLine()).StartsWith("tile"))
                    {
                        String[] fields = line.Split(',');
                        id = fields[1];
                        Debug.Log("Name of tile is " + id);
                        Console.WriteLine("Name of tile is " + id);
                        match = tiles.Find(t => t.name.Equals(id));
                        if(match != null && fields.Length == NUM_FIELDS)
                        {
                            match.coordinates.x = int.Parse(fields[2]);
                            match.coordinates.y = int.Parse(fields[3]);
                            match.rotations = int.Parse(fields[4]);

                            foreach(CardinalDirection c in Enum.GetValues(typeof(CardinalDirection)))
                            {

                                adj = (fields[5 + (int)c].Equals("nil")) ? null : tiles.Find(t => t.name.Equals(fields[5 + (int)c]));
                                match.EdgeAdjacency[c] = adj;
                            }

                            match.assembled = true;

                        } else if(id.Contains("gen"))
                        {
                            //TODO: generate new tile
                            continue;
                        }
                    }
                }
            }
            
        }


    }
}