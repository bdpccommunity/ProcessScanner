# ============================================================
#  PROCESS SECURITY SCANNER - With GUI API Key Input
#  Author: Auto-Generated
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =======================
#  GUI: API KEY INPUT BOX
# =======================
function Show-ApiKeyDialog {

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Process Security Scanner"
    $form.Size = New-Object System.Drawing.Size(480, 260)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 26)
    $form.ForeColor = [System.Drawing.Color]::White

    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🔍 PROCESS SECURITY SCANNER"
    $titleLabel.Font = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 180)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(440, 30)
    $form.Controls.Add($titleLabel)

    # Subtitle
    $subLabel = New-Object System.Windows.Forms.Label
    $subLabel.Text = "VirusTotal API Key দিন scan শুরু করতে:"
    $subLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
    $subLabel.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 200)
    $subLabel.Location = New-Object System.Drawing.Point(20, 60)
    $subLabel.Size = New-Object System.Drawing.Size(440, 20)
    $form.Controls.Add($subLabel)

    # API Key TextBox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 88)
    $textBox.Size = New-Object System.Drawing.Size(430, 28)
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 45)
    $textBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 180)
    $textBox.BorderStyle = "FixedSingle"
    $textBox.UseSystemPasswordChar = $false
    $textBox.Text = ""
    $form.Controls.Add($textBox)

    # Show/Hide Password Checkbox
    $showCheck = New-Object System.Windows.Forms.CheckBox
    $showCheck.Text = "API Key দেখান"
    $showCheck.Font = New-Object System.Drawing.Font("Consolas", 8)
    $showCheck.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 180)
    $showCheck.Location = New-Object System.Drawing.Point(20, 118)
    $showCheck.Size = New-Object System.Drawing.Size(200, 20)
    $showCheck.Add_CheckedChanged({
        $textBox.UseSystemPasswordChar = -not $showCheck.Checked
    })
    $form.Controls.Add($showCheck)

    # Info Label
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "⚠  Admin হিসেবে run করলে সব process দেখা যাবে"
    $infoLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
    $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 80)
    $infoLabel.Location = New-Object System.Drawing.Point(20, 145)
    $infoLabel.Size = New-Object System.Drawing.Size(440, 18)
    $form.Controls.Add($infoLabel)

    # START Button
    $startBtn = New-Object System.Windows.Forms.Button
    $startBtn.Text = "▶  SCAN শুরু করুন"
    $startBtn.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $startBtn.Location = New-Object System.Drawing.Point(20, 175)
    $startBtn.Size = New-Object System.Drawing.Size(200, 38)
    $startBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 130)
    $startBtn.ForeColor = [System.Drawing.Color]::Black
    $startBtn.FlatStyle = "Flat"
    $startBtn.FlatAppearance.BorderSize = 0
    $startBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $startBtn.Add_Click({
        if ([string]::IsNullOrWhiteSpace($textBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "API Key খালি রাখা যাবে না!",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        } else {
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        }
    })
    $form.Controls.Add($startBtn)

    # CANCEL Button
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = "✕  বাতিল"
    $cancelBtn.Font = New-Object System.Drawing.Font("Consolas", 10)
    $cancelBtn.Location = New-Object System.Drawing.Point(240, 175)
    $cancelBtn.Size = New-Object System.Drawing.Size(120, 38)
    $cancelBtn.BackColor = [System.Drawing.Color]::FromArgb(60, 30, 40)
    $cancelBtn.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    $cancelBtn.FlatStyle = "Flat"
    $cancelBtn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    $cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelBtn)

    $form.AcceptButton = $startBtn
    $form.CancelButton = $cancelBtn

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text.Trim()
    }
    return $null
}

# =======================
#  LOGGING
# =======================
$LogPath = "ProcessScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

# =======================
#  SIGNATURE CHECK
# =======================
function Get-SignatureStatus {
    param ([string]$EXEPath)
    try {
        if (-not (Test-Path $EXEPath)) { return "FileNotFound" }
        (Get-AuthenticodeSignature -FilePath $EXEPath).Status.ToString()
    }
    catch { "Error" }
}

