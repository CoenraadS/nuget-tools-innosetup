<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param (
    [Parameter(Position=0)]
	[string[]]$Tasks
	,
    [Parameter(Mandatory=$true)]
    [String]$Version
    )

# Bootstrap
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
	$ErrorActionPreference = 1
	if (!(Get-Command Invoke-Build -ErrorAction 0)) {
		Install-Module InvokeBuild -Scope CurrentUser -Force
		Import-Module InvokeBuild
	}
	return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

. $BuildRoot\HelperScripts.ps1

$innoSetupDir = "$BuildRoot\InnoSetup"
$downloadCachePath = "$BuildRoot\Downloads"
$installerPath = "$downloadCachePath\innosetup-$Version.exe"

$dotnetArgs=@(
    '--configuration'
    "Release"
    '--verbosity'
    'quiet'
    '/nologo' # Disable printing MSBuild version
    '-nodereuse:false' # Use -nodereuse:false to prevent deadlock https://github.com/dotnet/sdk/issues/9452
    )

task Clean-Dotnet {
    Run "dotnet" "clean $BuildRoot\src $dotnetArgs"
}

task Clean-InnoSetup {
    remove $innoSetupDir
}

task Clean Clean-Dotnet, Clean-InnoSetup

task Download-InnoSetup {
    mkdir $downloadCachePath -F | Out-Null
    Download-If-Not-Exist $installerPath "http://files.jrsoftware.org/is/6/innosetup-$Version.exe"
    Download-If-Not-Exist $downloadCachePath\ISCrypt.dll https://jrsoftware.org/download.php/iscrypt.dll
 }

task Install-InnoSetup Download-InnoSetup, { 
    mkdir $innoSetupDir -F | Out-Null
    Run $installerPath "/verysilent /allusers /dir=$innoSetupDir"
    Copy-Item $downloadCachePath\ISCrypt.dll -Destination $innoSetupDir\
    Remove-Item $innoSetupDir -Include "unins000.*", "Examples" -Recurse
}

task Pack {
    Run "dotnet" "pack $BuildRoot\src\InnoSetup.Cli.csproj -o $BuildRoot\nupkg /p:Version=$Version $dotnetArgs"
}

task Test {
    Set-Location $BuildRoot\Test
    mkdir tools -F | Out-Null
    Run "dotnet" "tool uninstall InnoSetup.Cli --tool-path tools" -ContinueOnError $True
    Run "dotnet" "tool install InnoSetup.Cli --tool-path tools"
    GetISCCPath
}

task . Clean, Install-InnoSetup, Pack, Test