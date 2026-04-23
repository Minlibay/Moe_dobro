$password = ConvertTo-SecureString "XQ9114iFXF25" -AsPlainText -Force

# Команды для выполнения на сервере
$commands = @"
cd /var/www/buble-master/backend
pm2 logs moe-dobro-api --lines 50 --err
echo "---"
curl http://localhost:3000/api/fundraisers
"@

# Подключение через SSH
$sshCommand = "echo '$password' | ssh root@185.40.4.195 '$commands'"

Write-Host "Подключение к VPS..."
Write-Host "Выполните команду вручную:"
Write-Host ""
Write-Host "ssh root@185.40.4.195"
Write-Host "Пароль: XQ9114iFXF25"
Write-Host ""
Write-Host "Затем выполните:"
Write-Host "cd /var/www/buble-master/backend"
Write-Host "pm2 logs moe-dobro-api --err --lines 50"
