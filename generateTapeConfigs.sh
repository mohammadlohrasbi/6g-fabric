#!/bin/bash

mkdir -p tape-configs

channels=(
  "generalchannelapp"
  "securitychannelapp"
  "monitoringchannelapp"
  "iotchannelapp"
  "channelapp5"
  "channelapp6"
  "channelapp7"
  "channelapp8"
  "channelapp9"
  "channelapp10"
  "channelapp11"
  "channelapp12"
  "channelapp13"
  "channelapp14"
  "channelapp15"
  "channelapp16"
  "channelapp17"
  "channelapp18"
  "channelapp19"
)

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

for channel in "${channels[@]}"; do
  for chaincode in "${chaincodes[@]}"; do
    cat << EOF > tape-configs/config_${chaincode}_${channel}.yaml
target: localhost:7050
channel: ${channel}
contractID: ${chaincode}
ccType: golang
nProc: 10
rate: 100
txDuration: 60
arguments:
  chaincodeFunction: AssignResource
  chaincodeArguments:
    - resource${RANDOM}
    - "100"
    - "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    - "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
query:
  chaincodeFunction: QueryResource
  chaincodeArguments:
    - resource${RANDOM}
EOF
  done
done

echo "Generated Tape configuration files"
