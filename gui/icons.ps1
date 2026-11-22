# Prints {"lowercase app name": "base64 PNG"} for installed apps.
# Read-only: icons come from DisplayIcon, the install folder's main exe,
# or a Store package's logo.
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class MoleoIcon {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern uint ExtractIconEx(string file, int index, IntPtr[] large, IntPtr[] small, uint n);
    [DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);
}
'@

$out = @{}
function ConvertTo-Png64([System.Drawing.Image]$img) {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.DrawImage($img, 0, 0, 32, 32)
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    [Convert]::ToBase64String($ms.ToArray())
}

function Get-FileIcon64([string]$spec) {
    if (-not $spec) { return $null }
    $spec = [Environment]::ExpandEnvironmentVariables($spec.Trim().Trim('"'))
    $index = 0
    if ($spec -match '^(.*?),\s*(-?\d+)$') { $spec = $Matches[1].Trim('"'); $index = [int]$Matches[2] }
    if (-not (Test-Path -LiteralPath $spec -PathType Leaf)) { return $null }
    if ($spec -match '\.(png|jpg|bmp)$') {
        $img = [System.Drawing.Image]::FromFile($spec); $r = ConvertTo-Png64 $img; $img.Dispose(); return $r
    }
    $large = New-Object IntPtr[] 1
    if ([MoleoIcon]::ExtractIconEx($spec, $index, $large, $null, 1) -gt 0 -and $large[0] -ne [IntPtr]::Zero) {
        $icon = [System.Drawing.Icon]::FromHandle($large[0])
        $r = ConvertTo-Png64 $icon.ToBitmap()
        [void][MoleoIcon]::DestroyIcon($large[0])
        return $r
    }
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($spec)
    if ($icon) { return ConvertTo-Png64 $icon.ToBitmap() }
    return $null
}

$keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
foreach ($e in (Get-ItemProperty $keys)) {
    $name = [string]$e.DisplayName
    if (-not $name) { continue }
    $k = $name.Trim().ToLowerInvariant()
    if ($out.ContainsKey($k)) { continue }
    $b64 = Get-FileIcon64 ([string]$e.DisplayIcon)
    if (-not $b64 -and $e.InstallLocation -and (Test-Path -LiteralPath $e.InstallLocation)) {
        $exe = Get-ChildItem -LiteralPath $e.InstallLocation -Filter *.exe -File |
            Where-Object { $_.Name -notmatch 'unins|setup|update|crash|helper' } |
            Sort-Object Length -Descending | Select-Object -First 1
        if ($exe) { $b64 = Get-FileIcon64 $exe.FullName }
    }
    if (-not $b64 -and [string]$e.UninstallString -match '"?([^"]+\.exe)') { $b64 = Get-FileIcon64 $Matches[1] }
    if ($b64) { $out[$k] = $b64 }
}

foreach ($p in (Get-AppxPackage | Where-Object { -not $_.IsFramework -and $_.SignatureKind -ne 'System' })) {
    $m = Get-AppxPackageManifest -Package $p.PackageFullName
    $logo = [string]$m.Package.Properties.Logo
    if (-not $logo) { continue }
    $dir = Join-Path $p.InstallLocation (Split-Path $logo)
    $base = [IO.Path]::GetFileNameWithoutExtension($logo)
    $file = Get-ChildItem -LiteralPath $dir -Filter "$base*.png" -File | Sort-Object Length -Descending | Select-Object -First 1
    if (-not $file) { continue }
    try { $img = [System.Drawing.Image]::FromFile($file.FullName); $b64 = ConvertTo-Png64 $img; $img.Dispose() } catch { continue }
    $names = @($p.Name)
    $dn = [string]$m.Package.Properties.DisplayName
    if ($dn -and -not $dn.StartsWith('ms-resource:')) { $names += $dn }
    foreach ($n in $names) { $k = $n.Trim().ToLowerInvariant(); if (-not $out.ContainsKey($k)) { $out[$k] = $b64 } }
}
[Console]::Out.Write(($out | ConvertTo-Json -Compress))
