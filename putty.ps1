# Define IP addresses and password
$master_ip = "52.149.215.12"
$worker2_ip = "52.149.215.15"
$worker_ip = "52.149.208.51"
$password = "Maersk@12345"

# Path to PuTTY and plink executables
$putty_path = "C:\Program Files\PuTTY\putty.exe"

# Function to launch PuTTY session
function Launch-PuttySession {
    param (
        [string]$ip,
        [string]$password
    )

    # Launch PuTTY session
    Start-Process -FilePath $putty_path -ArgumentList "-ssh bigboss@$ip -pw $password"
}

# Launch PuTTY sessions
Launch-PuttySession -ip $master_ip -password $password
Launch-PuttySession -ip $worker2_ip -password $password
Launch-PuttySession -ip $worker_ip -password $password