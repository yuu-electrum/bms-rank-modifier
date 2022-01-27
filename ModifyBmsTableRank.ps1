param
(
	[String]$source,
	[String]$tableSource,
	[String]$destination
)

$encoding = 'UTF8'
$codePage = 65001

$shouldExit = $false
if ([string]::IsNullOrEmpty($source))
{
	Write-Host 'Set a parent directory having BMS charts to convert #RANK'
	$shouldExit = $true
}

if ([string]::IsNullOrEmpty($destination))
{
	Write-Host 'Set a destination directory to output #RANK-converted charts'
	$shouldExit = $true
}

if (!(Test-Path -LiteralPath $source))
{
	Write-Host 'A source directory seems not exist.'
	$shouldExit = $true
}

if ($shouldExit)
{
	Write-Host 'Exiting...'
	Exit
}

$currentDir = Split-Path $MyInvocation.MyCommand.Path
[Reflection.Assembly]::LoadFile($currentDir + "\Hnx8.ReadJEnc.dll") | Out-Null

Write-Host "Started converting table json set..."

#=================================================
# Loads files from the chart origin
#=================================================
$chartFiles = Get-ChildItem $source -Recurse -File | Where-Object { $_.FullName -match ".+\.bm(s|l|e)+" }
$charts = @{}
foreach ($chartFile in $chartFiles)
{
	$targetFile = Get-Item -LiteralPath $chartFile.FullName
	$targetEncodingInfoReader = New-Object Hnx8.ReadJEnc.FileReader($targetFile)
	$targetCodePage = [int]$targetEncodingInfoReader.Read($targetFile).CodePage
	$targetEncoding = [Text.Encoding]::GetEncoding($targetCodePage)
	
	$fileReader = New-Object System.IO.StreamReader($chartFile.FullName, $targetEncoding)
	
	while (!$fileReader.EndOfStream)
	{
		$origin = $fileReader.ReadLine()
		if ($origin.Contains("#TITLE"))
		{
			# Reading file is skipped after found #TITLE
			$title = ($origin -Replace "#TITLE ", "")
			$md5 = Get-FileHash -Algorithm MD5 -LiteralPath $chartFile.FullName
			$sha256 = Get-FileHash -Algorithm SHA256 -LiteralPath $chartFile.FullName
			
			$charts[$title] = @{md5 = $md5; sha256 = $sha256}
			Break
		}
	}
}

#=================================================
# Loads files from the table set
#=================================================
$table = Get-Content -LiteralPath ($tableSource + 'score.json') -Encoding $encoding | ConvertFrom-Json
$chartTable = @{}
foreach ($row in $table)
{
	$chartTable[$row.title] = $row
}

#=================================================
# Compares and modifies its filehash to #RANK-modified ones
#=================================================
$modifiedJsonItems = New-Object System.Collections.Generic.List[PSCustomObject]
foreach($chart in $charts.GetEnumerator())
{
	if (!$chartTable.Contains($chart.Key))
	{
		# Ignores a chart if no entry was found in the chart table
		Continue
	}
	
	$modifiedChartRow = $chartTable[$chart.Key]
	
	$areBothNull = $true
	if (!($chart.Value.md5 -eq $null))
	{
		$modifiedChartRow.md5 = $chart.Value.md5.Hash.toLower()
		$areBothNull = $false
	}
	
	if (!($chart.Value.sha256 -eq $null))
	{
		$modifiedChartRow.sha256 = $chart.Value.sha256.Hash.toLower()
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

$modifiedJsonItems | ConvertTo-Json | Out-File ($destination + '\score.json')