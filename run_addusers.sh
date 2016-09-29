#!/bin/bash

docker cp ./addusers2.sh openldap_ldapserver_1:/addusers.sh

docker exec -it openldap_ldapserver_1 /bin/bash /addusers.sh
