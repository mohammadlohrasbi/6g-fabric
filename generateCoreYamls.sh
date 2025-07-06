#!/bin/bash

# دایرکتوری برای فایل‌های تنظیمات
mkdir -p config

# تولید فایل core-org*.yaml برای هر سازمان
for org in {1..10}; do
  port=$((7051 + (org-1)*1000))
  chaincode_port=$((7052 + (org-1)*1000))
  operations_port=$((9443 + (org-1)*1000))
  cat << EOF > config/core-org${org}.yaml
peer:
  id: peer0.org${org}.example.com
  networkId: fabric_network
  listenAddress: 0.0.0.0:${port}
  chaincodeListenAddress: 0.0.0.0:${chaincode_port}
  address: peer0.org${org}.example.com:${port}
  gossip:
    bootstrap: peer0.org${org}.example.com:${port}
    externalEndpoint: peer0.org${org}.example.com:${port}
    useLeaderElection: true
    orgLeader: false
  fileSystemPath: /var/hyperledger/production
  BCCSP:
    Default: SW
    SW:
      Hash: SHA2
      Security: 256
      FileKeyStore:
        KeyStore: /var/hyperledger/peer/msp/keystore
  mspConfigPath: /var/hyperledger/peer/msp
  localMspId: Org${org}MSP
  tls:
    enabled: true
    clientAuthRequired: false
    cert:
      file: /var/hyperledger/peer/tls/server.crt
    key:
      file: /var/hyperledger/peer/tls/server.key
    rootcert:
      file: /var/hyperledger/peer/tls/ca.crt
    clientRootCAs:
      - /var/hyperledger/peer/tls/ca.crt
  chaincode:
    builder: /var/hyperledger/chaincode-builder
    pull: true
    installTimeout: 300s
    executeTimeout: 30s
  vm:
    endpoint: unix:///var/run/docker.sock
    docker:
      tls:
        enabled: false
      attachStdout: true
  logging:
    level: info
    format: '%{color}%{time:2006-01-02 15:04:05.000 MST} [%{module}] %{shortfunc} -> %{level:.4s} %{id:03x}%{color:reset} %{message}'
ledger:
  state:
    stateDatabase: goleveldb
    couchDBConfig:
      couchDBAddress: couchdb:5984
      username:
      password:
      maxRetries: 3
      maxRetriesOnStartup: 10
      requestTimeout: 35s
      createGlobalChangesDB: false
  history:
    enableHistoryDatabase: true
operations:
  listenAddress: 0.0.0.0:${operations_port}
  tls:
    enabled: true
    cert:
      file: /var/hyperledger/peer/tls/server.crt
    key:
      file: /var/hyperledger/peer/tls/server.key
    clientAuthRequired: false
    clientRootCAs:
      - /var/hyperledger/peer/tls/ca.crt
metrics:
  provider: prometheus
  statsd:
    network: udp
    address: 127.0.0.1:8125
    writeInterval: 10s
    prefix:
EOF
done

echo "فایل‌های تنظیمات core-org*.yaml برای 10 سازمان تولید شد."