# =======================
#  VIRUSTOTAL HASH CHECK
# =======================
function Check-VirusTotalHash {
    param([string]$FilePath, [string]$ApiKey)
    try {
        $hash = (Get-FileHash $FilePath -Algorithm SHA256).Hash
        $headers = @{ "x-apikey" = $ApiKey }
        $url = "https://www.virustotal.com/api/v3/files/$hash"
        $response = Invoke-RestMethod -Method GET -Uri $url -Headers $headers
        $stats = $response.data.attributes.last_analysis_stats
        $mal = $stats.malicious
        $sus = $stats.suspicious
        $total = $stats.harmless + $stats.undetected + $mal + $sus
        $risk = "Clean"
        if ($mal -ge 5) { $risk = "HIGH RISK" }
        elseif ($mal -ge 3) { $risk = "MEDIUM RISK" }
        elseif ($mal -ge 1 -or $sus -ge 3) { $risk = "LOW RISK" }
        return @{ Hash=$hash; Malicious=$mal; Suspicious=$sus; Detection="$mal/$total"; Risk=$risk }
    }
    catch {
        return @{ Hash="Error"; Malicious="Error"; Suspicious="Error"; Detection="N/A"; Risk="Unknown" }
    }
}

# =======================
#  FILE DETAILS
# =======================
function Get-FileDetails {
    param([string]$FilePath)
    try {
        $f = Get-Item $FilePath
        $v = $f.VersionInfo
        return @{
            Company = $v.CompanyName
            Description = $v.FileDescription
            Version = $v.FileVersion
            SizeKB = [math]::Round($f.Length / 1KB, 2)
        }
    }
    catch {
        return @{ Company="N/A"; Description="N/A"; Version="N/A"; SizeKB="N/A" }
    }
}

# =======================
#  MAIN SCAN
# =======================
function Start-ProcessSecurityScan {
    param([string]$ApiKey)

    Write-Log "Starting FULL C:\ process scan"

    $scannedFiles = @{}
    $unsigned = 0
    $suspicious = 0
    $processes = Get-Process -ErrorAction SilentlyContinue

    foreach ($p in $processes) {
        try {
            foreach ($m in $p.Modules) {
                $modulePath = $m.FileName
                if ([string]::IsNullOrEmpty($modulePath) `
                    -or -not ($modulePath.StartsWith("C:\")) `
                    -or $scannedFiles.ContainsKey($modulePath)) { continue }

                $scannedFiles[$modulePath] = $true
                $sig = Get-SignatureStatus $modulePath

                if ($sig -ne "Valid") {
                    $unsigned++
                    Write-Host "`n============================" -ForegroundColor Yellow
                    Write-Host "Process : $($p.ProcessName)  PID:$($p.Id)" -ForegroundColor Yellow
                    Write-Host "Path    : $modulePath" -ForegroundColor Yellow
                    Write-Host "Signature: $sig" -ForegroundColor Yellow

                    $info = Get-FileDetails $modulePath
                    Write-Host "Company : $($info.Company)"
                    Write-Host "Desc    : $($info.Description)"
                    Write-Host "Version : $($info.Version)"
                    Write-Host "Size KB : $($info.SizeKB)"

                    Write-Host "VirusTotal Scan..." -ForegroundColor Gray
                    $vt = Check-VirusTotalHash -FilePath $modulePath -ApiKey $ApiKey

                    Write-Host "Hash     : $($vt.Hash)"
                    Write-Host "Detection: $($vt.Detection)"
                    Write-Host "Risk     : $($vt.Risk)" -ForegroundColor Red

                    if ($vt.Malicious -ge 3) {
                        Write-Host "🚨 MALICIOUS FILE DETECTED" -ForegroundColor Red
                        $suspicious++
                    }

                    Start-Sleep -Milliseconds 500
                }
            }
        }
        catch {}
    }

    Write-Host "`n===== SCAN SUMMARY =====" -ForegroundColor Green
    Write-Host "Total unique files scanned: $($scannedFiles.Count)"
    Write-Host "Unsigned files found     : $unsigned"
    Write-Host "Suspicious files         : $suspicious"
    Write-Host "Log file saved to        : $LogPath" -ForegroundColor Green

    Write-Log "Scan complete. Unsigned: $unsigned | Suspicious: $suspicious"

    # Done popup
    [System.Windows.Forms.MessageBox]::Show(
        "✅ Scan সম্পন্ন!`n`nScanned Files : $($scannedFiles.Count)`nUnsigned      : $unsigned`nSuspicious    : $suspicious`n`nLog: $LogPath",
        "Scan Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# =======================
#  ENTRY POINT
# =======================
$host.UI.RawUI.WindowTitle = "Process Security Scanner"

Write-Host "=== FULL C:\ PROCESS SECURITY SCANNER ===" -ForegroundColor Cyan

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠  Admin হিসেবে run করলে বেশি visibility পাবেন" -ForegroundColor Yellow
}

# Show API Key Input Box
$apiKey = Show-ApiKeyDialog

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "বাতিল করা হয়েছে। Script বন্ধ।" -ForegroundColor Red
    exit
}

Write-Host "API Key গ্রহণ করা হয়েছে। Scan শুরু হচ্ছে..." -ForegroundColor Green
Start-Sleep 1
Start-ProcessSecurityScan -ApiKey $apiKey

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
