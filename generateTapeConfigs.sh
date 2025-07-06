#!/bin/bash

# دایرکتوری برای فایل‌های پیکربندی
mkdir -p config

# تولید فایل tape-config.yaml
cat << EOF > config/tape-config.yaml
network:
  fabric:
    topology: config/networkConfig.yaml
    connectionProfile:
      path: config/connection-org1.json
      discover: true
test:
  channels:
EOF

# افزودن کانال‌ها
for channel in generalchannelapp securitychannelapp monitoringchannelapp iotchannelapp {5..19}; do
  if [[ $channel =~ [0-9] ]]; then
    channel_name="channelapp${channel}"
  else
    channel_name="${channel}"
  fi
  cat << EOF >> config/tape-config.yaml
    - name: ${channel_name}
      chaincodes:
EOF
  # قراردادهای جغرافیایی
  for geo_cc in {1..10}; do
    cat << EOF >> config/tape-config.yaml
        - id: geo_cc${geo_cc}
          version: v1
          functions:
            - name: AssignResource
              args: ["resourceID", "amount", "start", "end"]
            - name: QueryResource
              args: ["resourceID"]
EOF
  done
  # قراردادهای عمومی
  for public_cc in {1..75}; do
    cat << EOF >> config/tape-config.yaml
        - id: public_cc${public_cc}
          version: v1
          functions:
            - name: AssignResource
              args: ["resourceID", "amount", "start", "end"]
            - name: QueryResource
              args: ["resourceID"]
EOF
  done
done

cat << EOF >> config/tape-config.yaml
tape:
  host: localhost
  port: 3000
  numberOfWorkers: 10
  tps: 200
EOF

echo "Generated config/tape-config.yaml"
