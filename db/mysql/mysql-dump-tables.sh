#!/bin/bash -e
mysql --skip-column-names --batch -e \
"select table_name from information_schema.tables \
 where table_schema = database()" $* |
xargs --max-args 1 mysqldump -d --single-transaction --skip-comments $*
