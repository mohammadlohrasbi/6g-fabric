#!/bin/bash

mkdir -p caliper-benchmarks

cat << EOF > caliper-benchmarks/benchmark.yaml
test:
  name: blockchain-performance-test
  description: Performance test for Hyperledger Fabric chaincodes
  workers:
    number: 10
  rounds:
EOF

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
    cat << EOF >> caliper-benchmarks/benchmark.yaml
    - txNumber: 1000
      rateControl:
        type: fixed-rate
        opts:
          tps: 100
      workload:
        module: workload.js
        arguments:
          chaincodeID: ${chaincode}
          channel: ${channel}
          txType: invoke
          contractFunction: AssignResource
          contractArguments: ["resource${RANDOM}", "100", "$(date -u +%Y-%m-%dT%H:%M:%SZ)", "$(date -u +%Y-%m-%dT%H:%M:%SZ)"]
    - txNumber: 500
      rateControl:
        type: fixed-rate
        opts:
          tps: 50
      workload:
        module: workload.js
        arguments:
          chaincodeID: ${chaincode}
          channel: ${channel}
          txType: query
          contractFunction: QueryResource
          contractArguments: ["resource${RANDOM}"]
EOF
  done
done

cat << EOF >> caliper-benchmarks/benchmark.yaml
network:
  config: ../networkConfig.yaml
  fabric:
    connectionProfile: connection-org1.json
    walletPath: wallet
EOF

cat << EOF > caliper-benchmarks/workload.js
'use strict';

module.exports.info = 'Custom workload for testing chaincodes';

let bc, contx;

module.exports.init = async function(blockchain, context, args) {
    bc = blockchain;
    contx = context;
    contx.chaincodeID = args.chaincodeID;
    contx.channel = args.channel;
    contx.txType = args.txType;
    contx.contractFunction = args.contractFunction;
    contx.contractArguments = args.contractArguments;
};

module.exports.run = async function() {
    let args = {
        chaincodeFunction: contx.contractFunction,
        chaincodeArguments: contx.contractArguments
    };
    if (contx.txType === 'invoke') {
        return bc.invokeSmartContract(contx, contx.chaincodeID, contx.channel, args);
    } else {
        return bc.querySmartContract(contx, contx.chaincodeID, contx.channel, args);
    }
};

module.exports.end = async function() {
    return Promise.resolve();
};
EOF

echo "Generated Caliper benchmark configuration"
