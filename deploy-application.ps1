    ##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Uninstall sysmon64 if present
		if (Test-Path -Path "C:\Windows\Sysmon64.exe") { Execute-Process -Path "C:\Windows\Sysmon64.exe" -Parameters "-u force" }
		if (Test-Path -Path "C:\Windows\Sysmon64.exe") { Remove-File -Path "C:\Windows\Sysmon64.exe" -Recurse }
		if (Test-Path -Path "C:\Windows\Sysmon64.exe.old") { Remove-File -Path "C:\Windows\Sysmon64.exe.old" -Recurse }

		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
	
	    ## Uninstall sysmon if already installed
	    if (Test-Path -Path "C:\Windows\Sysmon.exe") { 
		    Write-Log -Message ">>>>>>>>>> Sysmon.exe found - EXEC: C:\Windows\Sysmon.exe -u" -LogType 'CMTrace'
		    $ret = Execute-Process -Path "C:\Windows\Sysmon.exe" -Parameters "-u" -IgnoreExitCode "1601" -PassThru
		    if ($ret.Exitcode -ne 0) {
				    Write-Log -Message ">>>>>>>>>> uninstall failed - EXEC: C:\Windows\Sysmon.exe -u force" -LogType 'CMTrace'
				    Execute-Process -Path "C:\Windows\Sysmon.exe" -Parameters "-u force" 
			    } else {
				    Write-Log -Message ">>>>>>>>>> sysmon uninstalled successfully" -LogType 'CMTrace'
			    }
	    }

		## Cleanup
		Write-Log -Message ">>>>>>>>>> Wait 30 seconds and cleanup orphaned files" -LogType 'CMTrace'
	    Start-Sleep -Seconds 30
	    if (Test-Path -Path "C:\Windows\Sysmon.exe") { Remove-File -Path "C:\Windows\Sysmon.exe" -Recurse }
	    if (Test-Path -Path "C:\Windows\SysmonDrv.sys") { Remove-File -Path "C:\Windows\SysmonDrv.sys" -Recurse }
	    if (Test-Path -Path "C:\Windows\sysmon_config.xml") { Remove-File -Path "C:\Windows\sysmon_config.xml" -Recurse }
	    if (Test-Path -Path "C:\Windows\Sysmon.exe.old") { Remove-File -Path "C:\Windows\Sysmon.exe.old" -Recurse }
	    if (Test-Path -Path "C:\Windows\Sysmon.exe") { Rename-Item "C:\Windows\Sysmon.exe" -NewName "Sysmon.exe.old" }

	    ## Install sysmon
	    Write-Log -Message ">>>>>>>>>> Install sysmon $appVersion and start service" -LogType 'CMTrace'		
		  Copy-Item -Path "$dirFiles\*.*" -Destination "C:\Windows" -Recurse
	    Execute-Process -Path "c:\Windows\Sysmon.exe" -Parameters "-i `"c:\Windows\sysmon_config.xml`" -accepteula"
     
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

        Write-Log -Message ">>>>>>>>>> Post Checks" -LogType 'CMTrace'	
        ## Check if file/reg exist
        $items = @(
            "C:\Windows\Sysmon.exe",
            "C:\Windows\SysmonDrv.sys",
            "HKLM:\SYSTEM\CurrentControlSet\Services\Sysmon",
            "HKLM:\SYSTEM\CurrentControlSet\Services\SysmonDrv",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{5770385f-c22a-43e0-bf4c-06f5698ffbd9}",
            "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-Microsoft-Windows-Sysmon-Operational"
        )
        foreach ( $i in $items ) {
            If ( Test-Path $i ) {
                Write-Log -Message ">>> Post-Check ok for files/reg $i"
            } else {
                Write-Log -Message ">>> Post-Check failed for item $i"
                Exit-Script -ExitCode 1
            }
        }

        ## Check services
        $services = @(
            "Sysmon",
            "SysmonDrv",
            "splunkforwarder"
        )
        foreach ( $s in $services ) {
            $status = (Get-Service $s -ErrorAction SilentlyContinue).Status
            If ($status -like 'Running') { 
                Write-Log -Message ">>> Post-Check ok for service $s"
            } else {
                Write-Log -Message ">>> Post-Check failed for service $s"
                Exit-Script -ExitCode 1
            }
        }
        
