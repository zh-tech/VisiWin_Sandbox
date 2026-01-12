using System;
using System.Windows;
using System.Windows.Controls;
using VisiWin.Controls;
using VisiWin.ApplicationFramework;

namespace HMI
{
    /// <summary>
    /// Interaction logic for MainView1.xaml
    /// </summary>
    [ExportView("MainView1")]
    public partial class MainView1 : VisiWin.Controls.View
    {
        public MainView1()
        {
            InitializeComponent();
        }
    }
}
