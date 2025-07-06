#!/bin/bash

# دایرکتوری برای فایل‌های پیکربندی
mkdir -p config

# تولید پروفایل اتصال برای هر سازمان
for org in {1..10}; do
  cat << EOF > config/connection-org${org}.json
{
  "name": "Network-Org${org}",
  "version": "1.0.0",
  "client": {
    "organization": "Org${org}",
    "connection": {
      "timeout": {
        "peer": {
          "endorser": "300",
          "eventHub": "300",
          "eventReg": "300"
        },
        "orderer": "300"
      }
    }
  },
  "organizations": {
    "Org${org}": {
      "mspid": "Org${org}MSP",
      "peers": [
        "peer0.org${org}.example.com"
      ],
      "certificateAuthorities": [
        "ca.org${org}.example.com"
      ]
    }
  },
  "peers": {
    "peer0.org${org}.example.com": {
      "url": "grpcs://localhost:$((7051 + (org-1)*1000))",
      "tlsCACerts": {
        "path": "crypto-config/peerOrganizations/org${org}.example.com/peers/peer0.org${org}.example.com/tls/ca.crt"
      },
      "grpcOptions": {
        "ssl-target-name-override": "peer0.org${org}.example.com",
        "hostnameOverride": "peer0.org${org}.example.com"
      }
    }
  },
  "certificateAuthorities": {
    "ca.org${org}.example.com": {
      "url": "https://localhost:$((7054 + (org-1)*1000))",
      "caName": "ca-org${org}",
      "tlsCACerts": {
        "path": "crypto-config/peerOrganizations/org${org}.example.com/ca/ca.org${org}.example.com-cert.pem"
      },
      "httpOptions": {
        "verify": false
      }
    }
  },
  "orderers": {
    "orderer.example.com": {
      "url": "grpcs://localhost:7050",
      "tlsCACerts": {
        "path": "crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
      },
      "grpcOptions": {
        "ssl-target-name-override": "orderer.example.com",
        "hostnameOverride": "orderer.example.com"
      }
    }
  },
  "channels": {
    "generalchannelapp": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org${org}.example.com": {
          "endorsingPeer": true,
          "chaincodeQuery": true,
          "ledgerQuery": true,
          "eventSource": true
        }
      }
    },
    "securitychannelapp": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org${org}.example.com": {
          "endorsingPeer": true,
          "chaincodeQuery": true,
          "ledgerQuery": true,
          "eventSource": true
        }
      }
    },
    "monitoringchannelapp": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org${org}.example.com": {
          "endorsingPeer": true,
          "chaincodeQuery": true,
          "ledgerQuery": true,
          "eventSource": true
        }
      }
    },
    "iotchannelapp": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org${org}.example.com": {
          "endorsingPeer": true,
          "chaincodeQuery": true,
          "ledgerQuery": true,
          "eventSource": true
        }
      }
    }
EOF
  # افزودن کانال‌های channelapp5 تا channelapp19
  for channel in {5..19}; do
    cat << EOF >> config/connection-org${org}.json
    ,"channelapp${channel}": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org${org}.example.com": {
          "endorsingPeer": true,
          "chaincodeQuery": true,
          "ledgerQuery": true,
          "eventSource": true
        }
      }
    }
EOF
  done
  cat << EOF >> config/connection-org${org}.json
  }
}
EOF
done

echo "Generated connection profiles for all organizations (connection-org1.json to connection-org10.json)"
