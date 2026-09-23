using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml;
using static System.Windows.Forms.LinkLabel;

namespace PictViewer
{
    public partial class Form2 : Form
    {
        private List<string> titles = new List<string>();

        public List<List<string>> nameLists { get; private set; } = new List<List<string>>() ;

        private Label nameLabel;
        public int SelectedValue { get; private set; } = 0;

        public bool initResult;


        public Form2()
        {
            //InitializeComponentは、デザイナーで編集した場合に必要になる
            //今回は不使用のため不要
            //InitializeComponent();

            initResult = true;

            if (!LoadSettingFromXML())
            {
                initResult = false;
                return;
            }

            int y = 20; // 初期Y座標
            int dy = 40;  //変化量Y座標
            int idButton = 0;
            foreach (string title in titles)
            {
                Button btn = new Button
                {
                    Text = title,
                    Size = new Size(100, 30),
                    Location = new Point(20, y),
                    FlatStyle = FlatStyle.Flat,
                    Font = new Font("Meiryo", 8),
                    Tag = idButton,
                };
                //btn.Click += (s, e) => MessageBox.Show($"「{ib}」クリックされました");
                btn.Click += (s, e) => {
                    SelectedValue = (int)btn.Tag;
                    this.DialogResult = DialogResult.OK;
                    this.Close(); 
                };

                btn.Enter += (s, e) => nameLabel.Text = string.Join("\n", nameLists[(int)btn.Tag]);

                this.Controls.Add(btn);
                y += dy; // 次のボタンのY座標をずらす
                idButton++;
            }

            nameLabel = new Label()
            {
                //Text = "初期状態",
                Location = new Point(140, 20),
                Font = new Font("Meiryo", 8),
                AutoSize = true,
            };
            this.Controls.Add(nameLabel);

            this.Size = new Size(300, 250);

            //this.KeyDown += Form2_KeyDown;
            this.KeyPreview = true;
            this.AutoScroll = true;
        }

        private bool LoadSettingFromXML()
        {
            string xmlname = "RegisteredNameSet.xml";
            if (!File.Exists(xmlname))
            {
                MessageBox.Show("RegisteredNameSet.xmlが見つかりません。");
                return false;
            }

            XmlDocument doc = new XmlDocument();
            doc.Load(xmlname);
            XmlNodeList nodes = doc.SelectNodes("/root/situation");
            foreach (XmlNode node in nodes)
            {
                string title = node["title"].InnerText;
                titles.Add(title);

                List<string> nameList = new List<string>();
                XmlNodeList nameNodes = node.SelectNodes("name");
                int ina = 1;
                foreach (XmlNode nameNode in nameNodes)
                {
                    string name = nameNode.InnerText;
                    nameList.Add($"{ina}_{name}");
                    ina++;
                }
                nameLists.Add(nameList);
            }
            return true;
        }



        //private void Form2_KeyDown(object sender, KeyEventArgs e)
        //{

        //    if (e.KeyCode == Keys.F6)
        //    {
        //        MessageBox.Show($"ラベル");
        //    }
        //}

    }
}





