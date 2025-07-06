#!/bin/bash

# دایرکتوری برای فایل‌های پیکربندی
mkdir -p config

# تولید core.yaml برای هر سازمان
for org in {1..10}; do
  cat << EOF > config/core-org${org}.yaml
peer:
  id: peer0.org${org}.example.com
  networkId: dev
  listenAddress: 0.0.0.0:$((7051 + (org-1)*1000))
  address: peer0.org${org}.example.com:$((7051 + (org-1)*1000))
  localMspId: Org${org}MSP
  mspConfigPath: /etc/hyperledger/fabric/msp
  tls:
    enabled: true
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/tls/ca.crt
    clientAuthRequired: false
  gossip:
    useLeaderElection: true
    orgLeader: false
    endpoint: peer0.org${org}.example.com:$((7051 + (org-1)*1000))
    maxBlockCountToStore: 100
    maxPropagationBurstLatency: 10ms
    maxPropagationBurstSize: 10
    propagateIterations: 1
    propagatePeerNum: 3
    bootstrap: peer0.org${org}.example.com:$((7051 + (org-1)*1000))
  fileSystemPath: /var/hyperledger/production
  BCCSP:
    Default: SW
    SW:
      Hash: SHA2
      Security: 256
      FileKeyStore:
        KeyStore: /etc/hyperledger/fabric/msp/keystore
  limits:
    concurrency:
      endorserService: 2500
      deliverService: 2500
EOF
done

echo "Generated core.yaml files for all organizations (core-org1.yaml to core-org10.yaml)"
