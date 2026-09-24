using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Xml.Linq;

namespace ExeTester
{
    public partial class MainWindow : Window
    {
        private const int MaxDisplayLength = 20;

        private readonly List<ExeItem> _exeItems = new List<ExeItem>();

        public MainWindow()
        {
            InitializeComponent();
            LoadConfig();
        }

        private void LoadConfig()
        {
            string configPath = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "ExeTester.xml");

            if (!File.Exists(configPath))
            {
                MessageBox.Show(
                    "設定ファイルが見つかりません。\n" + configPath,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                return;
            }

            try
            {
                XDocument document = XDocument.Load(configPath);

                XElement root = document.Root;

                if (root == null)
                {
                    throw new Exception("設定ファイルのルート要素がありません。");
                }

                LoadFiles(
                    root.Element("LogFiles"),
                    LogFilePanel);

                LoadFiles(
                    root.Element("ConfigFiles"),
                    ConfigFilePanel);

                LoadExecutables(
                    root.Element("Executables"));

                UpdateAllProcessStatus();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "設定ファイルの読み込みに失敗しました。\n\n" +
                    ex.Message,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void LoadFiles(
            XElement parent,
            StackPanel panel)
        {
            if (parent == null)
            {
                return;
            }

            foreach (XElement element in parent.Elements("File"))
            {
                string name =
                    (string)element.Attribute("Name");

                string path =
                    (string)element.Attribute("Path");

                if (string.IsNullOrEmpty(name) ||
                    string.IsNullOrEmpty(path))
                {
                    continue;
                }

                TextBlock link = CreateFileLink(name, path);

                panel.Children.Add(link);
            }
        }

        private TextBlock CreateFileLink(
            string name,
            string path)
        {
            TextBlock link = new TextBlock();

            link.Text = TruncateText(name);
            link.ToolTip = name;

            link.Foreground = Brushes.Blue;
            link.TextDecorations = TextDecorations.Underline;

            link.Cursor = Cursors.Hand;

            link.Margin = new Thickness(0, 0, 0, 8);

            link.Tag = path;

            link.MouseLeftButtonUp += FileLink_Click;

            return link;
        }

        private void LoadExecutables(XElement parent)
        {
            if (parent == null)
            {
                return;
            }

            foreach (XElement element in parent.Elements("Exe"))
            {
                string name =
                    (string)element.Attribute("Name");

                string path =
                    (string)element.Attribute("Path");

                string processName =
                    (string)element.Attribute("ProcessName");

                if (string.IsNullOrEmpty(name) ||
                    string.IsNullOrEmpty(path))
                {
                    continue;
                }

                ExeItem item = new ExeItem();

                item.Name = name;
                item.Path = path;
                item.ProcessName = processName;

                _exeItems.Add(item);

                CreateExeRow(item);
                CreateProcessRow(item);
            }
        }

        private void CreateExeRow(ExeItem item)
        {
            Grid grid = new Grid();

            grid.Margin = new Thickness(0, 0, 0, 5);

            grid.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(1, GridUnitType.Star)
                });

            grid.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(55)
                });

