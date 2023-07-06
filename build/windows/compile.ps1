$CurrentDir = Get-Location
$CompileScriptPath = Get-Item $PSScriptRoot
$RootDir = ($CompileScriptPath).Parent.Parent.FullName
$ScriptingDir = Join-Path $RootDir "addons\sourcemod\scripting" -Resolve
$OutputDir = Join-Path $RootDir "addons\sourcemod\plugins\franug_jailbreak"
$SMCompilerRoot = "build\windows\sourcemod-1.10.0"
$SMCompiler = Join-Path $RootDir "$SMCompilerRoot\spcomp.exe" -Resolve

if (!(Test-Path -PathType Container $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir
}

#$SourceFiles = @(
#  "anticamp.sp", "armas_jailbreak.sp", "franug_captain.sp", 
#  "franug_jailbreak.sp", "jailbreak_escondite.sp", "jailbreak_fd.sp", 
#  "jailbreak_ff.sp", "jailbreak_hideweapons.sp", "jailbreak_hud.sp", 
#  "jailbreak_lr.sp", "jailbreak_menu.sp", "jailbreak_noct.sp", "jailbreak_normas.sp", 
#  "jailbreak_noscope.sp", "jailbreak_open.sp", "jailbreak_pilla.sp", 
#  "jailbreak_rondas.sp", "jailbreak_war.sp", "jailbreak_wartotal.sp", 
#  "jailbreak_zombies.sp", "jb_flashbang.sp", "jb_glock.sp", "jb_hp.sp", "jb_p90.sp", 
#  "jb_usp.sp", "jb_velocity.sp", "jb_wincredits.sp", "jb_zeus.sp", "muter.sp", 
#  "noblock.sp", "oscuridad.sp", "shortsprint.sp"
#)

$SourceFiles = @(
  "jb_wincredits.sp"
)

$IncludeList = @(
  "addons\sourcemod\scripting\include",
  "build\include",
  "$SMCompilerRoot\include"
)

# Add include directories to param list
$Params = [System.Collections.ArrayList]@()
foreach ($Path in $IncludeList) {
  $AbsolutePath = Join-Path $RootDir $Path
  $null = $Params.Add("-i$AbsolutePath")
}

Set-Location $ScriptingDir

try {
  foreach ($FilePath in $SourceFiles) {
    $AbsolutePath = Join-Path $ScriptingDir $FilePath -Resolve
    $ParentPath = Join-Path $OutputDir (Split-Path -Path $FilePath)
    
    if (!(Test-Path -PathType Container $ParentPath)) {
      New-Item -ItemType Directory -Path $ParentPath
    }
    
    $OutputPath = Join-Path $OutputDir ($FilePath.Replace(".sp", ".smx"))
    & $SMCompiler $Params $AbsolutePath "-o$OutputPath"
  }
}
catch {
  Write-Host $_
  Write-Host $_.ScriptStackTrace
}
finally {
  Set-Location $CurrentDir
}

Pause