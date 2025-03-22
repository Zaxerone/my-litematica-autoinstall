chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

if (-not [bool]$MyInvocation.MyCommand.Path) {
} else {
    Write-Host "Running Litematica Installer directly..." -ForegroundColor Green
}

$litematica = "https://www.curseforge.com/api/v1/mods/308892/files/5393557/download"
$malilib = "https://cdn.modrinth.com/data/GcWjdA9I/versions/YYfmFXPZ/malilib-fabric-1.20.4-0.18.3.jar"
$fabric_api = "https://www.curseforge.com/api/v1/mods/306612/files/5664862/download"
$optifabric = "https://www.curseforge.com/api/v1/mods/322385/files/5025647/download"
$optifine = "https://optifine.net/downloadx?f=OptiFine_1.20.4_HD_U_I7.jar&x=2431b221c60ad0b0dc41b296fd79e0ec"
$litematica_printer = "https://cdn.modrinth.com/data/3llatzyE/versions/xeDghx1o/litematica-printer-1.20.4-3.2.1.jar"
$fabric_installer = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar"

function Ensure-ModsFolder {
    $minecraftPath = "$env:APPDATA\.minecraft"
    $modsPath = "$minecraftPath\mods"

    if (-not (Test-Path $modsPath)) {
        New-Item -Path $modsPath -ItemType Directory -Force | Out-Null
        Write-Host "Mods folder created at $modsPath" -ForegroundColor Green
    }

    return $modsPath
}

function Download-File {
    param (
        [string]$Url,
        [string]$OutputPath
    )

    Write-Host "Downloading $(Split-Path $OutputPath -Leaf)..." -ForegroundColor Cyan

    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        $webClient.DownloadFile($Url, $OutputPath)

        if (Test-Path $OutputPath) {
            $fileInfo = Get-Item $OutputPath
            if ($fileInfo.Length -gt 0) {
                Write-Host "Download completed: $(Split-Path $OutputPath -Leaf) ($('{0:N2}' -f ($fileInfo.Length / 1MB)) MB)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "Downloaded file is empty: $(Split-Path $OutputPath -Leaf)" -ForegroundColor Red
                Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
                return $false
            }
        } else {
            Write-Host "Failed to download file: $(Split-Path $OutputPath -Leaf)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host ("Error downloading " + (Split-Path $OutputPath -Leaf) + ": " + $_.Exception.Message) -ForegroundColor Red
        return $false
    }
    finally {
        if ($webClient -ne $null) {
            $webClient.Dispose()
        }
    }
}

