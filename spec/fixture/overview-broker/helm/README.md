# Helm chart for Overview Broker

Helm chart which creates a deployment for the overview and registers it with
service catalog

```
helm install test-broker .
```

| Option  | Default | Description
|---------|---------|-------------|
|register |true     | set `false` to create broker without also creating service-catalog ClusterServiceBroker to register it in the cluster
|brokerUsername | random 24 char alpha numeric     | override default generated username
|brokerPassword | random 24 char alpha numeric     | override default generated password
