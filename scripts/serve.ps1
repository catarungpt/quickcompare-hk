# Minimal static file server for the QuickCompare HK site.
# No Node or Python needed. Serves ../site on http://localhost:5173/.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/serve.ps1
#
param(
  [int]$Port = 5173
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\site")).Path
$rootPrefix = $root.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar

$mime = @{
  ".html"        = "text/html; charset=utf-8"
  ".css"         = "text/css; charset=utf-8"
  ".js"          = "text/javascript; charset=utf-8"
  ".json"        = "application/json; charset=utf-8"
  ".svg"         = "image/svg+xml; charset=utf-8"
  ".webmanifest" = "application/manifest+json; charset=utf-8"
  ".woff2"       = "font/woff2"
  ".png"         = "image/png"
  ".jpg"         = "image/jpeg"
  ".jpeg"        = "image/jpeg"
  ".gif"         = "image/gif"
  ".ico"         = "image/x-icon"
  ".txt"         = "text/plain; charset=utf-8"
}

function Send-Response {
  param(
    [System.IO.Stream]$Stream,
    [int]$Status,
    [string]$StatusText,
    [string]$ContentType,
    [byte[]]$Body,
    [bool]$HeadOnly
  )

  $headers = "HTTP/1.1 $Status $StatusText`r`n" +
             "Content-Type: $ContentType`r`n" +
             "Content-Length: $($Body.Length)`r`n" +
             "Cache-Control: no-store`r`n" +
             "Connection: close`r`n`r`n"
  $headerBytes = [Text.Encoding]::ASCII.GetBytes($headers)
  $Stream.Write($headerBytes, 0, $headerBytes.Length)
  if (-not $HeadOnly) {
    $Stream.Write($Body, 0, $Body.Length)
  }
  $Stream.Flush()
}

$listener = $null
for ($attempt = 0; $attempt -lt 8; $attempt++) {
  $tryPort = $Port + $attempt
  try {
    $candidate = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $tryPort)
    $candidate.Start()
    $listener = $candidate
    $Port = $tryPort
    break
  } catch {
    if ($attempt -eq 7) {
      Write-Error "Could not bind a port between $Port and $($Port + 7)."
      exit 1
    }
  }
}

Write-Host ""
Write-Host "  QuickCompare HK preview" -ForegroundColor Green
Write-Host "  http://localhost:$Port/" -ForegroundColor Cyan
Write-Host "  Serving $root"
Write-Host "  Press Ctrl+C to stop."
Write-Host ""

while ($true) {
  $client = $listener.AcceptTcpClient()
  $client.ReceiveTimeout = 10000

  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader(
      $stream,
      [System.Text.Encoding]::ASCII,
      $false,
      1024,
      $true
    )

    $requestLine = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($requestLine)) {
      continue
    }

    while ($true) {
      $line = $reader.ReadLine()
      if ($null -eq $line -or $line -eq "") {
        break
      }
    }

    $parts = $requestLine.Split(" ")
    if ($parts.Length -lt 2) {
      continue
    }

    $method = $parts[0].ToUpperInvariant()
    $rawPath = $parts[1]
    $headOnly = $method -eq "HEAD"

    if ($method -ne "GET" -and -not $headOnly) {
      $body = [Text.Encoding]::UTF8.GetBytes("Method not allowed")
      Send-Response -Stream $stream -Status 405 -StatusText "Method Not Allowed" -ContentType "text/plain; charset=utf-8" -Body $body -HeadOnly $false
      continue
    }

    $urlPath = ($rawPath -split "\?")[0]
    $urlPath = [Uri]::UnescapeDataString($urlPath)
    if ($urlPath -eq "/" -or $urlPath -eq "") {
      $urlPath = "/index.html"
    }

    $relative = $urlPath.TrimStart("/").Replace("/", [IO.Path]::DirectorySeparatorChar)
    $filePath = [IO.Path]::GetFullPath((Join-Path $root $relative))

    if ($filePath -ne $root -and -not $filePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
      $body = [Text.Encoding]::UTF8.GetBytes("Forbidden")
      Send-Response -Stream $stream -Status 403 -StatusText "Forbidden" -ContentType "text/plain; charset=utf-8" -Body $body -HeadOnly $headOnly
      continue
    }

    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
      $body = [Text.Encoding]::UTF8.GetBytes("Not found: $urlPath")
      Send-Response -Stream $stream -Status 404 -StatusText "Not Found" -ContentType "text/plain; charset=utf-8" -Body $body -HeadOnly $headOnly
      continue
    }

    $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
    $contentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { "application/octet-stream" }
    $body = [IO.File]::ReadAllBytes($filePath)

    Send-Response -Stream $stream -Status 200 -StatusText "OK" -ContentType $contentType -Body $body -HeadOnly $headOnly

    if ($urlPath -ne "/index.html") {
      Write-Host ("  {0} {1}  {2:N0} KB" -f $method, $urlPath, ($body.Length / 1KB)) -ForegroundColor DarkGray
    }
  } catch {
    Write-Host ("  request failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
  } finally {
    $client.Close()
    $client.Dispose()
  }
}
