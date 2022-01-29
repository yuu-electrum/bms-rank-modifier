param
(
	[String]$source,
	[String]$destination,
	[Boolean]$copyOtherFile,
	[int]$rankId = 3,
	[Boolean]$preservesRankWhenAlreadyHarder = $false
)

$shouldExit = $false
if ([string]::IsNullOrEmpty($source))
{
	Write-Host 'Set a parent directory having BMS charts to convert #RANK'
	$shouldExit = $true
}

if ([string]::IsNullOrEmpty($destination))
{
	Write-Host 'Set a destination directory to output #RANK-converted charts'
	$shouldExit = $frue
}

if ($shouldExit)
{
	Write-Host 'Exiting...'
	Exit
}

if (!(Test-Path $destination))
{
	New-Item $destination -ItemType Directory | Out-Null
}

$currentDir = Split-Path $MyInvocation.MyCommand.Path
[Reflection.Assembly]::LoadFile($currentDir + "\Hnx8.ReadJEnc.dll") | Out-Null

$bmsFiles = Get-ChildItem $source -Recurse -File

$targetBmsFiles = $bmsFiles | Where-Object { $_.FullName -match ".+\.bm(s|l|e)+" }
$totalFileCount = $targetBmsFiles.Count
$currentFileCount = 1

$reportFilePath = (Convert-Path $destination) + "\ConvertReport-" + (Get-Date -UFormat "%Y%m%d%H%M%S") + ".txt"
$reportWriter = New-Object System.IO.StreamWriter($reportFilePath, $false, [Text.Encoding]::GetEncoding("UTF-8"))

$completeConvertingCount = 0
$incompleteConvertingCount = 0
$skippedCount = 0

$startedAt = Get-Date

$errorFiles = @{}
$unchangedFiles = @{}
$convertDetails = @{}

foreach ($bmsFile in $targetBmsFiles)
{
	$progressInPercentage = $currentFileCount / $totalFileCount * 100
	Write-Progress -Activity "Progress" -Id 1 -CurrentOperation "#RANK modification started." -Status $currentFileCount'/'$totalFileCount -PercentComplete $progressInPercentage

	$file = Get-Item -LiteralPath $bmsFile.FullName
	$encodingInfoReader = New-Object Hnx8.ReadJEnc.FileReader($file)
	$codePage = [int]$encodingInfoReader.Read($file).CodePage
	
	$encoding = [Text.Encoding]::GetEncoding($codePage)
	$fileReader = New-Object System.IO.StreamReader($bmsFile.FullName, $encoding)
	
	$destinationFilePath = (Convert-Path $destination) + $bmsFile.FullName.Replace((Convert-Path $source), "")
	$destinationFileDirectory = Split-Path $destinationFilePath
	
	if ($copyOtherFile -And !(Test-Path -LiteralPath $destinationFilePath))
	{
		Write-Progress -Activity "Progress" -Id 1 -CurrentOperation "Other files (not charts but waves and images) will be copied..." -Status $currentFileCount'/'$totalFileCount -PercentComplete $progressInPercentage
		$sourceFileDirectory = Split-Path $bmsFile.FullName
		robocopy $sourceFileDirectory $destinationFileDirectory /MT:8 | Out-Null
	}
	
	if (!(Test-Path -LiteralPath $destinationFilePath))
	{
		Write-Progress -Activity "Progress" -Id 1 -CurrentOperation "The target file does not exist and has been created." -Status $currentFileCount'/'$totalFileCount -PercentComplete $progressInPercentage
		New-Item -Path $destinationFilePath -ItemType File -Force | Out-Null
	}
	
	Write-Progress -Activity "Progress" -Id 1 -CurrentOperation "Modifying #RANK..." -Status $currentFileCount'/'$totalFileCount -PercentComplete $progressInPercentage
	
	$isError = $false
	try
	{
		Set-ItemProperty -LiteralPath $bmsFile.FullName -Name IsReadOnly -Value $false
		if (Test-Path -LiteralPath $destinationFilePath)
		{
			Set-ItemProperty -LiteralPath $destinationFilePath -Name IsReadOnly -Value $false | Out-Null
		}
		
		$fileWriter = New-Object System.IO.StreamWriter($destinationFilePath, $false, [Text.Encoding]::GetEncoding($codePage))
		$isError = $false
		
		while (!$fileReader.EndOfStream)
		{
			$origin = $fileReader.ReadLine()
			$line = $origin -Replace "#RANK [0-9]+","#RANK $rankId"
						
			if ($origin.Contains("#RANK"))
			{
				$rank = [int]($origin -replace "#RANK ", "")
				if ($rank -gt $rankId -And $preservesRankWhenAlreadyHarder)
				{
					$fileWriter.WriteLine($origin)
					$unchangedFiles[$currentFileCount] = @{originFilePath = $bmsFile.FullName}
					$skippedCount = $skippedCount + 1
					Continue
				}
			}
			
			$fileWriter.WriteLine($line)
		}
	}
	catch
	{
		Write-Progress -Activity "Progress" -Id 1 -CurrentOperation "An error occurred. Skipping..." -Status $currentFileCount'/'$totalFileCount -PercentComplete $progressInPercentage
		$isError = $true
		$errorFiles[$currentFileCount] = @{originFilePath = $bmsFile.FullName; message = $_.Exception.Message}
	}
	finally
	{
		$fileReader.Close()
		$fileWriter.Close()
	}
	
	if ($isError)
	{
		$incompleteConvertingCount = $incompleteConvertingCount + 1
	}
	else
	{
		$completeConvertingCount = $completeConvertingCount + 1
		
		$sourceMd5Hash = Get-FileHash -Algorithm MD5 -LiteralPath $bmsFile.FullName
		$destinationMd5Hash = Get-FileHash -Algorithm MD5 -LiteralPath $destinationFilePath
		$convertDetails[$sourceMd5Hash.Hash] = $destinationMd5Hash.Hash
	}

	$currentFileCount = $currentFileCount + 1
}

$convertDetails | ConvertTo-Json | Out-File ($destination + '\convert_detail.json')

$reportWriter.WriteLine('===== Converting Summary =====')
$reportWriter.WriteLine('Total (to be convered): ' + $totalFileCount)
$reportWriter.WriteLine('Complete: ' + ($completeConvertingCount - $skippedCount))
$reportWriter.WriteLine('Incomplete: ' + $incompleteConvertingCount)
$reportWriter.WriteLine('Skipped: ' + $skippedCount)
$reportWriter.WriteLine('Started at ' + $startedAt + ', ended at ' + (Get-Date))
$reportWriter.WriteLine('Took ' + ((Get-Date) - $startedAt).TotalSeconds + ' seconds')

$reportWriter.WriteLine('')
$reportWriter.WriteLine('===== Incomplete Convertings =====')

foreach ($errorFile in $errorFiles.GetEnumerator())
{
	$key = $errorFile.Key
	$value = $errorFile.Value
	$reportWriter.WriteLine('#' + $key + ' ' + $value.originFilePath)
	$reportWriter.WriteLine($value.message);
	$reportWriter.WriteLine("");
}

$reportWriter.WriteLine('')
$reportWriter.WriteLine('===== Unchanged =====')
$reportWriter.WriteLine('Files listed below are remain unchanged, as its #RANK value is already harder than you specified.')

foreach ($unchangedFile in $unchangedFiles.GetEnumerator())
{
	$key = $unchangedFile.Key
	$value = $unchangedFile.Value
	$reportWriter.WriteLine('#' + $key + ' ' + $value.originFilePath)
}

$reportWriter.Close()