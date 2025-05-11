# Ждем когда основная БД запуститься
until pg_isready -h primary -p 5432 -U postgres; do
  sleep 1
done

# чистим контейнер standby
rm -rf /var/lib/postgresql/data/*

# Копируем основную БД
PGPASSWORD=postgres pg_basebackup -h primary -D /var/lib/postgresql/data -U postgres -Fp -Xs -P -R

# Конфигурация для основной БД
echo "primary_conninfo = 'host=primary port=5432 user=postgres password=postgres'" >> /var/lib/postgresql/data/postgresql.auto.conf

# повышаем привилегии 
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Запускаем БД с нужными конфигами
su postgres -c 'postgres -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf'
