

sudo rpm --install https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo yum install -y  amazon-cloudwatch-agent git java-1.8.0-openjdk-devel mariadb unzip

git clone https://github.com/aws-samples/unishop-monolith-to-microservices.git /home/ec2-user/MonoToMicro


cd /home/ec2-user/
wget https://services.gradle.org/distributions/gradle-5.6.3-bin.zip
unzip -d /home/ec2-user/ /home/ec2-user/gradle-5.6.3-bin.zip
export PATH=$PATH:/home/ec2-user/gradle-5.6.3/bin
cd /home/ec2-user/MonoToMicro/MonoToMicroLegacy
gradle clean build

sudo su -

cat << EOF >> /etc/systemd/system/mono2micro.service
[Unit]
Description=Restart Mono2Micro
Wants=network.target
After=syslog.target network-online.target amazon-cloudwatch-agent.target
[Service]
Type=simple
ExecStart=/home/ec2-user/MonoToMicro/m2minit.sh
Restart=on-failure
RestartSec=60
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/mono2micro.service
ls -ltarh /etc/systemd/system/mono2micro.service


cat << EOF >> /home/ec2-user/MonoToMicro/m2minit.sh
#!/bin/bash
source /home/ec2-user/MonoToMicro/m2mcfg.sh
source /home/ec2-user/MonoToMicro/m2mrun.sh
EOF

chmod 555 /home/ec2-user/MonoToMicro/m2minit.sh
chown ec2-user:ec2-user /home/ec2-user/MonoToMicro/m2minit.sh


cat << EOF >> /home/ec2-user/MonoToMicro/m2mcfg.sh
#!/bin/bash
export Database=_DATABASE_ENDPOINT_
export MONO_TO_MICRO_DB_ENDPOINT=_DATABASE_ENDPOINT_
export AWS_DEFAULT_REGION=_AWS_REGION_
export UI_RANDOM_NAME=_UI_BUCKET_NAME_
export ASSETS_RANDOM_NAME=_ASSET_BUCKET_NAME_
export PATH=$PATH:/home/ec2-user/gradle-5.6.3/bin
EOF

chmod 555 /home/ec2-user/MonoToMicro/m2mcfg.sh 
chown ec2-user:ec2-user /home/ec2-user/MonoToMicro/m2mcfg.sh


cat << EOF >> /home/ec2-user/MonoToMicro/m2mrun.sh
#!/bin/bash
java -jar /home/ec2-user/MonoToMicro/MonoToMicroLegacy/build/libs/MonoToMicroLegacy-0.0.1-SNAPSHOT.jar
  &> /home/ec2-user/MonoToMicro/MonoToMicroLegacy/build/libs/app.log &
EOF

chmod 555 /home/ec2-user/MonoToMicro/m2mrun.sh
chown ec2-user:ec2-user /home/ec2-user/MonoToMicro/m2mrun.sh


cat << EOF >> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ec2-user/MonoToMicro/MonoToMicroLegacy/build/libs/app.log",
            "log_group_name": "_LOG_GROUP_NAME_",
            "log_stream_name": "_LOG_GROUP_NAME_-app",
            "timezone": "Local"
          }
        ]
      }
    }
  }
}
EOF

chmod 444 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
chown ec2-user:ec2-user /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json