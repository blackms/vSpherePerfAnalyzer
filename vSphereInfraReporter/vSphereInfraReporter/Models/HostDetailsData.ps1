<#	
	.NOTES
	===========================================================================
	 Created on:   	02/05/2017 15:43
	 Created by:   	Alessio Rocchi <arocchi@vmware.com>
	 Organization: 	VMware
	 Filename:     	HostDetailsData.ps1
	===========================================================================
	.DESCRIPTION
		HostDetailsData
#>

class HostDetailsData
{
	[System.String]$vCenter
	[System.String]$description
	[System.String]$cluster
	[System.String]$host
	[System.String]$type
	[System.String]$state
	[System.String]$pSocket
	[System.String]$pCore
	[System.String]$LogicalCPU
	[System.String]$vCPU
	[System.String]$cpuRatio
	[System.String]$cpuRatioRaw
	[System.String]$avgCPU
	[System.String]$maxCPU
	[System.String]$minCPU
	[int]$pRam
	[int]$vRam
	[System.String]$usgRam
	[System.String]$avgRam
	[System.String]$maxRam
	[System.String]$minRam
	[int]$vms
	
	HostDetailsData()
	{
		
	}
}