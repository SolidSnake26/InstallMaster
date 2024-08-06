class NetworkChecker {
	
	[bool] CheckConnectionToHost([string]$hostName) {
		$ping = New-Object System.Net.NetworkInformation.Ping
		$timeout = 1000  # Timeout in milliseconds

		try {
			$pingReply = $ping.Send($hostName, $timeout)
			if ($pingReply.Status -eq 'Success') { return $true } # Connection successful
			else { Write-Output "Failed to connect to $hostName."; return $false }# Connection failed
		}
		catch {
			Write-Output "Failed to connect to $hostName. Error: $_"
			return $false  # Connection failed
		}
	}	
	[bool] CheckConnectionWithRetryPrompt([string]$hostName) {
		$retryCount = 0
        
		do {
			$connectionResult = $this.CheckConnectionToHost($hostName)
            
			if ($connectionResult) { return $true } # Connection successful
			
			else {
				$retryCount++
                
				$wshell = New-Object -ComObject WScript.Shell
				$userChoice = $wshell.Popup("Failed to connect to $hostName. Retry?", 0, "Connection Retry", 4)
                
				if ($userChoice -eq 6) { Write-Output "Retrying connection to $hostName..." }
				else {
					Write-Output "User cancelled the retry."
					return $false  # Connection failed after user cancellation
				}
			}
		} while ($retryCount -lt 3)

		# Write-Output "Failed to connect to $hostName after 3 retries."
		return $false  # Connection failed after retries
	}
	[bool] CheckConnectionToHost([string]$hostName, [int]$port) {
		try {
			$client = New-Object System.Net.Sockets.TcpClient
			$client.Connect($hostName, $port)
            
			if ($client.Connected) {
				Write-Output "Connection to $hostName on port $port successful."
				$client.Close()
				return $true
			}
			else {
				Write-Output "Failed to connect to $hostName on port $port."
				$client.Close()
				return $false
			}
		}
		catch {
			Write-Output "Error occurred while trying to connect to $hostName on port $port : $_"
			return $false
		}
	}
}

class NetworkMounts {

	[bool]ValidateNetworkPathFormat([string]$NetworkPath) {
		try {
			$uri = New-Object System.Uri($NetworkPath) -ErrorAction Stop
			
			if ($uri -ne $null -and $uri.Scheme -eq "file" -and $uri.Host -ne "" -and $uri.Segments.Count -ge 2) {
				Write-Debug "User entered a valid network path format: $NetworkPath"
				return $true
			} else {
				Write-Error "User did not enter a valid network path format"
				return $false
			}		
		}
		catch {
			Write-Error $_.Exception.Message
			throw $_.Exception  # Re-throw the terminating error
		}	
	}

	MountNetworkDrive([string]$NetworkPath, [string]$User, [string]$Password) {
		[hashtable]$MountStatus = [ordered]@{ 'Error' = $null; 'Status' = $null; 'Drive' = $null }
		[bool]$validatePath = $false
        
		try {
			try {
				$validatePath = ValidateNetworkPathFormat($NetworkPath)
			}
			catch {
				<#Do this if a terminating exception happens#>
			}
            
			$PrevousMount = Get-SmbMapping -RemotePath $NetworkPath -ErrorAction SilentlyContinue
			if ($PrevousMount -and $PrevousMount.Status -eq 'OK') 
			{ Remove-SmbMapping -RemotePath $NetworkPath -Force -ErrorAction SilentlyContinue }
		}
		catch {           

		}

		try {
			#$networkChecker = [NetworkChecker]::new()			
		}
		catch {
            
		}
	}	
}


#<#
# Create an instance of the NetworkChecker class
#$networkChecker = [NetworkChecker]::new()

# Test connection with retry prompt
#$hostToCheck = "localhost"
#$connectionResult = $networkChecker.CheckConnectionWithRetryPrompt($hostToCheck)

# Test checking connection to SQL Server with hostname and port
#$serverName = "localhost"
#$port = 1433

#if ($connectionResult) { Write-Output "Successfully connected to $hostToCheck." }
#else { Write-Output "Failed to connect to $hostToCheck after retries." }
#if ($networkChecker.CheckConnectionToHost($serverName, $port)) {
#	Write-Output "SQL Server on $serverName is available on port $port."
#}
#else {
#	Write-Output "SQL Server on $serverName is not available on port $port."
#}

##>

$nwMount = [NetworkMounts]::new()
if ($nwMount.ValidateNetworkPathFormat("\\192.168.2.2")) {
	Write-Host "OK"
}
else {
	Write-Host "Not OK"
}