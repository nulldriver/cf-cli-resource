> :information_source: **This is a local copy of https://github.com/cloudfoundry/overview-broker which is licensed Apache-2.0. The code in this folder is therefore also licensed under the terms of the Apache License 2.0.**

# Overview Broker

| Job | Status |
| :-: | :----: |
| Unit | ![Unit status](https://hush-house.pivotal.io/api/v1/teams/marketplace/pipelines/best-broker/jobs/absolute-unit/badge) |
| Conformance | ![Conformance status](https://hush-house.pivotal.io/api/v1/teams/marketplace/pipelines/best-broker/jobs/conformance/badge) |
| [Dockerhub](https://hub.docker.com/r/ismteam/overview-broker) | ![Dockerhub status](https://hush-house.pivotal.io/api/v1/teams/marketplace/pipelines/best-broker/jobs/push-to-dockerhub/badge) |

A simple service broker conforming to the [Open Service Broker API](https://github.com/openservicebrokerapi/servicebroker/)
specification that hosts a dashboard showing information on service instances
and bindings created by any platform the broker is registered with.

Other fun features this broker provides include:
* Edit the broker catalog without redeploys to speed up testing
* History of recent requests and responses
* Ability to enable different error modes to test platform integrations
* Change the response mode on the fly (sync only/async only/async where possible)
* A range of configuration parameter schemas for provision service instance,
  update service instance and create service binding
* Asynchronous service instance provisions, updates and deletes
* Asynchronous service binding creates and deletes
* Fetching service instances and bindings
* Generic extensions for fetching the [Health](extensions/health.yaml) and
  [Info](extensions/info.yaml) for a service instance

### What is the Open Service Broker API?

![Open Service Broker API](images/openservicebrokerapi.png)

The [Open Service Broker API](https://www.openservicebrokerapi.org) project
allows developers, ISVs, and SaaS vendors a single, simple, and elegant way to
deliver services to applications running within cloud native platforms such as
Cloud Foundry, OpenShift, and Kubernetes. The project includes individuals from
Fujitsu, Google, IBM, Pivotal, RedHat and SAP.

### Quick start

#### Dockerhub

The latest version of `overview-broker` can always be found on
[Dockerhub](https://hub.docker.com/r/ismteam/overview-broker). You can
pull and run the latest image with:
```bash
docker pull ismteam/overview-broker
docker run ismteam/overview-broker
```

#### Build it
```bash
git clone git@github.com:cloudfoundry/overview-broker.git
cd overview-broker
npm install

# Start overview-broker
npm start

# Or to run the tests
npm test
```

#### Configuration
* To set the BasicAuth credentials, set the `BROKER_USERNAME` and
  `BROKER_PASSWORD` environmental variables. Otherwise the defaults of `admin`
  and `password` will be used.
* To expose a route service, set the `ROUTE_URL`
  environmental variable to a url. It must have https scheme.
* To expose a syslog drain service, set the `SYSLOG_DRAIN_URL`
  environmental variable to a url.
* To expose a volume mount service, set the `EXPOSE_VOLUME_MOUNT_SERVICE`
  environmental variable to `true`.
* To generate many plans with a range of configuration parameter schemas, set
  the `ENABLE_EXAMPLE_SCHEMAS` environmental variable to `true`.
* By default, all asynchronous operations take 1 second to complete. To override
  this, set the `ASYNCHRONOUS_DELAY_IN_SECONDS` environmental variable to the
  number of seconds all operations should take.
* To specify how long platforms should wait before timing out an asynchronous
  operation, set the `MAXIMUM_POLLING_DURATION_IN_SECONDS` environmental
  variable.
* To specify how long Platforms should wait in between polling the
  `/last_operation` endpoint for service instances or bindings, set the
  `POLLING_INTERVAL_IN_SECONDS` environmental variable to the number of seconds
  a platform should wait before trying again.
* To change the name of the service(s) exposed by the service broker, set the
  `SERVICE_NAME` environmental variable.
* To change the description of the service(s) exposed by the service broker,
  set the `SERVICE_DESCRIPTION` environmental variable.
* To set the response mode of the service broker (note that this can also be
  changed via the broker dashboard), set the `RESPONSE_MODE` environmental
  variable to one of the [available modes](app.js#L42).
* To set the error mode of the service broker (note that this can also be
 changed via the broker dashboard), set the `ERROR_MODE` environmental
 variable to one of the [available modes](app.js#L28).

---

### Platforms

#### Cloud Foundry

##### 1. Deploying the broker

* First you will need to deploy the broker as an application:
    ```bash
    cf push overview-broker -i 1 -m 256M -k 256M --random-route -b https://github.com/cloudfoundry/nodejs-buildpack
    ```
* You can also use an application manifest to deploy the broker as an
    application:
    ```bash
    wget https://raw.githubusercontent.com/cloudfoundry/overview-broker/master/examples/cloudfoundry/manifest.yaml
    cf push
    ```
* The overview broker dashboard should now be accessible:
    ```bash
    open "https://$(cf app the-best-broker | awk '/routes:/{ print $2 }')/dashboard"
    ```

##### 2. Registering the broker

* To register the broker to a space (does not require admin credentials), run:
    ```bash
    cf create-service-broker --space-scoped overview-broker admin password <url-of-deployed-broker>
    ```
    The basic auth credentials "admin" and "password" can be specified if needed
    (see [Configuration](#configuration)).
* The services and plans provided by this broker should now be available in the
  marketplace:
  ```bash
  cf marketplace
  ```


##### 3. Creating a service instance

* Now for the exciting part... it's time to create a new service instance:
    ```bash
    cf create-service overview-service small my-instance
    ```
    You can give your service a specific name in the dashboard by providing the
    `name` configuration parameter:
    ```bash
    cf create-service overview-service small my-instance -c '{ "name": "My Service Instance" }'
    ```
* If you now head back to the dashboard, you should see your new service
  instance!

##### 4. Creating a service binding

* To bind the service instance to your application, you will need to first push
  an application to Cloud Foundry with `cf push`. You can then create a new
  binding with:
    ```bash
    cf bind-service <app-name> my-instance
    ```

#### Kubernetes

##### 1. Deploying the broker

* Deploy the broker and a load balancer that will be used to access it:
    ```bash
    wget https://raw.githubusercontent.com/cloudfoundry/overview-broker/master/examples/kubernetes/overview-broker-app.yaml
    wget https://raw.githubusercontent.com/cloudfoundry/overview-broker/master/examples/kubernetes/overview-broker-service.yaml
    kubectl create -f overview-broker-app.yaml
    kubectl create -f overview-broker-service.yaml
    ```
    You can check this has succeeded by running `kubectl get deployments` and
    `kubectl get services`.
* Once the load balancer is up and running, he overview broker dashboard should
  be accessible:
    ```bash
    open "http://$(kubectl get service overview-broker-service -o json | jq -r .status.loadBalancer.ingress[0].ip)/dashboard"
    ```

##### 2. Registering the broker

* To register the broker, you first need to install the Service Catalog. The
  instructions to do this can be found
  [here](https://github.com/kubernetes-sigs/service-catalog/blob/master/docs/install.md).
  If service catalog fails to install due to permissions, you might want to look
  at [this guide](https://helm.sh/docs/using_helm/#tiller-and-role-based-access-control).
* You should now be able to register the service broker you deployed earlier
  by creating a `clusterservicebrokers` custom resource:
    ```bash
    BROKER_URL="http://$(kubectl get service overview-broker-service -o json | jq -r .status.loadBalancer.ingress[0].ip)"
    cat <<EOF | kubectl create -f -
    apiVersion: v1
    kind: Secret
    metadata:
      name: overview-broker-secret
      namespace: default
    type: Opaque
    stringData:
      username: admin
      password: password
    EOF
    cat <<EOF | kubectl create -f -
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ClusterServiceBroker
    metadata:
      name: overview-broker
      namespace: default
    spec:
      url: ${BROKER_URL}
      authInfo:
        basic:
          secretRef:
            name: overview-broker-secret
            namespace: default
    EOF
   ```
  Note that if you changed the default basic auth credentials (see
  [Configuration](#configuration)), then you will need to change the Secret
  defined above.
* The services and plans provided by this broker should now be available:
    ```bash
    kubectl get clusterserviceclasses
    kubectl get clusterserviceplans
    ```

##### 3. Creating a service instance

* Now for the exciting part... it's time to create a new service instance:
    ```bash
    cat <<EOF | kubectl create -f -
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceInstance
    metadata:
      name: my-instance
      namespace: default
    spec:
      clusterServiceClassExternalName: overview-service
      clusterServicePlanExternalName: small
    EOF
    ```
* If you now head back to the dashboard, you should see your new service
  instance!

##### 4. Creating a service binding

* Creating a service binding with service-catalog will result in a new Secret
  being created which represents the information returned from the service
  broker for the binding. To create a new service binding, you can run:
    ```bash
    cat <<EOF | kubectl create -f -
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: my-instance-binding
      namespace: default
    spec:
      instanceRef:
        name: my-instance
      secretName: my-instance-secret
    EOF
    ```
  To see the contents of the service binding, you can get the associated secret
  with:
    ```bash
    kubectl get secret my-instance-secret -o yaml
    ```
  Note that the data shown will be base64 encoded.
