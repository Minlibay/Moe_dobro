$password = "XQ9114iFXF25"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("root", $securePassword)

# Установка Git
$session = New-SSHSession -ComputerName 185.40.4.195 -Credential $credential -AcceptKey
Invoke-SSHCommand -SessionId $session.SessionId -Command "apt update && apt install -y git"
Remove-SSHSession -SessionId $session.SessionId
