<#
	.SYNOPSIS
		A brief description of the vSpherePerf.ps1 file.
	
	.DESCRIPTION
		vSphere Performance Collector
	
	.PARAMETER vCenterFilePath
		Define the file containing the vCenters list
	
	.PARAMETER LogFile
		Path for the Log file
	
	.NOTES
		===========================================================================
		Created on:   	27/04/2017 12:08
		Author:         Alessandro De Vecchi <adevecchi@vmware.com>
		Author2:     	Alessio Rocchi <arocchi@vmware.com>
		Organization: 	VMware
		Filename:     	vSpherePerf.ps1
		===========================================================================
#>
[CmdletBinding(ConfirmImpact = 'None',
			   SupportsShouldProcess = $false)]
param
(
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   ValueFromRemainingArguments = $false,
			   Position = 0,
			   HelpMessage = 'Define the file containing the vCenters list')]
	[ValidateNotNullOrEmpty()]
	[System.String]$vCenterFilePath,
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   ValueFromRemainingArguments = $false,
			   Position = 1,
			   HelpMessage = 'Path for the Log file')]
	[AllowNull()]
	[AllowEmptyString()]
	[System.String]$LogFile
)

# Import core Modules
."Core\Logging.ps1"
."Core\vcConnector.ps1"
."Core\BackgroundJob.ps1"
."Models\ClusterPerformanceData.ps1"
."Models\HostDetailsData.ps1"

<#
	.SYNOPSIS
		Performance Retriever Core Logic
	
	.DESCRIPTION
		Given a vCenter Name, this function retrieve all the performances and return them.
	
	.PARAMETER vCenterName
		Name of the vCenter
