#!/bin/bash
##############################################################################
# COPYRIGHT Ericsson AB 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson AB. The programs may be used and/or copied only with written
# permission from Ericsson AB. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################
#
# Write the current postgres password to db_pwd puppet manifest, so that it
# doesn't get lost/overwritten by an upgrade of this EXTRlitppuppetpuppetdb
# package.
#
DB_PWD_MANIFEST="/opt/ericsson/nms/litp/etc/puppet/modules/puppetdb/manifests/db_pwd.pp"
ERRFILE="/tmp/EXTRlitppuppetpuppetdb_postinstall_err$$"
INITIAL_PWD="md5958e1c4182a7ba15d80dd107f211e35a"
PG_HBA_CONF="/var/opt/rh/rh-postgresql96/lib/pgsql/data/pg_hba.conf"
hostname=$(hostname)

if [ -f "${DB_PWD_MANIFEST}" ]; then

   if grep "hostssl*.all*.postgres" ${PG_HBA_CONF}
   then
      psql_cmd="psql -h ${hostname}"
   else
      psql_cmd="psql"
   fi

   DB_PWD=$(sudo -u postgres  -- ${psql_cmd} -q -c "\t" -c "SELECT rolpassword FROM pg_authid WHERE rolname = 'postgres';" 2>"${ERRFILE}")
   RC=$?

   if [ "${RC}" -eq 0 ]; then
      DB_PWD=$(printf "${DB_PWD}" | tr -d ' \n')
      [ -z "${DB_PWD}" ] && DB_PWD="${INITIAL_PWD}"
   else
      DB_PWD="${INITIAL_PWD}"
   fi
   sed -i "s/^\(  \$postgres_password = \)'<<md5pwd>>'$/\1'"${DB_PWD}"'/" "${DB_PWD_MANIFEST}"

   [ -s "${ERRFILE}" ] && rm "${ERRFILE}"
fi
exit 0
