$UserDefinedList = read-host "Enter Computer List"
$ComputerList = Get-Content $UserDefinedList
$a = Get-Date  # Import computer list

foreach ($SingleComp in $ComputerList) {
	If (Test-Connection $SingleComp -quiet -count 1){
		############################################
		#Run ping test to see if computer responds #
		############################################
		Write-Host "$SingleComp appears to be online." -ForegroundColor Green
		Write-Output "$SingleComp" >> Online_$UserDefinedList.txt
    } else {
		#############################################
		# Test-Connection failed, system is offline #
		#############################################
		Write-Host "$SingleComp is offline/not responding." -ForegroundColor Red -BackgroundColor Yellow
		Write-Output "$SingleComp" >> Offline_$UserDefinedList.txt
	}

}
Start-Sleep 30