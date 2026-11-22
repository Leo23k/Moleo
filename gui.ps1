#Requires -Version 5.1
#Requires -PSEdition Desktop
[CmdletBinding()]
param([switch]$Validate)

$ErrorActionPreference = 'Stop'
try {
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Moleo" Width="1320" Height="850"
        MinWidth="980" MinHeight="680" WindowStartupLocation="CenterScreen"
        Background="#080D1B" Foreground="#EDF5FF" FontFamily="Segoe UI"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
  <Window.Resources>
    <SolidColorBrush x:Key="Background" Color="#080D1B"/>
    <SolidColorBrush x:Key="Muted" Color="#8290A8"/>
    <SolidColorBrush x:Key="Surface" Color="#111A2E"/>
    <SolidColorBrush x:Key="SurfaceRaised" Color="#18243A"/>
    <SolidColorBrush x:Key="Stroke" Color="#24324A"/>
    <SolidColorBrush x:Key="CleanAccent" Color="#62D9FF"/>
    <SolidColorBrush x:Key="AnalyzeAccent" Color="#9B8CFF"/>
    <SolidColorBrush x:Key="StatusAccent" Color="#62D9FF"/>
    <SolidColorBrush x:Key="Cyan" Color="#62D9FF"/>
    <SolidColorBrush x:Key="Violet" Color="#9B8CFF"/>
    <SolidColorBrush x:Key="Success" Color="#93C995"/>
    <SolidColorBrush x:Key="Warning" Color="#F4C77A"/>
    <SolidColorBrush x:Key="Error" Color="#DB7277"/>
    <SolidColorBrush x:Key="TextPrimary" Color="#EDF5FF"/>
    <SolidColorBrush x:Key="TextSecondary" Color="#AAB8CC"/>
    <SolidColorBrush x:Key="NavSelected" Color="#DDF8FF"/>
    <SolidColorBrush x:Key="NavSelectedBorder" Color="#62D9FF"/>
    <Style x:Key="PageHeading" TargetType="TextBlock"><Setter Property="FontSize" Value="22"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
    <Style x:Key="BodyText" TargetType="TextBlock"><Setter Property="FontSize" Value="13"/><Setter Property="Foreground" Value="{StaticResource TextSecondary}"/><Setter Property="TextWrapping" Value="Wrap"/></Style>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#DFE9F7"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="12,9"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Template">
        <Setter.Value><ControlTemplate TargetType="Button">
          <Border x:Name="Chrome" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10" Padding="{TemplateBinding Padding}">
            <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Chrome" Property="Background" Value="#18243A"/><Setter TargetName="Chrome" Property="BorderBrush" Value="#35516F"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Chrome" Property="Background" Value="#20314D"/></Trigger>
            <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Chrome" Property="BorderBrush" Value="#62D9FF"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.55"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="NavButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Margin" Value="3,2"/><Setter Property="Padding" Value="16,8"/>
      <Setter Property="Foreground" Value="#AAB8CC"/><Setter Property="HorizontalContentAlignment" Value="Center"/>
    </Style>
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Stroke}"/>
      <Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="14"/>
      <Setter Property="Padding" Value="18"/>
    </Style>
    <Style x:Key="Eyebrow" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource Muted}"/><Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="BorderThickness" Value="1"/>
      <Style.Triggers>
        <Trigger Property="IsKeyboardFocused" Value="True"><Setter Property="BorderBrush" Value="#62D9FF"/></Trigger>
        <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.55"/></Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="#18243A"/><Setter Property="Foreground" Value="#AAB8CC"/>
      <Setter Property="BorderBrush" Value="#24324A"/><Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Padding" Value="9,8"/><Setter Property="FontSize" Value="10"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="DataGridRow">
      <Setter Property="MinHeight" Value="32"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#1B2A43"/></Trigger>
        <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="#253959"/><Setter Property="Foreground" Value="#EDF5FF"/></Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="DataGridCell">
      <Setter Property="Padding" Value="8,5"/><Setter Property="BorderThickness" Value="0"/>
      <Style.Triggers>
        <Trigger Property="IsKeyboardFocusWithin" Value="True"><Setter Property="BorderBrush" Value="#62D9FF"/><Setter Property="BorderThickness" Value="1"/></Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="ProgressBar">
      <Setter Property="Height" Value="6"/><Setter Property="Foreground" Value="{StaticResource CleanAccent}"/>
      <Setter Property="Background" Value="#24324A"/><Setter Property="BorderThickness" Value="0"/>
    </Style>
  </Window.Resources>
  <Grid Margin="26,10,26,20">
    <Grid.RowDefinitions><RowDefinition Height="58"/><RowDefinition Height="52"/><RowDefinition Height="*"/></Grid.RowDefinitions>
    <Grid Grid.Row="0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock Text="Moleo" FontSize="20" FontWeight="Bold" VerticalAlignment="Center"/>
        <TextBlock Text="/" FontSize="14" Foreground="#8290A8" Margin="12,0" VerticalAlignment="Center"/>
        <TextBlock x:Name="PageTitle" Text="Clean" FontSize="14" FontWeight="SemiBold" Foreground="#DCE8F7" VerticalAlignment="Center"/>
      </StackPanel>
      <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock x:Name="VersionLabel" Text="Moleo" FontSize="10" Foreground="#8290A8" VerticalAlignment="Center" Margin="0,0,16,0"/>
        <Border x:Name="MetricStatePill" Background="#111A2E" BorderBrush="#24324A" BorderThickness="1" CornerRadius="14" Padding="10,6" Margin="0,0,8,0"><StackPanel Orientation="Horizontal"><Ellipse x:Name="MetricStateDot" Width="6" Height="6" Fill="#F4C77A" VerticalAlignment="Center" Margin="0,0,7,0"/><TextBlock x:Name="MetricState" Text="READING SYSTEM" FontSize="9" Foreground="#B4DDF5"/></StackPanel></Border>
        <Button x:Name="RefreshButton" Padding="10,7" ToolTip="Refresh system status"><TextBlock Text="Refresh"/></Button>
        <Button x:Name="NavSettings" Tag="Settings" Content="Settings" Padding="10,7" Margin="6,0,0,0"/>
      </StackPanel>
    </Grid>
    <Border Grid.Row="1" Background="#111A2E" BorderBrush="#24324A" BorderThickness="1" CornerRadius="20" Padding="4" HorizontalAlignment="Center" VerticalAlignment="Center">
      <StackPanel Orientation="Horizontal">
        <Button x:Name="NavClean" Style="{StaticResource NavButton}" Tag="Clean" Content="Clean"/>
        <Button x:Name="NavApps" Style="{StaticResource NavButton}" Tag="Apps" Content="Apps"/>
        <Button x:Name="NavOptimize" Style="{StaticResource NavButton}" Tag="Optimize" Content="Optimize"/>
        <Button x:Name="NavAnalyze" Style="{StaticResource NavButton}" Tag="Analyze" Content="Analyze"/>
        <Button x:Name="NavStatus" Style="{StaticResource NavButton}" Tag="Status" Content="Status"/>
      </StackPanel>
    </Border>
    <ScrollViewer Grid.Row="2" Margin="0,14,0,0" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,5,18">
        <Grid>
          <StackPanel x:Name="DashboardPage">
            <Border Background="#111A2E" BorderBrush="#24324A" BorderThickness="1" CornerRadius="20" Padding="25" Margin="0,0,0,17">
              <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="180"/></Grid.ColumnDefinitions>
                <StackPanel VerticalAlignment="Center"><TextBlock Text="SYSTEM OVERVIEW" Style="{StaticResource Eyebrow}" Foreground="#62D9FF"/><TextBlock x:Name="Greeting" Text="Welcome back." FontSize="27" FontWeight="SemiBold" Margin="0,9,0,6"/><TextBlock Text="Your system snapshot is live. No maintenance action runs automatically." FontSize="12" Foreground="#AAB8CC" TextWrapping="Wrap"/></StackPanel>
                <Ellipse Grid.Column="1" Width="190" Height="150" HorizontalAlignment="Right" VerticalAlignment="Center" Opacity="0.38">
                  <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#669B8CFF" Offset="0"/><GradientStop Color="#3362D9FF" Offset="0.5"/><GradientStop Color="#0062D9FF" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
                  <Ellipse.Effect><BlurEffect Radius="24"/></Ellipse.Effect>
                </Ellipse>
                <Viewbox Grid.Column="1" Width="120" Height="105" HorizontalAlignment="Right" VerticalAlignment="Center"><Canvas Width="120" Height="105"><Ellipse Canvas.Left="22" Canvas.Top="8" Width="82" Height="82" Stroke="#52637A" StrokeThickness="1"/><Ellipse Canvas.Left="34" Canvas.Top="20" Width="58" Height="58" Stroke="#8094AE" StrokeThickness="1"/><Ellipse Canvas.Left="52" Canvas.Top="38" Width="22" Height="22" Fill="#62D9FF"/><Ellipse Canvas.Left="96" Canvas.Top="20" Width="5" Height="5" Fill="#9B8CFF"/><Ellipse Canvas.Left="23" Canvas.Top="70" Width="4" Height="4" Fill="#78DCC1"/></Canvas></Viewbox>
              </Grid>
            </Border>
            <WrapPanel Margin="-6,0,-6,12">
              <Border Style="{StaticResource Card}" Width="300" Margin="6"><StackPanel><DockPanel><TextBlock Text="PROCESSOR" Style="{StaticResource Eyebrow}"/><TextBlock Text="&#xE950;" FontFamily="Segoe MDL2 Assets" Foreground="#62D9FF" DockPanel.Dock="Right"/></DockPanel><TextBlock x:Name="CpuValue" Text="Sampling…" FontSize="28" FontWeight="SemiBold" Margin="0,16,0,10"/><ProgressBar x:Name="CpuBar" Maximum="100" Value="0"/><TextBlock x:Name="CpuCaption" Text="Windows system time" FontSize="11" Foreground="#8290A8" Margin="0,10,0,0"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Width="300" Margin="6"><StackPanel><DockPanel><TextBlock Text="MEMORY" Style="{StaticResource Eyebrow}"/><TextBlock Text="&#xE7F4;" FontFamily="Segoe MDL2 Assets" Foreground="#9B8CFF" DockPanel.Dock="Right"/></DockPanel><TextBlock x:Name="MemoryValue" Text="Reading…" FontSize="28" FontWeight="SemiBold" Margin="0,16,0,10"/><ProgressBar x:Name="MemoryBar" Maximum="100" Value="0" Foreground="#9B8CFF"/><TextBlock x:Name="MemoryCaption" Text="Physical memory" FontSize="11" Foreground="#8290A8" Margin="0,10,0,0"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Width="300" Margin="6"><StackPanel><DockPanel><TextBlock Text="SYSTEM DRIVE" Style="{StaticResource Eyebrow}"/><TextBlock Text="&#xE958;" FontFamily="Segoe MDL2 Assets" Foreground="#62D9FF" DockPanel.Dock="Right"/></DockPanel><TextBlock x:Name="DiskValue" Text="Reading…" FontSize="25" FontWeight="SemiBold" Margin="0,16,0,10"/><ProgressBar x:Name="DiskBar" Maximum="100" Value="0" Foreground="#62D9FF"/><TextBlock x:Name="DiskCaption" Text="Available capacity" FontSize="11" Foreground="#8290A8" Margin="0,10,0,0"/></StackPanel></Border>
            </WrapPanel>
            <Grid Margin="0,0,0,15"><Grid.ColumnDefinitions><ColumnDefinition Width="1.3*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Border Style="{StaticResource Card}" Margin="0,0,8,0"><StackPanel><DockPanel><TextBlock Text="STORAGE OVERVIEW" Style="{StaticResource Eyebrow}"/><TextBlock x:Name="UpdatedAt" Text="Waiting for sample" FontSize="10" Foreground="#8290A8" DockPanel.Dock="Right"/></DockPanel><TextBlock x:Name="StorageSummary" Text="Reading system drive…" FontSize="17" FontWeight="SemiBold" Margin="0,17,0,11"/><ProgressBar x:Name="StorageBar" Maximum="100" Value="0" Height="8"/><DockPanel Margin="0,12,0,0"><TextBlock x:Name="StorageUsed" Text="Used —" FontSize="11" Foreground="#AAB8CC"/><TextBlock x:Name="StorageFree" Text="Free —" FontSize="11" Foreground="#AAB8CC" DockPanel.Dock="Right"/></DockPanel></StackPanel></Border>
              <Border Grid.Column="1" Style="{StaticResource Card}" Margin="8,0,0,0"><StackPanel><TextBlock Text="QUICK ACCESS" Style="{StaticResource Eyebrow}"/><Button x:Name="QuickAnalyze" Margin="0,12,0,0"><StackPanel Orientation="Horizontal"><TextBlock Text="&#xE958;" FontFamily="Segoe MDL2 Assets" Foreground="#62D9FF" Width="27"/><TextBlock Text="Explore disk"/></StackPanel></Button><Button x:Name="QuickClean"><StackPanel Orientation="Horizontal"><TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Foreground="#62D9FF" Width="27"/><TextBlock Text="System cleanup"/></StackPanel></Button><Button x:Name="QuickApps"><StackPanel Orientation="Horizontal"><TextBlock Text="&#xECAA;" FontFamily="Segoe MDL2 Assets" Foreground="#62D9FF" Width="27"/><TextBlock Text="View applications"/></StackPanel></Button></StackPanel></Border>
            </Grid>
            <Border Style="{StaticResource Card}"><DockPanel><StackPanel><TextBlock Text="RECENT ACTIVITY" Style="{StaticResource Eyebrow}"/><TextBlock Text="No GUI operations recorded in this session." FontSize="12" Foreground="#AAB8CC" Margin="0,10,0,0"/><TextBlock Text="Metrics are read-only. Cleanup and system changes require a separate, explicit workflow." FontSize="11" Foreground="#8290A8" Margin="0,4,0,0" TextWrapping="Wrap"/></StackPanel><TextBlock Text="&#xE823;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#637A97" VerticalAlignment="Center" DockPanel.Dock="Right"/></DockPanel></Border>
          </StackPanel>
          <Grid x:Name="CleanPage" Visibility="Collapsed" Margin="18,8,18,16">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="205"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <DockPanel Grid.Row="0" Margin="0,0,0,14"><Button x:Name="CleanScanButton" DockPanel.Dock="Right" Background="{StaticResource CleanAccent}" Foreground="#080D1B" BorderBrush="{StaticResource CleanAccent}"><StackPanel Orientation="Horizontal"><TextBlock Text="Scan"/></StackPanel></Button><StackPanel><TextBlock Text="Clean" Style="{StaticResource PageHeading}"/><TextBlock Text="Review safe cleanup candidates before making a change." FontSize="12" Foreground="#8290A8" Margin="0,4,0,0"/></StackPanel></DockPanel>
            <Border Grid.Row="1" Background="#111A2E" BorderBrush="#24324A" BorderThickness="1" CornerRadius="18" Padding="25" Margin="0,0,0,14">
              <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="2*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel VerticalAlignment="Center"><TextBlock Text="RECOVERABLE SPACE · ESTIMATE" FontSize="10" FontWeight="SemiBold" Foreground="#B4DDF5"/><TextBlock x:Name="CleanHeroSize" Text="Scan to begin" FontSize="34" FontWeight="SemiBold" Margin="0,10,0,4"/><TextBlock x:Name="CleanPlanSummary" Text="The scan lists safe candidates. Nothing is selected or removed automatically." FontSize="12" Foreground="#AAB8CC" TextWrapping="Wrap"/></StackPanel>
                <Grid Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" Width="150" Height="150"><Ellipse Fill="#263D5D"/><Ellipse Margin="12" Fill="#406A8B"/><Ellipse Margin="20" Fill="#8CAAC9" Opacity="0.78"/><Path Data="M18,92 C44,67 68,113 111,79 L132,119 L18,132 Z" Fill="#637A97" Opacity="0.8"/><Ellipse Width="18" Height="18" Fill="#DDF8FF" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,25,34,0"/></Grid>
              </Grid>
            </Border>
            <TextBlock x:Name="CleanStatus" Grid.Row="2" Text="No scan has been run. Nothing will be removed automatically." FontSize="12" Foreground="#AAB8CC" Margin="2,0,0,10" TextWrapping="Wrap"/>
            <Border Grid.Row="3" Style="{StaticResource Card}" Padding="6" MinHeight="180" Margin="0,0,0,12">
              <DataGrid x:Name="CleanItemsGrid" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" IsReadOnly="False" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="11" EnableRowVirtualization="True" EnableColumnVirtualization="True" MaxHeight="430" MinHeight="160">
                <DataGrid.Columns>
                  <DataGridCheckBoxColumn Header="Select" Binding="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="58"/>
                  <DataGridTextColumn Header="GROUP" Binding="{Binding Group}" Width="150" IsReadOnly="True"/>
                  <DataGridTextColumn Header="PATH" Binding="{Binding Path}" Width="2*" IsReadOnly="True"/>
                  <DataGridTextColumn Header="REASON" Binding="{Binding Reason}" Width="2*" IsReadOnly="True"/>
                  <DataGridTextColumn Header="ESTIMATE" Binding="{Binding EstimatedDisplay}" Width="100" IsReadOnly="True"/>
                </DataGrid.Columns>
              </DataGrid>
            </Border>
            <Border Grid.Row="4" Style="{StaticResource Card}" Padding="12" Margin="0,0,0,5">
              <WrapPanel VerticalAlignment="Center">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,10,4"><ComboBox x:Name="CleanGroupPicker" Width="150" Height="34" Background="#18243A" Foreground="#EDF5FF" BorderBrush="#2D405C"/><Button x:Name="CleanSelectGroup" Margin="7,0,0,0" Padding="9,7" Content="Select group"/><Button x:Name="CleanClearGroup" Margin="4,0,0,0" Padding="9,7" Content="Clear group"/></StackPanel>
                <StackPanel Width="230" VerticalAlignment="Center" Margin="4,0,10,4"><TextBlock x:Name="CleanSelectedSummary" Text="0 selected · estimate 0 B" FontSize="12" FontWeight="SemiBold"/><TextBlock Text="Estimate only; actual freed space can differ." FontSize="10" Foreground="#8290A8" Margin="0,3,0,0" TextWrapping="Wrap"/></StackPanel>
                <Button x:Name="CleanExecuteButton" IsEnabled="False" Background="#18243A" BorderBrush="#2D405C" Content="Review and clean" Margin="2,0,0,4"/>
              </WrapPanel>
            </Border>
            <ListBox x:Name="CleanResults" Grid.Row="5" MaxHeight="110" Background="Transparent" BorderThickness="0" Foreground="#AAB8CC" FontSize="11" Margin="0,5,0,0" Visibility="Collapsed"/>
          </Grid>
          <Grid x:Name="AppsPage" Visibility="Collapsed" Margin="18,8,18,16">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <DockPanel Grid.Row="0" Margin="0,0,0,14"><Button x:Name="AppsScanButton" DockPanel.Dock="Right" Background="{StaticResource CleanAccent}" Foreground="#080D1B" BorderBrush="{StaticResource CleanAccent}" Content="Scan apps"/><StackPanel><TextBlock Text="Apps" Style="{StaticResource PageHeading}"/><TextBlock Text="Installed applications · sized by the existing Mole inventory scan" FontSize="12" Foreground="#8290A8" Margin="0,4,0,0"/></StackPanel></DockPanel>
            <DockPanel Grid.Row="1" Margin="0,0,0,9"><TextBox x:Name="AppsSearch" DockPanel.Dock="Right" Width="220" Height="32" VerticalContentAlignment="Center" Background="#111A2E" Foreground="#EDF5FF" BorderBrush="#2D405C" Padding="8,4" ToolTip="Filter installed applications"/><TextBlock x:Name="AppsStatus" Text="Scan to load installed applications." FontSize="12" Foreground="#AAB8CC" VerticalAlignment="Center" TextWrapping="Wrap"/></DockPanel>
            <Border Grid.Row="2" Style="{StaticResource Card}" Padding="6" MinHeight="220"><DataGrid x:Name="AppsGrid" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" IsReadOnly="False" CanUserSortColumns="True" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="12" EnableRowVirtualization="True" EnableColumnVirtualization="True"><DataGrid.Columns><DataGridCheckBoxColumn Header="SELECT" Binding="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="62"/><DataGridTextColumn Header="APPLICATION" Binding="{Binding Name}" SortMemberPath="Name" Width="2*" IsReadOnly="True"/><DataGridTextColumn Header="PUBLISHER" Binding="{Binding Publisher}" SortMemberPath="Publisher" Width="1.3*" IsReadOnly="True"/><DataGridTextColumn Header="VERSION" Binding="{Binding Version}" SortMemberPath="Version" Width="105" IsReadOnly="True"/><DataGridTextColumn Header="SOURCE" Binding="{Binding Source}" SortMemberPath="Source" Width="105" IsReadOnly="True"/><DataGridTextColumn Header="SIZE" Binding="{Binding SizeHuman}" SortMemberPath="SizeKB" Width="95" IsReadOnly="True"/></DataGrid.Columns></DataGrid></Border>
            <Border Grid.Row="3" Style="{StaticResource Card}" Padding="12" Margin="0,12,0,0"><DockPanel><Button x:Name="AppsUninstallButton" DockPanel.Dock="Right" IsEnabled="False" Background="{StaticResource Violet}" Foreground="#080D1B" BorderBrush="{StaticResource Violet}" Content="Review and uninstall"/><StackPanel><TextBlock x:Name="AppsSelectedSummary" Text="0 selected" FontSize="13" FontWeight="SemiBold"/><TextBlock Text="Uninstall uses the registered remover once. Leftovers follow Mole's protected Recycle Bin checks." FontSize="10" Foreground="#8290A8" Margin="0,4,0,0" TextWrapping="Wrap"/></StackPanel></DockPanel></Border>
            <ListBox x:Name="AppsResults" Grid.Row="4" MaxHeight="100" Background="Transparent" BorderThickness="0" Foreground="#AAB8CC" FontSize="11" Margin="0,5,0,0" Visibility="Collapsed"/>
          </Grid>
          <Grid x:Name="OptimizePage" Visibility="Collapsed" Margin="18,8,18,16">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Margin="0,0,0,14"><TextBlock Text="Optimize" Style="{StaticResource PageHeading}"/><TextBlock Text="Run one reviewed maintenance task at a time. Checks are read-only; system actions require confirmation." FontSize="12" Foreground="#8290A8" Margin="0,4,0,0" TextWrapping="Wrap"/></StackPanel>
            <TextBlock x:Name="OptimizeStatus" Grid.Row="1" Text="Loading available tasks…" FontSize="12" Foreground="#AAB8CC" Margin="0,0,0,9" TextWrapping="Wrap"/>
            <Border Grid.Row="2" Style="{StaticResource Card}" Padding="6" MinHeight="220"><DataGrid x:Name="OptimizeGrid" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" IsReadOnly="False" CanUserSortColumns="True" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="12" EnableRowVirtualization="True" EnableColumnVirtualization="True"><DataGrid.Columns><DataGridCheckBoxColumn Header="SELECT" Binding="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="62"/><DataGridTextColumn Header="TASK" Binding="{Binding Name}" SortMemberPath="Name" Width="175" IsReadOnly="True"/><DataGridTextColumn Header="TYPE" Binding="{Binding Kind}" SortMemberPath="Kind" Width="90" IsReadOnly="True"/><DataGridTextColumn Header="DETAILS / IMPACT" Binding="{Binding Description}" Width="*" IsReadOnly="True"/></DataGrid.Columns></DataGrid></Border>
            <DockPanel Grid.Row="3" Margin="0,10,0,0"><Button x:Name="OptimizeRunButton" DockPanel.Dock="Right" IsEnabled="False" Background="{StaticResource Violet}" Foreground="#080D1B" BorderBrush="{StaticResource Violet}" Content="Review selected tasks"/><TextBlock x:Name="OptimizeSelectedSummary" Text="0 selected" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center"/></DockPanel>
            <ListBox x:Name="OptimizeResults" Grid.Row="4" MaxHeight="140" Background="Transparent" BorderThickness="0" Foreground="#AAB8CC" FontSize="11" Margin="0,5,0,0" Visibility="Collapsed"/>
          </Grid>
          <Grid x:Name="AnalyzePage" Visibility="Collapsed" Margin="18,8,18,14">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <DockPanel Grid.Row="0" Margin="0,0,0,13"><Button x:Name="AnalyzeScanButton" DockPanel.Dock="Right" Background="{StaticResource AnalyzeAccent}" Foreground="#080D1B" BorderBrush="{StaticResource AnalyzeAccent}" Content="Scan"/><StackPanel><TextBlock Text="Analyze" Style="{StaticResource PageHeading}"/><TextBlock Text="Read-only disk scan · folder sizes are measured by the Mole scanner." FontSize="12" Foreground="#8290A8" Margin="0,4,0,0"/></StackPanel></DockPanel>
            <Grid Grid.Row="1" Margin="0,0,0,9"><Grid.ColumnDefinitions><ColumnDefinition Width="96"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><ComboBox x:Name="AnalyzeDrivePicker" Grid.Column="0" Height="34" Background="#18243A" Foreground="#EDF5FF" BorderBrush="#2D405C" Margin="0,0,7,0"/><TextBox x:Name="AnalyzePathBox" Grid.Column="1" MinWidth="120" Height="34" VerticalContentAlignment="Center" Background="#111A2E" Foreground="#EDF5FF" BorderBrush="#2D405C" Padding="8,4" Margin="0,0,7,0"/><Button x:Name="AnalyzeBrowseButton" Grid.Column="2" Content="Browse…" Margin="0,0,7,0"/><Button x:Name="AnalyzeBackButton" Grid.Column="3" Content="Back" IsEnabled="False" Margin="0,0,7,0"/><Button x:Name="AnalyzeCancelButton" Grid.Column="4" Content="Cancel scan" IsEnabled="False"/></Grid>
            <DockPanel Grid.Row="2" Margin="0,0,0,10"><TextBlock x:Name="AnalyzeStatus" Text="Choose a drive or folder to scan." FontSize="12" Foreground="#AAB8CC" TextWrapping="Wrap"/><TextBox x:Name="AnalyzeSearch" DockPanel.Dock="Right" Width="190" Height="30" VerticalContentAlignment="Center" Background="#111A2E" Foreground="#EDF5FF" BorderBrush="#2D405C" Padding="7,3" ToolTip="Filter current results"/></DockPanel>
            <Grid Grid.Row="3"><Grid.ColumnDefinitions><ColumnDefinition Width="1.05*"/><ColumnDefinition Width="1.6*"/></Grid.ColumnDefinitions><Grid.RowDefinitions><RowDefinition Height="1.25*"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Border Grid.RowSpan="2" Style="{StaticResource Card}" Padding="6" Margin="0,0,10,0"><DataGrid x:Name="AnalyzeEntriesGrid" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True" CanUserSortColumns="True" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="11" MinHeight="180"><DataGrid.Columns><DataGridTextColumn Header="NAME" Binding="{Binding Name}" SortMemberPath="Name" Width="1.1*"/><DataGridTextColumn Header="TYPE" Binding="{Binding Kind}" SortMemberPath="Kind" Width="62"/><DataGridTextColumn Header="SIZE" Binding="{Binding SizeDisplay}" SortMemberPath="Size" Width="90"/></DataGrid.Columns></DataGrid></Border>
              <Border Grid.Column="1" Style="{StaticResource Card}" Padding="14" Margin="0,0,0,10"><DockPanel><StackPanel DockPanel.Dock="Top" Margin="0,0,0,12"><TextBlock Text="TOP-LEVEL SIZE MAP" Style="{StaticResource Eyebrow}"/><TextBlock Text="Tile widths reflect the measured size of each item." FontSize="10" Foreground="#8290A8" Margin="0,3,0,0"/></StackPanel><Grid x:Name="AnalyzeTreemap" MinHeight="170" ClipToBounds="True"><TextBlock x:Name="AnalyzeTreemapEmpty" Text="Scan a folder to map its measured contents." Foreground="#AAB8CC" FontSize="12" TextWrapping="Wrap" VerticalAlignment="Center" HorizontalAlignment="Center"/></Grid></DockPanel></Border>
              <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}" Padding="6"><DockPanel><TextBlock Text="LARGEST FILES" Style="{StaticResource Eyebrow}" DockPanel.Dock="Top" Margin="5,2,0,5"/><DataGrid x:Name="AnalyzeLargeFilesGrid" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True" CanUserSortColumns="True" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="11" MinHeight="90"><DataGrid.Columns><DataGridTextColumn Header="FILE" Binding="{Binding Name}" SortMemberPath="Name" Width="1.1*"/><DataGridTextColumn Header="SIZE" Binding="{Binding SizeDisplay}" SortMemberPath="Size" Width="90"/><DataGridTextColumn Header="PATH" Binding="{Binding Path}" SortMemberPath="Path" Width="1.4*"/></DataGrid.Columns></DataGrid></DockPanel></Border>
            </Grid>
          </Grid>
          <Grid x:Name="StatusPage" Visibility="Collapsed" Margin="18,12,18,18">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <StackPanel><TextBlock Text="Status" Style="{StaticResource PageHeading}"/><TextBlock Text="Live measurements from the Mole Status collector." FontSize="12" Foreground="#8290A8" Margin="0,4,0,15"/></StackPanel>
            <UniformGrid Grid.Row="1" Columns="3" Margin="-5,-5,-5,7">
              <Border Style="{StaticResource Card}" Margin="5" Background="#142137"><StackPanel><TextBlock Text="CPU" Style="{StaticResource Eyebrow}" Foreground="{StaticResource StatusAccent}"/><TextBlock x:Name="StatusCpu" Text="Waiting for collector…" FontSize="23" FontWeight="SemiBold" Margin="0,9,0,9"/><ProgressBar x:Name="StatusCpuBar" Maximum="100" Value="0" Foreground="{StaticResource StatusAccent}"/><TextBlock Text="System utilization" Foreground="#8290A8" FontSize="10" Margin="0,7,0,0"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Margin="5" Background="#142137"><StackPanel><TextBlock Text="MEMORY" Style="{StaticResource Eyebrow}" Foreground="{StaticResource StatusAccent}"/><TextBlock x:Name="StatusMemory" Text="Waiting for collector…" FontSize="21" FontWeight="SemiBold" Margin="0,9,0,9"/><ProgressBar x:Name="StatusMemoryBar" Maximum="100" Value="0" Foreground="{StaticResource StatusAccent}"/><TextBlock x:Name="StatusMemoryCaption" Text="Physical memory" Foreground="#8290A8" FontSize="10" Margin="0,7,0,0"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Margin="5" Background="#142137"><StackPanel><TextBlock Text="SYSTEM DRIVE" Style="{StaticResource Eyebrow}" Foreground="{StaticResource StatusAccent}"/><TextBlock x:Name="StatusDisk" Text="Waiting for collector…" FontSize="19" FontWeight="SemiBold" Margin="0,9,0,9"/><ProgressBar x:Name="StatusDiskBar" Maximum="100" Value="0" Foreground="{StaticResource StatusAccent}"/><TextBlock x:Name="StatusDiskCaption" Text="Disk usage" Foreground="#8290A8" FontSize="10" Margin="0,7,0,0"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Margin="5"><StackPanel><TextBlock Text="DISK I/O" Style="{StaticResource Eyebrow}"/><TextBlock x:Name="StatusDiskIO" Text="Waiting for collector…" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,4"/><TextBlock Text="Read / write · MB/s" Foreground="#8290A8" FontSize="10"/></StackPanel></Border>
              <Border Style="{StaticResource Card}" Margin="5"><StackPanel><TextBlock Text="NETWORK" Style="{StaticResource Eyebrow}"/><TextBlock x:Name="StatusNetwork" Text="Waiting for collector…" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,4"/><TextBlock x:Name="StatusNetworkCaption" Text="Receive / transmit · MB/s" Foreground="#8290A8" FontSize="10"/></StackPanel></Border>
            </UniformGrid>
            <StackPanel Grid.Row="2"><TextBlock x:Name="StatusUpdated" Text="Waiting for collector" FontSize="10" Foreground="#8290A8" Margin="2,1,0,10"/><TextBlock Text="PROCESSES" Style="{StaticResource Eyebrow}" Margin="2,0,0,7"/><Border Style="{StaticResource Card}" Padding="6"><DataGrid x:Name="StatusProcesses" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True" CanUserSortColumns="True" HeadersVisibility="Column" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#24324A" RowBackground="#111A2E" AlternatingRowBackground="#141F34" Background="#111A2E" BorderThickness="0" Foreground="#DFE9F7" FontSize="11" MaxHeight="280" MinHeight="120"><DataGrid.Columns><DataGridTextColumn Header="PROCESS" Binding="{Binding Name}" SortMemberPath="Name" Width="2*"/><DataGridTextColumn Header="PID" Binding="{Binding PID}" SortMemberPath="PID" Width="70"/><DataGridTextColumn Header="CPU" Binding="{Binding CpuDisplay}" SortMemberPath="CPU" Width="90"/><DataGridTextColumn Header="MEMORY" Binding="{Binding MemoryDisplay}" SortMemberPath="MemoryBytes" Width="110"/></DataGrid.Columns></DataGrid></Border></StackPanel>
          </Grid>
          <StackPanel x:Name="SettingsPage" Visibility="Collapsed"><TextBlock Text="Settings" FontSize="25" FontWeight="SemiBold"/><TextBlock Text="Application preferences and diagnostics" FontSize="12" Foreground="#8290A8" Margin="0,6,0,20"/><Border Style="{StaticResource Card}" MaxWidth="850" HorizontalAlignment="Left"><StackPanel><TextBlock Text="Appearance" Style="{StaticResource Eyebrow}"/><TextBlock Text="Dark interface · English · live metrics refresh every 2 seconds" FontSize="13" Foreground="#D0CFCA" Margin="0,9,0,18"/><TextBlock Text="ABOUT MOLEO" Style="{StaticResource Eyebrow}"/><TextBlock Text="Moleo for Windows" FontSize="13" Foreground="#D0CFCA" Margin="0,9,0,0"/><TextBlock Text="Clean Preview · Apps inventory and uninstall · Optimize tasks · system status · disk analysis" FontSize="11" Foreground="#8290A8" Margin="0,4,0,0" TextWrapping="Wrap"/></StackPanel></Border></StackPanel>
        </Grid>
      </ScrollViewer>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    $message = "Moleo could not initialize its Windows interface.`n`n$($_.Exception.Message)"
    if ($Validate) { throw $message }
    try { [Windows.MessageBox]::Show($message, 'Moleo startup error', 'OK', 'Error') | Out-Null }
    catch { Write-Error $message }
    exit 1
}
$names = 'Dashboard','Clean','Apps','Optimize','Analyze','Status','Settings'
$pages = @{}
foreach ($name in $names) { $pages[$name] = $window.FindName("${name}Page") }
$title = $window.FindName('PageTitle')
$navNames = @{ Clean='Clean'; Apps='Apps'; Optimize='Optimize'; Analyze='Analyze'; Status='Status'; Settings='Settings' }
function Show-Page([string]$Name) {
    foreach ($key in $pages.Keys) { $pages[$key].Visibility = [Windows.Visibility]::Collapsed }
    $pages[$Name].Visibility = [Windows.Visibility]::Visible
    $title.Text = $Name
    foreach ($key in $navNames.Keys) {
        $button = $window.FindName("Nav$key")
        if ($key -eq $Name) {
            $button.Background = $window.FindResource('NavSelected')
            $button.BorderBrush = $window.FindResource('NavSelectedBorder')
            $button.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#111A2E')
        } else {
            $button.Background = [Windows.Media.Brushes]::Transparent
            $button.BorderBrush = [Windows.Media.Brushes]::Transparent
            $button.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#AAB8CC')
        }
    }
}
foreach ($name in $navNames.Keys) {
    $button = $window.FindName("Nav$name")
    $button.Add_Click({ param($sender,$eventArgs) Show-Page -Name ([string]$sender.Tag) })
}
function Get-CleanSelection($Items) {
    $selected = @($Items | Where-Object Selected)
    $bytes = 0L
    if ($selected.Count) { $bytes = [long](($selected | Measure-Object -Property EstimatedBytes -Sum).Sum) }
    [pscustomobject]@{ Items = $selected; Count = $selected.Count; Bytes = $bytes; Ids = [string[]]@($selected | ForEach-Object Id) }
}
function Test-CleanConfirmationResult($Result) { return $Result -eq [Windows.MessageBoxResult]::Yes }
foreach ($pair in @(@('QuickAnalyze','Analyze'),@('QuickClean','Clean'),@('QuickApps','Apps'))) {
    $button = $window.FindName($pair[0]); $pageName = $pair[1]
    $button.Tag = $pageName
    $button.Add_Click({ param($sender,$eventArgs) Show-Page -Name ([string]$sender.Tag) })
}
$controls = @{}
foreach ($name in 'CpuValue','CpuCaption','CpuBar','MemoryValue','MemoryCaption','MemoryBar','DiskValue','DiskCaption','DiskBar','StorageSummary','StorageBar','StorageUsed','StorageFree','UpdatedAt','StatusCpu','StatusCpuBar','StatusMemory','StatusMemoryBar','StatusDisk','StatusDiskBar','StatusMemoryCaption','StatusDiskCaption','StatusDiskIO','StatusNetwork','StatusNetworkCaption','StatusUpdated','StatusProcesses') {
    $controls[$name] = $window.FindName($name)
}
function Format-Bytes([uint64]$Bytes) {
    if ($Bytes -ge 1TB) { return '{0:N1} TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N1} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N0} MB' -f ($Bytes / 1MB) }
    return '{0:N0} KB' -f ($Bytes / 1KB)
}
function Format-CleanBytes([long]$Bytes) {
    if ($Bytes -ge 1TB) { return '{0:N2} TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N1} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N0} KB' -f ($Bytes / 1KB) }
    return '{0:N0} B' -f $Bytes
}
function ConvertFrom-MoleStatusSnapshot([string]$Json) {
    $snapshot = $Json | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $snapshot.cpu -or $null -eq $snapshot.memory -or $null -eq $snapshot.disks -or -not $snapshot.collected_at) { throw 'Status collector returned an incomplete JSON snapshot.' }
    if ([double]$snapshot.cpu.usage -lt 0 -or [double]$snapshot.cpu.usage -gt 100 -or [long]$snapshot.memory.total -le 0 -or [long]$snapshot.memory.used -gt [long]$snapshot.memory.total) { throw 'Status collector returned inconsistent metrics.' }
    return $snapshot
}
function Get-MoleBackendPath([string]$Name) {
    foreach ($candidate in @((Join-Path $PSScriptRoot "bin\$Name.exe"),(Join-Path $PSScriptRoot "$Name.exe"))) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function ConvertFrom-MoleAnalyzeEvent([string]$Json) {
    $eventData = $Json | ConvertFrom-Json -ErrorAction Stop
    if ($eventData.type -notin @('progress','result')) { throw 'Analyze backend sent an unknown event.' }
    return $eventData
}
function Stop-MoleChildProcess($Process) {
    if ($null -eq $Process) { return $true }
    try {
        if (-not $Process.HasExited) { $Process.Kill(); if (-not $Process.WaitForExit(1500)) { throw 'Backend process did not stop.' } }
        return $Process.HasExited
    } finally { $Process.Dispose() }
}
function Start-MoleProcessReads($Process, $State) {
    $State.OutputTask = $Process.StandardOutput.ReadLineAsync()
    $State.ErrorTask = $Process.StandardError.ReadLineAsync()
}
function Receive-MoleProcessLines($State) {
    foreach ($stream in @('Output','Error')) {
        $taskName = $stream + 'Task'
        $reader = if ($stream -eq 'Output') { $State.Process.StandardOutput } else { $State.Process.StandardError }
        $task = $State[$taskName]
        while ($task -and $task.IsCompleted) {
            try { $line = $task.GetAwaiter().GetResult() }
            catch { $State.Errors.Enqueue($_.Exception.Message); $line = $null }
            if ($null -eq $line) { $State[$taskName] = $null; break }
            if ($stream -eq 'Output') { $State.Queue.Enqueue($line) } else { $State.Errors.Enqueue($line) }
            $task = $reader.ReadLineAsync()
            $State[$taskName] = $task
        }
    }
    if (-not $Validate -and $Name -eq 'Apps' -and -not $appsState.Loaded -and -not $appsState.Process) { Start-AppsRequest 'inventory' @() }
    if (-not $Validate -and $Name -eq 'Optimize' -and -not $optimizeState.Loaded -and -not $optimizeState.Process) { Start-OptimizeCatalog }
}
function Set-MetricsUnavailable([string]$Reason) {
    foreach ($name in 'CpuValue','MemoryValue','DiskValue','StorageSummary','StatusCpu','StatusMemory','StatusDisk','StatusDiskIO','StatusNetwork') { $controls[$name].Text = 'N/A' }
    foreach ($name in 'CpuCaption','MemoryCaption','DiskCaption','StatusMemoryCaption','StatusDiskCaption','StatusNetworkCaption') { $controls[$name].Text = $Reason }
    foreach ($name in 'CpuBar','MemoryBar','DiskBar','StorageBar','StatusCpuBar','StatusMemoryBar','StatusDiskBar') { $controls[$name].Value = 0 }
    foreach ($name in 'StorageUsed','StorageFree') { $controls[$name].Text = $name + '  —' }
    $controls.UpdatedAt.Text = $Reason
    $controls.StatusUpdated.Text = $Reason
    $controls.StatusProcesses.ItemsSource = $null
    $window.FindName('MetricState').Text = 'METRICS UNAVAILABLE'
    $window.FindName('MetricState').Foreground = $window.FindResource('Error')
    $window.FindName('MetricStateDot').Fill = $window.FindResource('Error')
    $window.FindName('MetricStatePill').Background = '#3A2433'
}
function Update-Metrics($Snapshot) {
    try {
        $cpu = [double]$Snapshot.cpu.usage
        $memoryTotal = [long]$Snapshot.memory.total
        $memoryUsed = [long]$Snapshot.memory.used
        $memoryPercent = [double]$Snapshot.memory.used_percent
        $systemDrive = [Environment]::GetEnvironmentVariable('SystemDrive').TrimEnd('\') + '\'
        $disk = @($Snapshot.disks | Where-Object { [string]::Equals(([string]$_.mount).TrimEnd('\') + '\',$systemDrive,[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
        if (-not $disk.Count) { $disk = @($Snapshot.disks | Select-Object -First 1) }
        if (-not $disk.Count -or [long]$disk[0].total -le 0) { throw 'System disk metrics are unavailable.' }
        $disk = $disk[0]
        $diskUsed = [long]$disk.used
        $diskTotal = [long]$disk.total
        $diskFree = $diskTotal - $diskUsed
        $diskPercent = [double]$disk.used_percent
        $controls.CpuValue.Text = '{0:N0}%' -f $cpu
        $controls.CpuCaption.Text = '{0} logical processors · live' -f $Snapshot.cpu.logical_cpu
        $controls.CpuBar.Value = $cpu
        $controls.MemoryValue.Text = '{0:N1} GB' -f ($memoryUsed / 1GB)
        $controls.MemoryCaption.Text = '{0:N1} GB in use of {1:N1} GB' -f ($memoryUsed / 1GB),($memoryTotal / 1GB)
        $controls.MemoryBar.Value = $memoryPercent
        $controls.DiskValue.Text = '{0:N1} GB free' -f ($diskFree / 1GB)
        $controls.DiskCaption.Text = '{0:N1} GB total · {1:N0}% used' -f ($diskTotal / 1GB),$diskPercent
        $controls.DiskBar.Value = $diskPercent
        $controls.StorageSummary.Text = '{0} used on {1}' -f (Format-Bytes ([uint64]$diskUsed)),$disk.mount
        $controls.StorageBar.Value = $diskPercent
        $controls.StorageUsed.Text = 'Used  ' + (Format-Bytes ([uint64]$diskUsed))
        $controls.StorageFree.Text = 'Free  ' + (Format-Bytes ([uint64]$diskFree))
        $controls.StatusCpu.Text = '{0:N0}%' -f $cpu
        $controls.StatusCpuBar.Value = $cpu
        $controls.StatusMemory.Text = '{0:N1} GB / {1:N1} GB' -f ($memoryUsed / 1GB),($memoryTotal / 1GB)
        $controls.StatusMemoryCaption.Text = '{0:N0}% in use' -f $memoryPercent
        $controls.StatusMemoryBar.Value = $memoryPercent
        $controls.StatusDisk.Text = '{0:N1} GB / {1:N1} GB used' -f ($diskUsed / 1GB),($diskTotal / 1GB)
        $controls.StatusDiskCaption.Text = '{0:N1} GB available' -f ($diskFree / 1GB)
        $controls.StatusDiskBar.Value = $diskPercent
        $controls.StatusDiskIO.Text = '{0:N2} / {1:N2} MB/s' -f [double]$Snapshot.disk_io.read_rate,[double]$Snapshot.disk_io.write_rate
        $networkRx = @($Snapshot.network_history.rx_history)
        $networkTx = @($Snapshot.network_history.tx_history)
        if ($networkRx.Count -and $networkTx.Count) {
            $controls.StatusNetwork.Text = '{0:N2} / {1:N2} MB/s' -f [double]$networkRx[-1],[double]$networkTx[-1]
            $controls.StatusNetworkCaption.Text = 'Combined active adapter traffic'
        } else {
            $controls.StatusNetwork.Text = 'Unavailable'
            $controls.StatusNetworkCaption.Text = 'No network adapter data'
        }
        $processes = @($Snapshot.top_processes | ForEach-Object { [pscustomobject]@{ Name=$_.name; PID=$_.pid; CPU=[double]$_.cpu; CpuDisplay=('{0:N1}%' -f [double]$_.cpu); MemoryBytes=[long]$_.memory_bytes; MemoryDisplay=(Format-Bytes ([uint64]$_.memory_bytes)) } })
        $controls.StatusProcesses.ItemsSource = $processes
        $updated = ([datetime]$Snapshot.collected_at).ToLocalTime().ToString('HH:mm:ss')
        $controls.UpdatedAt.Text = 'Updated ' + $updated
        $controls.StatusUpdated.Text = 'Collector updated ' + $updated
        $window.FindName('MetricState').Text = 'MOLE STATUS · LIVE'
        $window.FindName('MetricState').Foreground = $window.FindResource('Success')
        $window.FindName('MetricStateDot').Fill = $window.FindResource('Success')
        $window.FindName('MetricStatePill').Background = '#142137'
    } catch { Set-MetricsUnavailable ('Metric data unavailable: ' + $_.Exception.Message) }
}

$statusState = @{ Process = $null; Queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); Errors = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); OutputTask = $null; ErrorTask = $null }
function Set-StatusUnavailable([string]$Reason) { Set-MetricsUnavailable $Reason }
function Start-StatusCollector {
    $binary = Get-MoleBackendPath 'status'
    if (-not $binary) { Set-StatusUnavailable 'Status backend is missing. Build it with .\scripts\build.ps1 (Go 1.24.6 required), or use the bundled Mole binaries.'; return }
    try {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $process.StartInfo.FileName = $binary
        $process.StartInfo.Arguments = '--watch --interval 2s'
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        if (-not $process.Start()) { throw 'Could not start status.exe.' }
        $statusState.Process = $process
        Start-MoleProcessReads $process $statusState
        $controls.StatusUpdated.Text = 'Connecting to Mole Status collector…'
    } catch { Set-StatusUnavailable ('Could not start Status backend: ' + $_.Exception.Message) }
}
function Poll-StatusCollector {
    if (-not $statusState.Process) { return }
    try { if ($statusState.Process.HasExited) { $statusState.Process.WaitForExit() } } catch {}
    Receive-MoleProcessLines $statusState
    $line = $null
    while ($statusState.Queue.TryDequeue([ref]$line)) {
        try { Update-Metrics (ConvertFrom-MoleStatusSnapshot $line) }
        catch { Set-StatusUnavailable ('Status data could not be read: ' + $_.Exception.Message) }
        $line = $null
    }
    $errorLine = $null
    while ($statusState.Errors.TryDequeue([ref]$errorLine)) {
        if ($errorLine -match '^status: collect failed:') { Set-StatusUnavailable $errorLine }
        $line = $errorLine
        $errorLine = $null
    }
    try {
        if ($statusState.Process.HasExited) {
            $exitCode = $statusState.Process.ExitCode
            if ($exitCode -ne 0) { Set-StatusUnavailable ('Status collector stopped (exit {0}): {1}' -f $exitCode,$line) }
            elseif (-not $line) { Set-StatusUnavailable 'Status collector stopped before returning metrics.' }
            $statusState.Process.Dispose(); $statusState.Process = $null
        }
    } catch { Set-StatusUnavailable ('Status collector failed: ' + $_.Exception.Message) }
}

$analyzeState = @{ Process = $null; Queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); Errors = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); OutputTask = $null; ErrorTask = $null; Items = @(); LargeFiles = @(); History = [System.Collections.Generic.List[string]]::new(); ResultReceived = $false; CancelRequested = $false; CancelStarted = $null }
function Format-AnalyzeItem($Item) {
    $kind = if ($Item.is_dir) { 'Folder' } else { 'File' }
    $sizeDisplay = if ([long]$Item.size -lt 0) { 'Scanning…' } else { Format-Bytes ([uint64]$Item.size) }
    [pscustomobject]@{ Name=[string]$Item.name; Path=[string]$Item.path; Kind=$kind; IsDir=[bool]$Item.is_dir; Size=[long]$Item.size; SizeDisplay=$sizeDisplay; State=[string]$Item.state }
}
function Update-AnalyzeFilter {
    $query = [string]$window.FindName('AnalyzeSearch').Text
    $visible = if ([string]::IsNullOrWhiteSpace($query)) { @($analyzeState.Items) } else { @($analyzeState.Items | Where-Object { $_.Name.IndexOf($query,[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Path.IndexOf($query,[StringComparison]::OrdinalIgnoreCase) -ge 0 }) }
    $window.FindName('AnalyzeEntriesGrid').ItemsSource = $visible
}
function Update-AnalyzeTreemap($Items) {
    $grid = $window.FindName('AnalyzeTreemap')
    $empty = $window.FindName('AnalyzeTreemapEmpty')
    $grid.ColumnDefinitions.Clear(); $grid.Children.Clear()
    $measured = @($Items | Where-Object { $_.Size -gt 0 })
    if (-not $measured.Count) {
        $empty.Text = if (@($Items).Count) { 'No complete size measurements are available for this view.' } else { 'No items were found in this folder.' }
        $empty.Visibility = [Windows.Visibility]::Visible
        $grid.Children.Add($empty) | Out-Null
        return
    }
    $empty.Visibility = [Windows.Visibility]::Collapsed
    $maximum = ($measured | Measure-Object -Property Size -Maximum).Maximum
    for ($index = 0; $index -lt $measured.Count; $index++) {
        $item = $measured[$index]
        $weight = [double]$item.Size / [double]$maximum
        $column = New-Object Windows.Controls.ColumnDefinition
        $column.Width = [Windows.GridLength]::new($weight,[Windows.GridUnitType]::Star)
        $grid.ColumnDefinitions.Add($column)
        $tile = New-Object Windows.Controls.Border
        $tile.Margin = '2'; $tile.Padding = '7'; $tile.CornerRadius = '7'
        $tile.Background = if ($item.IsDir) { '#28324C' } else { '#A96C48' }
        $tile.ToolTip = ("{0} · {1}`n{2}`n{3}" -f $item.Kind,$item.SizeDisplay,$item.Name,$item.Path)
        $label = New-Object Windows.Controls.TextBlock
        $label.Text = $item.Name; $label.TextTrimming = [Windows.TextTrimming]::CharacterEllipsis
        $label.TextWrapping = [Windows.TextWrapping]::Wrap; $label.VerticalAlignment = 'Center'
        $label.Foreground = '#080D1B'; $label.FontSize = 11; $label.FontWeight = 'SemiBold'
        $tile.Child = $label
        [Windows.Controls.Grid]::SetColumn($tile,$index)
        $grid.Children.Add($tile) | Out-Null
    }
}
function Finish-AnalyzeScan([string]$State, [string]$Message) {
    $analyzeTimer.Stop()
    if ($analyzeState.Process) {
        try { if (-not $analyzeState.Process.HasExited) { $analyzeState.Process.Kill(); $analyzeState.Process.WaitForExit(1500) } } catch {}
        try { $analyzeState.Process.Dispose() } catch {}; $analyzeState.Process = $null
    }
    $window.FindName('AnalyzeScanButton').IsEnabled = $true
    $window.FindName('AnalyzeCancelButton').IsEnabled = $false
    $window.FindName('AnalyzeBackButton').IsEnabled = ($analyzeState.History.Count -gt 0)
    $window.FindName('AnalyzeStatus').Text = $Message
    $window.FindName('AnalyzeStatus').Foreground = if ($State -eq 'error') { $window.FindResource('Error') } elseif ($State -eq 'partial') { $window.FindResource('Warning') } else { $window.FindResource('TextSecondary') }
    if (-not $analyzeState.ResultReceived) { Update-AnalyzeTreemap @() ; $window.FindName('AnalyzeTreemapEmpty').Text = $Message }
}
function Start-AnalyzeScan([string]$Target, [switch]$KeepHistory) {
    $binary = Get-MoleBackendPath 'analyze'
    if (-not $binary) { Finish-AnalyzeScan 'error' 'Analyze backend is missing. Build it with .\scripts\build.ps1 (Go 1.24.6 required), or use the bundled Mole binaries.'; return }
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) { Finish-AnalyzeScan 'error' 'Choose an existing drive or folder.'; return }
    if ($analyzeState.Process) { Finish-AnalyzeScan 'error' 'An Analyze scan is already running.'; return }
    if (-not $KeepHistory) { $analyzeState.History.Clear() }
    $analyzeState.Items = @(); $analyzeState.LargeFiles = @(); $analyzeState.ResultReceived = $false; $analyzeState.CancelRequested = $false; $analyzeState.CancelStarted = $null; $analyzeState.FinalState = $null; $analyzeState.FinalMessage = $null
    $window.FindName('AnalyzeEntriesGrid').ItemsSource = $null; $window.FindName('AnalyzeLargeFilesGrid').ItemsSource = $null; Update-AnalyzeTreemap @(); $window.FindName('AnalyzeTreemapEmpty').Text = 'Scanning measured folder sizes…'
    try {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $process.StartInfo.FileName = $binary
        $process.StartInfo.Arguments = '--gui-json'
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.RedirectStandardInput = $true
        $process.StartInfo.EnvironmentVariables['MO_ANALYZE_PATH'] = [IO.Path]::GetFullPath($Target)
        if (-not $process.Start()) { throw 'Could not start analyze.exe.' }
        $analyzeState.Process = $process
        Start-MoleProcessReads $process $analyzeState
        $window.FindName('AnalyzePathBox').Text = [IO.Path]::GetFullPath($Target)
        $window.FindName('AnalyzeScanButton').IsEnabled = $false
        $window.FindName('AnalyzeCancelButton').IsEnabled = $true
        $window.FindName('AnalyzeBackButton').IsEnabled = $false
        $window.FindName('AnalyzeStatus').Text = 'Scanning…'
        $window.FindName('AnalyzeStatus').Foreground = $window.FindResource('Cyan')
        $analyzeTimer.Start()
    } catch { Finish-AnalyzeScan 'error' ('Could not start Analyze backend: ' + $_.Exception.Message) }
}
function Poll-AnalyzeScan {
    if (-not $analyzeState.Process) { return }
    if ($analyzeState.CancelRequested -and (Get-Date).ToUniversalTime() -gt $analyzeState.CancelStarted.AddSeconds(4)) { try { if (-not $analyzeState.Process.HasExited) { $analyzeState.Process.Kill() } } catch {} }
    try { if ($analyzeState.Process.HasExited) { $analyzeState.Process.WaitForExit() } } catch {}
    Receive-MoleProcessLines $analyzeState
    $line = $null
    while ($analyzeState.Queue.TryDequeue([ref]$line)) {
        try {
            $eventData = ConvertFrom-MoleAnalyzeEvent $line
            if ($eventData.type -eq 'progress') {
                $window.FindName('AnalyzeStatus').Text = 'Scanning {0:N0} files · {1:N0} folders · {2} · {3}' -f [long]$eventData.files_scanned,[long]$eventData.dirs_scanned,(Format-Bytes ([uint64][Math]::Max(0,[long]$eventData.bytes_scanned))),[string]$eventData.current_path
            } elseif ($eventData.type -eq 'result') {
                $analyzeState.Items = @($eventData.entries | ForEach-Object { Format-AnalyzeItem $_ })
                $analyzeState.LargeFiles = @($eventData.large_files | ForEach-Object { Format-AnalyzeItem $_ })
                Update-AnalyzeFilter
                Update-AnalyzeTreemap $analyzeState.Items
                $window.FindName('AnalyzeLargeFilesGrid').ItemsSource = $analyzeState.LargeFiles
                $analyzeState.ResultReceived = $true
                $state = [string]$eventData.state
                if ($analyzeState.Items.Count -eq 0 -and $analyzeState.LargeFiles.Count -eq 0) { $analyzeState.FinalState = 'empty'; $analyzeState.FinalMessage = 'Scan complete. This folder contains no items.' }
                elseif ($state -eq 'partial') { $analyzeState.FinalState = 'partial'; $analyzeState.FinalMessage = 'Partial scan: {0} entries shown; some paths were inaccessible or changed.' -f $analyzeState.Items.Count }
                else { $analyzeState.FinalState = 'success'; $analyzeState.FinalMessage = 'Scan complete · {0} entries · {1} files · {2} measured' -f $analyzeState.Items.Count,[long]$eventData.total_files,(Format-Bytes ([uint64][Math]::Max([long]0,[long]$eventData.total_size))) }
            }
        } catch { Finish-AnalyzeScan 'error' ('Analyze data error: ' + $_.Exception.Message); return }
        $line = $null
    }
    $errorLine = $null; $errorText = $null
    while ($analyzeState.Errors.TryDequeue([ref]$errorLine)) { if ($errorLine) { $errorText = $errorLine }; $errorLine = $null }
    try {
        if ($analyzeState.Process.HasExited) {
            $analyzeState.Process.WaitForExit()
            $exitCode = $analyzeState.Process.ExitCode
            if ($analyzeState.CancelRequested) { Finish-AnalyzeScan 'cancelled' 'Scan cancelled. No files were changed.' }
            elseif (-not $analyzeState.ResultReceived -or $exitCode -ne 0) { if (-not $errorText) { $errorText = 'Analyze backend exited without a result.' }; Finish-AnalyzeScan 'error' ('Scan failed: ' + $errorText) }
            else { Finish-AnalyzeScan $analyzeState.FinalState $analyzeState.FinalMessage }
        }
    } catch { Finish-AnalyzeScan 'error' ('Analyze process failed: ' + $_.Exception.Message) }
}

$cleanState = @{
    Runspace = $null; Worker = $null; Async = $null; Cancellation = $null
    Operation = $null; PlanId = $null; Items = $null; CloseWhenIdle = $false
}
$cleanControls = @{}
foreach ($name in 'CleanScanButton','CleanStatus','CleanItemsGrid','CleanGroupPicker','CleanSelectGroup','CleanClearGroup','CleanSelectedSummary','CleanExecuteButton','CleanResults') {
    $cleanControls[$name] = $window.FindName($name)
}
function Ensure-CleanRunspace($State) {
    if ($State.Runspace) { return }
    $runspace = [RunspaceFactory]::CreateRunspace()
    $bootstrap = [PowerShell]::Create()
    try {
        $runspace.Open()
        $bootstrap.Runspace = $runspace
        $backendPath = (Join-Path $PSScriptRoot 'lib\clean\plan.ps1').Replace("'", "''")
        $null = $bootstrap.AddScript("`$ErrorActionPreference='Stop'; . '$backendPath'")
        $null = $bootstrap.Invoke()
        if ($bootstrap.Streams.Error.Count) { throw $bootstrap.Streams.Error[0].ToString() }
        $State.Runspace = $runspace
    } catch {
        $runspace.Close(); $runspace.Dispose()
        throw
    } finally { $bootstrap.Dispose() }
}
function Start-CleanTask($State, [string]$Mode, [string]$PlanId, [string[]]$ItemIds) {
    Ensure-CleanRunspace $State
    $State.Worker = [PowerShell]::Create()
    $State.Worker.Runspace = $State.Runspace
    if ($Mode -eq 'Scan') {
        $null = $State.Worker.AddScript('$ErrorActionPreference="Stop"; New-MoleCleanPlan -CancellationToken $args[0]').AddArgument($State.Cancellation.Token)
    } else {
        $null = $State.Worker.AddScript('$ErrorActionPreference="Stop"; Invoke-MoleCleanPlan -PlanId $args[0] -ItemIds ([string[]]$args[1])').AddArgument($PlanId).AddArgument([string[]]$ItemIds)
    }
    $State.Async = $State.Worker.BeginInvoke()
}
function Update-CleanSelection($State) {
    $selection = Get-CleanSelection $State.Items
    $cleanControls.CleanSelectedSummary.Text = '{0} selected · estimate {1}' -f $selection.Count,(Format-CleanBytes $selection.Bytes)
    $cleanControls.CleanExecuteButton.IsEnabled = ($selection.Count -gt 0 -and $State.Operation -eq $null -and $State.PlanId)
}
function Finish-CleanTask($State) {
    $cleanTimer.Stop()
    $mode = $State.Operation
    $output = @()
    $failure = $null
    try {
        $output = @($State.Worker.EndInvoke($State.Async))
        if ($State.Worker.Streams.Error.Count) { throw $State.Worker.Streams.Error[0].ToString() }
    } catch { $failure = $_.Exception.Message }
    finally {
        $State.Worker.Dispose(); $State.Worker = $null; $State.Async = $null
        $State.Operation = $null
    }
    if ($mode -eq 'Scan') {
        $cleanControls.CleanScanButton.Content = 'Scan'
        $cleanControls.CleanScanButton.IsEnabled = $true
        if ($State.Cancellation.IsCancellationRequested) {
            $cleanControls.CleanStatus.Text = 'Scan cancelled. Nothing was removed.'
            $cleanControls.CleanStatus.Foreground = $window.FindResource('Warning')
            $window.FindName('CleanHeroSize').Text = 'Scan cancelled'
            $window.FindName('CleanPlanSummary').Text = 'Run a new scan to review cleanup candidates.'
        } elseif ($failure) {
            $cleanControls.CleanStatus.Text = 'Scan failed: ' + $failure
            $cleanControls.CleanStatus.Foreground = $window.FindResource('Error')
            $window.FindName('CleanHeroSize').Text = 'Unavailable'
            $window.FindName('CleanPlanSummary').Text = 'No cleanup plan was created.'
        } elseif ($output.Count -eq 0) {
            $cleanControls.CleanStatus.Text = 'Scan returned no plan. Scan again.'
            $cleanControls.CleanStatus.Foreground = $window.FindResource('Error')
            $window.FindName('CleanHeroSize').Text = 'Unavailable'
            $window.FindName('CleanPlanSummary').Text = 'No cleanup plan was returned.'
        } else {
            $plan = $output[0]
            $State.PlanId = $plan.PlanId
            $State.Items = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
            foreach ($item in $plan.Items) {
                $State.Items.Add([pscustomobject]@{
                    Selected = $false; Id = $item.Id; Group = $item.Group; Path = $item.Path
                    Reason = $item.Reason; EstimatedBytes = [long]$item.EstimatedBytes
                    EstimatedDisplay = Format-CleanBytes ([long]$item.EstimatedBytes)
                })
            }
            $cleanControls.CleanItemsGrid.ItemsSource = $State.Items
            $groups = @($plan.Items | ForEach-Object Group | Sort-Object -Unique)
            $window.FindName('CleanHeroSize').Text = Format-CleanBytes ([long]$plan.EstimatedBytes)
            $window.FindName('CleanPlanSummary').Text = '{0} items across {1} groups · estimated recoverable space' -f $State.Items.Count,$groups.Count
            $cleanControls.CleanGroupPicker.ItemsSource = $groups
            if ($groups.Count) { $cleanControls.CleanGroupPicker.SelectedIndex = 0 }
            $cleanControls.CleanResults.Visibility = [Windows.Visibility]::Collapsed
            $cleanControls.CleanResults.Items.Clear()
            if ($State.Items.Count) {
                $cleanControls.CleanStatus.Text = 'Found {0} eligible files · estimated total {1} · none selected by default. {2} candidate(s) were skipped as unsafe or unverifiable.' -f $State.Items.Count,(Format-CleanBytes ([long]$plan.EstimatedBytes)),$plan.SkippedCount
                $cleanControls.CleanStatus.Foreground = $window.FindResource('Success')
            } else {
                $cleanControls.CleanStatus.Text = 'No eligible files found. Nothing was removed.'
                $cleanControls.CleanStatus.Foreground = $window.FindResource('TextSecondary')
            }
            Update-CleanSelection $State
        }
        $State.Cancellation.Dispose(); $State.Cancellation = $null
    } else {
        $State.PlanId = $null
        foreach ($item in $State.Items) { $item.Selected = $false }
        $cleanControls.CleanItemsGrid.Items.Refresh()
        $cleanControls.CleanScanButton.IsEnabled = $true
        $cleanControls.CleanExecuteButton.IsEnabled = $false
        $cleanControls.CleanItemsGrid.IsReadOnly = $true
        $cleanControls.CleanGroupPicker.IsEnabled = $false
        $cleanControls.CleanSelectGroup.IsEnabled = $false
        $cleanControls.CleanClearGroup.IsEnabled = $false
        Update-CleanSelection $State
        $cleanControls.CleanResults.Items.Clear()
        $cleanControls.CleanResults.Visibility = [Windows.Visibility]::Visible
        if ($failure -or $output.Count -eq 0) {
            $cleanControls.CleanStatus.Text = 'Plan invalid or execution failed. Scan again. ' + $failure
            $cleanControls.CleanStatus.Foreground = $window.FindResource('Error')
            $cleanControls.CleanResults.Items.Add('No success was reported. ' + $failure) | Out-Null
        } else {
            $result = $output[0]
            foreach ($item in $result.Results) {
                if ($item.Success) {
                    $line = 'Removed · {0} · file size {1}' -f $item.Path,(Format-CleanBytes ([long]$item.BytesRemoved))
                } else { $line = 'Failed · {0} · {1}' -f $item.Path,$item.Error }
                $cleanControls.CleanResults.Items.Add($line) | Out-Null
            }
            $cleanControls.CleanStatus.Text = 'Finished: {0} removed, {1} failed · successful file size {2}. Observed drive-space changes are separate and may include other system activity. Scan again before another operation.' -f $result.SucceededCount,$result.FailedCount,(Format-CleanBytes ([long]$result.LogicalBytesRemoved))
            $cleanControls.CleanStatus.Foreground = if ($result.FailedCount) { $window.FindResource('Warning') } else { $window.FindResource('Success') }
            foreach ($drive in $result.ObservedDriveSpace) {
                if ($null -ne $drive.DeltaBytes) { $cleanControls.CleanResults.Items.Add(('Observed free-space change · {0} · {1}' -f $drive.Drive,(Format-CleanBytes ([long]$drive.DeltaBytes)))) | Out-Null }
            }
        }
    }
    if ($State.CloseWhenIdle) { $window.Close() }
}

$cleanTimer = New-Object Windows.Threading.DispatcherTimer
$cleanTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$cleanTimer.Add_Tick({ if ($cleanState.Async -and $cleanState.Async.IsCompleted) { Finish-CleanTask $cleanState } })
$cleanControls.CleanScanButton.Add_Click({
    if ($cleanState.Operation -eq 'Scan') {
        $cleanState.Cancellation.Cancel()
        $cleanControls.CleanScanButton.IsEnabled = $false
        $cleanControls.CleanStatus.Text = 'Cancelling scan…'
        return
    }
    if ($cleanState.Operation) { return }
    $cleanState.PlanId = $null
    $cleanState.Items = @()
    Update-CleanSelection $cleanState
    $cleanControls.CleanItemsGrid.ItemsSource = $null
    $cleanControls.CleanGroupPicker.ItemsSource = $null
    $cleanControls.CleanGroupPicker.IsEnabled = $true
    $cleanControls.CleanItemsGrid.IsReadOnly = $false
    $cleanControls.CleanSelectGroup.IsEnabled = $true
    $cleanControls.CleanClearGroup.IsEnabled = $true
    $cleanControls.CleanExecuteButton.IsEnabled = $false
    $cleanControls.CleanResults.Visibility = [Windows.Visibility]::Collapsed
    $cleanControls.CleanResults.Items.Clear()
    $cleanState.Cancellation = New-Object System.Threading.CancellationTokenSource
    $cleanState.Operation = 'Scan'
    $cleanControls.CleanScanButton.Content = 'Cancel scan'
    $cleanControls.CleanStatus.Text = 'Scanning eligible cache files…'
    $window.FindName('CleanHeroSize').Text = 'Scanning…'
    $window.FindName('CleanPlanSummary').Text = 'Checking safe cleanup candidates. No files are changed during scan.'
    $cleanControls.CleanStatus.Foreground = $window.FindResource('Cyan')
    try { Start-CleanTask $cleanState 'Scan' $null @(); $cleanTimer.Start() }
    catch { $cleanState.Operation = $null; $cleanControls.CleanScanButton.Content = 'Scan'; $cleanControls.CleanStatus.Text = 'Could not start scan: ' + $_.Exception.Message; $cleanControls.CleanStatus.Foreground = $window.FindResource('Error'); $window.FindName('CleanHeroSize').Text = 'Unavailable'; $window.FindName('CleanPlanSummary').Text = 'No cleanup plan was created.' }
})
$cleanControls.CleanSelectGroup.Add_Click({
    if (-not $cleanState.PlanId) { return }
    $group = [string]$cleanControls.CleanGroupPicker.SelectedItem
    foreach ($item in $cleanState.Items) { if ($item.Group -eq $group) { $item.Selected = $true } }
    $cleanControls.CleanItemsGrid.Items.Refresh(); Update-CleanSelection $cleanState
})
$cleanControls.CleanClearGroup.Add_Click({
    if (-not $cleanState.PlanId) { return }
    $group = [string]$cleanControls.CleanGroupPicker.SelectedItem
    foreach ($item in $cleanState.Items) { if ($item.Group -eq $group) { $item.Selected = $false } }
    $cleanControls.CleanItemsGrid.Items.Refresh(); Update-CleanSelection $cleanState
})
$cleanControls.CleanItemsGrid.Add_CellEditEnding({
    $null = $window.Dispatcher.BeginInvoke([Action]{ Update-CleanSelection $cleanState })
})
$cleanControls.CleanExecuteButton.Add_Click({
    if (-not $cleanState.PlanId -or $cleanState.Operation) { return }
    $selection = Get-CleanSelection $cleanState.Items
    if (-not $selection.Count) { return }
    $message = "Remove $($selection.Count) selected cleanup file(s)?`n`nEstimated file size: $(Format-CleanBytes $selection.Bytes)`nScope: selected files shown in this scan only.`n`nThis action is permanent. Changed, protected, linked, or unverifiable files will be refused."
    $answer = [Windows.MessageBox]::Show($window, $message, 'Confirm Clean Preview', [Windows.MessageBoxButton]::YesNo, [Windows.MessageBoxImage]::Warning)
    if (-not (Test-CleanConfirmationResult $answer)) { return }
    $ids = $selection.Ids
    $cleanState.Operation = 'Execute'
    $cleanControls.CleanScanButton.IsEnabled = $false
    $cleanControls.CleanExecuteButton.IsEnabled = $false
    $cleanControls.CleanStatus.Text = 'Rechecking selected files against the scan snapshot…'
    $cleanControls.CleanStatus.Foreground = $window.FindResource('Cyan')
    try { Start-CleanTask $cleanState 'Execute' $cleanState.PlanId $ids; $cleanTimer.Start() }
    catch { $cleanState.Operation = $null; $cleanState.PlanId = $null; $cleanControls.CleanScanButton.IsEnabled = $true; $cleanControls.CleanExecuteButton.IsEnabled = $false; $cleanControls.CleanStatus.Text = 'Execution could not start. Scan again: ' + $_.Exception.Message; $cleanControls.CleanStatus.Foreground = $window.FindResource('Error') }
})
$window.Add_Closing({ param($sender,$eventArgs)
    if ($cleanState.Operation -eq 'Scan') { $cleanState.CloseWhenIdle = $true; $cleanState.Cancellation.Cancel(); $eventArgs.Cancel = $true }
    elseif ($cleanState.Operation -eq 'Execute') { $cleanState.CloseWhenIdle = $true; $eventArgs.Cancel = $true }
})
$window.Add_Closed({
    $cleanTimer.Stop()
    if ($cleanState.Runspace) { $cleanState.Runspace.Close(); $cleanState.Runspace.Dispose() }
})

$appsState = @{ Process=$null; Queue=[System.Collections.Concurrent.ConcurrentQueue[string]]::new(); Errors=[System.Collections.Concurrent.ConcurrentQueue[string]]::new(); OutputTask=$null; ErrorTask=$null; Operation=$null; Items=@(); Loaded=$false }
$optimizeState = @{ Process=$null; Queue=[System.Collections.Concurrent.ConcurrentQueue[string]]::new(); Errors=[System.Collections.Concurrent.ConcurrentQueue[string]]::new(); OutputTask=$null; ErrorTask=$null; Operation=$null; Items=@(); Loaded=$false; TaskIds=@(); Index=0; Results=@() }
function Start-MoleScriptBackend($State, [string]$ScriptName, [string]$Arguments, $InputObject) {
    $scriptPath = Join-Path $PSScriptRoot "bin\$ScriptName"
    $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "Backend script is missing: $ScriptName" }
    if (-not (Test-Path -LiteralPath $powershellPath -PathType Leaf)) { throw 'Windows PowerShell 5.1 is not available.' }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $powershellPath
    $process.StartInfo.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" {1}' -f $scriptPath,$Arguments
    $process.StartInfo.UseShellExecute = $false; $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true; $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardInput = ($null -ne $InputObject)
    if (-not $process.Start()) { throw "Could not start $ScriptName." }
    $State.Process = $process
    $State.Queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $State.Errors = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    Start-MoleProcessReads $process $State
    if ($null -ne $InputObject) {
        try {
            $process.StandardInput.WriteLine(($InputObject | ConvertTo-Json -Depth 5 -Compress))
            $process.StandardInput.Close()
        } catch {
            try { Stop-MoleChildProcess $process | Out-Null } catch {}
            $State.Process = $null
            throw
        }
    }
}
function Update-AppsSelection {
    $items = @($appsState.Items | Where-Object Selected)
    $window.FindName('AppsSelectedSummary').Text = '{0} selected' -f $items.Count
    $window.FindName('AppsUninstallButton').IsEnabled = ($items.Count -gt 0 -and -not $appsState.Process)
}
function Start-AppsRequest([string]$Action, [string[]]$Ids) {
    if ($appsState.Process) { return }
    $appsState.Items = @(); $window.FindName('AppsGrid').ItemsSource = $null
    $window.FindName('AppsUninstallButton').IsEnabled = $false
    $window.FindName('AppsScanButton').IsEnabled = $false
    $window.FindName('AppsStatus').Text = if ($Action -eq 'inventory') { 'Scanning installed applications…' } else { 'Rechecking selected apps and running their registered uninstallers…' }
    $window.FindName('AppsStatus').Foreground = $window.FindResource('Cyan')
    $appsState.Operation = $Action
    try {
        Start-MoleScriptBackend $appsState 'uninstall.ps1' '-GuiJson' @{ action=$Action; ids=@($Ids) }
        $appsTimer.Start()
    } catch {
        $appsState.Operation = $null; $window.FindName('AppsScanButton').IsEnabled = $true
        $window.FindName('AppsStatus').Text = 'Apps backend unavailable: ' + $_.Exception.Message
        $window.FindName('AppsStatus').Foreground = $window.FindResource('Error')
    }
}
function Update-AppsFilter {
    $search = [string]$window.FindName('AppsSearch').Text
    $visible = if ([string]::IsNullOrWhiteSpace($search)) { @($appsState.Items) } else { @($appsState.Items | Where-Object { $_.Name.IndexOf($search,[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Publisher.IndexOf($search,[StringComparison]::OrdinalIgnoreCase) -ge 0 }) }
    $window.FindName('AppsGrid').ItemsSource = $visible
}
function Poll-AppsBackend {
    if (-not $appsState.Process) { return }
    Receive-MoleProcessLines $appsState
    if (-not $appsState.Process.HasExited) { return }
    $appsState.Process.WaitForExit()
    $exitCode = $appsState.Process.ExitCode
    $appsState.Process.Dispose(); $appsState.Process = $null
    $line = $null; $responseLine = $null
    while ($appsState.Queue.TryDequeue([ref]$line)) { if ($line) { $responseLine = $line }; $line = $null }
    $errorLine = $null; $errorText = $null
    while ($appsState.Errors.TryDequeue([ref]$errorLine)) { if ($errorLine) { $errorText = $errorLine }; $errorLine = $null }
    $response = $null
    try {
        if (-not $responseLine) { throw $(if ($errorText) { $errorText } else { "Apps backend exited with code $exitCode without a response." }) }
        $response = $responseLine | ConvertFrom-Json -ErrorAction Stop
        if ($response.State -eq 'error') { throw $response.Error }
        if ($exitCode -ne 0) { throw $(if ($errorText) { $errorText } else { "Apps backend exited with code $exitCode." }) }
        if ($appsState.Operation -eq 'inventory') {
            $appsState.Items = @($response.Items | ForEach-Object { $_ | Add-Member -NotePropertyName Selected -NotePropertyValue $false -Force -PassThru })
            $appsState.Loaded = $true
            Update-AppsFilter
            $window.FindName('AppsStatus').Text = if ($appsState.Items.Count) { '{0} installed applications · sizes may be unverified where Windows denied access.' -f $appsState.Items.Count } else { 'No applications are available in the current inventory.' }
            $window.FindName('AppsStatus').Foreground = $window.FindResource('TextSecondary')
        } else {
            $results = @($response.Results)
            $window.FindName('AppsResults').Items.Clear()
            foreach ($result in $results) {
                $window.FindName('AppsResults').Items.Add(('{0} · {1} · {2}' -f $result.Name,$result.State,$result.Details)) | Out-Null
            }
            $window.FindName('AppsResults').Visibility = [Windows.Visibility]::Visible
            $success = @($results | Where-Object State -eq 'success').Count
            $failed = $results.Count - $success
            $window.FindName('AppsStatus').Text = 'Uninstall result: {0} removed, {1} failed. Refreshing inventory…' -f $success,$failed
            $window.FindName('AppsStatus').Foreground = if ($failed) { $window.FindResource('Warning') } else { $window.FindResource('Success') }
        }
    } catch {
        $window.FindName('AppsStatus').Text = 'Apps request failed: ' + $_.Exception.Message
        $window.FindName('AppsStatus').Foreground = $window.FindResource('Error')
    } finally {
        $appsState.Operation = $null
        $window.FindName('AppsScanButton').IsEnabled = $true
        Update-AppsSelection
    }
    if ($response -and $response.State -eq 'complete') { Start-AppsRequest 'inventory' @() }
}
function Update-OptimizeSelection {
    $items = @($optimizeState.Items | Where-Object Selected)
    $window.FindName('OptimizeSelectedSummary').Text = '{0} selected' -f $items.Count
    $window.FindName('OptimizeRunButton').IsEnabled = ($items.Count -gt 0 -and -not $optimizeState.Process -and $optimizeState.Operation -ne 'Run')
}
function Start-OptimizeCatalog {
    if ($optimizeState.Process) { return }
    $optimizeState.Operation = 'Catalog'; $optimizeState.Items = @(); $window.FindName('OptimizeGrid').ItemsSource = $null
    $window.FindName('OptimizeStatus').Text = 'Loading backend task list…'
    try { Start-MoleScriptBackend $optimizeState 'optimize.ps1' '-GuiCatalog' $null; $optimizeTimer.Start() }
    catch { $optimizeState.Operation = $null; $window.FindName('OptimizeStatus').Text = 'Optimize backend unavailable: ' + $_.Exception.Message; $window.FindName('OptimizeStatus').Foreground = $window.FindResource('Error') }
}
function Start-NextOptimizeTask {
    if ($optimizeState.Index -ge $optimizeState.TaskIds.Count) {
        $success = @($optimizeState.Results | Where-Object State -eq 'success').Count
        $preview = @($optimizeState.Results | Where-Object State -eq 'preview').Count
        $failed = @($optimizeState.Results | Where-Object State -in @('error','unavailable')).Count
        $window.FindName('OptimizeStatus').Text = 'Finished: {0} completed, {1} previewed, {2} failed or unavailable. Review each result below.' -f $success,$preview,$failed
        $window.FindName('OptimizeStatus').Foreground = if ($failed -or $preview) { $window.FindResource('Warning') } else { $window.FindResource('Success') }
        $optimizeState.Operation = $null; Update-OptimizeSelection; return
    }
    $task = [string]$optimizeState.TaskIds[$optimizeState.Index]
    $entry = $optimizeState.Items | Where-Object Id -eq $task | Select-Object -First 1
    $window.FindName('OptimizeStatus').Text = 'Running: ' + $entry.Name
    try { Start-MoleScriptBackend $optimizeState 'optimize.ps1' ('-GuiTask ' + $task) $null }
    catch {
        $optimizeState.Results += [pscustomobject]@{ Id=$task; Name=$entry.Name; State='error'; Details=$_.Exception.Message }
        $window.FindName('OptimizeResults').Items.Add(('{0} · error · {1}' -f $entry.Name,$_.Exception.Message)) | Out-Null
        $window.FindName('OptimizeResults').Visibility = [Windows.Visibility]::Visible
        $optimizeState.Index++; Start-NextOptimizeTask; return
    }
    $optimizeTimer.Start()
}
function Start-OptimizeTasks {
    $null = $window.FindName('OptimizeGrid').CommitEdit([Windows.Controls.DataGridEditingUnit]::Cell,$true)
    $null = $window.FindName('OptimizeGrid').CommitEdit([Windows.Controls.DataGridEditingUnit]::Row,$true)
    $selected = @($optimizeState.Items | Where-Object Selected)
    if (-not $selected.Count -or $optimizeState.Operation -or $optimizeState.Process) { return }
    $actions = @($selected | Where-Object Kind -eq 'Action')
    if ($actions.Count) {
        $names = ($actions | ForEach-Object { '• ' + $_.Name + ' — ' + $_.Description }) -join "`n"
        $checks = @($selected | Where-Object Kind -eq 'Check')
        $checkNames = if ($checks.Count) { ($checks | ForEach-Object Name) -join ', ' } else { 'None' }
        $body = "Run these system actions?`n`n$names`n`nRead-only checks included: $checkNames`nEach task runs separately; failed tasks will be reported individually."
        if ([Windows.MessageBox]::Show($body,'Confirm Optimize actions','YesNo','Warning') -ne [Windows.MessageBoxResult]::Yes) { return }
    }
    $optimizeState.TaskIds = @($selected | ForEach-Object Id); $optimizeState.Index = 0; $optimizeState.Results = @()
    $window.FindName('OptimizeResults').Items.Clear(); $window.FindName('OptimizeResults').Visibility = [Windows.Visibility]::Visible
    $optimizeState.Operation = 'Run'; Update-OptimizeSelection; Start-NextOptimizeTask
}
function Poll-OptimizeBackend {
    if (-not $optimizeState.Process) { return }
    Receive-MoleProcessLines $optimizeState
    if (-not $optimizeState.Process.HasExited) { return }
    $optimizeState.Process.WaitForExit()
    $exitCode = $optimizeState.Process.ExitCode
    $optimizeState.Process.Dispose(); $optimizeState.Process = $null
    $line = $null; $responseLine = $null
    while ($optimizeState.Queue.TryDequeue([ref]$line)) { if ($line) { $responseLine = $line }; $line = $null }
    $errorLine = $null; $errorText = $null
    while ($optimizeState.Errors.TryDequeue([ref]$errorLine)) { if ($errorLine) { $errorText = $errorLine }; $errorLine = $null }
    try {
        if (-not $responseLine) { throw $(if ($errorText) { $errorText } else { "Optimize backend exited with code $exitCode without a response." }) }
        if ($optimizeState.Operation -eq 'Catalog') {
            $catalog = @($responseLine | ConvertFrom-Json -ErrorAction Stop)
            if ($exitCode -ne 0 -or -not $catalog.Count) { throw 'Optimize backend returned no task catalog.' }
            $optimizeState.Items = @($catalog | ForEach-Object { $_ | Add-Member -NotePropertyName Selected -NotePropertyValue $false -Force -PassThru })
            $optimizeState.Loaded = $true
            $window.FindName('OptimizeGrid').ItemsSource = $optimizeState.Items
            $window.FindName('OptimizeStatus').Text = '{0} available tasks · checks are read-only; actions need confirmation.' -f $optimizeState.Items.Count
            $window.FindName('OptimizeStatus').Foreground = $window.FindResource('TextSecondary')
            $optimizeState.Operation = $null
        } else {
            $result = $responseLine | ConvertFrom-Json -ErrorAction Stop
            if ($exitCode -ne 0 -and $result.State -ne 'error') { $result.State = 'error'; $result.Details = $errorText }
            $optimizeState.Results += $result
            $window.FindName('OptimizeResults').Items.Add(('{0} · {1} · {2}' -f $result.Name,$result.State,$result.Details)) | Out-Null
            $window.FindName('OptimizeResults').Visibility = [Windows.Visibility]::Visible
            $optimizeState.Index++
        }
    } catch {
        if ($optimizeState.Operation -eq 'Run') {
            $task = [string]$optimizeState.TaskIds[$optimizeState.Index]
            $entry = $optimizeState.Items | Where-Object Id -eq $task | Select-Object -First 1
            $result = [pscustomobject]@{ Id=$task; Name=$entry.Name; State='error'; Details=$_.Exception.Message }
            $optimizeState.Results += $result
            $window.FindName('OptimizeResults').Items.Add(('{0} · error · {1}' -f $entry.Name,$_.Exception.Message)) | Out-Null
            $optimizeState.Index++
        } else {
            $window.FindName('OptimizeStatus').Text = 'Optimize task list failed: ' + $_.Exception.Message
            $window.FindName('OptimizeStatus').Foreground = $window.FindResource('Error')
            $optimizeState.Operation = $null
        }
    }
    if ($optimizeState.Operation -eq 'Run') { Start-NextOptimizeTask } else { Update-OptimizeSelection }
}
$appsTimer = New-Object Windows.Threading.DispatcherTimer
$appsTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$appsTimer.Add_Tick({ if ($appsState.Process) { Poll-AppsBackend } else { $appsTimer.Stop() } })
$optimizeTimer = New-Object Windows.Threading.DispatcherTimer
$optimizeTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$optimizeTimer.Add_Tick({ if ($optimizeState.Process) { Poll-OptimizeBackend } elseif ($optimizeState.Operation -ne 'Run') { $optimizeTimer.Stop() } })
$statusTimer = New-Object Windows.Threading.DispatcherTimer
$statusTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$statusTimer.Add_Tick({ Poll-StatusCollector })
$analyzeTimer = New-Object Windows.Threading.DispatcherTimer
$analyzeTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$analyzeTimer.Add_Tick({ Poll-AnalyzeScan })
$window.FindName('AnalyzeDrivePicker').ItemsSource = [IO.Directory]::GetLogicalDrives()
$window.FindName('AnalyzeDrivePicker').Add_SelectionChanged({ if ($window.FindName('AnalyzeDrivePicker').SelectedItem) { $window.FindName('AnalyzePathBox').Text = [string]$window.FindName('AnalyzeDrivePicker').SelectedItem } })
$window.FindName('AnalyzeScanButton').Add_Click({ Start-AnalyzeScan ([string]$window.FindName('AnalyzePathBox').Text) })
$window.FindName('AnalyzeCancelButton').Add_Click({
    if ($analyzeState.Process) {
        $analyzeState.CancelRequested = $true
        $analyzeState.CancelStarted = [DateTime]::UtcNow
        $window.FindName('AnalyzeStatus').Text = 'Cancelling scan…'
        try { $analyzeState.Process.StandardInput.WriteLine('cancel'); $analyzeState.Process.StandardInput.Flush() } catch { try { $analyzeState.Process.Kill() } catch {} }
    }
})
$window.FindName('AnalyzeBackButton').Add_Click({
    if ($analyzeState.History.Count -gt 0) {
        $target = $analyzeState.History[$analyzeState.History.Count - 1]
        $analyzeState.History.RemoveAt($analyzeState.History.Count - 1)
        Start-AnalyzeScan $target -KeepHistory
    }
})
$window.FindName('AnalyzeBrowseButton').Add_Click({
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = [string]$window.FindName('AnalyzePathBox').Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $window.FindName('AnalyzePathBox').Text = $dialog.SelectedPath }
    $dialog.Dispose()
})
$window.FindName('AnalyzeSearch').Add_TextChanged({ Update-AnalyzeFilter })
$window.FindName('AppsScanButton').Add_Click({ Start-AppsRequest 'inventory' @() })
$window.FindName('AppsSearch').Add_TextChanged({ Update-AppsFilter })
$window.FindName('AppsGrid').Add_CellEditEnding({ $null = $window.Dispatcher.BeginInvoke([Action]{ Update-AppsSelection }) })
$window.FindName('AppsUninstallButton').Add_Click({
    $null = $window.FindName('AppsGrid').CommitEdit([Windows.Controls.DataGridEditingUnit]::Cell,$true)
    $null = $window.FindName('AppsGrid').CommitEdit([Windows.Controls.DataGridEditingUnit]::Row,$true)
    $selected = @($appsState.Items | Where-Object Selected)
    if (-not $selected.Count -or $appsState.Process) { return }
    $names = ($selected | ForEach-Object { '• ' + $_.Name }) -join "`n"
    $unchecked = @($selected | Where-Object { -not $_.SizeChecked }).Count
    $message = "Uninstall $($selected.Count) selected app(s)?`n`n$names`n`nDisplayed size: inventory estimate only; it does not predict freed disk space.`nThe registered uninstaller will run once per app. Mole will recheck each app and only recycle leftovers through its existing safety checks.`n`n$unchecked selected size value(s) are unverified."
    if ([Windows.MessageBox]::Show($message,'Review app uninstall','YesNo','Warning') -ne [Windows.MessageBoxResult]::Yes) { return }
    $window.FindName('AppsResults').Items.Clear(); $window.FindName('AppsResults').Visibility = [Windows.Visibility]::Collapsed
    Start-AppsRequest 'uninstall' ([string[]]@($selected | ForEach-Object Id))
})
$window.FindName('OptimizeGrid').Add_CellEditEnding({ $null = $window.Dispatcher.BeginInvoke([Action]{ Update-OptimizeSelection }) })
$window.FindName('OptimizeRunButton').Add_Click({ Start-OptimizeTasks })
$window.FindName('AnalyzeEntriesGrid').Add_MouseDoubleClick({
    $item = $window.FindName('AnalyzeEntriesGrid').SelectedItem
    if ($item -and $item.Kind -eq 'Folder' -and (Test-Path -LiteralPath $item.Path -PathType Container)) {
        $analyzeState.History.Add([string]$window.FindName('AnalyzePathBox').Text)
        Start-AnalyzeScan ([string]$item.Path) -KeepHistory
    }
})
$window.Add_Closing({
    if ($appsState.Operation -eq 'uninstall' -or $optimizeState.Operation -eq 'Run') {
        $eventArgs.Cancel = $true
        [Windows.MessageBox]::Show('Wait for the selected app or system task to finish before closing Moleo. Each result is checked and recorded before the window closes.','Operation in progress','OK','Information') | Out-Null
    }
})
$window.Add_Closed({
    $statusTimer.Stop(); $analyzeTimer.Stop(); $appsTimer.Stop(); $optimizeTimer.Stop()
    try { Stop-MoleChildProcess $statusState.Process } catch {}
    try { Stop-MoleChildProcess $analyzeState.Process } catch {}
    try { Stop-MoleChildProcess $appsState.Process } catch {}
    try { Stop-MoleChildProcess $optimizeState.Process } catch {}
})

if ($Validate) {
    foreach ($name in 'DashboardPage','CleanPage','CleanHeroSize','CleanPlanSummary','CleanScanButton','CleanStatus','CleanItemsGrid','CleanGroupPicker','CleanSelectGroup','CleanClearGroup','CleanSelectedSummary','CleanExecuteButton','CleanResults','AppsPage','AppsScanButton','AppsStatus','AppsSearch','AppsGrid','AppsUninstallButton','AppsSelectedSummary','AppsResults','OptimizePage','OptimizeStatus','OptimizeGrid','OptimizeRunButton','OptimizeSelectedSummary','OptimizeResults','AnalyzePage','AnalyzeScanButton','AnalyzeEntriesGrid','AnalyzeLargeFilesGrid','AnalyzeSearch','AnalyzePathBox','AnalyzeCancelButton','AnalyzeTreemap','AnalyzeTreemapEmpty','StatusPage','StatusCpu','StatusCpuBar','StatusMemory','StatusMemoryBar','StatusDisk','StatusDiskBar','StatusDiskIO','StatusNetwork','StatusProcesses','SettingsPage','RefreshButton','NavClean','NavApps','NavOptimize','NavAnalyze','NavStatus','NavSettings') {
        if ($null -eq $window.FindName($name)) { throw "GUI control is missing: $name" }
    }
    foreach ($pageName in 'Clean','Apps','Optimize','Analyze','Status','Settings') {
        $window.FindName("Nav$pageName").RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        if ($pages[$pageName].Visibility -ne [Windows.Visibility]::Visible -or $title.Text -ne $pageName) { throw "Top navigation did not activate $pageName." }
    }
    $appsState.Items = @([pscustomobject]@{ Selected=$false },[pscustomobject]@{ Selected=$true })
    Update-AppsSelection
    if ($window.FindName('AppsSelectedSummary').Text -ne '1 selected' -or -not $window.FindName('AppsUninstallButton').IsEnabled) { throw 'Apps selection did not update the selected count and action state.' }
    $optimizeState.Items = @([pscustomobject]@{ Selected=$false },[pscustomobject]@{ Selected=$true })
    Update-OptimizeSelection
    if ($window.FindName('OptimizeSelectedSummary').Text -ne '1 selected' -or -not $window.FindName('OptimizeRunButton').IsEnabled) { throw 'Optimize selection did not update the selected count and action state.' }
    $appsState.Items = @(); $optimizeState.Items = @()
    $window.FindName('QuickAnalyze').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    if ($pages.Analyze.Visibility -ne [Windows.Visibility]::Visible -or $title.Text -ne 'Analyze') { throw 'Dashboard quick access did not activate Analyze.' }
    $sample = ConvertFrom-MoleStatusSnapshot '{"collected_at":"2026-10-15T12:00:00Z","cpu":{"usage":10,"logical_cpu":8},"memory":{"used":40,"total":100,"used_percent":40},"disks":[{"mount":"C:\\","used":50,"total":100,"used_percent":50}],"disk_io":{"read_rate":0.1,"write_rate":0.2},"network":[],"network_history":{"rx_history":[0.3],"tx_history":[0.4]},"top_processes":[]}'
    if ($sample.memory.used -ne 40 -or $sample.cpu.usage -ne 10) { throw 'Status JSON parsing failed.' }
    Update-Metrics $sample
    if ($controls.StatusCpu.Text -ne '10%' -or $controls.StatusDiskIO.Text -notmatch '0[.,]10' -or $controls.StatusNetwork.Text -notmatch '0[.,]30') { throw ('Status snapshot was not applied to dashboard controls: CPU={0}; I/O={1}; network={2}; updated={3}' -f $controls.StatusCpu.Text,$controls.StatusDiskIO.Text,$controls.StatusNetwork.Text,$controls.StatusUpdated.Text) }
    Set-MetricsUnavailable 'test collector failure'
    if ($controls.StatusCpu.Text -ne 'N/A' -or $controls.CpuValue.Text -ne 'N/A') { throw 'A collector failure retained stale metric values.' }
    $badJSONRejected = $false
    try { $null = ConvertFrom-MoleStatusSnapshot '{"memory":{"total":0}}' } catch { $badJSONRejected = $true }
    if (-not $badJSONRejected) { throw 'Incomplete Status JSON was accepted.' }
    if ((ConvertFrom-MoleAnalyzeEvent '{"type":"progress","files_scanned":3}').files_scanned -ne 3 -or (ConvertFrom-MoleAnalyzeEvent '{"type":"result","state":"complete","entries":[]}').state -ne 'complete') { throw 'Analyze NDJSON parsing failed.' }
    $badAnalyzeRejected = $false
    try { $null = ConvertFrom-MoleAnalyzeEvent '{"type":"unexpected"}' } catch { $badAnalyzeRejected = $true }
    if (-not $badAnalyzeRejected) { throw 'Unknown Analyze events were accepted.' }
    $child = New-Object Diagnostics.Process
    $child.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $child.StartInfo.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $child.StartInfo.Arguments = '-NoProfile -NonInteractive -Command "[Console]::WriteLine(''stdout''); [Console]::Error.WriteLine(''stderr''); Start-Sleep -Seconds 30"'
    $child.StartInfo.UseShellExecute = $false; $child.StartInfo.CreateNoWindow = $true
    $child.StartInfo.RedirectStandardOutput = $true; $child.StartInfo.RedirectStandardError = $true
    if (-not $child.Start()) { throw 'Backend process test child did not start.' }
    $childState = @{ Process = $child; Queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); Errors = [System.Collections.Concurrent.ConcurrentQueue[string]]::new(); OutputTask = $null; ErrorTask = $null }
    Start-MoleProcessReads $child $childState
    $readDeadline = (Get-Date).AddSeconds(3)
    while (($childState.Queue.Count -eq 0 -or $childState.Errors.Count -eq 0) -and (Get-Date) -lt $readDeadline) { Receive-MoleProcessLines $childState; Start-Sleep -Milliseconds 25 }
    if ($childState.Queue.Count -ne 1 -or $childState.Errors.Count -ne 1) { Stop-MoleChildProcess $child | Out-Null; throw 'Asynchronous stdout/stderr reads did not return both child process streams.' }
    if (-not (Stop-MoleChildProcess $child)) { throw 'Backend process cleanup did not stop a running child.' }
    $statusBinaryMissing = $null -eq (Get-MoleBackendPath 'status')
    $analyzeBinaryMissing = $null -eq (Get-MoleBackendPath 'analyze')
    $statusBackendConnected = $false
    $analyzeFixtureScanned = $false
    $analyzeTreemapRendered = $false
    $analyzeTimerCallbackWorks = $false
    $optimizeBackendConnected = $false
    Start-OptimizeCatalog
    $optimizeDeadline = (Get-Date).AddSeconds(8)
    while ($optimizeState.Process -and (Get-Date) -lt $optimizeDeadline) { Poll-OptimizeBackend; Start-Sleep -Milliseconds 50 }
    $optimizeTimer.Stop()
    if ($optimizeState.Process) { Stop-MoleChildProcess $optimizeState.Process | Out-Null; $optimizeState.Process = $null; throw 'Optimize catalog backend did not finish validation.' }
    if (-not $optimizeState.Loaded -or $optimizeState.Items.Count -ne 7) { throw 'Optimize task catalog was not received from the backend.' }
    $optimizeBackendConnected = $true
    if ($statusBinaryMissing) { Start-StatusCollector; if ($controls.StatusCpu.Text -ne 'N/A') { throw 'Missing Status backend did not enter unavailable state.' } }
    else {
        Start-StatusCollector
        $statusDeadline = (Get-Date).AddSeconds(8)
        while ($statusState.Process -and $controls.StatusCpu.Text -eq 'N/A' -and (Get-Date) -lt $statusDeadline) { Poll-StatusCollector; Start-Sleep -Milliseconds 100 }
        if ($statusState.Process) { Stop-MoleChildProcess $statusState.Process | Out-Null; $statusState.Process = $null }
        if ($controls.StatusCpu.Text -eq 'N/A') { throw ('Status backend did not deliver a usable snapshot: ' + $controls.StatusUpdated.Text) }
        $statusBackendConnected = $true
    }
    if ($analyzeBinaryMissing) { Start-AnalyzeScan ([IO.Path]::GetTempPath()); if ($window.FindName('AnalyzeStatus').Text -notmatch 'backend is missing') { throw 'Missing Analyze backend did not report the build requirement.' } }
    else {
        $fixture = Join-Path ([IO.Path]::GetTempPath()) ('moleo-gui-validate-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $fixture | Out-Null
        [IO.File]::WriteAllText((Join-Path $fixture 'gui-fixture.txt'),'Moleo GUI Analyze validation')
        try {
            $analyzeFrame = New-Object Windows.Threading.DispatcherFrame
            $analyzeFrameTimer = New-Object Windows.Threading.DispatcherTimer
            $analyzeFrameTimer.Interval = [TimeSpan]::FromSeconds(8)
            $analyzeFrameTimer.Add_Tick({ $analyzeFrameTimer.Stop(); $analyzeFrame.Continue = $false })
            $analyzeTimer.Add_Tick({ if (-not $analyzeState.Process) { $analyzeFrame.Continue = $false } })
            Start-AnalyzeScan $fixture
            $analyzeFrameTimer.Start()
            [Windows.Threading.Dispatcher]::PushFrame($analyzeFrame)
            $analyzeTimer.Stop(); $analyzeFrameTimer.Stop()
            if ($analyzeState.Process) { Stop-MoleChildProcess $analyzeState.Process | Out-Null; $analyzeState.Process = $null; throw 'Analyze backend did not finish the validation fixture.' }
            if ($analyzeState.Items.Name -notcontains 'gui-fixture.txt') { throw 'Analyze GUI did not display the fixture result.' }
            if ($window.FindName('AnalyzeTreemap').Children.Count -lt 1) { throw ('Analyze size map did not render measured fixture data: ' + (($analyzeState.Items | ForEach-Object { '{0}={1}' -f $_.Name,$_.Size }) -join ', ')) }
            $analyzeTimerCallbackWorks = $true
            $analyzeTreemapRendered = $true
            $analyzeFixtureScanned = $true
        } finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $selection = Get-CleanSelection @([pscustomobject]@{ Selected = $false; Id = 'keep'; EstimatedBytes = 10L },[pscustomobject]@{ Selected = $true; Id = 'one'; EstimatedBytes = 25L },[pscustomobject]@{ Selected = $true; Id = 'two'; EstimatedBytes = 40L })
    if ($selection.Count -ne 2 -or $selection.Bytes -ne 65 -or $selection.Ids -notcontains 'one' -or $selection.Ids -contains 'keep') { throw 'Clean selection or estimate validation failed.' }
    if (Test-CleanConfirmationResult ([Windows.MessageBoxResult]::No) -or -not (Test-CleanConfirmationResult ([Windows.MessageBoxResult]::Yes))) { throw 'Clean confirmation validation failed.' }
    $windowCloseStopsBackend = $false
    if (-not $statusBinaryMissing) {
        Start-StatusCollector
        $controls.StatusUpdated.Text = 'Waiting for timer callback'
        $callbackFrame = New-Object Windows.Threading.DispatcherFrame
        $callbackTimeout = New-Object Windows.Threading.DispatcherTimer
        $callbackTimeout.Interval = [TimeSpan]::FromSeconds(2)
        $callbackTimeout.Add_Tick({ $callbackTimeout.Stop(); $callbackFrame.Continue = $false })
        $statusTimer.Start(); $callbackTimeout.Start()
        [Windows.Threading.Dispatcher]::PushFrame($callbackFrame)
        $statusTimer.Stop(); $callbackTimeout.Stop()
        if ($controls.StatusUpdated.Text -eq 'Waiting for timer callback') { throw 'Status DispatcherTimer callback did not poll the backend.' }
        $closeProbe = [Diagnostics.Process]::GetProcessById($statusState.Process.Id)
        $window.Close()
        if (-not $closeProbe.WaitForExit(2000)) { $closeProbe.Dispose(); throw 'Closing the GUI did not stop the Status backend.' }
        $closeProbe.Dispose(); $windowCloseStopsBackend = $true
    }
    [pscustomobject]@{ XamlLoaded = $true; NavigationWorks = $true; CleanSelectionWorks = $true; CleanConfirmationRequired = $true; CleanHandlersReady = $true; AppsControlsReady = $true; AppsSelectionWorks = $true; OptimizeControlsReady = $true; OptimizeSelectionWorks = $true; OptimizeBackendConnected = $optimizeBackendConnected; StatusJsonParsing = $true; StatusUnavailableHandling = $true; StatusTimerCallbackWorks = -not $statusBinaryMissing; AnalyzeJsonParsing = $true; AnalyzeTimerCallbackWorks = $analyzeTimerCallbackWorks; BackendProcessStops = $true; WindowCloseStopsBackend = $windowCloseStopsBackend; StatusBackendMissingHandled = $statusBinaryMissing; AnalyzeBackendMissingHandled = $analyzeBinaryMissing; StatusBackendAvailable = -not $statusBinaryMissing; AnalyzeBackendAvailable = -not $analyzeBinaryMissing; StatusBackendConnected = $statusBackendConnected; AnalyzeFixtureScanned = $analyzeFixtureScanned; AnalyzeTreemapRendered = $analyzeTreemapRendered; AnalyzeControlsReady = $true } | ConvertTo-Json -Compress
    return
}

$version = 'unknown'
$versionPath = Join-Path $PSScriptRoot 'VERSION'
if (Test-Path -LiteralPath $versionPath) { $version = (Get-Content -LiteralPath $versionPath -Raw).Trim() }
$window.FindName('VersionLabel').Text = "Moleo · version $version"
$window.FindName('Greeting').Text = if ((Get-Date).Hour -lt 12) { 'Good morning.' } elseif ((Get-Date).Hour -lt 18) { 'Good afternoon.' } else { 'Good evening.' }
$window.FindName('RefreshButton').Add_Click({
    if ($statusState.Process) { $controls.StatusUpdated.Text = 'Mole Status collector refreshes every 2 seconds.' }
    else { Start-StatusCollector }
})
Start-StatusCollector
$statusTimer.Start()
Show-Page 'Clean'
$null = $window.ShowDialog()

