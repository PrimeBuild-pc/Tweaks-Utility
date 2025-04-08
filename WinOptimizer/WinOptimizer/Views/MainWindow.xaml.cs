using System;
using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;
using WinOptimizer.Services;
using WinOptimizer.ViewModels;

namespace WinOptimizer.Views
{
    public partial class MainWindow : Window
    {
        public static Array OptimizationProfiles => Enum.GetValues(typeof(OptimizationProfile));

        public MainWindow(HardwareService hardwareService, OptimizationService optimizationService)
        {
            InitializeComponent();
            
            // Set data context
            var viewModel = new MainViewModel(optimizationService, hardwareService);
            DataContext = viewModel;

            // Set up hardware summary for the expanded system info section
            var hardwareSummary = new Dictionary<string, string>
            {
                ["CPU"] = hardwareService.SystemInfo["CPU.Name"],
                ["GPU"] = GetGpuSummary(hardwareService),
                ["RAM"] = hardwareService.SystemInfo["RAM.Total"] + " (" + hardwareService.SystemInfo["RAM.Free"] + " free)",
                ["Storage"] = GetStorageSummary(hardwareService)
            };

            // Add the hardware summary to the view model properties
            typeof(MainViewModel).GetProperty("HardwareSummary")?.SetValue(viewModel, hardwareSummary);
        }

        private string GetGpuSummary(HardwareService service)
        {
            foreach (var key in service.SystemInfo.Keys)
            {
                if (key.StartsWith("GPU"))
                {
                    return service.SystemInfo[key];
                }
            }
            return "GPU information not available";
        }

        private string GetStorageSummary(HardwareService service)
        {
            foreach (var key in service.SystemInfo.Keys)
            {
                if (key.StartsWith("Disk"))
                {
                    return service.SystemInfo[key];
                }
            }
            return "Storage information not available";
        }
    }

    public class BoolToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return (bool)value ? Visibility.Visible : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return (Visibility)value == Visibility.Visible;
        }
    }

    public class InverseBoolConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }
    }

    public class BoolToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return (bool)value ? new SolidColorBrush(Colors.ForestGreen) : new SolidColorBrush(Colors.Crimson);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
