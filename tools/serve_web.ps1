# Serves build/web on http://localhost:8080 for testing the Web export (correct MIME types for .wasm / .pck).
#   powershell -ExecutionPolicy Bypass -File tools/serve_web.ps1
param([int]$Port = 8080, [string]$Root = "build/web")
$root = (Resolve-Path $Root).Path
$types = @{ ".html" = "text/html"; ".js" = "application/javascript"; ".wasm" = "application/wasm"; ".pck" = "application/octet-stream";
            ".png" = "image/png"; ".svg" = "image/svg+xml"; ".json" = "application/json"; ".ico" = "image/x-icon"; ".wav" = "audio/wav" }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$Port/  (Ctrl+C to stop)"
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.LocalPath
    if ($path -eq "/") { $path = "/index.html" }
    $file = Join-Path $root ($path.TrimStart("/") -replace "/", "\")
    if (Test-Path $file -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $ctx.Response.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" })
        $ctx.Response.Headers.Add("Cache-Control", "no-store")
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
}
