for DB in $(mysql -h127.0.0.1 -uroot -proot -e "show databases" | grep se_)
do
  mysql -h127.0.0.1 -u root -proot -D $DB < drop_schema.sql
done
mysql -h127.0.0.1 -u root -proot -D solaredge < drop_schema.sql
