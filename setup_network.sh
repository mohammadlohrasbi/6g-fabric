#!/bin/bash

# تنظیم متغیرهای محیطی
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt

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
  export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
}

# تولید بلوک جنسیس
configtxgen -profile GeneralGenesis -outputBlock ./genesis.block -configPath ${FABRIC_CFG_PATH}

# تولید کانال‌ها
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp {5..19}; do
  if [[ $channel =~ [0-9] ]]; then
    channel_name="channelapp${channel}"
  else
    channel_name="${channel}"
  fi
  configtxgen -profile ${channel_name^} -outputCreateChannelTx ./${channel_name}.tx -channelID ${channel_name} -configPath ${FABRIC_CFG_PATH}
done

# راه‌اندازی کانال‌ها
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp {5..19}; do
  if [[ $channel =~ [0-9] ]]; then
    channel_name="channelapp${channel}"
  else
    channel_name="${channel}"
  fi
  setOrg 1 peer0.org1.example.com 7051
  peer channel create -o orderer.example.com:7050 -c ${channel_name} -f ./${channel_name}.tx --tls --cafile $ORDERER_CA
  for org in {1..10}; do
    port=$((7051 + (org-1)*1000))
    setOrg ${org} peer0.org${org}.example.com ${port}
    peer channel join -b ${channel_name}.block
  done
done

# نصب و راه‌اندازی قراردادهای هوشمند
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp {5..19}; do
  if [[ $channel =~ [0-9] ]]; then
    channel_name="channelapp${channel}"
  else
    channel_name="${channel}"
  fi
  # قراردادهای جغرافیایی (10 قرارداد)
  for geo_cc in {1..10}; do
    cc_name="geo_cc${geo_cc}"
    for org in {1..10}; do
      port=$((7051 + (org-1)*1000))
      setOrg ${org} peer0.org${org}.example.com ${port}
      peer chaincode install -n ${cc_name} -v 1.0 -p chaincode/geo_cc${geo_cc}
      if [ $org -eq 1 ]; then
        peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C ${channel_name} -n ${cc_name} -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member','Org6MSP.member','Org7MSP.member','Org8MSP.member','Org9MSP.member','Org10MSP.member')"
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
      if [ $org -eq 1 ]; then
        peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C ${channel_name} -n ${cc_name} -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member','Org6MSP.member','Org7MSP.member','Org8MSP.member','Org9MSP.member','Org10MSP.member')"
      fi
    done
  done
done

echo "Network setup completed with 19 channels and 85 chaincodes per channel."
