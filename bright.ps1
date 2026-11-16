<#
.SYNOPSIS
  Show or set monitor brightness for the laptop screen and external monitors.

.EXAMPLE
  bright            # show current brightness
  bright 30         # set every monitor to 30 %
  bright +10        # 10 % brighter
  bright -10        # 10 % darker
  bright 50 laptop  # only the built-in screen
  bright 50 ext     # only external monitors
#>
param(
    [string]$Value,
    [ValidateSet('all', 'laptop', 'ext', 'external')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'

if (-not ('BrightCtl.Ddc' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace BrightCtl {
    public class Ddc {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct PHYSICAL_MONITOR {
            public IntPtr hPhysicalMonitor;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string szPhysicalMonitorDescription;
        }
        delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdc, IntPtr rect, IntPtr data);

        [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorEnumProc proc, IntPtr data);
        [DllImport("dxva2.dll")] static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr hMonitor, out uint count);
        [DllImport("dxva2.dll")] static extern bool GetPhysicalMonitorsFromHMONITOR(IntPtr hMonitor, uint count, [Out] PHYSICAL_MONITOR[] monitors);
        [DllImport("dxva2.dll")] static extern bool DestroyPhysicalMonitors(uint count, PHYSICAL_MONITOR[] monitors);
        [DllImport("dxva2.dll")] static extern bool GetMonitorBrightness(IntPtr h, out uint min, out uint cur, out uint max);
        [DllImport("dxva2.dll")] static extern bool SetMonitorBrightness(IntPtr h, uint value);

        // Monitors use their own raw range (min..max), so values are converted to and from percent.
        public static List<string> Apply(int percent, int delta, bool relative) {
            var result = new List<string>();
            EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (hMon, hdc, rect, data) => {
                uint n;
                if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hMon, out n) || n == 0) return true;
                var mons = new PHYSICAL_MONITOR[n];
                if (!GetPhysicalMonitorsFromHMONITOR(hMon, n, mons)) return true;
                foreach (var m in mons) {
                    uint min, cur, max;
                    if (!GetMonitorBrightness(m.hPhysicalMonitor, out min, out cur, out max) || max <= min) continue;
                    int curPct = (int)Math.Round((cur - min) * 100.0 / (max - min));
                    int newPct = relative ? curPct + delta : (percent >= 0 ? percent : curPct);
                    newPct = Math.Max(0, Math.Min(100, newPct));
                    if (relative || percent >= 0) {
                        SetMonitorBrightness(m.hPhysicalMonitor, (uint)Math.Round(min + (max - min) * newPct / 100.0));
                    }
                    result.Add(m.szPhysicalMonitorDescription + "|" + newPct);
                }
                DestroyPhysicalMonitors(n, mons);
                return true;
            }, IntPtr.Zero);
            return result;
        }
    }
}
'@
}

$relative = $false; $percent = -1; $delta = 0
if ($Value) {
    if ($Value -notmatch '^[+-]?\d{1,3}$') {
        Write-Host "Usage: bright [0-100 | +N | -N] [all|laptop|ext]" -ForegroundColor Yellow
        exit 1
    }
    if ($Value -match '^[+-]') { $relative = $true; $delta = [int]$Value }
    else { $percent = [Math]::Min(100, [int]$Value) }
}

$doLaptop = $Target -in 'all', 'laptop'
$doExt    = $Target -in 'all', 'ext', 'external'
$found    = $false

if ($doLaptop) {
    $wmi = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue
    if ($wmi) {
        $found = $true
        $cur = [int]($wmi | Select-Object -First 1).CurrentBrightness
        $new = $cur
        if ($relative) { $new = [Math]::Max(0, [Math]::Min(100, $cur + $delta)) }
        elseif ($percent -ge 0) { $new = $percent }
        if ($Value) {
            Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods |
                Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{ Timeout = [uint32]1; Brightness = [byte]$new } | Out-Null
        }
        Write-Host ("Laptop screen: {0}%" -f $new)
    }
}

if ($doExt) {
    foreach ($line in [BrightCtl.Ddc]::Apply($percent, $delta, $relative)) {
        $found = $true
        $name, $pct = $line -split '\|'
        if ($name -match 'Generic PnP|^$') { $name = 'External monitor' }
        Write-Host ("{0}: {1}%" -f $name, $pct)
    }
}

if (-not $found) {
    Write-Host "No monitor answered. For an external monitor, turn on DDC/CI in its on-screen menu." -ForegroundColor Yellow
    exit 1
}
