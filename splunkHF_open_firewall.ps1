$UserDefinedList = read-host "Enter Computer List"
$remotehosts = get-content $UserDefinedList

foreach ($remotehost in $remotehosts)
{
	$rule = Invoke-command -ErrorVariable cmdExecutionStatus -ErrorAction SilentlyContinue -Computername $remotehost {netsh advfirewall firewall show rule name=all dir=in |findstr 9997}
	if ($cmdExecutionStatus -ne $NULL){
		Add-Content "C:\Temp\splunkfwenable.txt" "$cmdExecutionStatus"
		Write-Host "$remotehost`tFailed Connection`tSee 'C:\Temp\splunkfwenable.txt' for more information."
	}
	ElseIf($rule -eq "LocalPort:                            9997") {
		Write-Host "$remotehost`tRule Exists"
	}
	Else {
		Invoke-command -Computername $remotehost {netsh advfirewall firewall add rule name="Splunk HF Listening Port" dir=in action=allow protocol=TCP localport=9997 >> $NULL}
		Write-Host "$remotehost`tRule Added"
	}
$cmdExecutionStatus = $NULL
}