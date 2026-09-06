# run elevated by install-debian.sh, with windows-apps.txt and AppData staged
# next to it.

function Write-Step($message) {
  Write-Host "==> $message" -ForegroundColor Magenta
}

Write-Step 'hiding desktop icons...'
$explorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
Set-ItemProperty "$explorer\Advanced" HideIcons 1 -Type DWord
New-Item "$explorer\HideDesktopIcons\NewStartPanel" -Force | Out-Null
Set-ItemProperty "$explorer\HideDesktopIcons\NewStartPanel" '{645FF040-5081-101B-9F08-00AA002F954E}' 1 -Type DWord

Write-Step 'setting taskbar to autohide...'
$stuckRects = "$explorer\StuckRects3"
$settings = (Get-ItemProperty $stuckRects).Settings
$settings[8] = 0x03
Set-ItemProperty $stuckRects Settings $settings -Type Binary

if ([int](Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000) {
  Write-Step 'running win11debloat...'

  $apps = (Get-Content "$PSScriptRoot\windows-apps.txt" |
    Where-Object { $_ -and $_ -notmatch '^\s*#' } |
    ForEach-Object { $_.Trim() }) -join ','

  # -DisableMouseAcceleration is deliberately omitted; pointer precision is on
  # here on purpose. the launcher calls exit, so it runs in its own process.
  $debloatArgs = @(
    '-Silent', '-CreateRestorePoint', '-RemoveApps', '-Apps', $apps,
    '-ForceRemoveEdge', '-RemoveGamingApps', '-DisableDVR', '-DisableGameBarIntegration',
    '-DisableCopilot', '-DisableRecall', '-DisableClickToDo', '-DisableAISvcAutoStart',
    '-DisableBing', '-DisableWidgets', '-DisableTelemetry', '-DisableSuggestions',
    '-DisableLockscreenTips', '-DisableSearchHighlights', '-DisableDesktopSpotlight',
    '-DisableSettingsHome', '-DisableSettings365Ads', '-DisableStartRecommended',
    '-DisableStartPhoneLink', '-StartAllAppsList', '-TaskbarAlignLeft', '-HideSearchTb',
    '-HideTaskview', '-HideChat', '-EnableEndTask', '-EnableDarkMode', '-ShowKnownFileExt',
    '-RevertContextMenu', '-HideHome', '-HideGallery', '-ExplorerToThisPC',
    '-DisableStickyKeys', '-PreventUpdateAutoReboot', '-DisableDeliveryOptimization'
  )

  $launcher = Join-Path $env:TEMP 'win11debloat.ps1'
  Invoke-RestMethod https://debloat.raphi.re/ -OutFile $launcher
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher @debloatArgs
}

Write-Step 'setting keyboard repeat...'

Add-Type -Namespace Dotfiles -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
'@

# SPI_SETKEYBOARDDELAY=0 (shortest) and SPI_SETKEYBOARDSPEED=31 (fastest),
# written to the registry and applied without a sign-out.
[Dotfiles.Native]::SystemParametersInfo(0x17, 0, [IntPtr]::Zero, 0x3) | Out-Null
[Dotfiles.Native]::SystemParametersInfo(0x0B, 31, [IntPtr]::Zero, 0x3) | Out-Null

Write-Step 'disabling animations...'

Set-ItemProperty "$explorer\Advanced" TaskbarAnimations 0 -Type DWord
New-Item "$explorer\VisualEffects" -Force | Out-Null
Set-ItemProperty "$explorer\VisualEffects" VisualFXSetting 3 -Type DWord

# SPI_SETANIMATION with ANIMATIONINFO { cbSize = 8, iMinAnimate = 0 }.
$animation = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
[Runtime.InteropServices.Marshal]::WriteInt32($animation, 0, 8)
[Runtime.InteropServices.Marshal]::WriteInt32($animation, 4, 0)
[Dotfiles.Native]::SystemParametersInfo(0x49, 8, $animation, 0x3) | Out-Null
[Runtime.InteropServices.Marshal]::FreeHGlobal($animation)

# SPI_SETCLIENTAREAANIMATION, SPI_SETMENUANIMATION, SPI_SETCOMBOBOXANIMATION,
# SPI_SETLISTBOXSMOOTHSCROLLING, SPI_SETTOOLTIPANIMATION, SPI_SETSELECTIONFADE,
# SPI_SETMENUFADE, all set to FALSE.
foreach ($action in 0x1043, 0x1003, 0x1005, 0x1007, 0x1017, 0x1015, 0x1013) {
  [Dotfiles.Native]::SystemParametersInfo($action, 0, [IntPtr]::Zero, 0x3) | Out-Null
}

Write-Step 'setting max refresh rate...'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Display
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public int dmFields, dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE
    {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(string lpDevice, int iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, int dwFlags);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, int dwFlags, IntPtr lParam);
}
'@

