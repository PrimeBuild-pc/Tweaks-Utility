using System;
using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using WinOptimizer.Services;
using WinOptimizer.Views;

namespace WinOptimizer
{
    public partial class App : Application
    {
        private ServiceProvider _serviceProvider;

        public App()
        {
            var serviceCollection = new ServiceCollection();
            ConfigureServices(serviceCollection);
            _serviceProvider = serviceCollection.BuildServiceProvider();
        }

        private void ConfigureServices(IServiceCollection services)
        {
            // Register services
            services.AddSingleton<HardwareService>();
            services.AddSingleton<OptimizationService>();
            
            // Register views
            services.AddTransient<MainWindow>();
        }

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            var mainWindow = _serviceProvider.GetRequiredService<MainWindow>();
            mainWindow.Show();
        }
    }
}