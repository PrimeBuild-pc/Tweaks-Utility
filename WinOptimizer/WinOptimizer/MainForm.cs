using System;
using System.Windows.Forms;
using System.Collections.Generic;
using WinOptimizer.Services;

namespace WinOptimizer
{
    public partial class MainForm : Form
    {
        private readonly HardwareService _hardwareService;
        private readonly OptimizationService _optimizationService;

        public MainForm(HardwareService hardwareService, OptimizationService optimizationService)
        {
            InitializeComponent();
            
            _hardwareService = hardwareService;
            _optimizationService = optimizationService;
            
            // Subscribe to optimization events
            _optimizationService.OptimizationProgressUpdated += OnOptimizationProgressUpdated;
            _optimizationService.OptimizationStatusUpdated += OnOptimizationStatusUpdated;
            _optimizationService.OptimizationCompleted += OnOptimizationCompleted;
            
            // Connect the button click event
            btnOptimize.Click += BtnOptimize_Click;
        }

        private async void BtnOptimize_Click(object sender, EventArgs e)
        {
            btnOptimize.Enabled = false;
            progressBar.Value = 0;
            listResults.Items.Clear();
            lblStatus.Text = "Starting optimization...";
            
            // For now, using default balanced profile and optimizing all components
            await _optimizationService.ScanSystemAndOptimizeAsync(
                OptimizationProfile.Balanced,
                true, true, true, true);
        }

        private void OnOptimizationProgressUpdated(int progress)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<int>(OnOptimizationProgressUpdated), progress);
                return;
            }

            progressBar.Value = progress;
        }

        private void OnOptimizationStatusUpdated(string status)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<string>(OnOptimizationStatusUpdated), status);
                return;
            }

            lblStatus.Text = status;
        }

        private void OnOptimizationCompleted(List<OptimizationResult> results)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<List<OptimizationResult>>(OnOptimizationCompleted), results);
                return;
            }

            // Update UI when optimization completes
            btnOptimize.Enabled = true;
            
            // Display results
            listResults.Items.Clear();
            foreach (var result in results)
            {
                listResults.Items.Add($"{result.ComponentName}: {(result.Success ? "Success" : "Failed")} - {result.Message}");
            }
        }
    }
}
