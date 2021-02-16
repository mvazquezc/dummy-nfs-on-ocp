#!/bin/bash
rpcbind
unfsd -d -n 2049 -m 2049 -p -e /etc/exports
