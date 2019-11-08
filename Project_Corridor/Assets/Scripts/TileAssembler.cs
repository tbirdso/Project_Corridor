using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

namespace MapTiling {

    public class TileAssembler : MonoBehaviour
    {

        #region Public Members
        public string assemblerLocation;
        public string engineLocation;
        public string mapGenFolder;
        public TileInputWriter writer;
        public TileOutputReader reader;
        public TileMover mover;
        public TileGenerator generator;

        public List<Tile> TileList;
        #endregion

        #region Private Members
        private string fullAssemblePath;
        private string mapSrcLocation;
        private string mapDstLocation;
        private string engineFullPath;

        private bool failedAssemble = false;
        private int numFails = 0;
        #endregion

        const string srcName = "mapSrc.txt";
        const string dstName = "mapDst.csv";
        const int MAX_RETRIES = 10;

        public delegate void FailedAssembleHandler(object sender, EventArgs e);
        public static event FailedAssembleHandler FailedAssemble;

        #region Private Methods
        private void Start()
        {
            StartCoroutine(RunAssemble());
        }

        IEnumerator RunAssemble()
        {
            fullAssemblePath = Directory.GetCurrentDirectory() + "\\" + assemblerLocation;
            mapSrcLocation = Directory.GetCurrentDirectory() + "\\" + mapGenFolder + "\\" + srcName;
            mapDstLocation = Directory.GetCurrentDirectory() + "\\" + mapGenFolder + "\\" + dstName;
            engineFullPath = Directory.GetCurrentDirectory() + "\\" + engineLocation;

            FailedAssemble += new FailedAssembleHandler(FlagFailedAssemble);

            failedAssemble = true;
            while (failedAssemble && numFails < MAX_RETRIES)
            {
                failedAssemble = false;
                TileList = generator.GenerateTiles();
                writer.WriteToFile(mapSrcLocation, TileList);

                RunEngineExternal();
                yield return new WaitForSeconds(0.02f * TileList.Count);

                if (failedAssemble)
                {
                    foreach (Tile t in TileList)
                    {
                        Destroy(t.gameObject);
                    }

                } else
                {
                    reader.ReadFromFile(mapDstLocation, TileList);
                    mover.MoveTile(TileList);

                    GameObject player = GameObject.Find("Player");
                    Tile StartTile = TileList.Find(t => t.name.ToLower().Equals("start"));

                    mover.MoveToTile(player, StartTile);

                }
            }
        }

        void RunEngineExternal()
        {
            try
            {
                System.Diagnostics.Process proc = new System.Diagnostics.Process();

                proc.StartInfo.FileName = fullAssemblePath;
                proc.StartInfo.Arguments = mapSrcLocation + " " + mapDstLocation + " " + engineFullPath;
                proc.StartInfo.UseShellExecute = false;
                proc.StartInfo.RedirectStandardOutput = true;
                proc.StartInfo.RedirectStandardError = true;

                proc.OutputDataReceived += OutputHandler;
                proc.ErrorDataReceived += OutputHandler;
                proc.EnableRaisingEvents = true;

                proc.Start();
                proc.BeginOutputReadLine();
                proc.BeginErrorReadLine();

            }
            catch (System.Exception e)
            {
                Debug.Log("Encountered an error!");
                Debug.Log(e.ToString());
            }

        }

        private void ResetFailedAssemble(object sender, EventArgs e)
        {
            failedAssemble = false;
        }

        private void FlagFailedAssemble(object sender, EventArgs e)
        {
            failedAssemble = true;
            numFails += 1;
        }

        #endregion

        #region Private Static Methods
        private static void OutputHandler(object sendingProcess,
                System.Diagnostics.DataReceivedEventArgs outLine)
        {
            Debug.Log(outLine.Data);

            if(outLine.Data != null && outLine.Data.Contains("Failed"))
            {
                OnFailedAssemble(sendingProcess, outLine);
            }
        }

        private static void OnFailedAssemble(object sender, EventArgs e)
        {
            FailedAssembleHandler handler = FailedAssemble;
            handler?.Invoke(sender, e);
        }
        #endregion
    }
}
