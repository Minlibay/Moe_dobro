#!/usr/bin/expect -f

set timeout -1
spawn ssh root@185.40.4.195 "apt update && apt install -y git"
expect "password:"
send "XQ9114iFXF25\r"
expect eof
