# db admin user and password
$dbUser = "iwdbuser"
$dbPassword = "password"

# IceWarp installation dir
$iwMainDir = "C:\Program Files\IceWarp"

# backup retention temp dir
$rtDir = "C:\Program Files\IceWarp\backup\temp"

# how many older backups do we keep
$rtDays = 3

# directory where to store the backups
$backupDir = "C:\Program Files\IceWarp\backup\dbdump"

# MySQL data dir
$mysqlDataDir = "C:\Program Files\MariaDB 10.6\data"

# full path to mysqldump.exe binary
$mysqldump = "C:\Program Files\MariaDB 10.6\bin\mysqldump.exe"

# full path to 7z.exe binary
$zip = "C:\Program Files\7-Zip\7z.exe"

# check if backupDir and rtDir exist, create them if they don't
if (-not (Test-Path $backupDir)) { mkdir $backupDir }
if (-not (Test-Path $rtDir)) { mkdir $rtDir }

# get current date and time
$dateTime = Get-Date
$yy = $dateTime.Year.ToString().PadLeft(4, "0")
$mon = $dateTime.Month.ToString().PadLeft(2, "0")
$dd = $dateTime.Day.ToString().PadLeft(2, "0")
$hh = $dateTime.Hour.ToString().PadLeft(2, "0")
$min = $dateTime.Minute.ToString().PadLeft(2, "0")

# create backup directory with current timestamp as the name
$dirName = "$yy$mon$dd" + "_" + "$hh$min"
New-Item -ItemType Directory -Path "$backupDir\$dirName"

# switch to the "data" folder
Push-Location $mysqlDataDir

# iterate over the folder structure in the "data" folder to get the databases
Get-ChildItem -Directory | Where-Object { $_.Name -notin @('performance_schema', 'sys', 'mysql') } | ForEach-Object {

    # create subdirectory for the database backup
    $subDir = "$backupDir\$dirName\$($_.Name)"
    New-Item -ItemType Directory -Path $subDir

    # backup the database using mysqldump
    & $mysqldump --host="127.0.0.1" --user=$dbUser --password=$dbPassword --single-transaction --add-drop-table --databases $_.Name > "$subDir\$($_.Name).sql"

    # compress the SQL dump file using 7-Zip
    & $zip a -tgzip "$subDir\$($_.Name).sql.gz" "$subDir\$($_.Name).sql"

    # delete the uncompressed SQL dump file
    Remove-Item "$subDir\$($_.Name).sql"
}

# go back to the original location
Pop-Location

# backup server settings
& "$iwMainDir\tool.exe" export account "*@*" u_backup > "$backupDir\$dirName\acc_u_backup.csv"
& "$iwMainDir\tool.exe" export domain "*" d_backup > "$backupDir\$dirName\dom_d_backup.csv"
& $zip a -r "$backupDir\$dirName\cfg.7z" "$iwMainDir\config"
& $zip a -r "$backupDir\$dirName\cal.7z" "$iwMainDir\calendar"

# remove backups older than $rtDays days
$oldBackups = Get-ChildItem -Path $backupDir | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$rtDays) }

if ($oldBackups) {
    # move the old backups to the retention temp dir
    $oldBackups | Move-Item -Destination $rtDir -Force
}

# delete empty subdirectories from previous backups in the retention temp dir
$emptyDirs = Get-ChildItem -Path $rtDir -Recurse -Directory | Where-Object { -not (Get-ChildItem -Path $_.FullName) }

if ($emptyDirs) {
    $emptyDirs | Remove-Item -Recurse
}