            grid.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(55)
                });

            TextBlock name = new TextBlock();

            name.Text = TruncateText(item.Name);
            name.ToolTip = item.Name;

            name.VerticalAlignment =
                VerticalAlignment.Center;

            Button startButton = new Button();

            startButton.Content = "実行";
            startButton.Margin =
                new Thickness(2, 0, 2, 0);

            startButton.Tag = item;
            startButton.Click += StartButton_Click;

            Button stopButton = new Button();

            stopButton.Content = "停止";
            stopButton.Margin =
                new Thickness(2, 0, 0, 0);

            stopButton.Tag = item;
            stopButton.Click += StopButton_Click;

            Grid.SetColumn(name, 0);
            Grid.SetColumn(startButton, 1);
            Grid.SetColumn(stopButton, 2);

            grid.Children.Add(name);
            grid.Children.Add(startButton);
            grid.Children.Add(stopButton);

            ExePanel.Children.Add(grid);
        }

        private void CreateProcessRow(ExeItem item)
        {
            Grid grid = new Grid();

            grid.Margin = new Thickness(0, 0, 0, 5);

            grid.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(1, GridUnitType.Star)
                });

            grid.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(65)
                });

            TextBlock name = new TextBlock();

            name.Text = TruncateText(item.Name);
            name.ToolTip = item.Name;

            name.VerticalAlignment =
                VerticalAlignment.Center;

            TextBlock status = new TextBlock();

            status.Text = "停止";

            status.VerticalAlignment =
                VerticalAlignment.Center;

            item.StatusTextBlock = status;

            Grid.SetColumn(name, 0);
            Grid.SetColumn(status, 1);

            grid.Children.Add(name);
            grid.Children.Add(status);

            ProcessPanel.Children.Add(grid);
        }

        private void FileLink_Click(
            object sender,
            MouseButtonEventArgs e)
        {
            TextBlock link = sender as TextBlock;

            if (link == null)
            {
                return;
            }

            string path = link.Tag as string;

            if (string.IsNullOrEmpty(path))
            {
                return;
            }

            if (!File.Exists(path))
            {
                MessageBox.Show(
                    "ファイルが見つかりません。\n" + path,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            try
            {
                Process.Start(
                    new ProcessStartInfo
                    {
                        FileName = path,
                        UseShellExecute = true
                    });
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "ファイルを開けませんでした。\n\n" +
                    ex.Message,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void StartButton_Click(
            object sender,
            RoutedEventArgs e)
        {
            Button button = sender as Button;

            if (button == null)
            {
                return;
            }

            ExeItem item = button.Tag as ExeItem;

            if (item == null)
            {
                return;
            }

            if (!File.Exists(item.Path))
            {
                MessageBox.Show(
                    "EXEが見つかりません。\n" + item.Path,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            try
            {
                if (item.Process != null)
                {
                    if (!item.Process.HasExited)
                    {
                        return;
                    }

                    item.Process.Dispose();
                    item.Process = null;
                }

                ProcessStartInfo info =
                    new ProcessStartInfo();

                info.FileName = item.Path;
                info.WorkingDirectory = Path.GetDirectoryName(item.Path);
                info.UseShellExecute = true;

                item.Process = Process.Start(info);

                UpdateProcessStatus(item);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "EXEの起動に失敗しました。\n\n" +
                    ex.Message,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void StopButton_Click(
            object sender,
            RoutedEventArgs e)
        {
            Button button = sender as Button;

            if (button == null)
            {
                return;
            }

            ExeItem item = button.Tag as ExeItem;

            if (item == null)
            {
                return;
            }

            try
            {
                string processName = item.ProcessName;

                if (string.IsNullOrEmpty(processName))
                {
                    processName = Path.GetFileNameWithoutExtension(item.Path);
                }

                Process[] processes =
                    Process.GetProcessesByName(processName);

                if (processes.Length == 0)
                {
                    UpdateProcessStatus(item);
                    return;
                }

                foreach (Process process in processes)
                {
                    try
                    {
                        if (process.HasExited)
                        {
                            continue;
                        }

                        if (process.MainWindowHandle != IntPtr.Zero)
                        {
                            bool closed = process.CloseMainWindow();

                            if (closed && process.WaitForExit(3000))
                            {
                                continue;
                            }
                        }

                        process.Kill();
                        process.WaitForExit();
                    }
                    catch
                    {
                        // 個別プロセスの停止に失敗しても、
                        // 他のプロセスの停止を続行する
                    }
                    finally
                    {
                        process.Dispose();
                    }
                }

                UpdateProcessStatus(item);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "EXEの停止に失敗しました。\n\n" +
                    ex.Message,
                    "ExeTester",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void UpdateProcessButton_Click(
            object sender,
            RoutedEventArgs e)
        {
            UpdateAllProcessStatus();
        }

        private void UpdateAllProcessStatus()
        {
            foreach (ExeItem item in _exeItems)
            {
                UpdateProcessStatus(item);
            }
        }

        private void UpdateProcessStatus(ExeItem item)
        {
            bool running = false;

            try
            {
                string processName = item.ProcessName;

                if (string.IsNullOrEmpty(processName))
                {
                    processName = Path.GetFileNameWithoutExtension(item.Path);
                }

                Process[] processes =
                    Process.GetProcessesByName(processName);

                if (processes.Length > 0)
                {
                    running = true;

                    foreach (Process process in processes)
                    {
                        process.Dispose();
                    }
                }
            }
            catch
            {
                running = false;
            }

            if (running)
            {
                item.StatusTextBlock.Text = "起動中";
            }
            else
            {
                item.StatusTextBlock.Text = "停止";
            }
        }

        private string TruncateText(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            if (text.Length <= MaxDisplayLength)
            {
                return text;
            }

            if (MaxDisplayLength <= 3)
            {
                return text.Substring(
                    0,
                    MaxDisplayLength);
            }

            return text.Substring(
                0,
                MaxDisplayLength - 3) + "...";
        }
    }

    public class ExeItem
    {
        public string Name { get; set; }

        public string Path { get; set; }

        public string ProcessName { get; set; }

        public Process Process { get; set; }

        public TextBlock StatusTextBlock { get; set; }
    }
}