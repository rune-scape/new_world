Param(
	[string] $Platform,
	[string] $Arch = 'x86_64'
)

# can be: 'editor', 'template_debug.dev', 'template_release'
$CustomGodotDefaultTarget = 'editor'

if ('' -eq $Platform) {
	if (([System.Environment]::OSVersion.Platform) -eq "Win32NT") {
		$Platform = 'windows'
	} elseif (([System.Environment]::OSVersion.Platform) -eq "Unix") {
		$Platform = 'linuxbsd'
	} else {
		$Platform = ''
	}
}

if ('' -eq $Platform) {
	Write-Host " ~ couldnt detect platform, u can override it in $($global:MyInvocation.MyCommand.Definition)" -ForegroundColor red
	exit -1
}

# rune updates this
$CustomGodotVersion = '4.2.3.rc.custom_build.a45d9d793'
$CustomGodotBranch = 'rune-custom-4.2'

# dont change these
$CustomGodotValidPlatforms = @('windows', 'linuxbsd')
$CustomGodotValidTargets = @('editor', 'template_debug.dev', 'template_release')

$ProjectRoot = Resolve-Path (Join-Path "$PSScriptRoot" "..")

Write-Host "godot bins downloader! from rune!"
Write-Host " ~ project root: $ProjectRoot"
Write-Host " ~ version: $CustomGodotVersion"

if ($Platform -NotIn $CustomGodotValidPlatforms) {
	Write-Host " ~ invalid platform: '$Platform'" -ForegroundColor red
	exit -1
}
Write-Host " ~ platform: $Platform"
Write-Host " ~ arch: $Arch"

$BinDir = Join-Path "$ProjectRoot" "bin"
$CustomGodotDir = Join-Path "$BinDir" "godot"
$CustomGodotPlatformDir = Join-Path (Join-Path "$CustomGodotDir" "$Platform") "$Arch"

if (Test-Path "$CustomGodotPlatformDir") {
	$CustomGodotActiveTargets = Split-Path -Path (Join-Path "$CustomGodotPlatformDir" "*") -Leaf -Resolve | ?{ ("$_" -In $CustomGodotValidTargets) }
} else {
	$CustomGodotActiveTargets = @()
}
Write-Host " ~ active targets: $CustomGodotActiveTargets"

if ("$Platform" -eq 'windows') {
	$7zipExecutable = Join-Path "$BinDir" "7zr.exe"
	$GodotBinarySuffixes = @(
		".console.exe"
		".exe"
	)
	$GodotDebugSymbolSuffixes = @(
		".console.pdb"
		".pdb"
	)
} elseif ("$Platform" -eq 'linuxbsd') {
	$7zipExecutable = Join-Path "$BinDir" "7zz"
	$GodotBinarySuffixes = @(
		""
	)
	$GodotDebugSymbolSuffixes = @(
		".debugsymbols"
	)
}

if (-not (Test-Path $7zipExecutable)) {
	Write-Host " ~ could not find 7zip at '$7zipExecutable'" -ForegroundColor red
	exit -1
}
Write-Host " ~ 7zip: $7zipExecutable"

function Validate-CustomGodotTarget {
	Param([string] $Target)
	if ($Target -NotIn $CustomGodotValidTargets) {
		Write-Host " ~ invalid target: '$CustomGodotTarget'" -ForegroundColor red
		throw
	}
}

function Get-CustomGodotTargetDir {
	Param([string] $Target)
	Validate-CustomGodotTarget($Target)
	return Join-Path "$CustomGodotPlatformDir" $Target
}

function Get-CustomGodotBinaries {
	Param([string] $Target)
	if ('windows' -eq $Platform) {
		Write-Output -NoEnumerate @($GodotBinarySuffixes | %{ Join-Path (Get-CustomGodotTargetDir -Target $Target) "godot.$Platform.$Target.$Arch.llvm.$CustomGodotBranch$_" })
	} elseif ('linuxbsd' -eq $Platform) {
		Write-Output -NoEnumerate @($GodotBinarySuffixes | %{ Join-Path (Get-CustomGodotTargetDir -Target $Target) "godot.$Platform.$Target.$Arch.$CustomGodotBranch$_" })
	}
}

function Get-CustomGodotDebugSymbols {
	Param([string] $Target)
	if ('windows' -eq $Platform) {
		Write-Output -NoEnumerate @($GodotDebugSymbolSuffixes | %{ Join-Path (Get-CustomGodotTargetDir -Target $Target) "godot.$Platform.$Target.$Arch.llvm.$CustomGodotBranch$_" })
	} elseif ('linuxbsd' -eq $Platform) {
		Write-Output -NoEnumerate @($GodotDebugSymbolSuffixes | %{ Join-Path (Get-CustomGodotTargetDir -Target $Target) "godot.$Platform.$Target.$Arch.$CustomGodotBranch$_" })
	}
}

function Get-CustomGodotBinariesUrl {
	Param([string] $Target)
	Validate-CustomGodotTarget($Target)
	return "http://godotbins.boywaste.net:58985/$CustomGodotVersion/$Platform/$Arch/$Target.7z"
}

function Get-CustomGodotDebugSymbolsUrl {
	Param([string] $Target)
	Validate-CustomGodotTarget($Target)
	return "http://godotbins.boywaste.net:58985/$CustomGodotVersion/$Platform/$Arch/$Target.debug_symbols.7z"
}

function Get-CustomGodotMeta {
	Param([string] $Target)
	$CustomGodotMetaFile = Join-Path (Get-CustomGodotTargetDir -Target $Target) 'meta.txt'
	if (-not (Test-Path "$CustomGodotMetaFile")) {
		return @{
			version = 'unknown';
		}
	}
	return Get-Content "$CustomGodotMetaFile" -Raw | ConvertFrom-Json
}

function Write-CustomGodotMeta {
	Param([string] $Target, $Data = @{})
	$CustomGodotMetaFile = Join-Path (Get-CustomGodotTargetDir -Target $Target) 'meta.txt'
	$Data['version'] = $CustomGodotVersion
	$Data | ConvertTo-Json | Set-Content -Path "$CustomGodotMetaFile"
}

exit
