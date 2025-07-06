#!/bin/bash

# Generate crypto materials
cryptogen generate --config=./crypto-config.yaml

# Generate genesis block and channel transactions
configtxgen -profile GeneralGenesis -outputBlock ./genesis.block
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  configtxgen -profile ${channel^} -outputCreateChannelTx ./${channel}.tx -channelID ${channel}
done

# Start the network
docker-compose -f docker-compose.yaml up -d

# Create channels
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  peer channel create -o orderer.example.com:7050 -c ${channel} -f ./${channel}.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
  peer channel join -b ${channel}.block
done

# Install and instantiate chaincodes
chaincodes=(
  "GeoBasedAllocation"
  "AntennaLoadBalancer"
  "GeoPriorityAssign"
  "DynamicGeoSwitch"
  "GeoClusterAssign"
  "GeoSignalStrength"
  "GeoLatencyOptimizer"
  "GeoEnergyEfficient"
  "GeoMultiAntennaAssign"
  "GeoPathLossAssign"
  "ResourceAllocate"
  "BandwidthShare"
  "DynamicRouting"
  "LoadBalance"
  "UserAuth"
  "ThreatDetect"
  "NetworkMonitor"
  "DataAnalytics"
  "TransactionAudit"
  "ComplianceAudit"
  "FaultDetect"
  "PredictiveMaintenance"
  "ResourceMonitor"
  "QoSMonitor"
  "LatencyTracker"
  "EnergyOptimizer"
  "SecurityAudit"
  "PolicyEnforcer"
  "DataIntegrity"
  "AccessControl"
  "PerformanceMonitor"
  "NetworkOptimizer"
  "TrafficManager"
  "ServiceAllocator"
  "IoTManager"
  "DeviceRegistry"
  "SignalOptimizer"
  "ChannelManager"
  "ResourceScheduler"
  "FaultTolerance"
  "DataValidator"
  "NetworkDiagnostics"
  "UserManager"
  "AntennaManager"
  "ClusterManager"
  "GeoTracker"
  "LoadDistributor"
  "PriorityManager"
  "DynamicAllocator"
  "EnergyTracker"
  "SignalMonitor"
  "LatencyOptimizer"
  "PathLossCalculator"
  "RedundancyManager"
  "FailoverHandler"
  "ResourceBalancer"
  "NetworkPlanner"
  "IoTController"
  "SecurityEnforcer"
  "ComplianceTracker"
  "AuditManager"
  "PerformanceAnalyzer"
  "ServiceTracker"
  "ResourceController"
  "NetworkManager"
  "DataManager"
)

for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp channelapp{5..19}; do
  for chaincode in "${chaincodes[@]}"; do
    peer chaincode install -n ${chaincode} -v 1.0 -p github.com/chaincode/${chaincode}
    peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt -C ${channel} -n ${chaincode} -v 1.0 -c '{"Args":["Init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
  done
done

echo "Network setup and chaincodes deployed"
