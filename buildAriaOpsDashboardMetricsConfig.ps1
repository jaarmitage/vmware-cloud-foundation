# Replace with your Aria Operations URL
$AriaOperationsUrl = "https://tnsc-vsmvop-01.ipa.constellab.com/suite-api" 

Function Get-AuthToken {
    # Replace with your credentials
    $username = "admin"
    $password = 'password'

    # Create the request body
    $body = @{
        username = $username
        password = $password
    }

    $jsonBody = $body | ConvertTo-Json

    # Acquire the token
    $tokenResponse = Invoke-RestMethod -Uri "$AriaOperationsUrl/api/auth/token/acquire" -Method Post -Body $jsonBody -ContentType "application/json"

    # Extract the token
    return $tokenResponse.'auth-token'.token
}
$token = Get-AuthToken
$headers = @{
    Authorization = "vRealizeOpsToken $token"
}

$responseData = Invoke-RestMethod -Uri "$AriaOperationsUrl/api/adapterkinds/APPOSUCP/resourcekinds" -Method Get -Headers $headers
ForEach ($i in $responseData.'resource-kinds'.'resource-kind'.key) 
{ 
    $statkeys = Invoke-RestMethod -Method Get -Uri "$AriaOperationsUrl/api/adapterkinds/APPOSUCP/resourcekinds/$i/statkeys" -ContentType "application/json" -Headers $headers; 
    Write-Host "Adapter Kind: $i"; 
    ForEach ($n in $statkeys.'resource-kind-attributes'.'resource-kind-attribute'.key) 
    { 
        If ($n -notmatch "badge|compliance" -And $n -notmatch "System Attributes") 
        { 
            Write-Host "$n"; 
        } 
    } 
}
#$metrics = Invoke-RestMethod -Uri "$AriaOperationsUrl/api/adapterkinds/APPOSUCP/resourcekinds/$i/stattype" -Method Get -Headers $headers