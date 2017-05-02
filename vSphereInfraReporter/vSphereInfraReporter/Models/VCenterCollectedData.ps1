<#	
	.NOTES
	===========================================================================
	 Created on:   	02/05/2017 15:44
	 Created by:   	Alessio Rocchi <arocchi@vmware.com>
	 Organization: 	VMware
	 Filename:     	VCenterCollectedData.ps1
	===========================================================================
	.DESCRIPTION
		VCenterCollectedData
#>

."\ClusterPerformanceData.ps1"
."\HostDetailsData.ps1"

class VCenterCollectedData {
	[System.Collections.Generic.List[ClusterPerformanceData]]$ClusterPerformanceData
	[System.Collections.Generic.List[HostDetailsData]]$HostDetailsData
	
	VCenterCollectedData()
	{
		
	}
}