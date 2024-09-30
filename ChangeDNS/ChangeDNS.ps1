$NewDNSAddresses = "10.0.0.1","10.0.0.2"
$OldDNSAddress = "192.168.10.0", "192.168.10.1"

Function Write-Log{
    param(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
        [alias("message")]
        [string]$LogData,
        [Parameter(Mandatory=$False,Position=1)]
        [alias("foregroundcolor","FGC")]
        [string]$FGColor="white",
        [Parameter(Mandatory=$False,Position=2)]
        [alias("backgroundcolor","BGC")]
        [string]$BGColor="black"
        )
 
    $LogData = ((Get-Date -Format o) + " " + $LogData)
    add-content $Logfile $LogData
    Write-Host $LogData -foregroundcolor $FGColor -backgroundcolor $BGColor
}

Function Select-Folder {
    param(
        [Parameter(Mandatory=$True,Position=0)]
		[string[]]$Description        
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $SelectFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $SelectFolderDialog.Description = $Description
    $SelectFolderDialog.ShowDialog() | Out-Null
    $SelectFolderDialog.SelectedPath
}

Function Get-FileName {
    param(
        [Parameter(Mandatory=$True,Position=0)]
		[alias("directory")]
		[string[]]$initialdirectory        
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialdirectory
    $OpenFileDialog.Filter = "CSV (*.CSV)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}
 
$TimeStamp = (Get-Date -Format o |forEach-Object {$_ -replace ":","."}) + "-"
$LogName = $MyInvocation.MyCommand.Name.TrimEnd("ps1") + "log"
$LogPath = $PSScriptRoot
$LogFile = $LogPath + $Timestamp + $LogName

Write-Log "Script Successfully initialized"

$Servers = Import-CSV $(Get-FileName C:\temp)

Write-Log "Successully Imported Server List, begining to process DNS Server changes"

ForEach ($Server in $Servers){
    try{
        $Cimsession = new-cimsession -ComputerName $($Server.ServerName) -OperationTimeoutSec 10 -ErrorAction:Stop
        $ServerAddresses = Get-DnsClientServerAddress -AddressFamily IPv4 -CimSession $Cimsession
        ForEach ($ServerAddress in $ServerAddresses){
            
                Write-log "Found Address...need to change, Changing interface ($($ServerAddress.InterfaceIndex)), Interface Alias ($($ServerAddress.InterfaceAlias))"
                #Fixed variable that was referenced but not set. Temp fix until I can clean up the CIM session.
                Set-DnsClientServerAddress -InterfaceIndex $($ServerAddress.InterfaceIndex) -Addresses $NewDNSAddresses -CimSession $Cimsession
                Write-Log "Changed DNS Servers on ($($Server.ServerName) to ($NewDNSAddresses)"            
        }
    }
    catch{
        write-log "Server not found"
    }
}
Write-Log "Exiting Script"
