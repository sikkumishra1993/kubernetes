$username = "user-ooijnxjurzet@oreilly-cloudlabs.com"
$pass = "FpOdZy5eV1938kJ"
az login -u $username -p $pass

$subscriptionId=$(az account show --query id --output tsv)
# Output the subscription ID to a file
$subscriptionId | Out-File -FilePath "subscription_id.txt"

$rgname=$(az group list --query "[0].name" --output tsv)

$rgname | Out-File -FilePath "rg_name.txt"

terraform init -upgrade
terraform apply -auto-approve

$terraformOutput = terraform output -json | ConvertFrom-Json
# $terraformOutput.master_ip.value | Out-File -FilePath "master_ip.txt"
# $terraformOutput.worker2_ip.value | Out-File -FilePath "worker2_ip.txt"
# $terraformOutput.worker_ip.value | Out-File -FilePath "worker_ip.txt"

# Define IP addresses and password
$master_ip = $terraformOutput.master_ip.value
$worker2_ip = $terraformOutput.worker2_ip.value
$worker_ip = $terraformOutput.worker_ip.value
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

Remove-Item -Path "*.tfstate" -Force