## Requirements

```bash
brew install ansible
ansible-galaxy install weldpua2008.openjdk
ansible-galaxy install AnsibleShipyard.ansible-zookeeper
```

## Provisioning

### Zookeeper Cluster Setup

```bash
# install zookeeper
./generated.provision-zookeeper.sh

# verification
sudo tail -F /var/log/zookeeper/zookeeper.log
cat /opt/zookeeper-3.4.12/conf/zoo.cfg
cat /var/lib/zookeeper/myid
```
