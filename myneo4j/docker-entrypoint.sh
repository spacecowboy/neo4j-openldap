#!/bin/bash -eu

setting() {
    setting="${1}"
    value="${2}"
    file="${3:-neo4j.conf}"

    if [ ! -f "conf/${file}" ]; then
        if [ -f "conf/neo4j.conf" ]; then
            file="neo4j.conf"
        fi
    fi

    if [ -n "${value}" ]; then
        if grep -q -F "${setting}=" conf/"${file}"; then
            sed --in-place "s|.*${setting}=.*|${setting}=${value}|" conf/"${file}"
        else
            echo "${setting}=${value}" >>conf/"${file}"
        fi
    fi
}

if [ "$1" == "neo4j" ]; then
    setting "dbms.tx_log.rotation.retention_policy" "${NEO4J_dbms_txLog_rotation_retentionPolicy:-100M size}"
    setting "dbms.memory.pagecache.size" "${NEO4J_dbms_memory_pagecache_size:-512M}"
    setting "wrapper.java.additional=-Dneo4j.ext.udc.source" "${NEO4J_UDC_SOURCE:-docker}" neo4j-wrapper.conf
    setting "dbms.memory.heap.initial_size" "${NEO4J_dbms_memory_heap_maxSize:-512}" neo4j-wrapper.conf
    setting "dbms.memory.heap.max_size" "${NEO4J_dbms_memory_heap_maxSize:-512}" neo4j-wrapper.conf
    setting "dbms.unmanaged_extension_classes" "${NEO4J_dbms_unmanagedExtensionClasses:-}"
    setting "dbms.allow_format_migration" "${NEO4J_dbms_allowFormatMigration:-}"

    if [ "${NEO4J_AUTH:-}" == "none" ]; then
        setting "dbms.security.auth_enabled" "false"
    elif [[ "${NEO4J_AUTH:-}" == neo4j/* ]]; then
        password="${NEO4J_AUTH#neo4j/}"
        if [ "${password}" == "neo4j" ]; then
            echo "Invalid value for password. It cannot be 'neo4j', which is the default."
            exit 1
        fi
        bin/neo4j-admin users set-password neo4j "${password}"
    elif [ -n "${NEO4J_AUTH:-}" ]; then
        echo "Invalid value for NEO4J_AUTH: '${NEO4J_AUTH}'"
        exit 1
    fi

    setting "dbms.connector.http.listen_address" "0.0.0.0:7474"
    setting "dbms.connector.https.listen_address" "0.0.0.0:7473"
    setting "dbms.connector.bolt.listen_address" "0.0.0.0:7687"
    setting "dbms.mode" "${NEO4J_dbms_mode:-}"
    setting "ha.server_id" "${NEO4J_ha_serverId:-}"
    setting "ha.host.data" "${NEO4J_ha_host_data:-}"
    setting "ha.host.coordination" "${NEO4J_ha_host_coordination:-}"
    setting "ha.initial_hosts" "${NEO4J_ha_initialHosts:-}"

    [ -f "${EXTENSION_SCRIPT:-}" ] && . ${EXTENSION_SCRIPT}

    if [ -d /conf ]; then
        find /conf -type f -exec cp {} conf \;
    fi

    if [ -d /ssl ]; then
        setting "dbms.directories.certificates" "/ssl" neo4j.conf
    fi

    if [ -d /plugins ]; then
        setting "dbms.directories.plugins" "/plugins" neo4j.conf
    fi

    if [ -d /logs ]; then
        setting "dbms.directories.logs" "/logs" neo4j.conf
    fi

    exec bin/neo4j console
elif [ "$1" == "dump-config" ]; then
    if [ -d /conf ]; then
        cp --recursive conf/* /conf
    else
        echo "You must provide a /conf volume"
        exit 1
    fi
else
    exec "$@"
fi
