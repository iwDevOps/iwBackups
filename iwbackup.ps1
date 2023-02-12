# Define the database admin username and password
$dbUser = "user"
$dbPassword = "pass"

# Define the IceWarp installation directory
$iwMainDir = "C:\Program Files\IceWarp"

# Define the backup retention temporary directory
$rtDir = "C:\Program Files\IceWarp\backup\temp"

# Define the number of older backups to keep
$rtDays = 3

# Define the directory where backups will be stored
$backupDir = "C:\Program Files\IceWarp\backup\dbdump"

# Define the MySQL data directory
$mysqlDataDir = "C:\Program Files\MariaDB 10.2\data"

# Define the full path to the mysqldump.exe binary
$mysqldump = "C:\Program Files\MariaDB 10.2\bin\mysqldump.exe"

# Define the full path to the 7z.exe binary
$zip = "C:\Program Files\7-Zip\7z.exe"

# Check if the backup directory exists, if not create it
if (!(Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir
}

# Check if the retention temporary directory exists, if not create it
if (!(Test-Path $rtDir)) {
  New-Item -ItemType Directory -Path $rtDir
}

# Get the date
$date = Get-Date
$yy = $date.Year.ToString().Substring(2)
$mon = $date.Month.ToString().PadLeft(2, "0")
$dd = $date.Day.ToString().PadLeft(2, "0")

# Get the time
$hh = $date.Hour.ToString().PadLeft(2, "0")
$min = $date.Minute.ToString().PadLeft(2, "0")

# Define the directory name using the date and time
$dirName = "${yy}${mon}${dd}_${hh}${min}"

# Change the current directory to the MySQL data directory
Push-Location $mysqlDataDir

# Get the databases in the data folder
Get-ChildItem -Directory | ForEach-Object {
  if (!(Test-Path "$backupDir\$dirName")) {
    New-Item -ItemType Directory -Path "$backupDir\$dirName"
  }

  & $mysqldump --host="localhost" --user=$dbUser --password=$dbPassword --single-transaction --add-drop-table --databases $_.Name | Out-File "$backupDir\$dirName\$_.sql"

  & $zip a -tgzip "$backupDir\$dirName\$_.sql.gz" "$backupDir\$dirName\$_.sql"

  Remove-Item "$backupDir\$dirName\$_.sql"
}

# Return to the original directory
Pop-Location

# Backup the server settings
& $iwMainDir\tool.exe export account "*@*" u_backup | Out-File "$backupDir\$dirName\acc_u_backup.csv"
& $iwMainDir\tool.exe export domain "*" d_backup | Out-File "$backupDir\$dirName\dom_d_backup.csv"
& $zip a -r "$backupDir\$dirName\cfg.7z" "$iwMainDir\config"
& $zip a -r "$backupDir\$dirName\cal.7z" "$iwMainDir\calendar"

# Remove backups older than 3 days
Robocopy $backupDir $rtDir /mov /minage:$rtDays
Remove-Item "$rtDir\*" -Force -Recurse
