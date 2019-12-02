using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace BossRoomTiling {

    public enum TileColor
    {
        RED,
        YELLOW,
        BLUE
    }

    public enum TileVariant
    {
        CLEAR,
        ROCKY,
        WATER,
        COLUMN,
        WALL,
        BRIGHT,
        DIM,
        DARK
    }
    
    //Translate output from the FuzzyCLIPS program into boss room tile properties in Unity
    public class BossTileReader : MonoBehaviour
    {
        #region Constants
        // Number of expected fields in one CSV record
        const int NUM_FIELDS = 3;
        #endregion

        #region Public Members
        public int xLength = 20;
        public int zLength = 20;

        #endregion

        #region Public Methods
        /* Read output from CSV text channel into array in Unity
         */
        public List<BossTile> ReadFromFile(string file)
        {
            string line = null;
            int x, z;
            TileColor color;
            List<BossTile> grid = new List<BossTile>();

            using (StreamReader reader = new StreamReader(file))
            {
                while(!reader.EndOfStream)
                {
                    // Format: [x],[z],[variant]
                    // Sample line:
                    // 1,1,red
                    if ((line = reader.ReadLine()) != null)
                    {
                        String[] fields = line.Split(',');
                        Debug.Assert(fields.Length == NUM_FIELDS,
                            "Expected " + NUM_FIELDS + " fields in line, found " + fields.Length);

                        x = int.Parse(fields[0]);
                        z = int.Parse(fields[1]);

                        if (x > xLength || z > zLength) continue;

                        switch (fields[2])
                        {
                            case "blue":
                                color = TileColor.BLUE;
                                break;
                            case "yellow":
                                color = TileColor.YELLOW;
                                break;
                            default:
                                color = TileColor.RED;
                                break;
                        }

                        grid.Add(new BossTile(x, z, color));
                    }
                        
                }
            }
            return grid;            
        }
        #endregion
    }
}