using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace MapTiling {
    // Central handler for tile generation and assembly
    public class TileAssembler : MonoBehaviour
    {
        #region Constants
        const string srcName = "mapSrc.txt";
        const string dstName = "mapDst.csv";
        const int MAX_RETRIES = 10;
        const float YIELD_SECONDS_PER_TILE = 0.05f;
        #endregion

        #region Public Members
        // Relative path to AssembleNET application
        public string assemblerLocation;
        // Relative path to assemble.clp rules file
        public string engineLocation;
        // Relative path to folder containing text channel files
        public string mapGenFolder;

        // References to helper MapTiling classes
        public TileInputWriter writer;
        public TileOutputReader reader;
        public TileMover mover;
        public TileGenerator generator;

        // List of tiles to assemble
        public List<Tile> TileList = null;
        #endregion

        #region Private Members
        // Absolute path to AssembleNET application
        private string fullAssemblePath;
        // Absolute path to input text channel
        private string mapSrcLocation;
        // Absolute path to output text channel
        private string mapDstLocation;
        // Absolute path to assemble.clp rules file
        private string engineFullPath;

        // Asynchronous flag set for failed assemble
        private bool failedAssemble = false;
        private int numFails = 0;
        #endregion

        // Handler to pass information from static output class to dynamic assembler
        public static event EventHandler<EventArgs> FailedAssemble;
        public static event EventHandler<EventArgs> FinishedAssemble;

        #region Private Methods
        private void Start()
        {
            // Run assemble in coroutine that can yield back to Unity while
            // AssembleNET executes
            StartCoroutine(RunAssemble());
        }

        // Main function to generate, assemble, and place tiles to initiate scene
        IEnumerator RunAssemble()
        {
            fullAssemblePath = Directory.GetCurrentDirectory() + "\\" + assemblerLocation;
            mapSrcLocation = Directory.GetCurrentDirectory() + "\\" + mapGenFolder + "\\" + srcName;
            mapDstLocation = Directory.GetCurrentDirectory() + "\\" + mapGenFolder + "\\" + dstName;
            engineFullPath = Directory.GetCurrentDirectory() + "\\" + engineLocation;

            FailedAssemble += new EventHandler<EventArgs>(FlagFailedAssemble);

            failedAssemble = true;
            while (failedAssemble && numFails < MAX_RETRIES)
            {
                failedAssemble = false;

                // If a TileList has not been manually set generate a new list
                if((TileList == null || TileList.Count == 0) && generator != null)
                    TileList = generator.GenerateTiles();

                if (TileList == null || TileList.Count <= 2)
                {
                    throw new ArgumentNullException("Could not generate a list of Tile objects to assemble");
                }
                else
                {
                    // Write to text channel
                    writer.WriteToFile(mapSrcLocation, TileList);

                    // Start the assembler and yield until it completes
                    RunEngineExternal();
                    yield return new WaitForSeconds(YIELD_SECONDS_PER_TILE * TileList.Count);

                    // Once reasonably confident the assembly has finished, try to read in tile data
                    if (failedAssemble)
                    {
                        // If a map could not be generated, destroy the current instances and try again
                        foreach (Tile t in TileList)
                        {
                            Destroy(t.gameObject);
                        }
                        TileList = null;
                    }
                    else
                    {
                        // If a map was generated, move the tiles in Unity and center the player
                        reader.ReadFromFile(mapDstLocation, TileList);
                        mover.MoveTile(TileList);

                        GameObject player = GameObject.Find("Player");
                        Tile StartTile = TileList.Find(t => t.name.ToLower().Equals("start"));

                        mover.MoveToTile(player, StartTile);

                        OnFinishedAssemble(this, new EventArgs());
                    }
                }
            }
        }

        // Execute the AssembleNET application on the command line
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
            catch (Exception e)
            {
                Debug.LogError(e.ToString());
            }

        }
        
        // Delegate to flag running TileAssembler thread when asynchronous assembly failure detected
        private void FlagFailedAssemble(object sender, EventArgs e)
        {
            failedAssemble = true;
            numFails += 1;
        }

        #endregion

        #region Private Static Methods
        // Delegate to print out messages received from AssembleNET process
        private static void OutputHandler(object sendingProcess,
                System.Diagnostics.DataReceivedEventArgs outLine)
        {
            Debug.Log(outLine.Data);

            if(outLine.Data != null && outLine.Data.Contains("Failed"))
            {
                OnFailedAssemble(sendingProcess, outLine);
            }
        }

        // Fire event when AssembleNET cannot assemble a map
        private static void OnFailedAssemble(object sender, EventArgs e)
        {
            EventHandler<EventArgs> handler = FailedAssemble;
            handler?.Invoke(sender, e);
        }

        private static void OnFinishedAssemble(object sender, EventArgs e)
        {
            EventHandler<EventArgs> handler = FinishedAssemble;
            handler?.Invoke(sender, e);
        }
        #endregion
    }
}
