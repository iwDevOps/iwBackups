# iwBackups
Powershell script to backup IceWarp and MySQL
## Requierments
1 - [7-Zip](https://www.7-zip.org/download.html)

2 - [MariaDB 10.6](https://mariadb.org/download)

## The DBUser must be allowed to connect from the localhost
```powershell
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost';
```

Verify  
```sql
SELECT user,host FROM mysql.user WHERE host='localhost';
```

Verify example output
```sql
MariaDB [(none)]> SELECT user,host FROM mysql.user WHERE host='localhost'; 
+-------------+-----------+
| User        | Host      |
+-------------+-----------+
| iwdbuser    | localhost |
+-------------+-----------+
```

## The backups are placed in the \backup\dbdump\ folder 
