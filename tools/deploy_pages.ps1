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
git -c user.name="cronustjy-sketch" -c user.email="cronustjy@gmail.com" commit -m "Web build" --quiet
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "git commit failed (nothing changed, or no identity)" }
git push --quiet origin gh-pages
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "git push failed" }
Pop-Location
Write-Host "Published. Live at https://legion.cronuschores.xyz/"
