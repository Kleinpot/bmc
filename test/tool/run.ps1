param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $FlutterArgs
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $projectRoot '.env'

$values = @{}
if (Test-Path -LiteralPath $envPath) {
  foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^\s*(?:#|$)') {
      continue
    }
    if ($line -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
      throw 'Invalid line in .env; expected KEY=VALUE.'
    }

    $name = $matches[1]
    $value = $matches[2]
    if ($value.Length -ge 2 -and
        (($value.StartsWith('"') -and $value.EndsWith('"')) -or
         ($value.StartsWith("'") -and $value.EndsWith("'")))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    $values[$name] = $value
  }
}

$supabaseUrl = if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
  $env:SUPABASE_URL
} elseif ($values.ContainsKey('SUPABASE_URL') -and -not [string]::IsNullOrWhiteSpace($values['SUPABASE_URL'])) {
  $values['SUPABASE_URL']
} else {
  'https://acihoqulcvgsibgmvrfj.supabase.co'
}
$supabaseAnonKey = if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY)) {
  $env:SUPABASE_ANON_KEY
} elseif (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_PUBLISHABLE_KEY)) {
  $env:SUPABASE_PUBLISHABLE_KEY
} elseif ($values.ContainsKey('SUPABASE_ANON_KEY') -and -not [string]::IsNullOrWhiteSpace($values['SUPABASE_ANON_KEY'])) {
  $values['SUPABASE_ANON_KEY']
} elseif ($values.ContainsKey('SUPABASE_PUBLISHABLE_KEY') -and -not [string]::IsNullOrWhiteSpace($values['SUPABASE_PUBLISHABLE_KEY'])) {
  $values['SUPABASE_PUBLISHABLE_KEY']
} else {
  'sb_publishable_IL5f8sscSAFX4R4mEpGo8A_zx95WKIM'
}

$defines = @(
  "--dart-define=SUPABASE_URL=$supabaseUrl"
  "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
)

if ($FlutterArgs.Count -eq 0) {
  $FlutterArgs = @('run')
}

Push-Location $projectRoot
try {
  & flutter @FlutterArgs @defines
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}
