<#	
	.NOTES
	===========================================================================
	 Created on:   	02/05/2017 12:32
	 Created by:   	Alessio Rocchi <arocchi@vmware.com>
	 Organization: 	VMware
	 Filename:     	Logging.ps1
	===========================================================================
	.DESCRIPTION
		Logging Interface and Implementation
#>

class Logging {
	Logging()
	{
		if ($this.GetType() -eq [Logging])
		{
			throw ("Class must be Implemented")
		}
	}
	
	[System.Void] Info([System.String]$message)
	{
		throw ("Method Must be implemented.")
	}
	
	[System.Void] Warning([System.String]$message)
	{
		throw ("Method Must be implemented.")
	}
	
	[System.Void] Error([System.String]$message)
	{
		throw ("Method Must be implemented.")
	}
	
	[System.Void] Critical([System.String]$message)
	{
		throw ("Method Must be implemented.")
	}
}

class FileLogger: Logging
{
	# Properties
	[System.String]$LogFile
	[int32]$maxFileSize = 512kb
	[int32]$Rotation = 1
	
	#Constructor
	FileLogger([System.String]$LogFile): base ()
	{
		$this.LogFile = $LogFile
	}
	
	hidden [boolean] isRoteable([System.Object]$fileItem)
	{
		if ($fileItem.Lenght -gt $this.maxFileSize)
		{
			return $true
		}
		return $false
	}
	
	hidden [System.Void] writeToFile([System.String]$message, [System.String]$timeStamp)
	{
		try
		{
			$ErrorActionPreference = "Stop"
			$TestLogSize = Get-Item $this.LogFile
		}
		catch
		{
			Write-Error("[{0}] Fail to get file object: {1}. Does it exists?" -f ($timeStamp, $this.LogFile))
		}
		finally
		{
			$ErrorActionPreference = 'Continue'
		}
		
		if ($this.isRoteable((Get-Item $this.LogFile)))
		{
			[System.String]$rotatedFile = ("{0}.{1}" -f ($this.LogFile, $this.Rotation))
			Write-Debug("[{0}] Performing log rotation on file: {1}" -f ($timeStamp, $rotatedFile))
			Add-Content $this.LogFile -value ("[{0}] Performing log rotation on file: {1}" -f ($timeStamp, $rotatedFile))
			Rename-Item -Path $this.LogFile -NewName $rotatedFile
			$this.Rotation++
		}
		Add-Content -Path $this.LogFile -Value ("[{0}] {1}" -f ($timeStamp, $message))
	}
	
	# Method Implementation
	[System.Void] Info([System.String]$message)
	{
		$timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		write-Debug("[{0}] {1}" -f ($timeStamp, $message))
		$this.writeToFile($message, $timeStamp)
	}
}