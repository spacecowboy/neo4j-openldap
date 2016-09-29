#!/bin/bash -eu

## SETUP

cat <<EOF > /tmp/add_nodes.ldif
dn: ou=people,dc=example,dc=org
objectClass: organizationalUnit
ou: People

dn: ou=groups,dc=example,dc=org
objectClass: organizationalUnit
ou: Groups
EOF

ldapadd -x -D cn=admin,dc=example,dc=org -W -f /tmp/add_nodes.ldif

cat <<EOF > /tmp/memberof_config.ldif
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectClass: top
olcModulePath: /usr/lib/ldap
olcModuleLoad: memberof.la

dn: olcOverlay={0}memberof,olcDatabase={1}hdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof
EOF

cat <<EOF > /tmp/refint.ldif
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcmoduleload: refint.la
olcmodulepath: /usr/lib/ldap

dn: olcOverlay={1}refint,olcDatabase={1}hdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: {1}refint
olcRefintAttribute: memberof member manager owner
EOF

ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/memberof_config.ldif

#ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/refint1.ldif

ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/refint.ldif

## validate
#ldapsearch -xLLL -b cn=config -D cn=admin,dc=example,dc=org -W

## Add a user

PASSWORDHASH="$(slappasswd -h {SHA} -s secret)"

cat <<EOF > /tmp/add_user.ldif
dn: uid=john,ou=people,dc=example,dc=org
cn: John Doe
givenName: John
sn: Doe
uid: john
uidNumber: 5000
gidNumber: 10000
homeDirectory: /home/john
mail: john.doe@example.org
objectClass: top
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
loginShell: /bin/bash
userPassword: ${PASSWORDHASH}
EOF

ldapadd -x -D cn=admin,dc=example,dc=org -W -f /tmp/add_user.ldif

cat <<EOF > /tmp/add_group.ldif
dn: cn=mygroup,ou=groups,dc=example,dc=org
objectClass: groupofnames
cn: mygroup
description: All users
member: uid=john,ou=people,dc=example,dc=org
EOF

ldapadd -x -D cn=admin,dc=example,dc=org -W -f /tmp/add_group.ldif

## and validat
ldapsearch -x -D cn=admin,dc=example,dc=org -W -b uid=john,ou=people,dc=example,dc=org dn memberof
