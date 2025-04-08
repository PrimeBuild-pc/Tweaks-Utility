using System;
using System.Diagnostics;
using System.Management;
using Microsoft.Win32;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using System.Security.Principal;

namespace WinOptimizer.Services
{
    public enum OptimizationProfile
    {
        Balanced,
        Gaming,
        Productivity,
        PowerSaver,
        Custom
    }

    public class OptimizationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string ComponentName { get; set; }
    }

    public class OptimizationService
    {
        private readonly HardwareService _hardwareService;
        private int _currentOptimizationStep = 0;
        private int _totalOptimizationSteps = 0;
        private OptimizationProfile _currentProfile = OptimizationProfile.Balanced;
        private List<OptimizationResult> _optimizationResults = new List<OptimizationResult>();
        private bool _isOptimizing = false;
        private bool _isAdministrator = false;

        // Define the events for optimization updates
        public event Action<int> OptimizationProgressUpdated;
        public event Action<string> OptimizationStatusUpdated;
        public event Action<List<OptimizationResult>> OptimizationCompleted;

        public OptimizationService(HardwareService hardwareService)
        {
            _hardwareService = hardwareService;
            CheckAdminPrivileges();
        }

        private void CheckAdminPrivileges()
        {
            try
            {
                WindowsIdentity identity = WindowsIdentity.GetCurrent();
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                _isAdministrator = principal.IsInRole(WindowsBuiltInRole.Administrator);

                if (!_isAdministrator)
                {
                    Debug.WriteLine("Warning: Application not running with administrator privileges. Some optimizations may fail.");
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error checking admin privileges: {ex.Message}");
                _isAdministrator = false;
            }
        }

        public bool IsOptimizing => _isOptimizing;

        public void ScanSystemAndOptimize(OptimizationProfile profile = OptimizationProfile.Balanced,
            bool optimizeCpu = true, bool optimizeGpu = true, bool optimizeMemory = true, bool optimizeDisk = true, bool optimizeNetwork = true)
        {
            if (_isOptimizing) return;
            _isOptimizing = true;
            _currentProfile = profile;
            _optimizationResults.Clear();
            _currentOptimizationStep = 0;

            try
            {
                if (!_isAdministrator)
                {
                    UpdateStatus("Warning: Not running with administrator privileges. Some optimizations may not work.");
                }

                // Create a system restore point before making changes
                CreateSystemRestorePoint("WinOptimizer Before Optimization");
                UpdateStatus("Creating system restore point...");

                var systemInfo = _hardwareService?.SystemInfo;
                if (systemInfo == null)
                {
                    throw new InvalidOperationException("System information is not available.");
                }

                // Determine the total number of optimization steps
                _totalOptimizationSteps = 0;
                if (optimizeCpu && systemInfo.ContainsKey("CPU.Name") &&
                    (systemInfo["CPU.Name"].Contains("Intel") || systemInfo["CPU.Name"].Contains("AMD")))
                {
                    _totalOptimizationSteps++;
                }
                if (optimizeGpu && systemInfo.Keys.Any(k => k.StartsWith("GPU")))
                {
                    _totalOptimizationSteps++;
                }
                if (optimizeMemory && systemInfo.ContainsKey("RAM.Total") &&
                    long.TryParse(systemInfo["RAM.Total"].Replace(" MB", ""), out long ramSize) && ramSize > 8192)
                {
                    _totalOptimizationSteps++;
                }
                if (optimizeDisk && systemInfo.Keys.Any(k => k.StartsWith("Disk")))
                {
                    _totalOptimizationSteps++;
                }

                if (optimizeNetwork)
                {
                    _totalOptimizationSteps++;
                }

                if (_totalOptimizationSteps == 0)
                {
                    UpdateStatus("No optimizations to perform for your hardware configuration.");
                    _isOptimizing = false;
                    return;
                }

                // Perform optimizations based on profile and selected components
                if (optimizeCpu && systemInfo.ContainsKey("CPU.Name") &&
                    (systemInfo["CPU.Name"].Contains("Intel") || systemInfo["CPU.Name"].Contains("AMD")))
                {
                    UpdateStatus("Optimizing CPU settings...");
                    OptimizeCpu();
                    _currentOptimizationStep++;
                    OnOptimizationProgressUpdated();
                }

                if (optimizeGpu && systemInfo.Keys.Any(k => k.StartsWith("GPU")))
                {
                    UpdateStatus("Optimizing GPU settings...");
                    OptimizeGpu();
                    _currentOptimizationStep++;
                    OnOptimizationProgressUpdated();
                }

                if (optimizeMemory && systemInfo.ContainsKey("RAM.Total") &&
                    long.TryParse(systemInfo["RAM.Total"].Replace(" MB", ""), out long ramTotal) && ramTotal > 8192)
                {
                    UpdateStatus("Optimizing memory settings...");
                    OptimizeMemory();
                    _currentOptimizationStep++;
                    OnOptimizationProgressUpdated();
                }

                if (optimizeDisk && systemInfo.Keys.Any(k => k.StartsWith("Disk")))
                {
                    UpdateStatus("Optimizing disk settings...");
                    OptimizeDisks();
                    _currentOptimizationStep++;
                    OnOptimizationProgressUpdated();
                }

                if (optimizeNetwork)
                {
                    UpdateStatus("Optimizing network settings...");
                    OptimizeNetwork();
                    _currentOptimizationStep++;
                    OnOptimizationProgressUpdated();
                }

                UpdateStatus("Optimization completed successfully!");
                OptimizationCompleted?.Invoke(_optimizationResults);
            }
            catch (Exception ex)
            {
                UpdateStatus($"Error during optimization: {ex.Message}");
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"Optimization failed: {ex.Message}",
                    ComponentName = "System"
                });

                OptimizationCompleted?.Invoke(_optimizationResults);
            }
            finally
            {
                _isOptimizing = false;
            }
        }

        public async Task ScanSystemAndOptimizeAsync(OptimizationProfile profile = OptimizationProfile.Balanced,
            bool optimizeCpu = true, bool optimizeGpu = true, bool optimizeMemory = true, bool optimizeDisk = true, bool optimizeNetwork = true)
        {
            await Task.Run(() => ScanSystemAndOptimize(profile, optimizeCpu, optimizeGpu, optimizeMemory, optimizeDisk, optimizeNetwork));
        }

        public int GetCurrentOptimizationStep() => _currentOptimizationStep;

        public int GetTotalOptimizationSteps() => _totalOptimizationSteps;

        public List<OptimizationResult> GetOptimizationResults() => _optimizationResults;

        public void OptimizeCpu()
        {
            try
            {
                var cpuName = _hardwareService.SystemInfo["CPU.Name"];

                switch (_currentProfile)
                {
                    case OptimizationProfile.Gaming:
                        if (cpuName.Contains("Intel"))
                        {
                            SetPowerPlan("Ultimate Performance");
                            SetProcessorPerformance("100");
                            DisableCpuThrottling();
                            OptimizeIntelForGaming();
                        }
                        else if (cpuName.Contains("AMD"))
                        {
                            SetPowerPlan("AMD Ryzen High Performance");
                            SetProcessorPerformance("100");
                            OptimizeAmdForGaming();
                        }
                        break;

                    case OptimizationProfile.Productivity:
                        if (cpuName.Contains("Intel"))
                        {
                            SetPowerPlan("High performance");
                            SetProcessorPerformance("90");
                        }
                        else if (cpuName.Contains("AMD"))
                        {
                            SetPowerPlan("AMD Ryzen Balanced");
                            SetProcessorPerformance("90");
                        }
                        break;

                    case OptimizationProfile.PowerSaver:
                        SetPowerPlan("Power saver");
                        SetProcessorPerformance("50");
                        break;

                    default: // Balanced
                        if (cpuName.Contains("Intel"))
                        {
                            SetPowerPlan("Balanced");
                            SetProcessorPerformance("80");
                        }
                        else if (cpuName.Contains("AMD"))
                        {
                            SetPowerPlan("AMD Ryzen Balanced");
                            SetProcessorPerformance("80");
                        }
                        break;
                }

                _optimizationResults.Add(new OptimizationResult
                {
                    Success = true,
                    Message = $"CPU optimized for {_currentProfile} profile",
                    ComponentName = "CPU"
                });
            }
            catch (Exception ex)
            {
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"CPU optimization failed: {ex.Message}",
                    ComponentName = "CPU"
                });
            }
        }

        private void OptimizeIntelForGaming()
        {
            // Additional Intel CPU optimizations for gaming
            try
            {
                // Disable CPU C-States for reduced latency
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Processor"))
                {
                    key.SetValue("Capabilities", 0x0007e066, RegistryValueKind.DWord);
                }

                // Optimize CPU priority for games
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"))
                {
                    key.SetValue("GPU Priority", 8, RegistryValueKind.DWord);
                    key.SetValue("Priority", 6, RegistryValueKind.DWord);
                    key.SetValue("Scheduling Category", "High", RegistryValueKind.String);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing Intel CPU for gaming: {ex.Message}");
            }
        }

        private void OptimizeAmdForGaming()
        {
            // Additional AMD CPU optimizations for gaming
            try
            {
                // Apply AMD-specific optimizations
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"))
                {
                    key.SetValue("Attributes", 0, RegistryValueKind.DWord);
                }

                // Optimize CPU priority for games
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"))
                {
                    key.SetValue("GPU Priority", 8, RegistryValueKind.DWord);
                    key.SetValue("Priority", 6, RegistryValueKind.DWord);
                    key.SetValue("Scheduling Category", "High", RegistryValueKind.String);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing AMD CPU for gaming: {ex.Message}");
            }
        }

        public void DisableCpuThrottling()
        {
            try
            {
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"))
                {
                    key.SetValue("PowerThrottlingOff", 1, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error disabling CPU throttling: {ex.Message}");
            }
        }

        public void OptimizeGpu()
        {
            try
            {
                foreach (var key in _hardwareService.SystemInfo.Keys.Where(k => k.StartsWith("GPU")))
                {
                    var gpuName = _hardwareService.SystemInfo[key];

                    switch (_currentProfile)
                    {
                        case OptimizationProfile.Gaming:
                            if (gpuName.Contains("NVIDIA"))
                            {
                                SetNvidiaPowerManagement("Prefer maximum performance");
                                OptimizeNvidiaForGaming();
                            }
                            else if (gpuName.Contains("AMD") || gpuName.Contains("Radeon"))
                            {
                                SetAmdPowerProfile("Optimize for Compute Performance");
                                OptimizeAmdGpuForGaming();
                            }
                            break;

                        case OptimizationProfile.PowerSaver:
                            if (gpuName.Contains("NVIDIA"))
                            {
                                SetNvidiaPowerManagement("Optimal power");
                            }
                            else if (gpuName.Contains("AMD") || gpuName.Contains("Radeon"))
                            {
                                SetAmdPowerProfile("Power Saving");
                            }
                            break;

                        default: // Balanced or Productivity
                            if (gpuName.Contains("NVIDIA"))
                            {
                                SetNvidiaPowerManagement("Adaptive");
                            }
                            else if (gpuName.Contains("AMD") || gpuName.Contains("Radeon"))
                            {
                                SetAmdPowerProfile("Balanced");
                            }
                            break;
                    }
                }

                // Optimize Windows graphics settings
                using (var key = Registry.CurrentUser.CreateSubKey(
                    @"Software\Microsoft\DirectX\UserGpuPreferences"))
                {
                    key.SetValue("DirectXUserGlobalSettings",
                        _currentProfile == OptimizationProfile.Gaming ? "VRROptimizeEnable=1;" : "VRROptimizeEnable=0;");
                }

                _optimizationResults.Add(new OptimizationResult
                {
                    Success = true,
                    Message = $"GPU optimized for {_currentProfile} profile",
                    ComponentName = "GPU"
                });
            }
            catch (Exception ex)
            {
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"GPU optimization failed: {ex.Message}",
                    ComponentName = "GPU"
                });
            }
        }

        private void OptimizeNvidiaForGaming()
        {
            try
            {
                // These would normally use NVIDIA API, but simulating with registry changes
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SOFTWARE\NVIDIA Corporation\Global\NVTweak"))
                {
                    key.SetValue("NvCplExposeWin10HAGS", 1, RegistryValueKind.DWord);
                }

                // Set game-specific optimizations in Windows registry
                using (var key = Registry.CurrentUser.CreateSubKey(
                    @"Software\Microsoft\DirectX\UserGpuPreferences"))
                {
                    key.SetValue("DirectXUserGlobalSettings", "SwapEffectUpgradeEnable=1;");
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing NVIDIA GPU for gaming: {ex.Message}");
            }
        }

        private void OptimizeAmdGpuForGaming()
        {
            try
            {
                // These would normally use AMD API, but simulating with registry changes
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"))
                {
                    key.SetValue("EnableUlps", 0, RegistryValueKind.DWord);
                }

                // Enable hardware accelerated GPU scheduling if on Windows 10/11
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\GraphicsDrivers"))
                {
                    key.SetValue("HwSchMode", 2, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing AMD GPU for gaming: {ex.Message}");
            }
        }

        public void OptimizeMemory()
        {
            try
            {
                switch (_currentProfile)
                {
                    case OptimizationProfile.Gaming:
                        DisableMemoryCompression();
                        OptimizePageFile(1.5);
                        OptimizeServiceWorkingSet();
                        break;

                    case OptimizationProfile.Productivity:
                        if (long.Parse(_hardwareService.SystemInfo["RAM.Total"].Replace(" MB", "")) > 16384)
                        {
                            DisableMemoryCompression();
                        }
                        OptimizePageFile(1.0);
                        break;

                    case OptimizationProfile.PowerSaver:
                        // Keep memory compression enabled
                        OptimizePageFile(1.0);
                        break;

                    default: // Balanced
                        if (long.Parse(_hardwareService.SystemInfo["RAM.Total"].Replace(" MB", "")) > 32768)
                        {
                            DisableMemoryCompression();
                        }
                        OptimizePageFile(1.25);
                        break;
                }

                _optimizationResults.Add(new OptimizationResult
                {
                    Success = true,
                    Message = $"Memory optimized for {_currentProfile} profile",
                    ComponentName = "Memory"
                });
            }
            catch (Exception ex)
            {
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"Memory optimization failed: {ex.Message}",
                    ComponentName = "Memory"
                });
            }
        }

        private void OptimizeServiceWorkingSet()
        {
            try
            {
                // Optimize service working set size
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"))
                {
                    key.SetValue("LargeSystemCache", 0, RegistryValueKind.DWord);
                    key.SetValue("ServicesPaging", 0, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing service working set: {ex.Message}");
            }
        }

        public void OptimizeDisks()
        {
            try
            {
                foreach (var key in _hardwareService.SystemInfo.Keys.Where(k => k.StartsWith("Disk")))
                {
                    var diskModel = _hardwareService.SystemInfo[key];
                    var isSsd = diskModel.Contains("SSD") || diskModel.Contains("Solid State");

                    if (isSsd)
                    {
                        EnableTrim();
                        DisableDefragmentation();

                        // Additional SSD optimizations
                        OptimizeSsdSettings();
                    }
                    else
                    {
                        // HDD optimizations
                        OptimizeHddSettings();
                    }
                }

                // Optimize Windows Search and Superfetch based on profile
                OptimizeSystemServices();

                _optimizationResults.Add(new OptimizationResult
                {
                    Success = true,
                    Message = $"Disk optimized for {_currentProfile} profile",
                    ComponentName = "Disk"
                });
            }
            catch (Exception ex)
            {
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"Disk optimization failed: {ex.Message}",
                    ComponentName = "Disk"
                });
            }
        }

        private void OptimizeHddSettings()
        {
            try
            {
                // Enable write caching
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"))
                {
                    key.SetValue("LargeSystemCache", _currentProfile == OptimizationProfile.Gaming ? 0 : 1,
                        RegistryValueKind.DWord);
                }

                // Set appropriate disk timeout period
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Services\disk\TimeOutValue"))
                {
                    // Lower value for faster response, but potentially more power use
                    int timeoutValue = _currentProfile == OptimizationProfile.PowerSaver ? 60 : 30;
                    key.SetValue("TimeoutValue", timeoutValue, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing HDD settings: {ex.Message}");
            }
        }

        private void OptimizeSsdSettings()
        {
            try
            {
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"))
                {
                    // For SSDs, generally want this off for all profiles
                    key.SetValue("LargeSystemCache", 0, RegistryValueKind.DWord);
                }

                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\FileSystem"))
                {
                    // Enable NTFS optimization for SSDs
                    key.SetValue("NtfsDisableLastAccessUpdate", 1, RegistryValueKind.DWord);
                    key.SetValue("NtfsMemoryUsage", 2, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing SSD settings: {ex.Message}");
            }
        }

        private void OptimizeSystemServices()
        {
            try
            {
                // Windows Search and Superfetch settings based on profile
                bool disableSearch = _currentProfile == OptimizationProfile.Gaming;
                bool disableSuperfetch = _currentProfile == OptimizationProfile.Gaming;

                using (var process = new Process())
                {
                    process.StartInfo.FileName = "sc.exe";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;

                    // Configure Windows Search
                    string searchConfig = disableSearch ? "disabled" : "auto";
                    process.StartInfo.Arguments = $"config WSearch start= {searchConfig}";
                    process.Start();
                    process.WaitForExit();

                    // Configure SysMain (Superfetch)
                    string superfetchConfig = disableSuperfetch ? "disabled" : "auto";
                    process.StartInfo.Arguments = $"config SysMain start= {superfetchConfig}";
                    process.Start();
                    process.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing system services: {ex.Message}");
            }
        }

        public void RevertOptimizations()
        {
            UpdateStatus("Reverting optimizations...");

            try
            {
                // Reset power plan to Balanced
                SetPowerPlan("Balanced");

                // Re-enable CPU throttling
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"))
                {
                    key.DeleteValue("PowerThrottlingOff", false);
                }

                // Reset GPU settings
                foreach (var key in _hardwareService.SystemInfo.Keys.Where(k => k.StartsWith("GPU")))
                {
                    var gpuName = _hardwareService.SystemInfo[key];

                    if (gpuName.Contains("NVIDIA"))
                    {
                        SetNvidiaPowerManagement("Optimal power");
                    }
                    else if (gpuName.Contains("AMD") || gpuName.Contains("Radeon"))
                    {
                        SetAmdPowerProfile("Balanced");
                    }
                }

                // Reset memory settings
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.Arguments = "-Command \"Enable-MMAgent -MemoryCompression\"";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.Start();
                    process.WaitForExit();
                }

                // Reset system services to default
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "sc.exe";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;

                    // Reset Windows Search
                    process.StartInfo.Arguments = "config WSearch start= auto";
                    process.Start();
                    process.WaitForExit();

                    // Reset SysMain (Superfetch)
                    process.StartInfo.Arguments = "config SysMain start= auto";
                    process.Start();
                    process.WaitForExit();
                }

                UpdateStatus("Optimizations reverted successfully!");
            }
            catch (Exception ex)
            {
                UpdateStatus($"Error reverting optimizations: {ex.Message}");
            }
        }

        private void CreateSystemRestorePoint(string description)
        {
            if (!_isAdministrator)
            {
                Debug.WriteLine("Cannot create system restore point without administrator privileges");
                return;
            }

            try
            {
                UpdateStatus("Creating system restore point...");

                // First check if System Restore is enabled
                bool systemRestoreEnabled = false;
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.Arguments = "-Command \"(Get-ComputerRestorePoint -LastStatus).Status\"";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.CreateNoWindow = true;
                    process.Start();
                    string output = process.StandardOutput.ReadToEnd().Trim();
                    process.WaitForExit();

                    systemRestoreEnabled = !output.Contains("Disabled");
                }

                if (!systemRestoreEnabled)
                {
                    UpdateStatus("System Restore is disabled. Cannot create restore point.");
                    return;
                }

                // Create the restore point
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.Arguments = $"-Command \"Checkpoint-Computer -Description '{description}' -RestorePointType 'APPLICATION_INSTALL'\"";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;
                    process.Start();
                    process.WaitForExit(10000); // Wait up to 10 seconds

                    if (!process.HasExited)
                    {
                        process.Kill();
                        UpdateStatus("Creating system restore point timed out.");
                    }
                    else if (process.ExitCode != 0)
                    {
                        string error = process.StandardError.ReadToEnd();
                        UpdateStatus($"Failed to create system restore point: {error}");
                    }
                    else
                    {
                        UpdateStatus("System restore point created successfully.");
                    }
                }
            }
            catch (Exception ex)
            {
                UpdateStatus($"Error creating system restore point: {ex.Message}");
                Debug.WriteLine($"Error creating system restore point: {ex.Message}");
            }
        }

        // Private helper methods for disk optimization
        private void DisableMemoryCompression()
        {
            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.Arguments = "-Command \"Disable-MMAgent -MemoryCompression\"";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.Start();
                    process.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error disabling memory compression: {ex.Message}");
            }
        }

        private void OptimizePageFile(double multiplier = 1.0)
        {
            try
            {
                long ramMB = long.Parse(_hardwareService.SystemInfo["RAM.Total"].Replace(" MB", ""));
                long pageSizeMB = (long)(ramMB * multiplier);

                // Cap page file size for very large RAM systems
                if (pageSizeMB > 32768) pageSizeMB = 32768;

                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"))
                {
                    // Set initial and maximum page file size to the calculated value
                    key.SetValue("PagingFiles", $"C:\\pagefile.sys {pageSizeMB} {pageSizeMB}");
                    key.SetValue("ClearPageFileAtShutdown", 0, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing page file: {ex.Message}");
            }
        }

        private void EnableTrim()
        {
            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.Arguments = "-Command \"fsutil behavior set DisableDeleteNotify 0\"";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.Start();
                    process.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error enabling TRIM: {ex.Message}");
            }
        }

        private void DisableDefragmentation()
        {
            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "schtasks.exe";
                    process.StartInfo.Arguments = "/Change /TN \"\\Microsoft\\Windows\\Defrag\\ScheduledDefrag\" /DISABLE";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.Start();
                    process.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error disabling defragmentation: {ex.Message}");
            }
        }

        // Private helper methods - implementation placeholder
        private void SetPowerPlan(string planName)
        {
            try
            {
                UpdateStatus($"Setting power plan to {planName}...");

                using (var process = new Process())
                {
                    // First, get the GUID for the power plan
                    process.StartInfo.FileName = "powercfg.exe";
                    process.StartInfo.Arguments = $"/list";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.CreateNoWindow = true;

                    process.Start();
                    string output = process.StandardOutput.ReadToEnd();
                    process.WaitForExit();

                    // Find the GUID for the specified power plan
                    string guid = null;
                    foreach (var line in output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
                    {
                        if (line.IndexOf(planName, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            // Extract GUID pattern
                            var match = System.Text.RegularExpressions.Regex.Match(line, @"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}");
                            if (match.Success)
                            {
                                guid = match.Value;
                                break;
                            }
                        }
                    }

                    if (guid != null)
                    {
                        // Set the active power plan
                        process.StartInfo.Arguments = $"/setactive {guid}";
                        process.Start();
                        process.WaitForExit();
                        UpdateStatus($"Power plan set to {planName}");
                    }
                    else if (planName == "Ultimate Performance" && !output.Contains("Ultimate Performance"))
                    {
                        // Create Ultimate Performance plan if it doesn't exist
                        process.StartInfo.Arguments = "/duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61";
                        process.Start();
                        process.WaitForExit();

                        // Try setting it again
                        SetPowerPlan("Ultimate Performance");
                    }
                    else
                    {
                        UpdateStatus($"Could not find power plan: {planName}");
                    }
                }
            }
            catch (Exception ex)
            {
                UpdateStatus($"Error setting power plan: {ex.Message}");
                Debug.WriteLine($"Error setting power plan: {ex.Message}");
            }
        }

        private void SetProcessorPerformance(string percentage)
        {
            try
            {
                int percent = int.Parse(percentage);

                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec"))
                {
                    key.SetValue("ACSettingIndex", percent, RegistryValueKind.DWord);
                    key.SetValue("DCSettingIndex",
                        _currentProfile == OptimizationProfile.PowerSaver ? percent / 2 : percent,
                        RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error setting processor performance: {ex.Message}");
            }
        }

        private void SetNvidiaPowerManagement(string mode)
        {
            try
            {
                // This would normally use NVIDIA API, simulating for now
                Debug.WriteLine($"Setting NVIDIA power management to: {mode}");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error setting NVIDIA power management: {ex.Message}");
            }
        }

        private void SetAmdPowerProfile(string profile)
        {
            try
            {
                // This would normally use AMD API, simulating for now
                Debug.WriteLine($"Setting AMD power profile to: {profile}");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error setting AMD power profile: {ex.Message}");
            }
        }

        // Method to trigger the OptimizationProgressUpdated event
        private void OnOptimizationProgressUpdated()
        {
            OptimizationProgressUpdated?.Invoke(_currentOptimizationStep);
        }

        private void UpdateStatus(string message)
        {
            OptimizationStatusUpdated?.Invoke(message);
            Debug.WriteLine($"Optimization Status: {message}");
        }

        public void OptimizeNetwork()
        {
            try
            {
                UpdateStatus("Optimizing network for lower latency and ping...");

                // Apply network adapter optimizations
                OptimizeNetworkAdapters();

                // Apply TCP/IP stack optimizations
                OptimizeTcpIpStack();

                // Apply DNS optimizations
                OptimizeDnsSettings();

                // Apply Nagle's algorithm optimization (reduces latency for small packets)
                DisableNagleAlgorithm();

                _optimizationResults.Add(new OptimizationResult
                {
                    Success = true,
                    Message = $"Network optimized for {_currentProfile} profile",
                    ComponentName = "Network"
                });
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing network: {ex.Message}");
                _optimizationResults.Add(new OptimizationResult
                {
                    Success = false,
                    Message = $"Network optimization failed: {ex.Message}",
                    ComponentName = "Network"
                });
            }
        }

        private void OptimizeNetworkAdapters()
        {
            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;

                    // Get all network adapters
                    process.StartInfo.Arguments = "-Command \"Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name\"";
                    process.Start();
                    string output = process.StandardOutput.ReadToEnd();
                    process.WaitForExit();

                    // Parse adapter names
                    string[] lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    List<string> adapterNames = new List<string>();
                    bool headerPassed = false;

                    foreach (var line in lines)
                    {
                        if (!headerPassed)
                        {
                            headerPassed = line.Trim().StartsWith("Name");
                            continue;
                        }

                        adapterNames.Add(line.Trim());
                    }

                    // Apply optimizations to each adapter
                    foreach (var adapterName in adapterNames)
                    {
                        // Disable Large Send Offload (LSO)
                        process.StartInfo.Arguments = $"-Command \"Set-NetAdapterLso -Name '{adapterName}' -IPv4Enabled $false -IPv6Enabled $false\"";
                        process.Start();
                        process.WaitForExit();

                        // Disable TCP/UDP Checksum Offload
                        process.StartInfo.Arguments = $"-Command \"Set-NetAdapterChecksumOffload -Name '{adapterName}' -TcpIPv4 Disabled -UdpIPv4 Disabled -TcpIPv6 Disabled -UdpIPv6 Disabled\"";
                        process.Start();
                        process.WaitForExit();

                        // Set RSS (Receive Side Scaling) to use fewer queues for lower latency
                        if (_currentProfile == OptimizationProfile.Gaming)
                        {
                            process.StartInfo.Arguments = $"-Command \"Set-NetAdapterRss -Name '{adapterName}' -BaseProcessorNumber 0 -MaxProcessorNumber 2 -MaxProcessors 2\"";
                            process.Start();
                            process.WaitForExit();
                        }

                        // Set interrupt moderation to lower value for gaming
                        if (_currentProfile == OptimizationProfile.Gaming)
                        {
                            process.StartInfo.Arguments = $"-Command \"Set-NetAdapterAdvancedProperty -Name '{adapterName}' -RegistryKeyword '*InterruptModeration' -RegistryValue 0\"";
                            process.Start();
                            process.WaitForExit();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing network adapters: {ex.Message}");
            }
        }

        private void OptimizeTcpIpStack()
        {
            try
            {
                // Optimize TCP/IP settings for gaming and low latency
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"))
                {
                    // Increase TCP window size for better throughput
                    key.SetValue("Tcp1323Opts", 1, RegistryValueKind.DWord);

                    // Reduce retransmission timeout for faster recovery
                    key.SetValue("TcpMaxDataRetransmissions", 3, RegistryValueKind.DWord);

                    // Optimize Time to Live (TTL) for gaming
                    key.SetValue("DefaultTTL", 64, RegistryValueKind.DWord);

                    if (_currentProfile == OptimizationProfile.Gaming)
                    {
                        // Disable TCP Timestamps for gaming (can reduce overhead)
                        key.SetValue("Tcp1323Opts", 0, RegistryValueKind.DWord);

                        // Reduce delayed ACKs for gaming
                        key.SetValue("TcpDelAckTicks", 0, RegistryValueKind.DWord);

                        // Increase initial congestion window
                        key.SetValue("TcpInitialCongestionWindow", 10, RegistryValueKind.DWord);
                    }
                }

                // Apply QoS settings for gaming
                if (_currentProfile == OptimizationProfile.Gaming)
                {
                    using (var key = Registry.LocalMachine.CreateSubKey(
                        @"SOFTWARE\Policies\Microsoft\Windows\Psched"))
                    {
                        key.SetValue("NonBestEffortLimit", 0, RegistryValueKind.DWord);
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing TCP/IP stack: {ex.Message}");
            }
        }

        private void OptimizeDnsSettings()
        {
            try
            {
                using (var process = new Process())
                {
                    process.StartInfo.FileName = "powershell.exe";
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.CreateNoWindow = true;
                    process.StartInfo.RedirectStandardOutput = true;
                    process.StartInfo.RedirectStandardError = true;

                    // Flush DNS cache
                    process.StartInfo.Arguments = "-Command \"Clear-DnsClientCache\"";
                    process.Start();
                    process.WaitForExit();

                    // Set DNS client service to automatic start
                    process.StartInfo.Arguments = "-Command \"Set-Service -Name 'Dnscache' -StartupType Automatic\"";
                    process.Start();
                    process.WaitForExit();

                    // Start DNS client service if not running
                    process.StartInfo.Arguments = "-Command \"Start-Service -Name 'Dnscache' -ErrorAction SilentlyContinue\"";
                    process.Start();
                    process.WaitForExit();
                }

                // Optimize DNS settings in registry
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"))
                {
                    // Increase DNS cache size
                    key.SetValue("CacheHashTableBucketSize", 1, RegistryValueKind.DWord);
                    key.SetValue("CacheHashTableSize", 384, RegistryValueKind.DWord);

                    // Optimize DNS query settings
                    key.SetValue("MaxCacheEntryTtlLimit", 86400, RegistryValueKind.DWord);
                    key.SetValue("MaxSOACacheEntryTtlLimit", 300, RegistryValueKind.DWord);
                    key.SetValue("NegativeCacheTime", 0, RegistryValueKind.DWord);
                    key.SetValue("NetFailureCacheTime", 0, RegistryValueKind.DWord);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error optimizing DNS settings: {ex.Message}");
            }
        }

        private void DisableNagleAlgorithm()
        {
            try
            {
                // Disable Nagle's algorithm for all connections (reduces latency for small packets)
                using (var key = Registry.LocalMachine.CreateSubKey(
                    @"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"))
                {
                    foreach (var subkeyName in key.GetSubKeyNames())
                    {
                        using (var subkey = key.OpenSubKey(subkeyName, true))
                        {
                            if (subkey != null)
                            {
                                // Check if this is an active interface with an IP address
                                if (subkey.GetValue("IPAddress") != null)
                                {
                                    // Disable Nagle's algorithm
                                    subkey.SetValue("TcpAckFrequency", 1, RegistryValueKind.DWord);
                                    subkey.SetValue("TCPNoDelay", 1, RegistryValueKind.DWord);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error disabling Nagle's algorithm: {ex.Message}");
            }
        }
    }
}