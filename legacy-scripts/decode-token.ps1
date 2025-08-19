# JWT Token Decoder
$token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0dXNlciIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzU0MDQxMzYwLCJleHAiOjE3NTQxMjc3NjB9.DHcFfS2bGvU7ANBF4FEaXz4YJ2EymYKxZTrt5nT6Jps"

# Split token parts
$parts = $token.Split('.')
$header = $parts[0]
$payload = $parts[1]
$signature = $parts[2]

# Decode payload (Base64URL)
$payloadPadded = $payload
while ($payloadPadded.Length % 4 -ne 0) {
    $payloadPadded += "="
}
$payloadDecoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payloadPadded.Replace('-', '+').Replace('_', '/')))

Write-Host "Token Payload:" -ForegroundColor Cyan
$payloadDecoded | ConvertFrom-Json | ConvertTo-Json

# Check expiration
$payloadObj = $payloadDecoded | ConvertFrom-Json
$exp = $payloadObj.exp
$currentTime = [int][double]::Parse((Get-Date -UFormat %s))

Write-Host "`nToken Analysis:" -ForegroundColor Yellow
Write-Host "Issued At (iat): $(Get-Date -UnixTimeSeconds $payloadObj.iat)"
Write-Host "Expires At (exp): $(Get-Date -UnixTimeSeconds $exp)"
Write-Host "Current Time: $(Get-Date)"
Write-Host "Is Expired: $($currentTime -gt $exp)"
Write-Host "Time to expiry: $(($exp - $currentTime) / 3600) hours"
