#! /usr/bin/env bash

shopt -os errexit nounset pipefail
IFS=  # disable word splitting

##
script_path_=$(dirname "$0")

mssql_script_=$script_path_/create_mssql.sql
oracle_script_=$script_path_/create_oracle.sql
postgres_script_=$script_path_/create_postgresql.sql

choices_=(MSSQL Oracle PostgreSQL)

# database prompt, data path prompt, default data path
prompt_mssql_=("Name der Datenbank"
               "Pfad zur Datenbank-Datei"
               /var/opt/mssql/data)
prompt_oracle_=("Name des Tablespace"
                "Pfad zur Datenbank-Datei"
                "/u01/app/oracle/oradata/XE")
prompt_postgresql_=("Name der Datenbank")

declare -A sa_=([mssql]=sa
                [oracle]=sys
                [postgresql]=postgres)

## CHOOSE DATABASE ##
num_choices_=${#choices_[@]}
PS3="
Typ der Datenbank [1-$num_choices_]: "

printf "Typ der Datenbank waehlen\n"

# `unbound variable`-Fehler bei nicht-numerischer REPLY
shopt -ou nounset
select db_type_ in "${choices_[@]}"
do
	if ((1 <= REPLY && REPLY <= num_choices_)) 2> /dev/null
    then
	    break
    else
        printf "\nWahl nicht im gueltigen Bereich - noch einmal versuchen"
    fi
done
shopt -os nounset

db_type_=${db_type_,,}  # convert to lowercase

if [[ $db_type_ == mssql ]]
then
    db_prompt_=${prompt_mssql_[0]}
    data_prompt_=${prompt_mssql_[1]}
    default_data_path_=${prompt_mssql_[2]}
elif [[ $db_type_ == oracle ]]
then
    db_prompt_=${prompt_oracle_[0]}
    data_prompt_=${prompt_oracle_[1]}
    default_data_path_=${prompt_oracle_[2]}
else
    db_prompt_=${prompt_postgresql_[0]}
fi
sa_=${sa_[$db_type_]}

## PROMPT USER FOR INFORMATION  ##
unset db_ user_ data_path_

while [[ -z ${db_-} ]]
do
    read -erp "- $db_prompt_: " db_
done

while [[ -z ${user_-} ]]
do
    read -eri $db_ -p "- Name des Benutzers: " user_
done

read -erp "- Kennwort des Benutzers: " user_passwd_

if  [[ $db_type_ =~ (mssql|oracle) ]]
then
    while [[ -z ${data_path_-} ]]
    do
        read -eri $default_data_path_ -p "- $data_prompt_: " data_path_
    done
fi

read -erp "- Kennwort des Benutzers \`$sa_\`: " sa_passwd_

printf "\n** Erstelle Datenbank...\n"

## CREATE DATABASE AND USER ##
if   [[ $db_type_ == mssql ]]
then
    PATH=/opt/mssql-tools/bin:$PATH

    export db_ user_ user_passwd_ data_path_

    sqlcmd -U $sa_          \
           -P "$sa_passwd_" \
           -b               \
           -m 1             \
           -i "$script_path_/create_mssql.sql"

elif [[ $db_type_ == oracle ]]
then
    envvars_11xe_=/u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh
    source $envvars_11xe_

    # #
    sqlplus -S $sa_/$sa_passwd_ as sysdba @"$oracle_script_"    \
                                                "$db_"          \
                                                "$user_"        \
                                                "$user_passwd_" \
                                                "$data_path_"

# PostgreSQL
else
    psql --no-psqlrc                \
         --set ON_ERROR_STOP=on     \
         --set db=$db_              \
         --set user=$user_          \
         --set passwd=$user_passwd_ \
         --file "$postgres_script_" \
         postgresql://$sa_:$sa_passwd_@localhost
fi
