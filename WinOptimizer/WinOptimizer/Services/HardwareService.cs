using System;
using System.Collections.Generic;
using System.Management;
using System.Diagnostics;
using System.Threading.Tasks;

namespace WinOptimizer.Services
{
    public class HardwareService
    {
        private Dictionary<string, string> _systemInfo;
        
        public Dictionary<string, string> SystemInfo => _systemInfo ?? (_systemInfo = CollectSystemInfo());

        public HardwareService()
        {
            // Initialize
        }

        private Dictionary<string, string> CollectSystemInfo()
        {
            var result = new Dictionary<string, string>();
            
            try
            {
                // CPU Info
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_Processor"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        result["CPU.Name"] = obj["Name"].ToString();
                        result["CPU.Manufacturer"] = obj["Manufacturer"].ToString();
                        result["CPU.Cores"] = obj["NumberOfCores"].ToString();
                        result["CPU.Threads"] = obj["NumberOfLogicalProcessors"].ToString();
                        break; // Just get the first CPU
                    }
                }
                
                // RAM Info
                long totalRamMB = 0;
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_PhysicalMemory"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        totalRamMB += Convert.ToInt64(obj["Capacity"]) / (1024 * 1024);
                    }
                }
                result["RAM.Total"] = $"{totalRamMB} MB";
                
                // GPU Info
                int gpuIndex = 0;
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_VideoController"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        string gpuName = obj["Name"].ToString();
                        result[$"GPU.{gpuIndex}.Name"] = gpuName;
                        result[$"GPU.{gpuIndex}.RAM"] = obj["AdapterRAM"] != null ? 
                            (Convert.ToInt64(obj["AdapterRAM"]) / (1024 * 1024) + " MB") : "Unknown";
                        gpuIndex++;
                    }
                }
                
                // Disk Info
                int diskIndex = 0;
                using (var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_DiskDrive"))
                {
                    foreach (var obj in searcher.Get())
                    {
                        result[$"Disk.{diskIndex}.Model"] = obj["Model"].ToString();
                        result[$"Disk.{diskIndex}.Size"] = (Convert.ToInt64(obj["Size"]) / (1024 * 1024 * 1024) + " GB");
                        diskIndex++;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error collecting system info: {ex.Message}");
                // Add some minimal info so the app doesn't crash
                result["CPU.Name"] = "Unknown CPU";
                result["RAM.Total"] = "8192 MB";
                result["GPU.0.Name"] = "Unknown GPU";
                result["Disk.0.Model"] = "Unknown Disk";
            }
            
            return result;
        }

        public async Task<Dictionary<string, string>> RefreshSystemInfoAsync()
        {
            return await Task.Run(() => {
                _systemInfo = CollectSystemInfo();
                return _systemInfo;
            });
        }
    }
}