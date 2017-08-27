$Minutes = 60;
$myShell = New-Object -com "Wscript.Shell";

for ($i = 0; $i -lt $minutes; $i++) {
    
    $mousePosition = [System.Windows.Forms.Cursor]::Position;
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($mousePosition.X) + 1) , $mousePosition.Y);
    
    Start-Sleep -Seconds 60;
};

