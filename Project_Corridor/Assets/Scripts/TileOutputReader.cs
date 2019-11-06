using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace MapTiling {
    public class TileOutputReader : MonoBehaviour
    {
        const int NUM_TILE_FIELDS = 9;
        const int NUM_MULTI_FIELDS = 6;

        public Tile BackfillPrefab;

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
                        if (!id.Contains("backfill"))
                        {
                            match = tiles.Find(t => t.name.Equals(id));
                            if(match != null)
                                match.rotations = int.Parse(fields[4]);

                        } else
                        {
                            match = Instantiate(BackfillPrefab);
                            match.name = id;
                            tiles.Add(match);

                            if(id.Contains("backfill-N"))
                            {
                                match.rotations = 2;
                            } else if(id.Contains("backfill-E"))
                            {
                                match.rotations = 3;
                            } else if(id.Contains("backfill-S"))
                            {
                                match.rotations = 0;
                            } else if(id.Contains("backfill-W"))
                            {
                                match.rotations = 1;
                            } else
                            {
                                match.rotations = 0;
                            }
                        }
                        if (match != null && fields.Length == NUM_TILE_FIELDS)
                        {
                            match.coordinates.x = int.Parse(fields[2]);
                            match.coordinates.y = int.Parse(fields[3]);

                            foreach (CardinalDirection c in Enum.GetValues(typeof(CardinalDirection)))
                            {
                                adj = (fields[5 + (int)c].Equals("nil")) ? null : tiles.Find(t => t.name.Equals(fields[5 + (int)c]));
                                match.EdgeAdjacency[c] = adj;
                            }

                            match.assembled = true;
                        }
                        else if (id.Contains("backfill"))
                        {
                            
                            //TODO: generate new tile
                            continue;
                        }
                    }
                    else if (line.StartsWith("multitile"))
                    {
                        String[] fields = line.Split(',');
                        id = fields[1];
                        match = tiles.Find(t => t.name.Equals(id));
                        if (match != null && fields.Length == NUM_MULTI_FIELDS)
                        {
                            match.coordinates.x = (float)(int.Parse(fields[2]) + int.Parse(fields[3])) / 2;
                            match.coordinates.y = (float)(int.Parse(fields[4]) + int.Parse(fields[5])) / 2;
                            match.assembled = true;
                        }
                    }
                }
            }
            
        }


    }
}