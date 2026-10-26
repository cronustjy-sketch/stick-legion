# Exports the Web build to build/web (needs the Godot 4.7.2 export templates installed).
#   powershell -ExecutionPolicy Bypass -File tools/export_web.ps1 -Godot "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
param([string]$Godot = "godot")
New-Item -ItemType Directory -Force build/web | Out-Null
& $Godot --headless --path . --export-release "Web" build/web/index.html
Get-ChildItem build/web | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 2) } }
