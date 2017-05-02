<#	
	.NOTES
	===========================================================================
	 Created on:   	02/05/2017 14:14
	 Created by:    Alessio Rocchi <arocchi@vmware.com>
	 Organization: 	VMware
	 Filename:     	vcConnector.ps1
	===========================================================================
	.DESCRIPTION
		Singleton to handle vCenter Connector
#>

class vcConnector: System.IDisposable
{
	[String]$Username
	[String]$Password
	[String]$vCenter
	[PSObject]$server
	
	static [vcConnector]$instance
	
	vcConnector($Username, $Password, $vCenter)
	{
		Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue | Out-Null
		
		$this.Username = $Username
		$this.Password = $Password
		$this.vCenter = $vCenter
		$this.connect()
	}
	
	vcConnector($vcCredential, $vCenter)
	{
		Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue | Out-Null
		
		$this.vcCredential = $vcCredential
		$this.vCenter = $vCenter
		$this.connect()
	}
	
	[void] hidden connect()
	{
		try
		{
			if ([String]::IsNullOrEmpty($this.Username) -or [String]::IsNullOrEmpty($this.Password))
			{
				$vcCredential = Get-Credential
				Connect-VIServer -Server $this.vCenter -Credential $this.vcCredential -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
			}
			else
			{
				Connect-VIServer -Server $this.vCenter -User $this.Username -Password $this.Password -WarningAction SilentlyContinue -ErrorAction Stop
			}
			Write-Debug("Connected to vCenter: {0}" -f $this.vCenter)
		}
		catch
		{
			Write-Error($Error[0].Exception.Message)
			exit
		}
	}
	
	[void] Dispose()
	{
		Write-Debug("Called Dispose Method of Instance: {0}" -f ($this))
		Disconnect-VIServer -WarningAction SilentlyContinue -Server $this.vCenter -Force -Confirm:$false | Out-Null
	}
	
	static [vcConnector] GetInstance()
	{
		if ([vcConnector]::instance -eq $null)
		{
			[vcConnector]::instance = [vcConnector]::new()
		}
		
		return [vcConnector]::instance
	}
}