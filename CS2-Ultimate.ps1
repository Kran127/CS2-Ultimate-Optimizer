# --- Log in TEMP folder ---
$LogFile = "$env:TEMP\CS2-Optimizer.log"
"[$(Get-Date)] Script started" | Add-Content -Path $LogFile

# --- Clear caches ---
function Clear-Caches {
    "[$(Get-Date)] Clearing caches..." | Add-Content -Path $LogFile
    ipconfig /flushdns | Out-Null
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    arp -d * | Out-Null
    Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
    wevtutil el | ForEach-Object { try { wevtutil cl $_ } catch {} }
}

# --- Processes to lower priority ---
$targetProcesses = @("dwm","SearchIndexer","RuntimeBroker","svchost","OneDrive","explorer","ShellExperienceHost","SearchUI")

function Set-Priority($priority) {
    foreach ($p in $targetProcesses) {
        $proc = Get-Process -Name $p -ErrorAction SilentlyContinue
        if ($proc) {
            try {
                $proc.PriorityClass = $priority
                "[$(Get-Date)] $p → priority set to $priority" | Add-Content -Path $LogFile
            } catch {
                "[$(Get-Date)] $p → priority change failed" | Add-Content -Path $LogFile
            }
        }
    }
}

# --- CS2 optimization ---
function Optimize-CS2 {
    $cs2 = Get-Process -Name "cs2","cs2.exe","csgo" -ErrorAction SilentlyContinue
    if ($cs2) {
        "[$(Get-Date)] CS2 process found → optimizing..." | Add-Content -Path $LogFile
        Clear-Caches
        Set-Priority "Idle"
        $cs2.ProcessorAffinity = [int64]([math]::Pow(2, [Environment]::ProcessorCount) - 1)
        $cs2.PriorityClass = "High"
        Stop-Service -Name "wuauserv","SysMain","DiagTrack" -Force -ErrorAction SilentlyContinue
        while (Get-Process -Name "cs2","cs2.exe","csgo" -ErrorAction SilentlyContinue) {
            "[$(Get-Date)] CS2 running → optimization active..." | Add-Content -Path $LogFile
            Start-Sleep -Seconds 5
        }
        "[$(Get-Date)] CS2 closed → restoring settings." | Add-Content -Path $LogFile
        Set-Priority "Normal"
        Start-Service -Name "wuauserv","SysMain","DiagTrack" -ErrorAction SilentlyContinue
    } else {
        "[$(Get-Date)] CS2 process not found yet..." | Add-Content -Path $LogFile
    }
}

# --- Main loop ---
"[$(Get-Date)] Waiting for CS2 process..." | Add-Content -Path $LogFile
while ($true) {
    Optimize-CS2
    Start-Sleep -Seconds 5
}