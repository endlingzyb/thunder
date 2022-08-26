#!/usr/bin/env bash

hooks::on_config() {
  cat <<EOF
configVersion: v1
onStartup: 0
kubernetes:
  - apiVersion: crds.dosk.host/v1alpha1
    kind: FRPCIngress
    executeHookOnEvent: ["Added","Modified","Deleted"]
EOF
}

hooks::on_startup() {
  node /utils/config-generator.js
  screen -d -m /utils/keepalive /frp/frpc -c /frp/frpc.ini
}

hooks::on_event() {
  node /utils/config-generator.js
  pkill screen
  screen -d -m /utils/keepalive /frp/frpc -c /frp/frpc.ini
}

hooks::main() {
  if [[ "$1" == "--config" ]];
  then
    hooks::on_config
  else
    [[ "$(jq -r '.[0].binding' ${BINDING_CONTEXT_PATH})" == "onStartup" ]] \
      && hooks::on_startup || echo ''
    [[ "$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})" == "Event" ]] \
      && hooks::on_event || echo ''
  fi
}

hooks::main "$@"