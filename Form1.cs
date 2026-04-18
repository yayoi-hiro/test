using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml.Linq;
using SHDocVw;

namespace FolderExplorer
{

    public partial class Form1 : Form
    {
        [DllImport("user32.dll")]
        static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        const int SW_RESTORE = 9;


        private TreeView treeView1;
        private Button btnAddGroup;
        private Button btnAddFolder;
        private Button btnDelete;
        private Button btnSave;

        private const string FILE_PATH = "folders.txt";



        public Form1()
        {
            InitializeComponent2();
            LoadFromFile();
        }

        private void InitializeComponent2()
        {
            this.Text = "フォルダブックマーク";
            this.Width = 400;
            this.Height = 500;

            // ボタン
            btnAddGroup = new Button { Text = "グループ追加", Left = 10, Top = 10, Width = 90 };
            btnAddFolder = new Button { Text = "フォルダ追加", Left = 110, Top = 10, Width = 90 };
            btnDelete = new Button { Text = "削除", Left = 210, Top = 10, Width = 60 };
            btnSave = new Button { Text = "保存", Left = 280, Top = 10, Width = 60 };


            Button btnHelp = new Button();
            btnHelp.Text = "?";
            btnHelp.Width = 20;
            btnHelp.Height = 20;
            btnHelp.Top = 12;
            btnHelp.Left = 350;
            //btnHelp.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            //btnHelp.FlatStyle = FlatStyle.Flat;
            //btnHelp.FlatAppearance.BorderSize = 0;
            //btnHelp.BackColor = Color.LightGray;
            ToolTip tip = new ToolTip();
            tip.SetToolTip(btnHelp, "使い方");

            //GraphicsPath path = new GraphicsPath();
            //path.AddEllipse(0, 0, btnHelp.Width, btnHelp.Height);
            //btnHelp.Region = new Region(path);

            // TreeView
            treeView1 = new TreeView
            {
                Left = 10,
                Top = 40,
                Width = 360,
                Height = 400,
                AllowDrop = true
            };

            treeView1.ShowNodeToolTips = true;
            //treeView1.Font = new Font("Segoe UI", 9);

            // イベント
            btnAddGroup.Click += btnAddGroup_Click;
            btnAddFolder.Click += btnAddFolder_Click;
            btnDelete.Click += btnDelete_Click;
            btnSave.Click += btnSave_Click;
            btnHelp.Click += BtnHelp_Click;


            treeView1.ItemDrag += TreeView1_ItemDrag;
            treeView1.DragEnter += TreeView1_DragEnter;
            treeView1.DragDrop += TreeView1_DragDrop;
            treeView1.NodeMouseDoubleClick += TreeView1_NodeMouseDoubleClick;
            treeView1.AfterSelect += TreeView1_AfterSelect;
            treeView1.KeyDown += TreeView1_KeyDown;

            // 追加
            this.Controls.Add(btnAddGroup);
            this.Controls.Add(btnAddFolder);
            this.Controls.Add(btnDelete);
            this.Controls.Add(btnSave);
            this.Controls.Add(btnHelp);
            this.Controls.Add(treeView1);

            //ImageList imageList = new ImageList();

            //imageList.Images.Add("folder", GetFolderIcon());
            //imageList.Images.Add("group", GetFolderIcon()); // 同じでもOK

            //treeView1.ImageList = imageList;

        }

        // ----------------------------
        // 読み込み
        // ----------------------------
        private void LoadFromFile()
        {
            if (!File.Exists(FILE_PATH)) return;

            treeView1.Nodes.Clear();

            TreeNode currentGroup = null;

            foreach (var line in File.ReadAllLines(FILE_PATH))
            {
                var l = line.Trim();

                if (string.IsNullOrEmpty(l)) continue;

                if (l.StartsWith("[") && l.EndsWith("]"))
                {
                    string name = l.Trim('[', ']');
                    currentGroup = new TreeNode(name);
                    currentGroup.Tag = new NodeData { IsGroup = true };
                    if (name == "最近使った")
                    {
                        currentGroup.ForeColor = Color.Red;
                    }
                    else
                    {
                        currentGroup.ForeColor = Color.RoyalBlue;
                    }

                    treeView1.Nodes.Add(currentGroup);
                }
                else
                {
                    if (currentGroup == null) continue;

                    string path = l;
                    string display = Path.GetFileName(path);
                    if (string.IsNullOrEmpty(display)) display = path;

                    var node = new TreeNode(display);
                    node.Tag = new NodeData { Path = path, IsGroup = false };
                    node.ToolTipText = path;

                    currentGroup.Nodes.Add(node);
                }
            }

            treeView1.ExpandAll();
        }

