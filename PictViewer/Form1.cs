using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using Microsoft.VisualBasic.FileIO;
using System.Diagnostics;
//using static System.Windows.Forms.VisualStyles.VisualStyleElement;
//using System.Reflection.Emit;


namespace PictViewer
{
    public partial class Form1: Form
    {
        private PictureBox pictureBox;
        private Panel imagePanel;
        private List<string> imageFiles = new List<string>();
        private HashSet<string> selectedImages = new HashSet<string>();
        private int currentIndex = 0;
        private Label imageLabel;
        private TextBox textBox;
        private Label helpLabel;
        private bool isRenaming = false;


        public Form1(string folderPath)
        {
            InitializeComponent();
            this.Text = "画像ビュアー";
            this.WindowState = FormWindowState.Normal;
            this.ClientSize = new Size(900, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.KeyPreview = true;

            imagePanel = new Panel
            {
                Size = new Size(800, 500),
                Location = new Point(50, 30),
                BackColor = Color.Gray,
                BorderStyle = BorderStyle.None,
            };
            this.Controls.Add(imagePanel);

            pictureBox = new PictureBox
            {
                Size = new Size(790, 490), // 枠より少し小さく
                Location = new Point(5, 5), // 枠の内側に配置
                SizeMode = PictureBoxSizeMode.Zoom,
                BackColor = Color.White,
                BorderStyle = BorderStyle.None,
            };
            imagePanel.Controls.Add(pictureBox);

            imageLabel = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 30,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Meiryo", 12),
                BackColor = Color.LightGray
            };
            this.Controls.Add(imageLabel);


            textBox = new TextBox
            {
                Dock = DockStyle.Bottom,
                Height = 30,
                TextAlign = HorizontalAlignment.Center,
                Font = new Font("Meiryo", 12),
                BackColor = Color.White,
                Visible = false,
                

            };
            this.Controls.Add(textBox);

            helpLabel = new Label
            {
                Location = new Point(340, 550),
                Height = 30,
                AutoSize = true,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Meiryo", 10),
                ForeColor = Color.SlateGray,
                Text = "Space:選択, Delete:選択したものを削除, F2:リネーム, F4:一括リネーム",
                
            };
            this.Controls.Add(helpLabel);


            LoadImages(folderPath);
            ShowImage();


            this.KeyDown += Form1_KeyDown;
        }

        private void LoadImages(string folderPath)
        {
            if (Directory.Exists(folderPath))
            {
                var extensions = new[] { ".jpg", ".jpeg", ".png", ".bmp" };
                // 絶対パスを取得
                imageFiles = Directory.GetFiles(folderPath)
                    .Where(f => extensions.Contains(Path.GetExtension(f).ToLower()))
                    .ToList();
            }
        }

        private void ShowImage()
        {
            if (imageFiles.Count == 0) return;

            string currentFile = imageFiles[currentIndex];

            // 前の画像を解放
            if (pictureBox.Image != null)
            {
                pictureBox.Image.Dispose();
                pictureBox.Image = null;
            }

            pictureBox.Image = Image.FromFile(currentFile);
            imagePanel.BackColor = selectedImages.Contains(currentFile) ? Color.Red : Color.Gray;
            this.Text = $"画像ビュアー : {currentIndex+1}/{imageFiles.Count}";

            //絶対パスから相対パスを取得する
            imageLabel.Text = Path.GetFileName(imageFiles[currentIndex]);
            TurnRenamingMode(false);
        }

        private void TurnRenamingMode(bool mode)
        {
            if (mode)
            {
                imageLabel.Visible = false;
                textBox.Visible = true;
                textBox.Text = imageLabel.Text;
                textBox.Focus();
                textBox.SelectionStart = 0;
                textBox.SelectionLength = textBox.Text.Length - 4;

            }
            else
            {
                imageLabel.Visible = true;
                textBox.Visible = false;
                textBox.Text = "";
            }
            isRenaming = mode;
        }

