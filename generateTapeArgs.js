const fs = require('fs');

const contracts = [
  { name: 'GeoBasedAllocation', channel: 'generalchannelapp', invoke: 'AssignToNearestAntenna', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'AntennaLoadBalancer', channel: 'generalchannelapp', invoke: 'AssignToBalancedAntenna', invokeArgs: ['userID', '100'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoPriorityAssign', channel: 'generalchannelapp', invoke: 'AssignWithPriority', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'DynamicGeoSwitch', channel: 'generalchannelapp', invoke: 'SwitchToNearestAntenna', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoClusterAssign', channel: 'generalchannelapp', invoke: 'AssignToCluster', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoSignalStrength', channel: 'generalchannelapp', invoke: 'AssignBySignalStrength', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoLatencyOptimizer', channel: 'generalchannelapp', invoke: 'AssignByLatency', invokeArgs: ['userID', '100'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoEnergyEfficient', channel: 'generalchannelapp', invoke: 'AssignByEnergy', invokeArgs: ['userID', '100'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoMultiAntennaAssign', channel: 'generalchannelapp', invoke: 'AssignToMultipleAntennas', invokeArgs: ['userID', '2'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'GeoPathLossAssign', channel: 'generalchannelapp', invoke: 'AssignByPathLoss', invokeArgs: ['userID'], query: 'QueryAssignment', queryArgs: ['userID'] },
  { name: 'ResourceAllocate', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'BandwidthShare', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DynamicRouting', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'LoadBalance', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'UserAuth', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ThreatDetect', channel: 'securitychannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'NetworkMonitor', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DataAnalytics', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'TransactionAudit', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ComplianceAudit', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'FaultDetect', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PredictiveMaintenance', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ResourceMonitor', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'QoSMonitor', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'LatencyTracker', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'EnergyOptimizer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'SecurityAudit', channel: 'securitychannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PolicyEnforcer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DataIntegrity', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'AccessControl', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PerformanceMonitor', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'NetworkOptimizer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'TrafficManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ServiceAllocator', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'IoTManager', channel: 'iotchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DeviceRegistry', channel: 'iotchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'SignalOptimizer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ChannelManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ResourceScheduler', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'FaultTolerance', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DataValidator', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'NetworkDiagnostics', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'UserManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'AntennaManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ClusterManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'GeoTracker', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'LoadDistributor', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PriorityManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DynamicAllocator', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'EnergyTracker', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'SignalMonitor', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'LatencyOptimizer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PathLossCalculator', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'RedundancyManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'FailoverHandler', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ResourceBalancer', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'NetworkPlanner', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'IoTController', channel: 'iotchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'SecurityEnforcer', channel: 'securitychannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ComplianceTracker', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'AuditManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'PerformanceAnalyzer', channel: 'monitoringchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ServiceTracker', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'ResourceController', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'NetworkManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] },
  { name: 'DataManager', channel: 'generalchannelapp', invoke: 'AssignResource', invokeArgs: ['resourceID', 'amount', 'start', 'end'], query: 'QueryResource', queryArgs: ['resourceID'] }
];

function generateRandomID() {
  return 'ID_' + Math.random().toString(36).substr(2, 9);
}

function generateRandomAmount() {
  return Math.floor(Math.random() * 1000).toString();
}

function generateRandomTimestamp() {
  const now = new Date();
  now.setSeconds(now.getSeconds() + Math.floor(Math.random() * 3600));
  return now.toISOString();
}

const tapeArgs = contracts.map(contract => {
  const invokeArgs = contract.invokeArgs.map(arg => {
    if (arg === 'userID' || arg === 'resourceID') return generateRandomID();
    if (arg === 'amount') return generateRandomAmount();
    if (arg === 'start' || arg === 'end') return generateRandomTimestamp();
    return arg;
  });
  const queryArgs = contract.queryArgs.map(arg => {
    if (arg === 'userID' || arg === 'resourceID') return generateRandomID();
    return arg;
  });
  return {
    contractId: contract.name,
    channel: contract.channel,
    chaincodeFunction: contract.invoke,
    chaincodeArgs: invokeArgs,
    queryFunction: contract.query,
    queryArgs: queryArgs
  };
});

fs.writeFileSync('tape_args.json', JSON.stringify(tapeArgs, null, 2));
console.log('Generated tape_args.json');
