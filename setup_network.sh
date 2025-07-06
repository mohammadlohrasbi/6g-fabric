#!/bin/bash

# تنظیم متغیرهای محیطی
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt

# بررسی نسخه configtxgen
echo "Checking configtxgen version..."
configtxgen --version
if [ $? -ne 0 ]; then
  echo "Error: configtxgen not found or not installed correctly"
  exit 1
fi

# بررسی وجود فایل configtx.yaml
if [ ! -f "${FABRIC_CFG_PATH}/configtx.yaml" ]; then
  echo "Error: configtx.yaml not found in ${FABRIC_CFG_PATH}"
  exit 1
fi

# بررسی وجود فایل‌های core.yaml
for org in {1..10}; do
  if [ ! -f "${FABRIC_CFG_PATH}/core-org${org}.yaml" ]; then
    echo "Error: core-org${org}.yaml not found in ${FABRIC_CFG_PATH}"
    exit 1
  fi
done

# تابع برای تنظیم هویت سازمان
setOrg() {
  local org=$1
  local peer=$2
  local port=$3
  export CORE_PEER_LOCALMSPID="Org${org}MSP"
  export CORE_PEER_TLS_ROOTCA_FILE=${PWD}/crypto-config/peerOrganizations/org${org}.example.com/peers/peer0.org${org}.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/org${org}.example.com/users/Admin@org${org}.example.com/msp
  export CORE_PEER_ADDRESS=peer0.org${org}.example.com:${port}
  export FABRIC_CFG_PATH=${PWD}/config
  export CORE_PEER_FILESYSTEMPATH=/var/hyperledger/production
}

# تولید بلوک جنسیس
echo "Generating genesis block..."
configtxgen -profile GeneralGenesis -outputBlock ./genesis.block -configPath ${FABRIC_CFG_PATH}
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate genesis block"
  exit 1
fi

# تولید فایل‌های تراکنش کانال‌ها
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  echo "Generating channel transaction for ${channel}..."
  configtxgen -profile ${channel^} -outputCreateChannelTx ./${channel}.tx -channelID ${channel} -configPath ${FABRIC_CFG_PATH}
  if [ $? -ne 0 ]; then
    echo "Error: Failed to generate channel transaction for ${channel}"
    exit 1
  fi
done

# راه‌اندازی کانال‌ها
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  echo "Creating channel ${channel}..."
  setOrg 1 peer0.org1.example.com 7051
  peer channel create -o orderer.example.com:7050 -c ${channel} -f ./${channel}.tx --tls --cafile $ORDERER_CA
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create channel ${channel}"
    exit 1
  fi
  for org in {1..10}; do
    port=$((7051 + (org-1)*1000))
    setOrg ${org} peer0.org${org}.example.com ${port}
    peer channel join -b ${channel}.block
    if [ $? -ne 0 ]; then
      echo "Error: Org${org} failed to join channel ${channel}"
      exit 1
    fi
  done
done

# نصب و راه‌اندازی قراردادهای هوشمند
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  echo "Installing chaincodes on channel ${channel}..."
  # قراردادهای جغرافیایی (10 قرارداد)
  for geo_cc in {1..10}; do
    cc_name="geo_cc${geo_cc}"
    for org in {1..10}; do
      port=$((7051 + (org-1)*1000))
      setOrg ${org} peer0.org${org}.example.com ${port}
      peer chaincode install -n ${cc_name} -v 1.0 -p chaincode/geo_cc${geo_cc}
      if [ $? -ne 0 ]; then
        echo "Error: Failed to install chaincode ${cc_name} on Org${org}"
        exit 1
      fi
      if [ $org -eq 1 ]; then
        peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C ${channel} -n ${cc_name} -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member','Org6MSP.member','Org7MSP.member','Org8MSP.member','Org9MSP.member','Org10MSP.member')"
        if [ $? -ne 0 ]; then
          echo "Error: Failed to instantiate chaincode ${cc_name} on channel ${channel}"
          exit 1
        fi
      fi
    done
  done
  # قراردادهای عمومی (75 قرارداد)
  for public_cc in {1..75}; do
    cc_name="public_cc${public_cc}"
    for org in {1..10}; do
      port=$((7051 + (org-1)*1000))
      setOrg ${org} peer0.org${org}.example.com ${port}
      peer chaincode install -n ${cc_name} -v 1.0 -p chaincode/public_cc${public_cc}
      if [ $? -ne 0 ]; then
        echo "Error: Failed to install chaincode ${cc_name} on Org${org}"
        exit 1
      fi
      if [ $org -eq 1 ]; then
        peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C ${channel} -n ${cc_name} -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member','Org6MSP.member','Org7MSP.member','Org8MSP.member','Org9MSP.member','Org10MSP.member')"
        if [ $? -ne 0 ]; then
          echo "Error: Failed to instantiate chaincode ${cc_name} on channel ${channel}"
          exit 1
        fi
      fi
    done
  done
done

echo "Network setup completed with 19 channels and 85 chaincodes per channel."
