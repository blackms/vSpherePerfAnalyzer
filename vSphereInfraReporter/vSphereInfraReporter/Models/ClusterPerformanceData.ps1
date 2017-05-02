<#	
	.NOTES
	===========================================================================
	 Created on:   	02/05/2017 15:43
	 Created by:   	Alessio Rocchi <arocchi@vmware.com>
	 Organization: 	VMware
	 Filename:     	ClusterPerformanceData.ps1
	===========================================================================
	.DESCRIPTION
		ClusterPerformanceData
#>

class ClusterPerformanceData
{
	# Properties
	[System.String]$cluster
	[System.String]$vCenter
	[System.String]$state
	[float]$pSocket = 0
	[float]$pCore = 0
	[int]$logicalCpu = 0
	[int]$vCpu = 0
	[float]$cpuRatioRaw
	[System.String]$cpuRatio
	[float]$avgMaxCpu = 0
	[int]$maxCpu = 0
	[int]$minCpu = 0
	[int]$pRam = 0
	[int]$vRam = 0
	[float]$ramRatioRaw = 0
	[string]$ramRatio
	[float]$avgRam = 0
	[float]$maxRam = 0
	[float]$minRam = 0
	[int]$vms = 0
	
	ClusterPerformanceData()
	{
		
	}
}