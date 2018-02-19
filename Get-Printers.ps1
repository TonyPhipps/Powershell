$aPrinterList = @()

$StartTime = "11/01/2013 12:00:01 PM"
$EndTime = "11/01/2013 6:00:01 PM"
$Results = Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-PrintService/Operational"; ID=307} -ComputerName "print-01"


ForEach($Result in $Results){
  $ProperyData = [xml]$Result.ToXml()
  $PrinterName = $ProperyData.Event.UserData.DocumentPrinted.Param5
    
  If($PrinterName.Contains("HP-4350-01")){
    $hItemDetails = New-Object -TypeName psobject -Property @{
      DocName = $ProperyData.Event.UserData.DocumentPrinted.Param2
      UserName = $ProperyData.Event.UserData.DocumentPrinted.Param3
      MachineName = $ProperyData.Event.UserData.DocumentPrinted.Param4
      PrinterName = $PrinterName
      PageCount = $ProperyData.Event.UserData.DocumentPrinted.Param8
      TimeCreated = $Result.TimeCreated
    }

    $aPrinterList += $hItemDetails
  }
}

#Output results to CSV file
$aPrinterList | Export-Csv -LiteralPath C:\Temp\PrintAudit.csv