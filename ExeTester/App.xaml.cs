using System;
using System.Threading;
using System.Windows;

namespace ExeTester
{
    public partial class App : Application
    {
        private static Mutex _mutex;

        protected override void OnStartup(StartupEventArgs e)
        {
            bool createdNew;

            _mutex = new Mutex(
                true,
                @"Global\ExeTester",
                out createdNew);

            if (!createdNew)
            {
                MessageBox.Show(
                    "ExeTesterはすでに起動しています。",
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information);

                Shutdown();
                return;
            }

            base.OnStartup(e);
        }

        protected override void OnExit(ExitEventArgs e)
        {
            if (_mutex != null)
            {
                _mutex.ReleaseMutex();
                _mutex.Dispose();
                _mutex = null;
            }

            base.OnExit(e);
        }
    }
}