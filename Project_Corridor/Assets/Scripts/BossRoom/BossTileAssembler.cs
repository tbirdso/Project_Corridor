using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace BossRoomTiling
{
    // Central handler for tile generation and assembly
    public class BossTileAssembler : MonoBehaviour
    {
        #region Constants
        const string srcName = "mapSrc.txt";
        const string dstName = "mapDst.csv";
        const int MAX_RETRIES = 10;
        const float YIELD_SECONDS_PER_TILE = 0.05f;
        #endregion

        #region Public Members
        // Relative path to folder containing boss room CSV files
        public string bossFolder;

        // References to helper MapTiling classes
        public BossTileReader reader;

        // List of variant prefabs
        public List<BossTile> TileList = null;

        // Variant mappings
        public BossTile redVariant;
        public BossTile yellowVariant;
        public BossTile blueVariant;

        // Position of (0,0) coordinate
        public Vector3 origin;
        // Displacement between tiles
        public Vector2 delta;
        #endregion

        #region Private Members

        #endregion

        // Handler to pass information from static output class to dynamic assembler
        public static event EventHandler<EventArgs> FinishedAssemble;

        public void Start()
        {
            AssembleMap();
        }

        #region Private Methods
        private void AssembleMap()
        {
            string bossFile;
            List<BossTile> colors;

            int randNum = (int)UnityEngine.Random.Range(0.0f, 1.0f);
            bossFile = Directory.GetCurrentDirectory() + "\\" + bossFolder + "\\map" + randNum.ToString("D2") + ".txt";

            colors = reader.ReadFromFile(bossFile);

            PlaceTiles(colors);
        }

        private void PlaceTiles(List<BossTile> colorList)
        {
            foreach(BossTile tile in colorList)
            {
                BossTile t;
                Vector3 position = new Vector3(
                    origin.x + delta.x * tile.gridPosition.x,
                    origin.y,
                    origin.z + delta.y * tile.gridPosition.y);

                switch(tile.color)
                {
                    case TileColor.BLUE: t = blueVariant;
                        break;
                    case TileColor.YELLOW: t = yellowVariant;
                        break;
                    default: t = redVariant;
                        break;
                }

                Instantiate(t, position, Quaternion.identity, this.transform);

            }
        }

        #endregion

        #region Private Static Methods

        private static void OnFinishedAssemble(object sender, EventArgs e)
        {
            EventHandler<EventArgs> handler = FinishedAssemble;
            handler?.Invoke(sender, e);
        }
        #endregion
    }
}
