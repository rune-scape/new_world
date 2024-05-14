Param(
	[string] $Target,
	[string] $Project,
	[string] $Platform,
	[string] $Arch = 'x86_64',
	[switch] $DebugSymbols,
	[switch] $DownloadOnly,
	[switch] $Console
)

. "$PSScriptRoot/GodotProperties.ps1" -Platform $Platform -Arch $Arch
if ($LastExitCode) {
	pause
	exit -1
}

if ($Target -eq '') {
	$Target = $CustomGodotDefaultTarget
	Write-Host " ~ selected target: '$Target' (default)"
} else {
	Write-Host " ~ selected target: '$Target'"
}

if ($DebugSymbols) {
	Write-Host " ~ with debug symbols"
}

if ($Target -NotIn $CustomGodotValidTargets) {
	Write-Host " ~ invalid target: '$Target'" -ForegroundColor red
	pause
	exit -1
}

function FormatFileSize($num) {
    $suffix = "b", "kb", "mb", "gb"
    $index = 0
    while ($num -gt 1kb) {
        $num = $num / 1kb
        $index++
    } 

    "{0:N1}{1}" -f $num, $suffix[$index]
}

function DownloadFile($Url, $OutFile) {
	$uri = New-Object "System.Uri" "$Url"
	$remoteFileName = $url.split('/') | Select -Last 1
	
	$targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $OutFile, Create
	if ($null -eq $targetStream) {
		Write-Host " ~ could not create file: '$OutFile'" -ForegroundColor red
		throw
	}
	try {
		$progressActivity = " ~ downloading file '$remoteFileName'"
		$request = [System.Net.HttpWebRequest]::Create($uri)
		$request.set_Timeout(10000) # 10 second timeout
		Write-Progress -Activity $progressActivity -Status "asking politely..."
		try {
			$response = $request.GetResponse()
		} catch {
			Write-Progress -Activity $progressActivity -Status "request timed out"
			Write-Host " ~ request timed out" -ForegroundColor red
			throw
		}
		
		$contentLength = $response.get_ContentLength()
		
		$responseStream = $response.GetResponseStream()
		try {
			if ($null -eq $responseStream) {
				throw
			}
			
			$buffer = new-object byte[] 100kb
			$count = 0
			$downloadedBytes = $count
			do {
				$targetStream.Write($buffer, 0, $count)
				$count = $responseStream.Read($buffer,0,$buffer.length)
				$downloadedBytes = $downloadedBytes + $count
				$percentComplete = ($downloadedBytes / $contentLength) * 100
				Write-Progress -Activity $progressActivity -Status "$(FormatFileSize $downloadedBytes)/$(FormatFileSize $contentLength)" -PercentComplete $percentComplete
			} while ($count -gt 0)

			Write-Progress -Activity $progressActivity -Status "finished downloading file '$remoteFileName'" -Completed
			Write-Host " ~ finished downloading file '$remoteFileName'"
		} finally {
			$responseStream.Dispose()
		}
	} catch {
		Write-Host " ~ error downloading file: '$remoteFileName'" -ForegroundColor red
	} finally {
		$targetStream.Flush()
		$targetStream.Close()
		$targetStream.Dispose()
	}
}

function DownloadGodotBins($Url, $Dir, $ArchiveName, $ExpectedFiles) {
	$HasSomeFiles = @($ExpectedFiles | ?{ (Test-Path $_) }).count -gt 0
	$HasAllFiles = @($ExpectedFiles | ?{ !(Test-Path $_) }).count -eq 0
	if ($HasSomeFiles -and !$HasAllFiles) {
		Write-Host " ~ only some files are missing,, weird" -ForegroundColor yellow
	}
	
	New-Item -ItemType "directory" -Force "$Dir" | Out-Null
	if (!$?) {
		throw
	}
	
	$ArchivePath = Join-Path "$Dir" "$ArchiveName"
	DownloadFile -Url "$Url" -OutFile "$ArchivePath"
	& "$7zipExecutable" x "$ArchivePath" "-o$Dir"
	if ($LastExitCode) {
		pause
		Write-Host " ~ failed extracting '$ArchiveName'" -ForegroundColor red
		throw
	}
	Remove-Item -Recurse -Force "$ArchivePath" | Out-Null

	$MissingFiles = @($ExpectedFiles | ?{ !(Test-Path "$_") })
	if ($MissingFiles.count -gt 0) {
		Write-Host (" ~ downloaded failed, missing: `n`t" + ($MissingFiles -join "`n`t")) -ForegroundColor red
		throw
	}
}

$TargetsToUpdate = @("$Target")
foreach ($UpdateTarget in $CustomGodotActiveTargets) {
	if ("$UpdateTarget" -NotIn $TargetsToUpdate) {
		$TargetsToUpdate = $TargetsToUpdate + "$UpdateTarget"
	}
}

