# Set variables
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
$sshAgentScript = "$env:USERPROFILE\ssh-agent.ps1"

# Check if SSH key already exists
if (-not (Test-Path $sshKeyPath)) {
    # Generate SSH key
    ssh-keygen -t rsa -b 4096 -f $sshKeyPath -N ""

    # Add SSH key to ssh-agent
    ssh-agent | Out-File -FilePath $sshAgentScript
    . $sshAgentScript
    ssh-add $sshKeyPath
} else {
    Write-Output "SSH key already exists."
}

# Create script to auto-restart ssh-agent
@"
Start-Service ssh-agent
"@ | Out-File -FilePath $sshAgentScript

# Register script to run on user logon
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "SSHAgentRestart"
$regValue = "powershell.exe -File $sshAgentScript"

if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String
    Write-Output "SSH agent auto-restart script registered."
} else {
    Set-ItemProperty -Path $regPath -Name $regName -Value $regValue
    Write-Output "SSH agent auto-restart script updated."
}

Write-Output "SSH key setup and auto-restart script created."
