param
(
	[String]$convertDetailSource,
	[String]$tableSource,
	[String]$destination
)

$encoding = 'UTF8'
$codePage = 65001

$shouldExit = $false;
$currentDir = Split-Path $MyInvocation.MyCommand.Path
[Reflection.Assembly]::LoadFile($currentDir + "\Hnx8.ReadJEnc.dll") | Out-Null

if (!(Test-Path $convertDetailSource))
{
	Write-Host "A convert detail json file does not exist."
	$shouldExit = $true
}

if (!(Test-Path ($tableSource + "\score.json")))
{
	Write-Host "score.json does not exist in a directory specified."
	$shouldExit = $true
}

if ($shouldExit)
{
	Write-Host "Exiting..."
	Exit
}

Write-Host "Started converting table json set..."


#=================================================
# Loads convert details
#=================================================
$convertDetails = Get-Content -LiteralPath (Convert-Path $convertDetailSource) -Encoding $encoding | ConvertFrom-Json
$convertHashDetails = @{}
foreach ($detail in $convertDetails.GetEnumerator())
{
	$convertHashDetails[$detail.sourceMd5] = $detail
}

#=================================================
# Loads files from the table set
#=================================================
$table = Get-Content -LiteralPath (Convert-Path ($tableSource + 'score.json')) -Encoding $encoding | ConvertFrom-Json
$chartTable = @{}
foreach ($row in $table)
{
	$chartTable[$row.md5.ToUpper()] = $row
}

#=================================================
# Compares and modifies its filehash to #RANK-modified ones
#=================================================
$modifiedJsonItems = New-Object System.Collections.Generic.List[PSCustomObject]
foreach ($chart in $chartTable.GetEnumerator())
{
	if (!$convertHashDetails.Contains($chart.Key))
	{
		# Let it be if no entry was found in the chart table
		$modifiedJsonItems.Add($chart.Value)
		Continue
	}
	
	$modifiedChartRow = $chartTable[$chart.Key]
	$areBothNull = $true
	if (!($chart.Value.md5 -eq $null))
	{
		$modifiedChartRow.md5 = $convertHashDetails[$chart.Key].destinationMd5.toLower()
		$areBothNull = $false
	}
	
	if (!($chart.Value.sha256 -eq $null))
	{
		$modifiedChartRow.sha256 = $convertHashDetails[$chart.Key].destinationSha256.toLower()
		$areBothNull = $false
	}
	
	if ($areBothNull)
	{
		Write-Host "No filehash found. Skipping..."
		Continue
	}
	
	$modifiedJsonItems.Add($modifiedChartRow)
}

$destinationFilePath = ($destination + '\score.json')
if (!(Test-Path -LiteralPath $destinationFilePath))
{
	New-Item -Path (Split-Path $destinationFilePath) -ItemType Directory | Out-Null
	New-Item -Path $destinationFilePath -ItemType File -Force | Out-Null
}

$modifiedJsonItems | Sort { $_.level -As [Int] } | ConvertTo-Json | Out-File ((Convert-Path $destination) + '\score.json')