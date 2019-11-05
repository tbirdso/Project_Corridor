using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace MapTiling {

    public class TileAssembler : MonoBehaviour
    {
        public string assemblerLocation;
        public string engineLocation;
        public string mapGenFolder;
        public TileInputWriter writer;
        public TileOutputReader reader;

        public List<Tile> TileList;

        private string fullAssemblePath;
        private string mapSrcLocation;
        private string mapDstLocation;
        private string engineFullPath;

        const string srcName = "mapSrc.txt";
        const string dstName = "mapDst.csv";

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

            writer.WriteToFile(mapSrcLocation, TileList);
            RunEngineExternal();
            yield return new WaitForSeconds(1);
            reader.ReadFromFile(mapDstLocation, TileList);
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

        private static void OutputHandler(object sendingProcess,
                System.Diagnostics.DataReceivedEventArgs outLine)
        {
            Debug.Log(outLine.Data);
        }
    }
}
