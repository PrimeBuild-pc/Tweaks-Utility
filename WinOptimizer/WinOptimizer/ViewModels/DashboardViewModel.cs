using System;
using System.ComponentModel;
using System.Threading.Tasks;
using WinOptimizer.Services;
using WinOptimizer.ViewModels;

namespace WinOptimizer.ViewModels
{
    public class DashboardViewModel : ViewModelBase
    {
        private readonly HardwareService _hardwareService;
        private readonly OptimizationService _optimizationService;
        
        private string _statusMessage = "Ready";
        private string _systemInfoText;
        private int _cpuOptimizationProgress;
        private int _gpuOptimizationProgress;
        private int _memoryOptimizationProgress;
        private int _diskOptimizationProgress;

        public string StatusMessage
        {
            get => _statusMessage;
            set => SetField(ref _statusMessage, value);
        }

        public string SystemInfoText
        {
            get => _systemInfoText;
            set => SetField(ref _systemInfoText, value);
        }

        public int CpuOptimizationProgress
        {
            get => _cpuOptimizationProgress;
            set => SetField(ref _cpuOptimizationProgress, value);
        }

        public int GpuOptimizationProgress
        {
            get => _gpuOptimizationProgress;
            set => SetField(ref _gpuOptimizationProgress, value);
        }

        public int MemoryOptimizationProgress
        {
            get => _memoryOptimizationProgress;
            set => SetField(ref _memoryOptimizationProgress, value);
        }

        public int DiskOptimizationProgress
        {
            get => _diskOptimizationProgress;
            set => SetField(ref _diskOptimizationProgress, value);
        }

        public RelayCommand OptimizeCpuCommand { get; }
        public RelayCommand DisableThrottlingCommand { get; }
        public RelayCommand OptimizeGpuCommand { get; }
        public RelayCommand OptimizeMemoryCommand { get; }
        public RelayCommand OptimizeDisksCommand { get; }

        public DashboardViewModel(HardwareService hardwareService, 
                                OptimizationService optimizationService)
        {
            _hardwareService = hardwareService;
            _optimizationService = optimizationService;

            OptimizeCpuCommand = new RelayCommand(async () => await OptimizeCpu());
            DisableThrottlingCommand = new RelayCommand(async () => await DisableThrottling());
            OptimizeGpuCommand = new RelayCommand(async () => await OptimizeGpu());
            OptimizeMemoryCommand = new RelayCommand(async () => await OptimizeMemory());
            OptimizeDisksCommand = new RelayCommand(async () => await OptimizeDisks());

            LoadSystemInfo();
        }

        private void LoadSystemInfo()
        {
            var info = _hardwareService.SystemInfo;
            SystemInfoText = $"CPU: {info["CPU.Name"]}\n" +
                            $"GPU: {info["GPU.0.Name"]}\n" +
                            $"RAM: {info["RAM.Total"]}\n" +
                            $"Disk: {info["Disk.0.Model"]}";
        }

        private async Task OptimizeCpu()
        {
            StatusMessage = "Optimizing CPU...";
            CpuOptimizationProgress = 0;
            
            await Task.Run(() => {
                _optimizationService.OptimizeCpu();
                for (int i = 0; i <= 100; i += 10)
                {
                    CpuOptimizationProgress = i;
                    Task.Delay(100).Wait();
                }
            });

            StatusMessage = "CPU optimization complete";
        }

        private async Task DisableThrottling()
        {
            StatusMessage = "Disabling CPU throttling...";
            await Task.Run(() => _optimizationService.DisableCpuThrottling());
            StatusMessage = "CPU throttling disabled";
        }

        private async Task OptimizeGpu()
        {
            StatusMessage = "Optimizing GPU...";
            GpuOptimizationProgress = 0;
            
            await Task.Run(() => {
                _optimizationService.OptimizeGpu();
                for (int i = 0; i <= 100; i += 10)
                {
                    GpuOptimizationProgress = i;
                    Task.Delay(100).Wait();
                }
            });

            StatusMessage = "GPU optimization complete";
        }

        private async Task OptimizeMemory()
        {
            StatusMessage = "Optimizing memory...";
            MemoryOptimizationProgress = 0;
            
            await Task.Run(() => {
                _optimizationService.OptimizeMemory();
                for (int i = 0; i <= 100; i += 10)
                {
                    MemoryOptimizationProgress = i;
                    Task.Delay(100).Wait();
                }
            });

            StatusMessage = "Memory optimization complete";
        }

        private async Task OptimizeDisks()
        {
            StatusMessage = "Optimizing disks...";
            DiskOptimizationProgress = 0;
            
            await Task.Run(() => {
                _optimizationService.OptimizeDisks();
                for (int i = 0; i <= 100; i += 10)
                {
                    DiskOptimizationProgress = i;
                    Task.Delay(100).Wait();
                }
            });

            StatusMessage = "Disk optimization complete";
        }
    }
}