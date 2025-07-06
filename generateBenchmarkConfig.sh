#!/bin/bash

# دایرکتوری برای فایل‌های پیکربندی
mkdir -p config

# تولید فایل benchmark.yaml
cat << EOF > config/benchmark.yaml
test:
  name: fabric-benchmark
  description: Benchmark for Hyperledger Fabric with 19 channels and 85 chaincodes
  workers:
    type: local
    number: 10
  rounds:
EOF

# تولید دورهای تست برای هر کانال
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp {5..19}; do
  if [[ $channel =~ [0-9] ]]; then
    channel_name="channelapp${channel}"
  else
    channel_name="${channel}"
  fi
  # دورهای تست برای قراردادهای جغرافیایی
  for geo_cc in {1..10}; do
    cat << EOF >> config/benchmark.yaml
    - label: ${channel_name}_geo_cc${geo_cc}_invoke
      txType: invoke
      chaincodeID: geo_cc${geo_cc}
      channel: ${channel_name}
      contractFunction: AssignResource
      contractArguments: ["resourceID", "amount", "start", "end"]
      rateControl:
        type: fixed-rate
        opts:
          tps: 100
      workload:
        module: workload/callback.js
    - label: ${channel_name}_geo_cc${geo_cc}_query
      txType: query
      chaincodeID: geo_cc${geo_cc}
      channel: ${channel_name}
      contractFunction: QueryResource
      contractArguments: ["resourceID"]
      rateControl:
        type: fixed-rate
        opts:
          tps: 200
      workload:
        module: workload/callback.js
EOF
  done
  # دورهای تست برای قراردادهای عمومی
  for public_cc in {1..75}; do
    cat << EOF >> config/benchmark.yaml
    - label: ${channel_name}_public_cc${public_cc}_invoke
      txType: invoke
      chaincodeID: public_cc${public_cc}
      channel: ${channel_name}
      contractFunction: AssignResource
      contractArguments: ["resourceID", "amount", "start", "end"]
      rateControl:
        type: fixed-rate
        opts:
          tps: 100
      workload:
        module: workload/callback.js
    - label: ${channel_name}_public_cc${public_cc}_query
      txType: query
      chaincodeID: public_cc${public_cc}
      channel: ${channel_name}
      contractFunction: QueryResource
      contractArguments: ["resourceID"]
      rateControl:
        type: fixed-rate
        opts:
          tps: 200
      workload:
        module: workload/callback.js
EOF
  done
done

cat << EOF >> config/benchmark.yaml
network:
  fabric:
    topology: config/networkConfig.yaml
    connectionProfile:
      path: config/connection-org1.json
      discover: true
monitor:
  type:
    - docker
  docker:
    name:
      - peer0.org1.example.com
      - peer0.org2.example.com
      - peer0.org3.example.com
      - peer0.org4.example.com
      - peer0.org5.example.com
      - peer0.org6.example.com
      - peer0.org7.example.com
      - peer0.org8.example.com
      - peer0.org9.example.com
      - peer0.org10.example.com
      - orderer.example.com
  interval: 1
EOF

echo "Generated config/benchmark.yaml"
