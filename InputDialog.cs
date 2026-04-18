using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FolderExplorer
{
    public partial class InputDialog: Form
    {
        public string InputText => textBox.Text;

        private TextBox textBox;
        private Button okButton;
        private Button cancelButton;

        public InputDialog(string title)
        {
            this.Text = title;
            this.Width = 300;
            this.Height = 150;

            textBox = new TextBox { Left = 10, Top = 10, Width = 260 };

            okButton = new Button { Text = "OK", Left = 110, Width = 75, Top = 40 };
            cancelButton = new Button { Text = "キャンセル", Left = 195, Width = 75, Top = 40 };

            okButton.DialogResult = DialogResult.OK;
            cancelButton.DialogResult = DialogResult.Cancel;

            this.Controls.Add(textBox);
            this.Controls.Add(okButton);
            this.Controls.Add(cancelButton);

            this.AcceptButton = okButton;
            this.CancelButton = cancelButton;
        }

    }
}
