using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace WindowManager
{
    public partial class Form1 : Form
    {
        private readonly List<string> exePaths;
        private readonly List<string> exeNames;

        //廃止
        //[DllImport("user32.dll", SetLastError = true)]
        //static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        //[DllImport("user32.dll")]
        //static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        //static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        //static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

        //const uint SWP_NOMOVE = 0x0002;
        //const uint SWP_NOSIZE = 0x0001;
        //const uint SWP_SHOWWINDOW = 0x0040;


        [DllImport("user32.dll")]
        static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

        [DllImport("user32.dll")]
        static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        public const int SW_MAXIMIZE = 3;
        public const int SW_RESTORE = 9;


        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        public Form1()
        {
            InitializeComponent();

            exePaths = new List<string>
            {
                @"C:\Users\miyuj\Desktop\GUI\net8.0-windows\FileSelect.exe",
                @"C:\Users\miyuj\Desktop\プログラミング\★作成物\exeソフト\文字コード\CharCodeTranslate.exe",
                @"C:\Users\miyuj\Desktop\GUI\net8.0-windows\FileSelect.exe",
                @"C:\Users\miyuj\Desktop\GUI\net8.0-windows\FileSelect.exe",
                @"C:\Users\miyuj\Desktop\GUI\net8.0-windows\FileSelect.exe",
            };

            exeNames = new List<string>();
            exePaths.ForEach(s => exeNames.Add(Path.GetFileNameWithoutExtension(s)));
            InitializeTableLayoutPanel();
        }

        private void InitializeTableLayoutPanel()
        {
            tableLayoutPanel1.Height = exePaths.Count * 100;
            tableLayoutPanel1.RowStyles[0].SizeType = SizeType.Absolute;
            tableLayoutPanel1.RowStyles[0].Height = 35;

            for (int i = 0; i < exeNames.Count; i++)
            {
                var runningStatus = new PictureBox()
                {
                    Image = Properties.Resources.cancel,
                    Dock = DockStyle.Fill,
                    SizeMode = PictureBoxSizeMode.Zoom,
                };

                string exeNameDisp = exeNames[i].Substring(0, Math.Min(8, exeNames[i].Length));
                var name = new Label()
                {
                    Text = exeNameDisp,
                    Font = new Font("Segoe UI", 12, FontStyle.Regular),
                    TextAlign = ContentAlignment.MiddleLeft,
                    Dock = DockStyle.Fill,
                };

                var btnRun = new Button()
                {
                    Text = "起動",
                    Font = new Font("Segoe UI", 9, FontStyle.Regular),
                    Dock = DockStyle.Fill,
                    FlatStyle = FlatStyle.Flat,
                    UseVisualStyleBackColor = true,
                };
                btnRun.FlatAppearance.BorderSize = 0;
                btnRun.Click += new EventHandler(this.button4_Click);

                var btnSet = new Button()
                {
                    Text = "別画面",
                    Font = new Font("Segoe UI", 9, FontStyle.Regular),
                    Dock = DockStyle.Fill,
                    FlatStyle = FlatStyle.Flat,
                    UseVisualStyleBackColor = true,
                };
                btnSet.FlatAppearance.BorderSize = 0;
                btnSet.Click += new EventHandler(this.button2_Click);

                var btnUnset = new Button()
                {
                    Text = "戻す",
                    Font = new Font("Segoe UI", 9, FontStyle.Regular),
                    Dock = DockStyle.Fill,
                    FlatStyle = FlatStyle.Flat,
                    UseVisualStyleBackColor = true,
                };
                btnUnset.FlatAppearance.BorderSize = 0;
                btnUnset.Click += new EventHandler(this.button3_Click);

                tableLayoutPanel1.RowCount++;
                tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Absolute, 35));

                tableLayoutPanel1.Controls.Add(runningStatus, 0, i);
                tableLayoutPanel1.Controls.Add(name, 1, i);
                tableLayoutPanel1.Controls.Add(btnRun, 2, i);
                tableLayoutPanel1.Controls.Add(btnSet, 3, i);
                tableLayoutPanel1.Controls.Add(btnUnset, 4, i);
            }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            //IntPtr hWnd = FindWindow(null, "Form1");
            for(int i = 0; i < exeNames.Count; i++)
            {
                UpdateWindowRunningStatus(exeNames[i], i);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            var b = (Button)sender;
            var pos = tableLayoutPanel1.GetPositionFromControl(b);

            int x = 400;
            int y = 200;

            MoveExeWindow(exeNames[pos.Row], x, y);
        }

        private void button3_Click(object sender, EventArgs e)
        {
            var b = (Button)sender;
            var pos = tableLayoutPanel1.GetPositionFromControl(b);

            int x = 0;
            int y = 0;
            MoveExeWindow(exeNames[pos.Row], x, y);
        }

        private void button4_Click(object sender, EventArgs e)
        {
            var b = (Button)sender;
            var pos = tableLayoutPanel1.GetPositionFromControl(b);

            Process.Start(exePaths[pos.Row]);
            UpdateWindowRunningStatus(exeNames[pos.Row], pos.Row);
        }

        private bool UpdateWindowRunningStatus(string exeName, int row)
        {
            var pict = tableLayoutPanel1.GetControlFromPosition(0, row) as PictureBox;
            Process[] ps = Process.GetProcessesByName(exeName);

            if (ps.Length == 0)
            {
                pict.Image = Properties.Resources.cancel;
                return false;
            }
            else
            {
                pict.Image = Properties.Resources.check_darkgreen;
                return true;
            }
        }

        private void MoveExeWindow(string exeName, int x, int y)
        {
            Process[] ps = Process.GetProcessesByName(exeName);
            if (ps.Length == 0)
            {
                MessageBox.Show("ウィンドウが見つかりませんでした。");
                return;
            }
            IntPtr hWnd = ps[0].MainWindowHandle;

            // ウィンドウが最小化、最大化されているときの対処
            ShowWindow(hWnd, SW_RESTORE);
            System.Threading.Thread.Sleep(50);

            // ウィンドウサイズを取得
            RECT rect;
            GetWindowRect(hWnd, out rect);
            int width = rect.Right - rect.Left;
            int height = rect.Bottom - rect.Top;

            MoveWindow(hWnd, x, y, width, height, true);
            //SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
            //SetForegroundWindow(hWnd);
            ShowWindow(hWnd, SW_MAXIMIZE);
            //SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }
    }
}
