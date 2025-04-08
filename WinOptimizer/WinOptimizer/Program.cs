using System;
using System.Windows.Forms;
using WinOptimizer.Services;

namespace WinOptimizer
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            
            // Initialize services
            var hardwareService = new HardwareService();
            var optimizationService = new OptimizationService(hardwareService);
            
            // Start the main form
            Application.Run(new MainForm(hardwareService, optimizationService));
        }
    }
}
