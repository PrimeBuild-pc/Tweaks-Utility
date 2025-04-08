using System.Windows;
using WinOptimizer.Services;
using WinOptimizer.ViewModels;

namespace WinOptimizer
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            
            // Initialize services
            var hardwareService = new HardwareService();
            var optimizationService = new OptimizationService(hardwareService);
            var profileService = new ProfileService();
            
            // Set data context
            DataContext = new MainViewModel(
                hardwareService,
                optimizationService,
                profileService);
        }

        private void StartOptimizationButton_Click(object sender, RoutedEventArgs e)
        {
            var mainViewModel = (MainViewModel)DataContext;
            mainViewModel._optimizationService.ScanSystemAndOptimize();
        }
    }
}