#>
function RetrieveVCenterPerformances
{
	[CmdletBinding(SupportsShouldProcess = $false)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$vCenterName,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$vCenterUserName,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[ValidateNotNullOrEmpty()]
		[String]$vCenterPassword,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[AllowNull()]
		[String]$vCenterDescription,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[AllowNull()]
		[Logging]$Logger
	)
	
	Begin
	{
		
	}
	Process
	{
		$Logger.Info("Connecting to vCenter: {0}" -f ($vCenterName))
		$vc = [vcConnector]::new($vCenterUserName, $vCenterPassword, $vCenterName)
		
		$VMclusters = Get-View -ViewType ComputeResource
		
		[System.Collections.Generic.List[System.Management.Automation.PSCustomObject]]$Report

		ForEach ($VMcluster in $VMclusters)
		{
			$Logger.Info("`t`tProcessing Cluster " + $VMcluster + " (" + $CLcount + " of " + $VMclusters.count + ")")
			[ClusterPerformanceData]$clusterPerformanceData = [ClusterPerformanceData]::new()
			[ClusterPerformanceData]$tmpClusterPerformanceData = [ClusterPerformanceData]::new()
			
			$CLcount++
			$VMhosts = Get-View -ViewType HostSystem
			ForEach ($VMhost in $VMhosts)
			{
				$Logger.Info("`t`t`tGathering information from host " + $VMhost)
				[HostDetailsData]$hostDetailsData = [HostDetailsData]::new()
				$VMhostStatCPU = Get-Stat -Entity $VMhost.Name -Start (get-date).AddDays(-8) -Finish (Get-Date) -MaxSamples 10000 -Stat cpu.usage.average | Measure-Object -Property value -Average -Maximum -Minimum
				$VMhostStatRAM = Get-Stat -Entity $VMhost.Name -Start (get-date).AddDays(-8) -Finish (Get-Date) -MaxSamples 10000 -Stat mem.usage.average | Measure-Object -Property value -Average -Maximum -Minimum
				$vCPU, $vRAM, $CPUratioRaw, $CPUratio, $RAMratioRaw, $RAMratio = 0, 0, 0, 0, 0, 0
				[int]$VMhostThreads = $VMhost.extensiondata.hardware.cpuinfo.numcputhreads
				$VMhostRAM = [math]::Round($VMhostDetails.hardware.memorysize / 1024Mb, 2)
				$VMsDetails | Where-Object { $_.vmhost -like $VMhost } | ForEach-Object{ $vCPU += $_.numcpu }
				If (($vCPU -ne "0") -and ($VMhost.connectionstate -eq "Connected"))
				{
					$CPUratioRaw = [math]::Round($vCPU/$VMhostThreads, 2)
					$CPUratio = "$($CPUratioRaw)" + ":1"
				}
				Else
				{
					$CPUratioRaw = 0
					$CPUratio = "$($CPUratioRaw)" + ":1"
				}
				$VMsDetails | Where-Object { $_.vmhost -like $VMhost } | ForEach-Object { $vRAM += $_.MemoryMB }
				If (($vRAM -ne "0") -and ($VMhost.connectionstate -eq "Connected"))
				{
					$vRAM = [math]::Round($vRAM/1024, 2)
					$RAMratioRaw = [math]::Round(($vRAM/$VMhostRAM) * 100, 0)
				}
				Else
				{
					$vRAM = 0
					$RAMratioRaw = 0
				}
				
				$hostDetailsData.vCenter = $vCenterName
				$hostDetailsData.description = $vCenterDescription
				$hostDetailsData.cluster = $VMcluster.Name
				$hostDetailsData.host = $VMhost.Name
				$hostDetailsData.type = "$($VMhost.Manufacturer)" + " - " + "$($VMhost.Model)"
				$hostDetailsData.state = $VMhost.connectionstate
				$hostDetailsData.pSocket = $VMhostDetails.hardware.cpuinfo.numCpuPackages
				$hostDetailsData.pCore = $VMhostDetails.hardware.cpuinfo.numCpuCores
				$hostDetailsData.logicalCpu = $VMhostThreads
				$hostDetailsData.vCpu = $vCPU
				$hostDetailsData.cpuRatio = $CPUratio
				$hostDetailsData.avgCpu = "$([math]::Round($VMhostStatCPU.Average, 2))" + "%"
				$hostDetailsData.maxCpu = "$([math]::Round($VMhostStatCPU.Maximum, 2))" + "%"
				$hostDetailsData.minCpu = "$([math]::Round($VMhostStatCPU.Minimum, 2))" + "%"
				$hostDetailsData.pRam = $VMhostRAM
				$hostDetailsData.vRam = $vRAM
				$hostDetailsData.usgRam = "$($RAMratioRaw)" + "%"
				$hostDetailsData.avgRam = "$([math]::Round($VMhostStatRAM.Average, 2))" + "%"
				$hostDetailsData.maxRam = "$([math]::Round($VMhostStatRAM.Maximum, 2))" + "%"
				$hostDetailsData.minRam = "$([math]::Round($VMhostStatRAM.Minimum, 2))" + "%"
				$hostDetailsData.vms = $VMhost.extensiondata.vm.count

				$Report += $hostDetailsData
				
				$clusterPerformanceData.pSocket += $VMhostDetails.hardware.cpuinfo.numCpuPackages
				$clusterPerformanceData.pCore += $VMhostDetails.hardware.cpuinfo.numCpuCores
				$clusterPerformanceData.logicalCpu += $VMhostThreads
				$clusterPerformanceData.vCpu += $vCPU
				$clusterPerformanceData.cpuRatioRaw += $CPUratioRaw
				$clusterPerformanceData.avgMaxCpu += [Math]::Round($VMhostStatCPU.Average, 2)
				$clusterPerformanceData.maxCpu += [Math]::Round($VMhostStatCPU.Maximum, 2)
				$clusterPerformanceData.minCpu += [Math]::Round($VMhostStatCPU.Minimum, 2)
				$clusterPerformanceData.pRam += $VMhostRAM
				$clusterPerformanceData.vRam += $vRAM
				$clusterPerformanceData.ramRatioRaw += $RAMratioRaw
				$clusterPerformanceData.avgRam += [Math]::Round($VMhostStatRAM.Average, 2)
				$clusterPerformanceData.maxRam += [Math]::Round($VMhostStatRAM.Maximum, 2)
				$clusterPerformanceData.minRam += [Math]::Round($VMhostStatRAM.Minimum, 2)
				$clusterPerformanceData.vms += $hostDetailsData.vms
			}
			$clusterPerformanceData.vCenter = $vCenterName
			$clusterPerformanceData.cluster = $VMcluster.Name
			$clusterPerformanceData.host = $VMhosts.count
			$clusterPerformanceData.type = "vSphere Compute Cluster"
			$clusterPerformanceData.state = $VMcluster.extensiondata.OverallStatus
			$clusterPerformanceData.CPUratio = "[math]::Round($ClusterPerformanceData.cpuRatioRaw/$VMhosts.count, 2))" + ":1"
			$clusterPerformanceData.avgCpu = [math]::Round($ClusterPerformanceData.avgMaxCpu / $VMhosts.count, 0)
			$clusterPerformanceData.maxCpu = [math]::Round($ClusterPerformanceData.maxCpu / $VMhosts.count, 0)
			$clusterPerformanceData.minCpu = [math]::Round($ClusterPerformanceData.minCpu / $VMhosts.count, 0)
			$clusterPerformanceData.ramUsage = [math]::Round($ClusterPerformanceData.ramRationRaw / $VMhosts.count, 0)
			$clusterPerformanceData.avgRam = [math]::Round($ClusterPerformanceData.avgRam / $VMhosts.count, 0)
			$clusterPerformanceData.maxRam = [math]::Round($ClusterPerformanceData.maxRam / $VMhosts.count, 0)
			$clusterPerformanceData.minRam = [math]::Round($ClusterPerformanceData.minRam / $VMhosts.count, 0)
			
			$Report += $clusterPerformanceData
		}
		
		return $Report
	}
	End
	{
		
	}
}



$vcList = Get-Content $vCenterFilePath
foreach ($vcRow in $vcList)
{
	$vcRow = $vcRow.Split(',')
	$vcName = $vcRow[0]
	$vcUserName = $vcRow[1]
	$vcPassword = $vcRow[2]
	$vcDescription = $vcRow[3]
	[FileLogger]$logger = [FileLogger]::New($LogFile)
	RetrieveVCenterPerformances -vCenterName $vcName -vCenterPassword $vcPassword -vCenterUserName $vcUserName -vCenterDescription $vcDescription -Logger $logger
}
