$Minutes = 60;

for ($i = 0; $i -lt $Minutes; $i++) {
    
    $mousePosition = [System.Windows.Forms.Cursor]::Position;
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($mousePosition.X) + 1) , $mousePosition.Y);
    
    Start-Sleep -Seconds 60;
};