function Download-OptiFine {
    param (
        [string]$OutputPath
    )

    Write-Host "Downloading OptiFine_1.20.4_HD_U_I7.jar..." -ForegroundColor Cyan

    try {
        $sources = @(
            "https://optifine.net/download?f=OptiFine_1.20.4_HD_U_I7.jar",
            "https://optifined.net/adloadx.php?f=OptiFine_1.20.4_HD_U_I7.jar",
            "https://optifined.net/download.php?f=OptiFine_1.20.4_HD_U_I7.jar&direct=1"
        )
        
        foreach ($source in $sources) {
            try {
                Write-Host "Trying OptiFine source: $source" -ForegroundColor Cyan
                
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36")
                $webClient.Headers.Add("Referer", "https://optifine.net/downloads")
                $webClient.Headers.Add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8")
                $webClient.Headers.Add("Accept-Language", "en-US,en;q=0.9")
                $webClient.Headers.Add("sec-ch-ua", "`"Google Chrome`";v=`"118`", `"Chromium`";v=`"118`"")
                
                $webClient.DownloadFile($source, $OutputPath)
                
                if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 1000)) {
                    try {
                        [System.IO.Compression.ZipFile]::OpenRead($OutputPath).Dispose()
                        Write-Host "OptiFine download completed ($('{0:N2}' -f ((Get-Item $OutputPath).Length / 1MB)) MB)" -ForegroundColor Green
                        return $true
                    } catch {
                        Write-Host "Downloaded file is not a valid JAR/ZIP file from source $source. Trying another source..." -ForegroundColor Yellow
                        Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    Write-Host "Downloaded file is empty or too small from source $source. Trying another source..." -ForegroundColor Yellow
                    Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host ("Error downloading from source " + $source + ": " + $_.Exception.Message) -ForegroundColor Yellow
            } finally {
                if ($webClient -ne $null) {
                    $webClient.Dispose()
                }
            }
        }
        
        try {
            Write-Host "Trying alternative download method with Invoke-WebRequest..." -ForegroundColor Cyan
            $url = "https://optifine.net/downloadx?f=OptiFine_1.20.4_HD_U_I7.jar&x=becdab0461adbdb5bc34d075925013d0"
            
            $headers = @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
                "Referer" = "https://optifine.net/downloads"
                "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
                "Accept-Language" = "en-US,en;q=0.9"
                "sec-ch-ua" = "`"Google Chrome`";v=`"118`", `"Chromium`";v=`"118`""
            }
            
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -Headers $headers -OutFile $OutputPath -TimeoutSec 60
            $ProgressPreference = 'Continue'
            
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 1000)) {
                try {
                    [System.IO.Compression.ZipFile]::OpenRead($OutputPath).Dispose()
                    Write-Host "OptiFine download completed ($('{0:N2}' -f ((Get-Item $OutputPath).Length / 1MB)) MB)" -ForegroundColor Green
                    return $true
                } catch {
                    Write-Host "Downloaded file is not a valid JAR/ZIP file." -ForegroundColor Yellow
                    Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Write-Host ("Error with alternative download method: " + $_.Exception.Message) -ForegroundColor Yellow
        }
        
        Write-Host "All automatic download methods for OptiFine failed." -ForegroundColor Red
        Write-Host "Please manually download OptiFine from https://optifine.net/downloads" -ForegroundColor Yellow
        Write-Host "and place it in your .minecraft/mods folder as 'OptiFine_1.20.4_HD_U_I7.jar'" -ForegroundColor Yellow
        
        return $false
    }
    catch {
        Write-Host ("Error in Download-OptiFine function: " + $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

function Install-Fabric {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".jar"

    if (Download-File -Url $fabric_installer -OutputPath $tempFile) {
        Write-Host "Installing Fabric 1.20.4..." -ForegroundColor Cyan
        try {
            Start-Process -FilePath "java" -ArgumentList "-jar", $tempFile, "client", "-mcversion 1.20.4" -Wait
            Write-Host "Fabric 1.20.4 successfully installed" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host ("Error installing Fabric: " + $_.Exception.Message) -ForegroundColor Red
            return $false
        }
        finally {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        return $false
    }
}

function Main {
    try {
        $javaVersion = (java -version 2>&1 | Out-String)
        Write-Host "Java detected: $javaVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Java is not installed or not in the PATH. Please install Java before continuing." -ForegroundColor Red
        return
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $titleFont = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $normalFont = New-Object System.Drawing.Font("Segoe UI", 12)
    $buttonFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)

    $backgroundColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $accentColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
    $textColor = [System.Drawing.Color]::FromArgb(33, 33, 33)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Litematica Installer - Minecraft 1.20.4"
    $form.Size = New-Object System.Drawing.Size(720, 650)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = $backgroundColor
    $form.Font = $normalFont

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(700, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(10, 10)
    $headerPanel.BackColor = $accentColor
    $form.Controls.Add($headerPanel)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 25)
    $label.Size = New-Object System.Drawing.Size(660, 35)
    $label.Text = "Litematica Installer for Minecraft 1.20.4"
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Font = $titleFont
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $headerPanel.Controls.Add($label)

    $optionsPanel = New-Object System.Windows.Forms.Panel
    $optionsPanel.Size = New-Object System.Drawing.Size(700, 420)
    $optionsPanel.Location = New-Object System.Drawing.Point(10, 100)
    $optionsPanel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($optionsPanel)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $subtitleLabel.Size = New-Object System.Drawing.Size(660, 30)
    $subtitleLabel.Text = "Components to install:"
    $subtitleLabel.ForeColor = $textColor
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $optionsPanel.Controls.Add($subtitleLabel)

    $checkboxFabric = New-Object System.Windows.Forms.CheckBox
    $checkboxFabric.Location = New-Object System.Drawing.Point(40, 70)
    $checkboxFabric.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxFabric.Text = "Fabric (required)"
    $checkboxFabric.Checked = $true
    $checkboxFabric.Enabled = $false
    $checkboxFabric.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxFabric)

    $checkboxLitematica = New-Object System.Windows.Forms.CheckBox
    $checkboxLitematica.Location = New-Object System.Drawing.Point(40, 110)
    $checkboxLitematica.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxLitematica.Text = "Litematica (required)"
    $checkboxLitematica.Checked = $true
    $checkboxLitematica.Enabled = $false
    $checkboxLitematica.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxLitematica)

    $checkboxMalilib = New-Object System.Windows.Forms.CheckBox
    $checkboxMalilib.Location = New-Object System.Drawing.Point(40, 150)
    $checkboxMalilib.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxMalilib.Text = "MaLiLib (required for Litematica)"
    $checkboxMalilib.Checked = $true
    $checkboxMalilib.Enabled = $false
    $checkboxMalilib.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxMalilib)

    $checkboxFabricAPI = New-Object System.Windows.Forms.CheckBox
    $checkboxFabricAPI.Location = New-Object System.Drawing.Point(40, 190)
    $checkboxFabricAPI.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxFabricAPI.Text = "Fabric API (required for Litematica)"
    $checkboxFabricAPI.Checked = $true
    $checkboxFabricAPI.Enabled = $false
    $checkboxFabricAPI.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxFabricAPI)

    $separator = New-Object System.Windows.Forms.Label
    $separator.Location = New-Object System.Drawing.Point(20, 230)
    $separator.Size = New-Object System.Drawing.Size(660, 2)
    $separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $optionsPanel.Controls.Add($separator)

    $optionalLabel = New-Object System.Windows.Forms.Label
    $optionalLabel.Location = New-Object System.Drawing.Point(20, 245)
    $optionalLabel.Size = New-Object System.Drawing.Size(660, 30)
    $optionalLabel.Text = "Optional modules:"
    $optionalLabel.ForeColor = $textColor
    $optionalLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $optionsPanel.Controls.Add($optionalLabel)

    $checkboxPrinter = New-Object System.Windows.Forms.CheckBox
    $checkboxPrinter.Location = New-Object System.Drawing.Point(40, 285)
    $checkboxPrinter.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxPrinter.Text = "Litematica Printer (optional)"
    $checkboxPrinter.Checked = $false
    $checkboxPrinter.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxPrinter)

    $checkboxOptifine = New-Object System.Windows.Forms.CheckBox
    $checkboxOptifine.Location = New-Object System.Drawing.Point(40, 325)
    $checkboxOptifine.Size = New-Object System.Drawing.Size(620, 30)
    $checkboxOptifine.Text = "OptiFine (optional)"
    $checkboxOptifine.Checked = $false
    $checkboxOptifine.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxOptifine)

    $checkboxOptifabric = New-Object System.Windows.Forms.CheckBox
    $checkboxOptifabric.Location = New-Object System.Drawing.Point(60, 365)
    $checkboxOptifabric.Size = New-Object System.Drawing.Size(600, 30)
    $checkboxOptifabric.Text = "OptiFabric (required for OptiFine)"
    $checkboxOptifabric.Checked = $false
    $checkboxOptifabric.Enabled = $false
    $checkboxOptifabric.Font = $normalFont
    $optionsPanel.Controls.Add($checkboxOptifabric)

    $checkboxOptifine.Add_CheckedChanged({
        $checkboxOptifabric.Checked = $checkboxOptifine.Checked
    })

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(260, 540)
    $installButton.Size = New-Object System.Drawing.Size(200, 60)
    $installButton.Text = "INSTALL"
    $installButton.BackColor = $accentColor
    $installButton.ForeColor = [System.Drawing.Color]::White
    $installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $installButton.Font = $buttonFont
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Hand

    $installButton.Add_MouseEnter({
        $this.BackColor = [System.Drawing.Color]::FromArgb(46, 145, 50)
    })
    $installButton.Add_MouseLeave({
        $this.BackColor = $accentColor
    })

    $installButton.Add_Click({
        $form.Hide()

        $fabricSuccess = Install-Fabric
        if (-not $fabricSuccess) {
            [System.Windows.Forms.MessageBox]::Show("Fabric installation failed. The installation process will stop.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $form.Close()
            return
        }

        $modsFolder = Ensure-ModsFolder

        $successCount = 0
        $totalCount = 3

        if (Download-File -Url $litematica -OutputPath "$modsFolder\litematica-1.20.4.jar") { $successCount++ }
        if (Download-File -Url $malilib -OutputPath "$modsFolder\malilib-1.20.4.jar") { $successCount++ }
        if (Download-File -Url $fabric_api -OutputPath "$modsFolder\fabric-api-1.20.4.jar") { $successCount++ }

        if ($checkboxPrinter.Checked) {
            $totalCount++
            if (Download-File -Url $litematica_printer -OutputPath "$modsFolder\litematica-printer-1.20.4.jar") { $successCount++ }
        }

        if ($checkboxOptifine.Checked) {
            $totalCount += 2

            $optifineOutputPath = "$modsFolder\OptiFine_1.20.4_HD_U_I7.jar"
            if (Download-OptiFine -OutputPath $optifineOutputPath) { 
                $successCount++
                Write-Host "OptiFine jar verified and placed in mods folder." -ForegroundColor Green
            }

            if (Download-File -Url $optifabric -OutputPath "$modsFolder\optifabric-1.20.4.jar") {
                $successCount++
                Write-Host "OptiFabric successfully installed." -ForegroundColor Green
            }
        }

        if ($successCount -eq $totalCount) {
            [System.Windows.Forms.MessageBox]::Show("Installation completed successfully! ($successCount/$totalCount mods installed)", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Installation partially completed. $successCount/$totalCount mods were installed. Check console messages for details.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }

        Write-Host "Installation completed. You can now launch Minecraft with the Fabric 1.20.4 profile" -ForegroundColor Green

        $form.Close()
    })
    $form.Controls.Add($installButton)

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $form.ShowDialog() | Out-Null
}

Write-Host "`nTo install with one line, copy and paste this command in PowerShell:" -ForegroundColor Cyan
Write-Host "irm https://raw.githubusercontent.com/Zaxerone/my-litematica-autoinstall/main/install.ps1 | iex" -ForegroundColor Yellow

Main