try {
	foreach ($UpdateTarget in $TargetsToUpdate) {
		$IsMainTarget = $UpdateTarget -eq $Target
		$CurrentGodotMeta = Get-CustomGodotMeta -Target $UpdateTarget
		$CurrentGodotVersion = $CurrentGodotMeta.version
		$CustomGodotBinaries = Get-CustomGodotBinaries -Target $UpdateTarget
		$CustomGodotDebugSymbols = Get-CustomGodotDebugSymbols -Target $UpdateTarget
		$CustomGodotRequiredFiles = $CustomGodotBinaries
		if ($IsMainTarget -and $DebugSymbols) {
			$CustomGodotRequiredFiles += $CustomGodotDebugSymbols
		}
		$HasAllRequiredFiles = @($CustomGodotRequiredFiles | ?{ !(Test-Path $_) }).count -eq 0
		
		$NeedToRemove = $false
		$FilesToDownload = @($CustomGodotRequiredFiles | ?{ !(Test-Path $_) })
		if ($UpdateTarget -In $CustomGodotActiveTargets) {
			if ("$CurrentGodotVersion" -eq "$CustomGodotVersion") {
				Write-Host " ~ '$UpdateTarget' up to date"
				$NeedToRemove = $false
				if ($FilesToDownload.count -gt 0) {
					Write-Host " ~ but some files are missing"
				}
			} else {
				Write-Host " ~ '$UpdateTarget' needs an upgrade: '$CurrentGodotVersion' -> '$CustomGodotVersion'"
				$NeedToRemove = $true
				$FilesToDownload = $CustomGodotRequiredFiles
			}
		} else {
			Write-Host " ~ target '$UpdateTarget' not found"
			$NeedToRemove = $false
			$FilesToDownload = $CustomGodotRequiredFiles
		}

		$CustomGodotTargetDir = Get-CustomGodotTargetDir -Target $UpdateTarget
		if ($FilesToDownload.count -gt 0) {
			do {
				Write-Host " ~ do you want to download? (y/n): " -ForegroundColor yellow -NoNewLine
				$DownloadConfirmation = Read-Host
				if ("$DownloadConfirmation" -eq "n") {
					if (!$IsMainTarget -and (Test-Path "$CustomGodotTargetDir")) {
						do {
							Write-Host " ~ oki, do you want to just remove it? (deletes '$UpdateTarget') (y/n): " -ForegroundColor yellow -NoNewLine
							$RemoveConfirmation = Read-Host
							if ("$RemoveConfirmation" -eq "n") {
								Write-Host " ~ ok nvm bye :3 but you cant launch like this"
								pause
								exit -1
							}
						} until ("$RemoveConfirmation" -eq "y")
						$NeedToRemove = $true
						$FilesToDownload = @()
						break
					} else {
						Write-Host " ~ ok nvm bye :3 but you need it to launch"
						pause
						exit -1
					}
				}
			} until ("$DownloadConfirmation" -eq "y")
		}
		
		if ($NeedToRemove) {
			Write-Host " ~ removing $UpdateTarget (version: '$CurrentGodotVersion')"
			Remove-Item -Recurse -Force "$CustomGodotTargetDir" | Out-Null
			if (!$?) {
				throw
			}
		}
		
		if ($FilesToDownload.count -gt 0) {
			try {
				$NeedsNewBinaries = @($CustomGodotBinaries | ?{ $_ -in $FilesToDownload }).count -gt 0
				if ($NeedsNewBinaries) {
					DownloadGodotBins -Url (Get-CustomGodotBinariesUrl -Target $UpdateTarget) -Dir $CustomGodotTargetDir -ArchiveName "$UpdateTarget.7z" -ExpectedFiles $CustomGodotBinaries
				}
				
				$NeedsNewDebugSymbols = @($CustomGodotDebugSymbols | ?{ $_ -in $FilesToDownload }).count -gt 0
				if ($IsMainTarget -and $DebugSymbols -and $NeedsNewDebugSymbols) {
					DownloadGodotBins -Url (Get-CustomGodotDebugSymbolsUrl -Target $UpdateTarget) -Dir $CustomGodotTargetDir -ArchiveName "$UpdateTarget.debug_symbols.7z" -ExpectedFiles $CustomGodotDebugSymbols
				}
				
				Write-CustomGodotMeta -Target $UpdateTarget
			} catch {
				if (Test-Path "$CustomGodotTargetDir") {
					Remove-Item -Recurse -Force "$CustomGodotTargetDir" | Out-Null
				}
				throw
			}
		}
	}
} catch {
	Write-Host $_ -ForegroundColor red
	Write-Host " ~ uh oh, tell rune" -ForegroundColor red
	pause
	exit -1
}