# no registry value controls this: pick the highest frequency each attached
# display offers at its current resolution.
$device = New-Object Display+DISPLAY_DEVICE
$device.cb = [Runtime.InteropServices.Marshal]::SizeOf($device)
$deviceIndex = 0

while ([Display]::EnumDisplayDevices([NullString]::Value, $deviceIndex, [ref]$device, 0)) {
  $deviceIndex++

  if (-not ($device.StateFlags -band 0x1)) { continue }

  $current = New-Object Display+DEVMODE
  $current.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($current)

  if (-not [Display]::EnumDisplaySettings($device.DeviceName, -1, [ref]$current)) { continue }

  $best = $current.dmDisplayFrequency
  $mode = New-Object Display+DEVMODE
  $mode.dmSize = $current.dmSize
  $modeIndex = 0

  while ([Display]::EnumDisplaySettings($device.DeviceName, $modeIndex, [ref]$mode)) {
    $modeIndex++

    if ($mode.dmPelsWidth -eq $current.dmPelsWidth -and
        $mode.dmPelsHeight -eq $current.dmPelsHeight -and
        $mode.dmBitsPerPel -eq $current.dmBitsPerPel -and
        $mode.dmDisplayFrequency -gt $best) {
      $best = $mode.dmDisplayFrequency
    }
  }

  if ($best -le $current.dmDisplayFrequency) {
    Write-Host "$($device.DeviceName): already at $($current.dmDisplayFrequency)Hz"
    continue
  }

  $from = $current.dmDisplayFrequency
  $current.dmDisplayFrequency = $best
  $current.dmFields = 0x80000 -bor 0x100000 -bor 0x400000
  $result = [Display]::ChangeDisplaySettingsEx($device.DeviceName, [ref]$current, [IntPtr]::Zero, 0x1, [IntPtr]::Zero)
  Write-Host "$($device.DeviceName): ${from}Hz -> ${best}Hz (result $result)"
}

Write-Step 'binding yubikey to wsl...'

$usbipd = "$env:ProgramFiles\usbipd-win\usbipd.exe"

if (Test-Path $usbipd) {
  foreach ($line in (& $usbipd list)) {
    if ($line -match '^\s*(\S+)\s+1050:.*Not shared') {
      & $usbipd bind --busid $Matches[1]
    }
  }
} else {
  Write-Warning 'usbipd not found; skipping'
}

Write-Step 'restoring windows app settings...'

# powertoys writes its in-memory state back over settings.json on exit.
# windows terminal is left running since it is likely hosting this install.
Stop-Process -Name 'PowerToys*' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$appData = Join-Path $PSScriptRoot 'AppData\Local'

Get-ChildItem $appData -Recurse -File | ForEach-Object {
  $destination = Join-Path $env:LOCALAPPDATA $_.FullName.Substring($appData.Length + 1)
  New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
  Copy-Item $_.FullName $destination -Force
}

Write-Step 'starting powertoys...'

# powertoys recreates its logon task from settings.json on every launch, and
# launching it elevated makes that task elevated too.
$powertoys = @(
  "$env:ProgramFiles\PowerToys\PowerToys.exe",
  "$env:LOCALAPPDATA\PowerToys\PowerToys.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($powertoys) {
  Start-Process $powertoys
} else {
  Write-Warning 'powertoys not found; skipping'
}

Write-Step 'windows setup done'
