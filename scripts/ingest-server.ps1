# Local ingest server used by the browser crawlers.
#
# POST /ingest?chunk=NAME   save the posted JSON to data/raw/pns/chunk-NAME.json
# GET  /candidates?store=X  serve data/raw/pns/candidates-X.json
# GET  /status              list saved chunk files
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\ingest-server.ps1

$root = Split-Path -Parent $PSScriptRoot
$rawDir = Join-Path $root "data\raw\pns"
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8766/")
$listener.Prefixes.Add("http://127.0.0.1:8766/")
$listener.Start()
Write-Host "Ingest server on http://127.0.0.1:8766/"

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $res.AddHeader("Access-Control-Allow-Origin", "*")
    $res.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $res.AddHeader("Access-Control-Allow-Headers", "Content-Type")

    if ($req.HttpMethod -eq "OPTIONS") {
      $res.StatusCode = 204
      $res.Close()
      continue
    }

    if ($req.HttpMethod -eq "POST" -and $req.Url.AbsolutePath -eq "/ingest") {
      $chunk = $req.QueryString["chunk"]
      if (-not $chunk) { $chunk = "unknown" }
      $chunk = $chunk -replace '[^A-Za-z0-9._-]', '_'
      $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd()
      $reader.Close()
      $file = Join-Path $rawDir ("chunk-{0}.json" -f $chunk)
      [System.IO.File]::WriteAllText($file, $body, (New-Object System.Text.UTF8Encoding($false)))
      $res.StatusCode = 200
      $res.ContentType = "application/json"
      $out = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true,"bytes":' + $body.Length + '}')
      $res.ContentLength64 = $out.Length
      $res.OutputStream.Write($out, 0, $out.Length)
      $res.Close()
      continue
    }

    if ($req.HttpMethod -eq "GET" -and $req.Url.AbsolutePath -eq "/candidates") {
      $store = $req.QueryString["store"]
      $file = Join-Path $rawDir ("candidates-{0}.json" -f $store)
      if (Test-Path $file) {
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $res.StatusCode = 200
        $res.ContentType = "application/json; charset=utf-8"
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $res.StatusCode = 404
      }
      $res.Close()
      continue
    }

    if ($req.HttpMethod -eq "GET" -and $req.Url.AbsolutePath -eq "/status") {
      $files = Get-ChildItem $rawDir -Filter *.json | Sort-Object Name
      $json = @{ chunks = @($files | ForEach-Object { $_.Name }); count = $files.Count } | ConvertTo-Json
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
      $res.StatusCode = 200
      $res.ContentType = "application/json"
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    $res.StatusCode = 404
    $res.Close()
  } catch {
    break
  }
}
