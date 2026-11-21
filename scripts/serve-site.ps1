# Minimal static file server for the QuickCompare site.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve-site.ps1
# Then open http://localhost:8765/

$root = Split-Path -Parent $PSScriptRoot
$site = Join-Path $root "site"
$port = 8765

Add-Type -AssemblyName System.IO.Compression | Out-Null

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()
Write-Host "Serving $site on http://localhost:$port/"

$types = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml"
  ".webmanifest" = "application/manifest+json"
  ".woff2" = "font/woff2"
  ".woff" = "font/woff"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".ico" = "image/x-icon"
}

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.LocalPath.TrimStart("/")
    if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
    $file = Join-Path $site $path

    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = $types[$ext]
      if (-not $ct) { $ct = "application/octet-stream" }
      $ctx.Response.ContentType = $ct
      $ctx.Response.Headers.Add("Cache-Control", "no-cache")

      # Gzip text payloads. The 30 MB index is served eight times faster this way.
      $accept = $ctx.Request.Headers["Accept-Encoding"]
      if ($bytes.Length -gt 4096 -and $accept -and $accept.Contains("gzip") -and $ext -in @(".json", ".js", ".css", ".html", ".svg")) {
        $ms = New-Object System.IO.MemoryStream
        $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress, $true)
        $gz.Write($bytes, 0, $bytes.Length)
        $gz.Dispose()
        $bytes = $ms.ToArray()
        $ms.Dispose()
        $ctx.Response.AddHeader("Content-Encoding", "gzip")
      }

      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("Not found")
      $ctx.Response.ContentLength64 = $msg.Length
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $ctx.Response.Close()
  } catch {
    break
  }
}
