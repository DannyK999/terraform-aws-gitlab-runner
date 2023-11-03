#!/bin/bash -e
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

if [[ $(echo ${user_data_trace_log}) == false ]]; then
  set -x
fi

# Add current hostname to hosts file
tee /etc/hosts <<EOL
127.0.0.1   localhost localhost.localdomain $(hostname)
EOL

${eip}

for i in {1..7}; do
  echo "Attempt: ---- " $i
  yum -y update && break || sleep 60
done

# Adding workaround based on: https://github.com/awslabs/amazon-eks-ami/issues/1500
if yum list installed | grep amazon-ssm-agent; then
  echo "amazon-ssm-agent already present - skipping install"
else
  sudo yum install -y amazon-ssm-agent
  echo "Installing amazon-ssm-agent"
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi

systemctl restart amazon-ssm-agent

${logging}

${gitlab_runner}