        // ----------------------------
        // 保存
        // ----------------------------
        private void SaveToFile()
        {
            using (var sw = new StreamWriter(FILE_PATH))
            {
                foreach (TreeNode group in treeView1.Nodes)
                {
                    sw.WriteLine($"[{group.Text}]");

                    foreach (TreeNode child in group.Nodes)
                    {
                        var data = (NodeData)child.Tag;
                        sw.WriteLine(data.Path);
                    }

                    sw.WriteLine();
                }
            }
        }

        // ----------------------------
        // グループ追加
        // ----------------------------
        private void btnAddGroup_Click(object sender, EventArgs e)
        {
            using (var dlg = new InputDialog("グループ名入力"))
            {
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    string name = dlg.InputText;

                    if (string.IsNullOrWhiteSpace(name)) return;

                    var node = new TreeNode(name);
                    node.Tag = new NodeData { IsGroup = true };
                    node.ForeColor = Color.RoyalBlue;

                    treeView1.Nodes.Add(node);
                }
            }
        }

        // ----------------------------
        // フォルダ追加
        // ----------------------------
        private void btnAddFolder_Click(object sender, EventArgs e)
        {
            if (treeView1.SelectedNode == null) return;

            var data = (NodeData)treeView1.SelectedNode.Tag;

            TreeNode groupNode = data.IsGroup
                ? treeView1.SelectedNode
                : treeView1.SelectedNode.Parent;

            using (var dlg = new FolderBrowserDialog())
            {
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    string path = dlg.SelectedPath;

                    // 重複チェック
                    if (groupNode.Nodes.Cast<TreeNode>()
                        .Any(n => ((NodeData)n.Tag).Path == path))
                    {
                        MessageBox.Show("既に追加されています");
                        return;
                    }

                    string name = Path.GetFileName(path);
                    var node = new TreeNode(name);
                    node.Tag = new NodeData { Path = path, IsGroup = false };
                    node.ToolTipText = path;

                    groupNode.Nodes.Add(node);
                    groupNode.Expand();
                }
            }
        }

        // ----------------------------
        // 削除
        // ----------------------------
        private void btnDelete_Click(object sender, EventArgs e)
        {
            if (treeView1.SelectedNode == null) return;

            treeView1.SelectedNode.Remove();
        }

        // ----------------------------
        // 保存ボタン
        // ----------------------------
        private void btnSave_Click(object sender, EventArgs e)
        {
            SaveToFile();
        }

        private void BtnHelp_Click(object sender, EventArgs e)
        {
            MessageBox.Show(
        @"使い方

・グループ追加で分類できます
・フォルダ追加で登録
・ダブルクリックで開く
・Ctrl + ↑↓ で並び替え
・ドラッグでグループ移動

※変更は自動保存されます",
            "ヘルプ",
            MessageBoxButtons.OK,
            MessageBoxIcon.Information);
        }

        private TreeNode GetRecentGroup()
        {
            if (treeView1.Nodes.Count > 0 &&
                treeView1.Nodes[0].Text == "最近使った")
            {
                return treeView1.Nodes[0];
            }

            var group = new TreeNode("最近使った");
            group.Tag = new NodeData { IsGroup = true };
            group.ForeColor = Color.Red;

            treeView1.Nodes.Insert(0, group);
            return group;
        }

        private TreeNode CloneNode(TreeNode original)
        {
            var data = (NodeData)original.Tag;

            var node = new TreeNode(original.Text);
            node.Tag = new NodeData
            {
                Path = data.Path,
                IsGroup = false
            };
            node.ToolTipText = data.Path;

            return node;
        }

        private void AddToRecent(TreeNode node)
        {
            var data = (NodeData)node.Tag;
            if (data.IsGroup) return;

            var group = GetRecentGroup();

            // 重複削除
            foreach (TreeNode n in group.Nodes.Cast<TreeNode>().ToList())
            {
                var d = (NodeData)n.Tag;
                if (d.Path == data.Path)
                    group.Nodes.Remove(n);
            }

            // 先頭に追加
            var newNode = CloneNode(node);
            group.Nodes.Insert(0, newNode);

            // 5件制限
            while (group.Nodes.Count > 5)
            {
                group.Nodes.RemoveAt(group.Nodes.Count - 1);
            }

            group.Expand();

            SaveToFile();
        }

        // ----------------------------
        // ダブルクリックで開く
        // ----------------------------
        private void TreeView1_NodeMouseDoubleClick(object sender, TreeNodeMouseClickEventArgs e)
        {
            var data = (NodeData)e.Node.Tag;

            if (!data.IsGroup && Directory.Exists(data.Path))
            {
                //Process.Start("explorer.exe", data.Path);
                OpenOrActivateFolder(data.Path);
            }

            AddToRecent(e.Node);
        }

        // ----------------------------
        // ドラッグ移動
        // ----------------------------
        private void TreeView1_ItemDrag(object sender, ItemDragEventArgs e)
        {
            DoDragDrop(e.Item, DragDropEffects.Move);
        }

        private void TreeView1_DragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                e.Effect = DragDropEffects.Copy;
            }
            else
            {
                e.Effect = DragDropEffects.Move;
            }
        }

        private void TreeView1_DragDrop(object sender, DragEventArgs e)
        {
            // ------------------------
            // 外部（エクスプローラ）
            // ------------------------
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                string[] paths = (string[])e.Data.GetData(DataFormats.FileDrop);

                TreeNode group = GetOrCreateDefaultGroup();

                foreach (var path in paths)
                {
                    if (!Directory.Exists(path)) continue;

                    string name = Path.GetFileName(path);
                    if (string.IsNullOrEmpty(name)) name = path;

                    // 重複チェック
                    if (group.Nodes.Cast<TreeNode>()
                        .Any(n => ((NodeData)n.Tag).Path == path))
                        continue;

                    var node = new TreeNode(name);
                    node.Tag = new NodeData { Path = path, IsGroup = false };
                    node.ToolTipText = path;

                    group.Nodes.Add(node);
                }

                group.Expand();
                return;
            }
            // ------------------------
            // 内部ドラッグ（並び替え対応版）
            // ------------------------
            Point pt = treeView1.PointToClient(new Point(e.X, e.Y));
            TreeNode target = treeView1.GetNodeAt(pt);
            TreeNode dragged = (TreeNode)e.Data.GetData(typeof(TreeNode));

            if (target == null || dragged == null) return;

            var targetData = (NodeData)target.Tag;
            var draggedData = (NodeData)dragged.Tag;

            // グループは移動させない
            if (draggedData.IsGroup) return;

            TreeNode targetGroup;
            int insertIndex;

            // ドロップ先がグループ
            if (targetData.IsGroup)
            {
                targetGroup = target;
                insertIndex = target.Nodes.Count;
            }
            else
            {
                targetGroup = target.Parent;
                insertIndex = target.Index;
            }

            // 同じ場所なら何もしない
            if (dragged.Parent == targetGroup && dragged.Index == insertIndex)
                return;

            dragged.Remove();
            targetGroup.Nodes.Insert(insertIndex, dragged);
            targetGroup.Expand();
        }

        // ----------------------------
        // 選択時UI制御
        // ----------------------------
        private void TreeView1_AfterSelect(object sender, TreeViewEventArgs e)
        {
            var data = (NodeData)e.Node.Tag;

            btnAddFolder.Enabled = data.IsGroup;
        }

        private void TreeView1_KeyDown(object sender, KeyEventArgs e)
        {
            if (treeView1.SelectedNode == null) return;

            var node = treeView1.SelectedNode;
            var data = (NodeData)node.Tag;

            // グループは移動しない
            if (data.IsGroup) return;

            var parent = node.Parent;
            int index = node.Index;

            // Ctrl + ↑キー
            if (e.Control && e.KeyCode == Keys.Up)
            {
                if (index == 0) return;

                parent.Nodes.Remove(node);
                parent.Nodes.Insert(index - 1, node);

                treeView1.SelectedNode = node;
                e.Handled = true;

                SaveToFile();
            }

            // Ctrl + ↓キー
            if (e.Control && e.KeyCode == Keys.Down)
            {
                if (index >= parent.Nodes.Count - 1) return;

                parent.Nodes.Remove(node);
                parent.Nodes.Insert(index + 1, node);

                treeView1.SelectedNode = node;
                e.Handled = true;

                SaveToFile();
            }
        }

        public void OpenOrActivateFolder(string targetPath)
        {
            targetPath = Path.GetFullPath(targetPath).TrimEnd('\\');

            ShellWindows shellWindows = new ShellWindows();

            foreach (InternetExplorer window in shellWindows)
            {
                try
                {
                    string location = window.LocationURL;

                    if (string.IsNullOrEmpty(location)) continue;

                    // file:///C:/... → C:\... に変換
                    Uri uri = new Uri(location);
                    string path = uri.LocalPath.TrimEnd('\\');

                    if (string.Equals(path, targetPath, StringComparison.OrdinalIgnoreCase))
                    {
                        // 見つかった → 最前面へ
                        IntPtr hwnd = (IntPtr)window.HWND;
                        ShowWindow(hwnd, SW_RESTORE);
                        SetForegroundWindow(hwnd);
                        return;
                    }
                }
                catch
                {
                    // 無視
                }
            }

            // 見つからなければ新規で開く
            Process.Start("explorer.exe", targetPath);
        }

        private TreeNode GetOrCreateDefaultGroup()
        {
            if (treeView1.Nodes.Count > 1)
                return treeView1.Nodes[1];  // 先頭は最近使ったフォルダのため、除外

            if (treeView1.Nodes.Count > 0)
                return treeView1.Nodes[0];

            var node = new TreeNode("Default");
            node.Tag = new NodeData { IsGroup = true };
            treeView1.Nodes.Add(node);

            return node;
        }
        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            SaveToFile();
            base.OnFormClosing(e);
        }

    }

    class NodeData
    {
        public string Path;
        public bool IsGroup;
    }
}