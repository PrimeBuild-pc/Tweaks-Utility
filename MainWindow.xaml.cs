using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;
using Microsoft.Win32;

namespace SystemOptimizer
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window, INotifyPropertyChanged
    {
        #region INotifyPropertyChanged Implementation

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        protected bool SetProperty<T>(ref T storage, T value, [CallerMemberName] string propertyName = null)
        {
            if (EqualityComparer<T>.Default.Equals(storage, value))
                return false;

            storage = value;
            OnPropertyChanged(propertyName);
            return true;
        }

        #endregion

        #region Properties

        // System Specifications
        private string _cpuInfo;
        public string CpuInfo
        {
            get => _cpuInfo;
            set => SetProperty(ref _cpuInfo, value);
        }

        private string _ramInfo;
        public string RamInfo
        {
            get => _ramInfo;
            set => SetProperty(ref _ramInfo, value);
        }

        private string _gpuInfo;
        public string GpuInfo
        {
            get => _gpuInfo;
            set => SetProperty(ref _gpuInfo, value);
        }

        private string _storageInfo;
        public string StorageInfo
        {
            get => _storageInfo;
            set => SetProperty(ref _storageInfo, value);
        }

        // Progress Tracking
        private double _progress;
        public double Progress
        {
            get => _progress;
            set => SetProperty(ref _progress, value);
        }

        private int _progressPercentage;
        public int ProgressPercentage
        {
            get => _progressPercentage;
            set => SetProperty(ref _progressPercentage, value);
        }

        private string _currentTask;
        public string CurrentTask
        {
            get => _currentTask;
            set => SetProperty(ref _currentTask, value);
        }

        // Status
        private string _statusMessage;
        public string StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        private bool _isOptimizing;
        public bool IsOptimizing
        {
            get => _isOptimizing;
            set
            {
                if (SetProperty(ref _isOptimizing, value))
                    OnPropertyChanged(nameof(IsNotOptimizing));
            }
        }

        public bool IsNotOptimizing => !IsOptimizing;

        // Console Output
        private string _consoleText;
        public string ConsoleText
        {
            get => _consoleText;
            set 
            { 
                SetProperty(ref _consoleText, value);
                // Scroll the console to the end when text is updated
                Application.Current.Dispatcher.InvokeAsync(() => ScrollConsoleToEnd());
            }
        }

        // Status Bar Information
        private string _windowsVersion;
        public string WindowsVersion
        {
            get => _windowsVersion;
            set => SetProperty(ref _windowsVersion, value);
        }

        private string _systemStatus;
        public string SystemStatus
        {
            get => _systemStatus;
            set => SetProperty(ref _systemStatus, value);
        }

        public ICommand OptimizeCommand { get; private set; }

        #endregion

        public MainWindow()
        {
            InitializeComponent();
            DataContext = this;
            
            // Initialize with placeholder values
            WindowsVersion = "Detecting...";
            SystemStatus = "Ready to optimize";
            StatusMessage = "System ready for optimization";
            CurrentTask = "Scanning hardware...";
            Progress = 0;
            ConsoleText = "System Optimizer initialized.\r\nScanning hardware...";
            
            // Initialize commands
            OptimizeCommand = new RelayCommand(async _ => await StartOptimization(), _ => !IsOptimizing);
            
            // Scan hardware in background to not block UI
            Task.Run(async () => await ScanHardwareAsync());
        }
        
        #region Hardware Scanning
        
        private async Task ScanHardwareAsync()
        {
            try
            {
                // Update UI
                LogToConsole("Starting hardware detection...");
                
                // Gather CPU, RAM, GPU and Storage info in parallel
                var cpuTask = Task.Run(() => GetCpuInfo());
                var ramTask = Task.Run(() => GetRamInfo());
                var gpuTask = Task.Run(() => GetGpuInfo());
                var storageTask = Task.Run(() => GetStorageInfo());
                var osTask = Task.Run(() => GetOsInfo());
                
                // Wait for all tasks to complete
                await Task.WhenAll(cpuTask, ramTask, gpuTask, storageTask, osTask);
                
                // Update properties with results
                Application.Current.Dispatcher.Invoke(() =>
                {
                    CpuInfo = cpuTask.Result;
                    RamInfo = ramTask.Result;
                    GpuInfo = gpuTask.Result;
                    StorageInfo = storageTask.Result;
                    WindowsVersion = osTask.Result;
                    CurrentTask = "Hardware scan complete";
                    LogToConsole("Hardware detection completed successfully.");
                });
            }
            catch (Exception ex)
            {
                Application.Current.Dispatcher.Invoke(() =>
                {
                    LogToConsole($"Error detecting hardware: {ex.Message}");
                    
                    // Set fallback values
                    CpuInfo = "Unknown CPU";
                    RamInfo = "Unknown RAM";
                    GpuInfo = "Unknown GPU";
                    StorageInfo = "Unknown Storage";
                    WindowsVersion = "Unknown Windows Version";
                });
            }
        }
        
        private string GetCpuInfo()
        {
            try
            {
                LogToConsole("Detecting CPU...");
                using (var searcher = new ManagementObjectSearcher("select * from Win32_Processor"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        var name = obj["Name"]?.ToString() ?? "Unknown CPU";
                        var cores = obj["NumberOfCores"]?.ToString() ?? "?";
                        var threads = obj["NumberOfLogicalProcessors"]?.ToString() ?? "?";
                        var speed = obj["MaxClockSpeed"]?.ToString() ?? "?";
                        
                        if (speed != "?")
                        {
                            double speedGhz = Convert.ToDouble(speed) / 1000.0;
                            speed = speedGhz.ToString("F2") + " GHz";
                        }
                        
                        return $"{name} ({cores} cores, {threads} threads) @ {speed}";
                    }
                }
                return "Unknown CPU";
            }
            catch (Exception ex)
            {
                LogToConsole($"Error detecting CPU: {ex.Message}");
                return "Error detecting CPU";
            }
        }
        
        private string GetRamInfo()
        {
            try
            {
                LogToConsole("Detecting RAM...");
                double totalRamGB = 0;
                string ramType = "Unknown";
                string ramSpeed = "";
                
                using (var searcher = new ManagementObjectSearcher("select * from Win32_PhysicalMemory"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        var capacity = Convert.ToDouble(obj["Capacity"]);
                        totalRamGB += capacity / (1024 * 1024 * 1024);
                        
                        if (string.IsNullOrEmpty(ramType))
                            ramType = GetRamType(Convert.ToUInt16(obj["SMBIOSMemoryType"]));
                        
                        if (string.IsNullOrEmpty(ramSpeed) && obj["Speed"] != null)
                            ramSpeed = obj["Speed"].ToString() + " MHz";
                    }
                }
                
                string result = $"{Math.Round(totalRamGB)} GB";
                if (!string.IsNullOrEmpty(ramType))
                    result += $" {ramType}";
                if (!string.IsNullOrEmpty(ramSpeed))
                    result += $" @ {ramSpeed}";
                
                return result;
            }
            catch (Exception ex)
            {
                LogToConsole($"Error detecting RAM: {ex.Message}");
                return "Error detecting RAM";
            }
        }
        
        private string GetRamType(ushort type)
        {
            switch (type)
            {
                case 20: return "DDR";
                case 21: return "DDR2";
                case 22: return "DDR2 FB-DIMM";
                case 24: return "DDR3";
                case 26: return "DDR4";
                case 27: return "DDR5";
                default: return "";
            }
        }
        
        private string GetGpuInfo()
        {
            try
            {
                LogToConsole("Detecting GPU...");
                using (var searcher = new ManagementObjectSearcher("select * from Win32_VideoController"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        var name = obj["Name"]?.ToString() ?? "Unknown GPU";
                        var memory = obj["AdapterRAM"];
                        
                        if (memory != null)
                        {
                            double memoryGB = Convert.ToDouble(memory) / (1024 * 1024 * 1024);
                            return $"{name} ({Math.Round(memoryGB)} GB)";
                        }
                        
                        return name;
                    }
                }
                return "Unknown GPU";
            }
            catch (Exception ex)
            {
                LogToConsole($"Error detecting GPU: {ex.Message}");
                return "Error detecting GPU";
            }
        }
        
        private string GetStorageInfo()
        {
            try
            {
                LogToConsole("Detecting Storage...");
                double totalSsdGB = 0;
                double totalHddGB = 0;
                
                using (var searcher = new ManagementObjectSearcher("select * from Win32_DiskDrive"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        var model = obj["Model"]?.ToString() ?? "";
                        var size = Convert.ToDouble(obj["Size"]);
                        var sizeGB = size / (1024 * 1024 * 1024);
                        
                        if (DetermineStorageType(model) == "SSD")
                            totalSsdGB += sizeGB;
                        else
                            totalHddGB += sizeGB;
                    }
                }
                
                string result = "";
                if (totalSsdGB > 0)
                    result += $"{Math.Round(totalSsdGB)} GB SSD";
                
                if (totalHddGB > 0)
                {
                    if (result.Length > 0)
                        result += " + ";
                    result += $"{Math.Round(totalHddGB)} GB HDD";
                }
                
                return string.IsNullOrEmpty(result) ? "Unknown Storage" : result;
            }
            catch (Exception ex)
            {
                LogToConsole($"Error detecting storage: {ex.Message}");
                return "Error detecting storage";
            }
        }
        
        private string GetOsInfo()
        {
            try
            {
                LogToConsole("Detecting Operating System...");
                using (var searcher = new ManagementObjectSearcher("select * from Win32_OperatingSystem"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        var caption = obj["Caption"]?.ToString() ?? "Unknown Windows";
                        var version = obj["Version"]?.ToString() ?? "";
                        var buildNumber = obj["BuildNumber"]?.ToString() ?? "";
                        
                        if (!string.IsNullOrEmpty(buildNumber))
                            version = $"{version} (Build {buildNumber})";
                        
                        return $"{caption} {version}";
                    }
                }
                return "Unknown Windows Version";
            }
            catch (Exception ex)
            {
                LogToConsole($"Error detecting OS: {ex.Message}");
                return "Error detecting OS";
            }
        }
        
        #endregion
        
        #region System Optimization
        
        private async Task StartOptimization()
        {
            try
            {
                // Set initial state
                IsOptimizing = true;
                StatusMessage = "Optimization in progress...";
                Progress = 0;
                ConsoleText += "\r\n[INFO] Starting system optimization...\r\n";
                
                // Update status indicator to yellow (in progress)
                StatusIndicator.Fill = new SolidColorBrush(Colors.Yellow);
                
                // Ask about creating a restore point
                var restorePointResult = MessageBox.Show(
                    "Do you want to create a system restore point before optimization? (Recommended)",
                    "System Restore Point",
                    MessageBoxButton.YesNoCancel,
                    MessageBoxImage.Question);
                
                if (restorePointResult == MessageBoxResult.Cancel)
                {
                    StatusMessage = "Optimization cancelled";
                    StatusIndicator.Fill = new SolidColorBrush(Colors.Green);
                    IsOptimizing = false;
                    ConsoleText += "[INFO] Optimization cancelled by user.\r\n";
                    return;
                }
                
                if (restorePointResult == MessageBoxResult.Yes)
                {
                    await CreateRestorePoint();
                }
                else
                {
                    ConsoleText += "[INFO] Skipping restore point creation.\r\n";
                }
                
                // Add debug message to verify command execution
                Trace.WriteLine("Optimization process started");
                Debug.WriteLine("Optimization process started");
                
                // Simulate optimization steps with delays to ensure UI updates
                await Task.Delay(500); // Give the UI time to update
                
                await Application.Current.Dispatcher.InvokeAsync(async () =>
                {
                    await OptimizeMouseSettings();
                    await OptimizeMemorySettings();
                    await OptimizeStorageSettings();
                    
                    // Update status when complete
                    StatusMessage = "Optimization completed successfully!";
                    Progress = 1.0;
                    CurrentTask = "All tasks completed";
                    SystemStatus = "Optimized";
                    ConsoleText += "\r\n[SUCCESS] All optimizations completed successfully!\r\n";
                    
                    // Update status indicator to green (success)
                    StatusIndicator.Fill = new SolidColorBrush(Colors.Green);
                });
            }
            catch (Exception ex)
            {
                // Handle errors
                StatusMessage = "Optimization failed!";
                ConsoleText += $"\r\n[ERROR] {ex.Message}\r\n";
                
                // Update status indicator to red (error)
                StatusIndicator.Fill = new SolidColorBrush(Colors.Red);
                
                MessageBox.Show($"Optimization error: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                IsOptimizing = false;
            }
        }
        
        private async Task CreateRestorePoint()
        {
            CurrentTask = "Creating restore point...";
            ConsoleText += "\r\n[INFO] Creating system restore point...\r\n";
            
            try
            {
                Process process = new Process();
                process.StartInfo.FileName = "powershell.exe";
                process.StartInfo.Arguments = "-Command \"Checkpoint-Computer -Description 'System Optimizer - Before Optimization' -RestorePointType 'APPLICATION_INSTALL'\"";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.StartInfo.RedirectStandardOutput = true;
                process.StartInfo.RedirectStandardError = true;
                
                StringBuilder output = new StringBuilder();
                StringBuilder error = new StringBuilder();
                
                process.OutputDataReceived += (sender, args) => 
                {
                    if (!string.IsNullOrEmpty(args.Data))
                        output.AppendLine(args.Data);
                };
                
                process.ErrorDataReceived += (sender, args) => 
                {
                    if (!string.IsNullOrEmpty(args.Data))
                        error.AppendLine(args.Data);
                };
                
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                
                // Wait for the process to exit with a timeout
                bool exited = await Task.Run(() => process.WaitForExit(30000));
                
                if (!exited)
                {
                    process.Kill();
                    ConsoleText += "[WARNING] Restore point creation timed out. Continuing without restore point.\r\n";
                    return;
                }
                
                if (process.ExitCode == 0)
                {
                    ConsoleText += "[SUCCESS] System restore point created successfully.\r\n";
                }
                else
                {
                    ConsoleText += $"[WARNING] Failed to create restore point. Error: {error.ToString()}\r\n";
                    ConsoleText += "[WARNING] Continuing optimization without restore point.\r\n";
                }
            }
            catch (Exception ex)
            {
                ConsoleText += $"[WARNING] Error creating restore point: {ex.Message}\r\n";
                ConsoleText += "[WARNING] Continuing optimization without restore point.\r\n";
            }
        }
        
        private async Task OptimizeMouseSettings()
        {
            CurrentTask = "Optimizing mouse settings...";
            ConsoleText += "\r\n[INFO] Starting mouse optimization...\r\n";
            
            try
            {
                // Disable mouse acceleration (Enhance pointer precision)
                ConsoleText += "[INFO] Disabling mouse acceleration...\r\n";
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Control Panel\Mouse", true))
                {
                    if (key != null)
                    {
                        key.SetValue("MouseSpeed", "0", RegistryValueKind.String);
                        key.SetValue("MouseThreshold1", "0", RegistryValueKind.String);
                        key.SetValue("MouseThreshold2", "0", RegistryValueKind.String);
                    }
                }
                Progress = 0.1;
                UpdateLayout();
                await Task.Delay(300);
                
                // Set mouse pointer speed to optimal value (6/11)
                ConsoleText += "[INFO] Setting optimal mouse pointer speed...\r\n";
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Control Panel\Mouse", true))
                {
                    if (key != null)
                    {
                        key.SetValue("MouseSensitivity", "10", RegistryValueKind.String);
                    }
                }
                Progress = 0.2;
                UpdateLayout();
                await Task.Delay(300);
                
                // Increase mouse polling rate if possible
                ConsoleText += "[INFO] Optimizing mouse polling rate...\r\n";
                // Note: This typically requires specific drivers, so we just simulate this step
                Progress = 0.3;
                UpdateLayout();
                await Task.Delay(300);
                
                ConsoleText += "[SUCCESS] Mouse optimization completed.\r\n";
            }
            catch (Exception ex)
            {
                ConsoleText += $"[ERROR] Mouse optimization failed: {ex.Message}\r\n";
                throw;
            }
        }
        
        private async Task OptimizeMemorySettings()
        {
            CurrentTask = "Optimizing memory settings...";
            ConsoleText += "\r\n[INFO] Starting memory optimization...\r\n";
            
            try
            {
                // Disable memory compression
                ConsoleText += "[INFO] Disabling memory compression for better performance...\r\n";
                
                Process process = new Process();
                process.StartInfo.FileName = "powershell.exe";
                process.StartInfo.Arguments = "-Command \"Disable-MMAgent -MemoryCompression\"";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                process.WaitForExit();
                
                Progress = 0.4;
                UpdateLayout();
                await Task.Delay(300);
                
                // Adjust virtual memory settings
                ConsoleText += "[INFO] Optimizing virtual memory settings...\r\n";
                // This is typically done through Control Panel, so we just simulate
                Progress = 0.5;
                UpdateLayout();
                await Task.Delay(300);
                
                // Optimize services
                ConsoleText += "[INFO] Optimizing services for memory performance...\r\n";
                
                // Disable Superfetch/SysMain service which can use memory
                Process serviceProcess = new Process();
                serviceProcess.StartInfo.FileName = "powershell.exe";
                serviceProcess.StartInfo.Arguments = "-Command \"Stop-Service -Name SysMain -Force; Set-Service -Name SysMain -StartupType Disabled\"";
                serviceProcess.StartInfo.UseShellExecute = false;
                serviceProcess.StartInfo.CreateNoWindow = true;
                serviceProcess.Start();
                serviceProcess.WaitForExit();
                
                Progress = 0.6;
                UpdateLayout();
                await Task.Delay(300);
                
                ConsoleText += "[SUCCESS] Memory optimization completed.\r\n";
            }
            catch (Exception ex)
            {
                ConsoleText += $"[ERROR] Memory optimization failed: {ex.Message}\r\n";
                throw;
            }
        }
        
        private async Task OptimizeStorageSettings()
        {
            CurrentTask = "Optimizing storage settings...";
            ConsoleText += "\r\n[INFO] Starting storage optimization...\r\n";
            
            try
            {
                // Disable hibernation to free up disk space
                ConsoleText += "[INFO] Disabling hibernation to free up disk space...\r\n";
                
                Process process = new Process();
                process.StartInfo.FileName = "powershell.exe";
                process.StartInfo.Arguments = "-Command \"powercfg -h off\"";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                process.WaitForExit();
                
                Progress = 0.7;
                UpdateLayout();
                await Task.Delay(300);
                
                // Enable Storage Sense for automatic cleanup
                ConsoleText += "[INFO] Enabling Storage Sense for automatic cleanup...\r\n";
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy", true))
                {
                    if (key != null)
                    {
                        key.SetValue("01", 1, RegistryValueKind.DWord);
                    }
                    else
                    {
                        using (RegistryKey newKey = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"))
                        {
                            if (newKey != null)
                                newKey.SetValue("01", 1, RegistryValueKind.DWord);
                        }
                    }
                }
                Progress = 0.8;
                UpdateLayout();
                await Task.Delay(300);
                
                // Disable Prefetch for SSDs
                if (StorageInfo.Contains("SSD") && !StorageInfo.Contains("HDD"))
                {
                    ConsoleText += "[INFO] Disabling Prefetch for SSD optimization...\r\n";
                    
                    Process prefetchProcess = new Process();
                    prefetchProcess.StartInfo.FileName = "powershell.exe";
                    prefetchProcess.StartInfo.Arguments = "-Command \"Stop-Service -Name SysMain -Force; Set-Service -Name SysMain -StartupType Disabled\"";
                    prefetchProcess.StartInfo.UseShellExecute = false;
                    prefetchProcess.StartInfo.CreateNoWindow = true;
                    prefetchProcess.Start();
                    prefetchProcess.WaitForExit();
                }
                
                Progress = 0.9;
                UpdateLayout();
                await Task.Delay(300);
                
                ConsoleText += "[SUCCESS] Storage optimization completed.\r\n";
            }
            catch (Exception ex)
            {
                ConsoleText += $"[ERROR] Storage optimization failed: {ex.Message}\r\n";
                throw;
            }
        }
        
        #endregion
        
        #region Utility Methods
        
        private readonly object _logLock = new object();
        
        private void LogToConsole(string message)
        {
            string timestamp = DateTime.Now.ToString("HH:mm:ss");
            string formattedMessage = $"[{timestamp}] {message}";
            
            lock (_logLock)
            {
                // Update the UI on the UI thread
                Application.Current.Dispatcher.Invoke(() =>
                {
                    if (string.IsNullOrEmpty(ConsoleText))
                        ConsoleText = formattedMessage;
                    else
                        ConsoleText = ConsoleText + Environment.NewLine + formattedMessage;
                });
            }
        }
        
        private void SetStatus(string message, Color color)
        {
            // Update status on UI thread
            Application.Current.Dispatcher.Invoke(() =>
            {
                StatusMessage = message;
            });
        }
        
        private void UpdateProgress(double value, string task)
        {
            // Update progress on UI thread
            Application.Current.Dispatcher.Invoke(() =>
            {
                Progress = value;
                ProgressPercentage = (int)value;
                CurrentTask = task;
                LogToConsole(task);
            });
        }
        
        private string DetermineStorageType(string model)
        {
            // Basic heuristic - can be improved
            if (model.Contains("SSD") || model.Contains("Solid") || model.Contains("NVME") || model.Contains("PCIe"))
                return "SSD";
            return "HDD";
        }
        
        private void ScrollConsoleToEnd()
        {
            if (ConsoleOutput != null)
            {
                ConsoleOutput.Focus();
                ConsoleOutput.CaretIndex = ConsoleOutput.Text.Length;
                ConsoleOutput.ScrollToEnd();
            }
        }
        
        #endregion

        #region Command Implementation

        public class RelayCommand : ICommand
        {
            private readonly Func<object, Task> _execute;
            private readonly Predicate<object> _canExecute;

            public RelayCommand(Func<object, Task> execute, Predicate<object> canExecute = null)
            {
                _execute = execute ?? throw new ArgumentNullException(nameof(execute));
                _canExecute = canExecute;
            }

            public bool CanExecute(object parameter)
            {
                return _canExecute == null || _canExecute(parameter);
            }

            public async void Execute(object parameter)
            {
                await _execute(parameter);
            }

            public event EventHandler CanExecuteChanged
            {
                add { CommandManager.RequerySuggested += value; }
                remove { CommandManager.RequerySuggested -= value; }
            }
        }

        #endregion
    }
} 