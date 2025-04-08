using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Media;
using WinOptimizer.Services;
using System.Collections.Generic; // This should work but let's use fully qualified names too

namespace WinOptimizer.ViewModels
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly OptimizationService _optimizationService;
        private readonly HardwareService _hardwareService;
        private int _optimizationProgress;
        private bool _isOptimizing;
        private string _statusMessage;
        private ObservableCollection<OptimizationResult> _optimizationResults;
        private OptimizationProfile _selectedProfile;
        private bool _optimizeCpu = true;
        private bool _optimizeGpu = true;
        private bool _optimizeMemory = true;
        private bool _optimizeDisk = true;
        private ObservableCollection<KeyValuePair<string, string>> _hardwareSummary;

        public MainViewModel(OptimizationService optimizationService, HardwareService hardwareService)
        {
            _optimizationService = optimizationService;
            _hardwareService = hardwareService;
            _optimizationResults = new ObservableCollection<OptimizationResult>();
            _statusMessage = "Ready to optimize your system";
            _selectedProfile = OptimizationProfile.Balanced;

            OptimizeCommand = new RelayCommand(async _ => await StartOptimization(), _ => !IsOptimizing);
            RevertCommand = new RelayCommand(_ => RevertOptimization(), _ => !IsOptimizing);
            
            // Subscribe to optimization events
            _optimizationService.OptimizationProgressUpdated += progress => 
            {
                OptimizationProgress = progress;
            };
            
            _optimizationService.OptimizationStatusUpdated += message => 
            {
                StatusMessage = message;
            };
            
            _optimizationService.OptimizationCompleted += results => 
            {
                foreach (var result in results)
                {
                    OptimizationResults.Add(result);
                }
                IsOptimizing = false;
            };
        }

        public ObservableCollection<OptimizationResult> OptimizationResults
        {
            get => _optimizationResults;
            set
            {
                _optimizationResults = value;
                OnPropertyChanged();
            }
        }

        public int OptimizationProgress
        {
            get => _optimizationProgress;
            set
            {
                _optimizationProgress = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(OptimizationProgressPercentage));
            }
        }

        public int OptimizationProgressPercentage => 
            _optimizationService.GetTotalOptimizationSteps() == 0 ? 
            0 : 
            (int)((_optimizationProgress / (double)_optimizationService.GetTotalOptimizationSteps()) * 100);

        public bool IsOptimizing
        {
            get => _isOptimizing;
            set
            {
                _isOptimizing = value;
                OnPropertyChanged();
                CommandManager.InvalidateRequerySuggested();
            }
        }

        public string StatusMessage
        {
            get => _statusMessage;
            set
            {
                _statusMessage = value;
                OnPropertyChanged();
            }
        }

        public OptimizationProfile SelectedProfile
        {
            get => _selectedProfile;
            set
            {
                _selectedProfile = value;
                OnPropertyChanged();
            }
        }

        public bool OptimizeCpu
        {
            get => _optimizeCpu;
            set
            {
                _optimizeCpu = value;
                OnPropertyChanged();
            }
        }

        public bool OptimizeGpu
        {
            get => _optimizeGpu;
            set
            {
                _optimizeGpu = value;
                OnPropertyChanged();
            }
        }

        public bool OptimizeMemory
        {
            get => _optimizeMemory;
            set
            {
                _optimizeMemory = value;
                OnPropertyChanged();
            }
        }

        public bool OptimizeDisk
        {
            get => _optimizeDisk;
            set
            {
                _optimizeDisk = value;
                OnPropertyChanged();
            }
        }

        public ObservableCollection<KeyValuePair<string, string>> HardwareSummary
        {
            get => _hardwareSummary;
            set
            {
                _hardwareSummary = value;
                OnPropertyChanged();
            }
        }

        public ICommand OptimizeCommand { get; }
        public ICommand RevertCommand { get; }

        private async Task StartOptimization()
        {
            OptimizationResults.Clear();
            IsOptimizing = true;
            OptimizationProgress = 0;
            StatusMessage = "Starting system optimization...";

            await _optimizationService.ScanSystemAndOptimizeAsync(
                SelectedProfile, 
                OptimizeCpu, 
                OptimizeGpu, 
                OptimizeMemory, 
                OptimizeDisk);
        }

        private void RevertOptimization()
        {
            OptimizationResults.Clear();
            IsOptimizing = true;
            StatusMessage = "Reverting optimizations...";
            
            try
            {
                _optimizationService.RevertOptimizations();
                StatusMessage = "Optimizations reverted successfully!";
            }
            catch (Exception ex)
            {
                StatusMessage = $"Error reverting optimizations: {ex.Message}";
            }
            finally
            {
                IsOptimizing = false;
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class RelayCommand : ICommand
    {
        private readonly Action<object> _execute;
        private readonly Predicate<object> _canExecute;

        public RelayCommand(Action<object> execute, Predicate<object> canExecute = null)
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute;
        }

        public bool CanExecute(object parameter)
        {
            return _canExecute == null || _canExecute(parameter);
        }

        public void Execute(object parameter)
        {
            _execute(parameter);
        }

        public event EventHandler CanExecuteChanged
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }
    }
}