Write-Host " ~ ur all set :3"

if ($DownloadOnly) {
	pause
	exit
}

$LogDir = "$ProjectRoot/logs/"
New-Item -ItemType "directory" -Force "$LogDir" | Out-Null
if (!$?) {
	pause
	exit -1
}

$CustomGodotBinary = (Get-CustomGodotBinaries -Target "$Target")[0]
$GodotArgs = @()
if ('' -ne $Project) {
	if (-not (Test-Path "$Project")) {
		Write-Host " ~ project doesnt exist: '$Project'" -ForegroundColor red
		exit -1
	}
	$Project = Resolve-Path $Project
	Write-Host " ~ project: $Project"
	$GodotArgs = @("`"$Project`"")
}
$GodotArgsStr = $GodotArgs -join ' '

# cleanup old logs
$OldLogThreshold = (Get-Date).AddDays(-1)
Get-ChildItem -Path "$LogDir" -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $OldLogThreshold } | Remove-Item -Force

$LogTimestamp = (Get-Date -Format o) -replace ":","-"
$LogFile = (Join-Path "$LogDir" "log$LogTimestamp.txt")
Write-Host " ~ log file: $LogFile"
Write-Host " ~ launching $($Target): $CustomGodotBinary $GodotArgsStr"
if ($Console) {
	Write-Host " ~ with console output"
}

# various attempts at getting the output of the CONSOLE exe AND child processes (more like windows jobs i think?) to stream to a file
# i think its impossible without changing the console exe
# this will at least work with the launched exe until you do anything that closes it (like clicking on reload current project)

# ! nvm i fucking did it !
# it only writes after everything is closed, but it catches everything

# packaged into a var so it works later when expanded
$ErrorActionPreferenceVar = "`$ErrorActionPreference"
$StartLogGodotCommand = {
	$ErrorActionPreferenceVar = 'Continue'
	Start-Transcript -IncludeInvocationHeader -Path "$LogFile"
	& "$CustomGodotBinary" $GodotArgsStr
	Stop-Transcript
}
$StartLogGodotCommandStr = $StartLogGodotCommand | Out-String
$StartLogGodotCommandStr = $ExecutionContext.InvokeCommand.ExpandString($StartLogGodotCommandStr)

if ($Console) {
	Invoke-Expression $StartLogGodotCommandStr
	pause
} else {
	$StartLogGodotCommandBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($StartLogGodotCommandStr))
	if ($Platform -eq 'windows') {
		cscript "$PSScriptRoot/RunNoWindow.vbs" "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NonInteractive -EncodedCommand $StartLogGodotCommandBase64" | Out-Null
	} elseif ($Platform -eq 'linuxbsd') {
		bash -c "nohup pwsh -ExecutionPolicy Bypass -NonInteractive -EncodedCommand $StartLogGodotCommandBase64 > /dev/null 2>&1 &"
	} else {
		Write-Host " ~ oops wrong platform '$Platform' .. how did we get here??" -ForegroundColor red
		exit -1
	}
	Start-Sleep -Milliseconds 1000
}

# $RunLogScriptBlock = {
	# $ErrorActionPreference = "Continue"
	# Start-Transcript -IncludeInvocationHeader -Path $args[0]
	# $InvokeArgs = [System.Collections.ArrayList]($args)
	# $InvokeArgs.RemoveAt(0)
	# & @InvokeArgs
	# Stop-Transcript
	# pause
# }

#$GodotArgsStr = $args
#& Invoke-Expression "& `"$CustomGodotBinary`" 2>&1 > `"$ProjectRoot/logs/latest.txt`""
#& "$PSScriptRoot/LaunchGodot.bat" "$CustomGodotConsoleBinary" "$ProjectRoot/logs/latest.txt"
#& cmd /C "start `"`" /B `"$CustomGodotBinary`" $args *> `"$LogFile`""
#cscript "$PSScriptRoot/PsRunNoWindow.vbs" "$PSScriptRoot/DoLaunchGodot.ps1"
#Start-Process -NoNewWindow -RedirectStandardOutput "$ProjectRoot/logs/latest.txt" "$CustomGodotBinary"
#PowerShell.exe -ExecutionPolicy remotesigned -File "$PSScriptRoot/DLaunchGodot.ps1"
#& "$CustomGodotBinary" 2>&1 > "$ProjectRoot/logs/latest.txt"



#& "$CustomGodotBinary" @args *> "$LogFile"
#& "$CustomGodotBinary" @args
# $job = Start-Job -ArgumentList (@("$LogFile", "$CustomGodotBinary") + $args) -ScriptBlock $RunLogScriptBlock | wait-job

# try {
	# receive-job $job -ErrorAction Stop
# } catch {
	# "err $_"
# }

#Start-Sleep -Milliseconds 1000

#pause
