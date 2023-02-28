# iwBackups
Powershell script to backup IceWarp and MySQL
## Requierments
7-Zip https://www.7-zip.org/download.html
MariaDB 10.6

## The DBUser must be allowed to connect from the localhost
```powershell
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost';
```

Verify  
```sql
SELECT user FROM mysql.user WHERE host='localhost';
```


