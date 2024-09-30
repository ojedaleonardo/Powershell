$volumes = aws ec2 describe-volumes --query "Volumes[*].{ID:VolumeId,Encrypted:Encrypted,State:State,Attachments:Attachments}" --output json | ConvertFrom-Json
$volumeList = $volumes | ForEach-Object {
    $InstanceDetails = if ($_.Attachments.Count -gt 0) {
        $instanceId = $_.Attachments[0].InstanceId
        $instanceInfo = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key=='Name'].Value | [0]}" --output json | ConvertFrom-Json
        
        if ($instanceInfo.Count -gt 0) {
            "$($instanceInfo[0].ID) ($($instanceInfo[0].Name))"
        } else {
            "Not attached"
        }
    } else {
        "Not attached"
    }
    
    [PSCustomObject]@{
        VolumeId   = $_.ID
        Encrypted  = $_.Encrypted
        State      = $_.State
        InstanceId = $InstanceDetails
    }
}

$csvPath = "volumes.csv"
"VolumeId,Encrypted,State,InstanceId" | Out-File -FilePath $csvPath -Encoding UTF8
$volumeList | Export-Csv -Path $csvPath -NoTypeInformation -Append -Encoding UTF8
