# Define the named pipe path
$pipePath = "\\\\.\\pipe\\TONYTESTPATH"

# Create the named pipe server
$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream("TONYTESTNAME", [System.IO.Pipes.PipeDirection]::InOut)

# Output that the pipe has been created
Write-Host "Named pipe '$pipePath' created."

# Wait for a client to connect (optional, remove if not needed)
Write-Host "Waiting for client connection..."
$pipeServer.WaitForConnection()
Write-Host "Client connected."



# Close the pipe
$pipeServer.Close()

# Delete the named pipe
Remove-Item $pipePath

# Output that the pipe has been deleted
Write-Host "Named pipe '$pipePath' deleted."