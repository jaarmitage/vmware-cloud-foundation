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

$xmlLoc = '.\4_Policy-Business_Application_Monitoring.xml'

$xmlWriter = Get-Content -Path $xmlLoc
$xmlWriter.Formatting = "Indented"
$xmlWriter.Indentation = 4
$xmlAttrSearch = "Business Application Monitoring"
$parentElement = $xmlWriter.SelectSingleNode("//Policy[@name='$xmlAttrSearch']/PackageSettings")
If ($parentElement) {
    ForEach ($i in $responseData.'resource-kinds'.'resource-kind'.key) 
    { 
        $statkeys = Invoke-RestMethod -Method Get -Uri "$AriaOperationsUrl/api/adapterkinds/APPOSUCP/resourcekinds/$i/statkeys" -ContentType "application/json" -Headers $headers; 
        Write-Host "Adapter Kind: $i"; 
        $statn = @()
        ForEach ($n in $statkeys.'resource-kind-attributes'.'resource-kind-attribute') 
        { 
            $k = $n.key
            If ($k -match "badge|compliance") 
            { 
                $o = [PSCustomObject]@{
                    key = $k
                }
                Write-Host $o.key
                $statn += $o 
            } 
        }

        If ($statn.Count -gt 0) {
            $xmlWriter.WriteStartElement("Metrics")
            $xmlWriter.WriteAttributeString("adapterKind", "APPOSUCP")
            $xmlWriter.WriteAttributeString("resourceKind", $i)
            ForEach ($n in $statn) {
                $xmlWriter.WriteStartElement("Metric")
                $xmlWriter.WriteAttributeString("enabled", "false")
                $xmlWriter.WriteAttributeString("id", $n.key)
                $xmlWriter.WriteEndElement()
            }
            $xmlWriter.WriteEndElement()
        }
    }
    $xmlWriter.Save($xmlLoc)
}
$xmlWriter.Close()
#$metrics = Invoke-RestMethod -Uri "$AriaOperationsUrl/api/adapterkinds/APPOSUCP/resourcekinds/$i/stattype" -Method Get -Headers $headers