        private void Form1_KeyDown(object sender, KeyEventArgs e)
        {
            if (imageFiles.Count == 0) return;

            if (e.KeyCode == Keys.Right)
            {
                if (isRenaming)
                {
                    return;
                }
                if(currentIndex + 1 < imageFiles.Count)
                {
                    currentIndex++;
                    ShowImage();
                } 
                
            }
            else if (e.KeyCode == Keys.Left)
            {
                if (isRenaming)
                {
                    return;
                }
                if (currentIndex > 0)
                {
                    currentIndex--;
                    ShowImage();
                }
                
            }
            else if (e.KeyCode == Keys.Space)
            {
                string currentFile = imageFiles[currentIndex];
                if (selectedImages.Contains(currentFile))
                    selectedImages.Remove(currentFile);
                else
                    selectedImages.Add(currentFile);
                ShowImage();
            }

            // Delete:選択状態のファイルを削除
            else if (e.KeyCode == Keys.Delete && !isRenaming)
            {
                if(selectedImages.Count == 0)
                {
                    return;
                }

                DialogResult result = MessageBox.Show("削除しますか？", "確認", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (result != DialogResult.Yes)
                {
                    return;
                }

                foreach (var file in selectedImages.ToList())
                {
                    try
                    {
                        if (pictureBox.Image != null)
                        {
                            pictureBox.Image.Dispose();
                            pictureBox.Image = null;
                        }
                        FileSystem.DeleteFile(
                            file,
                            UIOption.OnlyErrorDialogs,
                            RecycleOption.SendToRecycleBin
                        );
                        imageFiles.Remove(file);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"削除失敗: {file}\n{ex.Message}");
                    }
                }

                selectedImages.Clear();
                currentIndex = Math.Min(currentIndex, imageFiles.Count - 1);
                ShowImage();
            }
            // F2:リネーム
            else if (e.KeyCode == Keys.F2)
            {
                TurnRenamingMode(!isRenaming);
            }
            // Enter:リネーム中に確定
            else if (e.KeyCode == Keys.Enter && isRenaming)
            {
                string currentPath = imageFiles[currentIndex];
                string newPath = Path.Combine(Path.GetDirectoryName(currentPath), textBox.Text);
                
                //変更なし、空文字列
                if (currentPath == newPath || textBox.Text == "")
                {
                    ShowImage();
                }
                //既存のファイルと同じ名前に変更された
                else if (File.Exists(newPath))
                {
                    MessageBox.Show("同じ名前のファイルが存在します: " + newPath);
                }
                //新規のファイル名に変更された
                else
                {
                    if (pictureBox.Image != null)
                    {
                        pictureBox.Image.Dispose();
                        pictureBox.Image = null;
                    }
                    File.Move(currentPath, newPath);
                    LoadImages(Path.GetDirectoryName(currentPath));
                    ShowImage();
                }

            }
            else if (e.KeyCode == Keys.F4)
            {
                using (Form2 subWindow = new Form2()) { 
                    subWindow.StartPosition = FormStartPosition.Manual;
                    subWindow.Location = this.Location;

                    if (!subWindow.initResult)
                    {
                        // XMLロード失敗時などはダイアログを表示しない
                        return;
                    }

                    // 非モーダル表示
                    if (subWindow.ShowDialog() == DialogResult.OK)
                    {
                        pictureBox.Image?.Dispose();
                        pictureBox.Image = null;

                        int result = subWindow.SelectedValue;
                        List<string> newNames = subWindow.nameLists[result];

                        int renameCount = Math.Min(newNames.Count, imageFiles.Count);

                        //一括リネーム処理
                        for (int i = 0; i < renameCount; i++)
                        {
                            string currentPath = imageFiles[i];
                            string newPath = Path.Combine(Path.GetDirectoryName(currentPath), newNames[i] + ".png");
                            if (currentPath == newPath)
                            {
                                continue;
                            }
                            else if (File.Exists(newPath))
                            {
                                break;
                            }
                            else
                            {
                                File.Move(currentPath, newPath);
                            }
                        }
                        LoadImages(Path.GetDirectoryName(imageFiles[0]));
                        ShowImage();
                        //Debug.WriteLine($"選ばれたのは: {subWindow.names[result][0]}");
                    }
                }


            }
        }
    }
}





