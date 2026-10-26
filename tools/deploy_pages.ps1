# Publishes build/web to the gh-pages branch (GitHub Pages), keeping the custom domain (CNAME) and .nojekyll.
#   powershell -ExecutionPolicy Bypass -File tools/deploy_pages.ps1
$ErrorActionPreference = "Stop"
$tmp = Join-Path $env:TEMP "stick-legion-pages"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
git clone --quiet --branch gh-pages --single-branch https://github.com/cronustjy-sketch/stick-legion.git $tmp
Get-ChildItem $tmp -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
Get-ChildItem build/web -File | Where-Object { $_.Extension -ne ".import" } | Copy-Item -Destination $tmp
Copy-Item tools/pages/CNAME, tools/pages/.nojekyll -Destination $tmp -Force   # CNAME must be in every deploy or the domain is lost
Push-Location $tmp
git add -A
git commit -m "Web build" --quiet
git push --quiet origin gh-pages
Pop-Location
Write-Host "Published. Live at https://legion.cronuschores.xyz/"
