var express = require('express'),
    moment = require('moment'),
    cfenv = require('cfenv'),
    randomstring = require('randomstring'),
    Logger = require('./logger'),
    GenerateUUID = require ('./uuid-generator'),
    ServiceBroker = require('./service_broker');

const { header, body, param, query, validationResult } = require('express-validator');
const { NIL } = require('uuid');

class ServiceBrokerInterface {

    constructor() {
        this.serviceBroker = new ServiceBroker();
        this.logger = new Logger();
        this.serviceInstances = {};
        this.latestRequests = [];
        this.latestResponses = [];
        this.instanceOperations = {};
        this.bindingOperations = {};
        this.numRequestsToSave = 5;
        this.numResponsesToSave = 5;
        this.started = moment().toString();

        // Check for completed asynchronous operations every 10 seconds
        var self = this;
        setInterval(() => { self.checkAsyncOperations() }, 10000);
    }

    checkRequest() {
        return [
            // Check for version header
            header('X-Broker-Api-Version', 'Missing broker api version').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 412, { error: JSON.stringify(errors) });
                    return;
                }
                next();
            }
        ]
    }

    getCatalog(request, response) {
        var data = this.serviceBroker.getCatalog();
        this.sendJSONResponse(response, 200, data);
    }

    createServiceInstance() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            body('service_id', 'Missing service_id').exists(),
            body('plan_id', 'Missing plan_id').exists(),
            body('organization_guid', 'Missing organization_guid').exists(),
            body('space_guid', 'Missing space_guid').exists(),
            (request, response) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                var serviceInstanceId = request.params.instance_id;
                let dashboardUrl = `${this.serviceBroker.getDashboardUrl()}?time=${new Date().toISOString()}`;
                let data = {
                    dashboard_url: dashboardUrl
                };

                // Check if we only support asynchronous operations
                if (process.env.responseMode == 'async' && request.query.accepts_incomplete != 'true') {
                    this.sendJSONResponse(response, 422, { error: 'AsyncRequired' } );
                    return;
                }

                // Check if the instance already exists
                if (serviceInstanceId in this.serviceInstances) {
                    // Check if different sevice or plan ID
                    if (
                        request.body.service_id != this.serviceInstances[serviceInstanceId].service_id ||
                        request.body.plan_id != this.serviceInstances[serviceInstanceId].plan_id ||
                        request.body.organization_guid != this.serviceInstances[serviceInstanceId].organization_guid ||
                        request.body.space_guid != this.serviceInstances[serviceInstanceId].space_guid) {
                        this.sendJSONResponse(response, 409, { error: 'Service or plan ID does not match' });
                        return;
                    }
                    // Check if a provision is already in progress
                    var operation = this.instanceOperations[serviceInstanceId];
                    if (operation && operation.type == 'provision' && operation.state == 'in progress') {
                        this.sendJSONResponse(response, 202, data);
                        return;
                    }
                    this.sendJSONResponse(response, 200, data);
                    return;
                }

                // Validate serviceId and planId
                var service = this.serviceBroker.getService(request.body.service_id);
                var plan = this.serviceBroker.getPlanForService(request.body.service_id, request.body.plan_id);
                if (!plan) {
                    this.sendJSONResponse(response, 400, { error: `Could not find service ${request.body.service_id}, plan ${request.body.plan_id}` });
                    return;
                }

                // Validate any configuration parameters if we have a schema
                var schema = null;
                try {
                    schema = plan.schemas.service_instance.create.parameters;
                }
                catch (e) {
                    // No schema to validate with
                }
                if (schema) {
                    var validationErrors = this.serviceBroker.validateParameters(schema, (request.body.parameters || {}));
                    if (validationErrors) {
                        this.sendJSONResponse(response, 400, { error: JSON.stringify(validationErrors) });
                        return;
                    }
                }

                // Validate maintenance info we were provided it
                if (request.body.maintenance_info) {
                    if (request.body.maintenance_info.version != plan.maintenance_info.version) {
                        this.sendJSONResponse(response, 422, { error: 'MaintenanceInfoConflict' } );
                        return;
                    }
                }

                // Create the service instance
                this.logger.debug(`Creating service instance ${serviceInstanceId} using service ${request.body.service_id} and plan ${request.body.plan_id}`);

                this.serviceInstances[serviceInstanceId] = {
                    created: moment().toString(),
                    last_updated: 'never',
                    api_version: request.header('X-Broker-Api-Version'),
                    service_id: request.body.service_id,
                    service_name: service.name,
                    plan_id: request.body.plan_id,
                    plan_name: plan.name,
                    parameters: request.body.parameters || {},
                    accepts_incomplete: (request.query.accepts_incomplete == 'true'),
                    organization_guid: request.body.organization_guid,
                    space_guid: request.body.space_guid,
                    context: request.body.context || {},
                    bindings: {},
                    data: data
                };

                if ((request.query.accepts_incomplete == 'true' && (process.env.responseMode == 'default') || process.env.responseMode == 'async')) {
                    // Set the end time for the operation to be one second from now
                    // unless an explicit delay was requested
                    var endTime = new Date();
                    if (parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS)) {
                        endTime.setSeconds(endTime.getSeconds() + parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS));
                    }
                    else {
                        endTime.setSeconds(endTime.getSeconds() + 1);
                    }
                    this.instanceOperations[serviceInstanceId] = {
                        type: 'provision',
                        state: 'in progress',
                        endTime: endTime
                    };
                    this.sendJSONResponse(response, 202, data);
                    return;
                }

                // Else return the data synchronously
                this.sendJSONResponse(response, 201, data);
            }
        ]
    }

    updateServiceInstance() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            body('service_id', 'Missing service_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                var serviceInstanceId = request.params.instance_id;

                var plan = null;
                if (request.body.plan_id) {
                    plan = this.serviceBroker.getPlanForService(request.body.service_id, request.body.plan_id);
                } else {
                    let service_id = this.serviceInstances[serviceInstanceId].service_id;
                    let plan_id = this.serviceInstances[serviceInstanceId].plan_id;
                    plan = this.serviceBroker.getPlanForService(service_id, plan_id);
                }

                // Validate serviceId and planId
                if (!plan) {
                    this.sendJSONResponse(response, 400, { error: `Could not find service ${request.body.service_id}, plan ${request.body.planid}` });
                    return;
                }

                // Check if we only support asynchronous operations
                if (process.env.responseMode == 'async' && request.query.accepts_incomplete != 'true') {
                    this.sendJSONResponse(response, 422, { error: 'AsyncRequired' } );
                    return;
                }

                // Validate any configuration parameters if we have a schema
                var schema = null;
                try {
                    schema = plan.schemas.service_instance.update.parameters;
                }
                catch (e) {
                    // No schema to validate with
                }
                if (schema) {
                    var validationErrors = this.serviceBroker.validateParameters(schema, (request.body.parameters || {}));
                    if (validationErrors) {
                        this.sendJSONResponse(response, 400, { error: JSON.stringify(validationErrors) });
                        return;
                    }
                }

                // Validate maintenance info we were provided it
                if (request.body.maintenance_info) {
                    if (request.body.maintenance_info.version != plan.maintenance_info.version) {
                        this.sendJSONResponse(response, 422, { error: 'MaintenanceInfoConflict' } );
                        return;
                    }
                }

                this.logger.debug(`Updating service ${serviceInstanceId}`);

                // Check if an operation is in progress
                var operation = this.instanceOperations[serviceInstanceId];
                if (operation && operation.state == 'in progress') {
                    this.sendJSONResponse(response, 422,  { error: 'ConcurrencyError' });
                    return;
                }

                this.serviceInstances[serviceInstanceId].api_version = request.header('X-Broker-Api-Version'),
                this.serviceInstances[serviceInstanceId].service_id = request.body.service_id;
                this.serviceInstances[serviceInstanceId].plan_id = plan.id;
                this.serviceInstances[serviceInstanceId].plan_name = plan.name;
                this.serviceInstances[serviceInstanceId].parameters = request.body.parameters || {};
                this.serviceInstances[serviceInstanceId].context = request.body.context || {};
                this.serviceInstances[serviceInstanceId].last_updated = moment().toString();

                let dashboardUrl = `${this.serviceBroker.getDashboardUrl()}?time=${new Date().toISOString()}`;
                let data = {
                    dashboard_url: dashboardUrl
                };

                if ((request.query.accepts_incomplete == 'true' && (process.env.responseMode == 'default') || process.env.responseMode == 'async')) {
                    // Set the end time for the operation to be one second from now
                    // unless an explicit delay was requested
                    var endTime = new Date();
                    if (parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS)) {
                        endTime.setSeconds(endTime.getSeconds() + parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS));
                    }
                    else {
                        endTime.setSeconds(endTime.getSeconds() + 1);
                    }
                    this.instanceOperations[serviceInstanceId] = {
                        type: 'update',
                        state: 'in progress',
                        endTime: endTime
                    };
                    this.sendJSONResponse(response, 202, data);
                    return;
                }

                // Else return the data synchronously
                this.sendJSONResponse(response, 200, data);
            }
        ]
    }

    deleteServiceInstance() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            query('service_id', 'Missing service_id').exists(),
            query('plan_id', 'Missing plan_id').exists(),
                (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                // Validate serviceId and planId
                var plan = this.serviceBroker.getPlanForService(request.query.service_id, request.query.plan_id);
                if (!plan) {
                    // Just throw a warning in case the broker was restarted so the IDs changed
                    console.warn('Could not find service %s, plan %s', request.query.service_id, request.query.plan_id);
                }

                // Check if we only support asynchronous operations
                if (process.env.responseMode == 'async' && request.query.accepts_incomplete != 'true') {
                    this.sendJSONResponse(response, 422, { error: 'AsyncRequired' } );
                    return;
                }

                var serviceInstanceId = request.params.instance_id;
                this.logger.debug(`Deleting service ${serviceInstanceId}`);

                // Check if an operation is in progress
                var operation = this.instanceOperations[serviceInstanceId];
                if (operation && operation.state == 'in progress') {
                    // If a provision is in progress, we can cancel it
                    if (operation.type == 'provision') {
                        delete this.instanceOperations[serviceInstanceId];
                    }
                    // Else it must be an update so we should fail
                    else {
                        this.sendJSONResponse(response, 422,  { error: 'ConcurrencyError' });
                        return;
                    }
                }

                // Delete the service instance from memory
                if (serviceInstanceId in this.serviceInstances) {
                   delete this.serviceInstances[serviceInstanceId];
                } else {
                    this.sendJSONResponse(response, 410, {});
                    return;
                }

                // Perform asynchronous deprovision
                if ((request.query.accepts_incomplete == 'true' && (process.env.responseMode == 'default') || process.env.responseMode == 'async')) {
                    // Set the end time for the operation to be one second from now
                    // unless an explicit delay was requested
                    var endTime = new Date();
                    if (parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS)) {
                        endTime.setSeconds(endTime.getSeconds() + parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS));
                    }
                    else {
                        endTime.setSeconds(endTime.getSeconds() + 1);
                    }
                    this.instanceOperations[serviceInstanceId] = {
                        type: 'deprovision',
                        state: 'in progress',
                        endTime: endTime
                    };
                    this.sendJSONResponse(response, 202, {});
                    return;
                }

                // Perform synchronous deprovision
                this.sendJSONResponse(response, 200, {});
            }
        ]
    }

    createServiceBinding() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            body('service_id', 'Missing service_id').exists(),
            body('plan_id', 'Missing plan_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                var serviceInstanceId = request.params.instance_id;
                var bindingId = request.params.binding_id;

                // Check that the instance already exists
                if (!this.serviceInstances[serviceInstanceId]) {
                    this.sendJSONResponse(response, 404, { error: `Could not find service instance ${serviceInstanceId}` });
                    return;
                }

                // Check if the binding already exists
                if (serviceInstanceId in this.serviceInstances && bindingId in this.serviceInstances[serviceInstanceId].bindings) {
                    // Check if different sevice or plan ID
                    if (request.body.service_id != this.serviceInstances[serviceInstanceId].bindings[bindingId].service_id ||
                    request.body.plan_id != this.serviceInstances[serviceInstanceId].bindings[bindingId].plan_id) {
                        this.sendJSONResponse(response, 409, { error: 'Service or plan ID does not match' });
                        return;
                    }
                    // Check if a bind is already in progress
                    var operation = this.bindingOperations[bindingId];
                    if (operation && operation.type == 'binding' && operation.state == 'in progress') {
                        this.sendJSONResponse(response, 202, {operation: operation.id });
                        return;
                    }
                    this.sendJSONResponse(response, 200, this.serviceInstances[serviceInstanceId].bindings[bindingId].data);
                    return;
                }

                // Validate serviceId and planId
                var service = this.serviceBroker.getService(request.body.service_id);
                if (!service) {
                    this.sendJSONResponse(response, 400, { error: `Could not find service ${request.body.service_id}` });
                    return;
                }
                var plan = this.serviceBroker.getPlanForService(request.body.service_id, request.body.plan_id);
                if (!plan) {
                    this.sendJSONResponse(response, 400, { error: `Could not find service/plan ${request.body.service_id}/${request.body.plan_id}`});
                    return;
                }

                // Check if we only support asynchronous operations
                if (process.env.responseMode == 'async' && request.query.accepts_incomplete != 'true') {
                    this.sendJSONResponse(response, 422, { error: 'AsyncRequired' } );
                    return;
                }

                // Validate any configuration parameters if we have a schema
                var schema = null;
                try {
                    schema = plan.schemas.service_binding.create.parameters;
                }
                catch (e) {
                    // No schema to validate with
                }
                if (schema) {
                    var validationErrors = this.serviceBroker.validateParameters(schema, (request.body.parameters || {}));
                    if (validationErrors) {
                        this.sendJSONResponse(response, 400, { error: JSON.stringify(validationErrors) });
                        return;
                    }
                }

                this.logger.debug(`Creating service binding ${bindingId} for service ${serviceInstanceId}`);

                // Generate the binding info depending on the type of binding
                var data = {};
                if (!service.requires || service.requires.length == 0) {
                    data = {
                        credentials: {
                            username: 'admin',
                            password: randomstring.generate(16)
                        }
                    };
                }
                else if (service.requires && service.requires.indexOf('syslog_drain') > -1) {
                    data = {
                        syslog_drain_url: process.env.SYSLOG_DRAIN_URL
                    };
                }
                else if (service.requires && service.requires.indexOf('volume_mount') > -1) {
                    data = {
                        volume_mounts: [{
                            driver: 'nfs',
                            container_dir: '/tmp',
                            mode: 'r',
                            device_type: 'shared',
                            device: {
                                volume_id: '1'
                            }
                        }]
                    };
                }
                else if (service.requires && service.requires.indexOf('route_forwarding') > -1) {
                    data = {
                        route_service_url: process.env.ROUTE_URL
                    };
                }

                // Save the binding to memory
                this.serviceInstances[serviceInstanceId].bindings[bindingId] = {
                    api_version: request.header('X-Broker-Api-Version'),
                    service_id: request.body.service_id,
                    plan_id: request.body.plan_id,
                    app_guid: request.body.app_guid,
                    bind_resource: request.body.bind_resource,
                    parameters: request.body.parameters,
                    data: data
                };

                // Perform asynchronous binding
                if ((request.query.accepts_incomplete == 'true' && (process.env.responseMode == 'default') || process.env.responseMode == 'async')) {
                    // Set the end time for the operation to be one second from now
                    // unless an explicit delay was requested
                    var endTime = new Date();
                    if (parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS)) {
                        endTime.setSeconds(endTime.getSeconds() + parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS));
                    }
                    else {
                        endTime.setSeconds(endTime.getSeconds() + 1);
                    }
                    this.bindingOperations[bindingId] = {
                        type: 'binding',
                        state: 'in progress',
                        endTime: endTime,
                        id: GenerateUUID()
                    };
                    this.sendJSONResponse(response, 202, { operation: this.bindingOperations[bindingId].id } );
                    return;
                }

                // Perform synchronous binding
                this.sendJSONResponse(response, 201, data);
            }
        ]
    }

    deleteServiceBinding() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            param('binding_id', 'Missing binding_id').exists(),
            query('service_id', 'Missing service_id').exists(),
            query('plan_id', 'Missing plan_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                var serviceInstanceId = request.params.instance_id;
                var bindingId = request.params.binding_id;

                // Check if we only support asynchronous operations
                if (process.env.responseMode == 'async' && request.query.accepts_incomplete != 'true') {
                    this.sendJSONResponse(response, 422, { error: 'AsyncRequired' } );
                    return;
                }

                // Check if an operation is in progress
                var operation = this.bindingOperations[bindingId];
                if (operation && operation.state == 'in progress') {
                    this.sendJSONResponse(response, 422,  { error: 'ConcurrencyError' });
                    return;
                }

                this.logger.debug(`Deleting service binding ${bindingId} for service ${serviceInstanceId}`);

                // Delete the service instance from memory
                if (serviceInstanceId in this.serviceInstances && bindingId in this.serviceInstances[serviceInstanceId].bindings) {
                    delete this.serviceInstances[serviceInstanceId].bindings[bindingId];
                }
                else {
                    this.sendJSONResponse(response, 410, {});
                    return;
                }

                // Perform asynchronous deprovision
                if ((request.query.accepts_incomplete == 'true' && (process.env.responseMode == 'default') || process.env.responseMode == 'async')) {
                    // Set the end time for the operation to be one second from now
                    // unless an explicit delay was requested
                    var endTime = new Date();
                    if (parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS)) {
                        endTime.setSeconds(endTime.getSeconds() + parseInt(process.env.ASYNCHRONOUS_DELAY_IN_SECONDS));
                    }
                    else {
                        endTime.setSeconds(endTime.getSeconds() + 1);
                    }
                    this.bindingOperations[bindingId] = {
                        type: 'unbinding',
                        state: 'in progress',
                        endTime: endTime,
                        id: GenerateUUID()
                    };
                    this.sendJSONResponse(response, 202, { operation: this.bindingOperations[bindingId].id });
                    return;
                }

                // Perform synchronous deprovision
                this.sendJSONResponse(response, 200, {});
            }
        ]
    }

    getLastServiceInstanceOperation() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }
                var serviceInstanceId = request.params.instance_id;
                var operation = this.instanceOperations[serviceInstanceId];
                this.getLastOperation(operation, serviceInstanceId, request, response);
            }
        ]
    }

    getLastServiceBindingOperation() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            param('binding_id', 'Missing binding_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }
                var bindingId = request.params.binding_id;
                var operation = this.bindingOperations[bindingId];
                if (request.query.operation != null && request.query.operation != operation.id){
                    this.sendJSONResponse(response, 400, { error: "Operation does not match" });
                    return;
                }
                this.getLastOperation(operation, bindingId, request, response);
            }
        ]
    }

    checkAsyncOperations() {
        var self = this;
        Object.keys(this.instanceOperations).forEach(function(key) {
            self.updateOperation(self.instanceOperations[key], key);
        });
        Object.keys(this.bindingOperations).forEach(function(key) {
            self.updateOperation(self.bindingOperations[key], key);
        });
    }

    updateOperation(operation, id) {
        // Exit early if should never finish
        if (process.env.errorMode == 'neverfinishasync') {
            return
        }

        // Check if the operation has finished
        if (operation.state == 'in progress' && operation.endTime < new Date()) {
            // Check if we should fail the operation
            operation.state = process.env.errorMode == 'failasync' ? 'failed' : 'succeeded';
            this.logger.debug(`Operation of type ${operation.type} completed with state ${operation.state} (id: ${id})`);
        }
    }

    getLastOperation(operation, id, request, response) {
        // If we don't know about the operation, presume that it failed since we have forgotten about it
        if (!operation) {
            this.sendJSONResponse(response, 200, {
                state: 'failed',
                description: 'The operation could not be found.'
            });
            return;
        }

        // Update the operation in case it has finished
        this.updateOperation(operation, id);

        // Check if the operation is still going
        if (operation.state == 'in progress') {
            // Check if we should add a Retry-After header
            if (parseInt(process.env.POLLING_INTERVAL_IN_SECONDS)) {
                response.append('Retry-After', parseInt(process.env.POLLING_INTERVAL_IN_SECONDS));
            }
        }

        // If this was a deprovision or delete binding operation that succeeded, return 410
        if (operation.state == 'succeeded' &&
        (operation.type == 'deprovision' || operation.type == 'unbinding')) {
            this.sendJSONResponse(response, 410, {
                state: operation.state,
                description: `Operation ${operation.state}`
            });
            return;
        }

        // Else return 200
        this.sendJSONResponse(response, 200, {
            state: operation.state,
            description: `Operation ${operation.state}`
        });
    }

    getServiceInstance() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                let serviceInstanceId = request.params.instance_id;
                if (!this.serviceInstances[serviceInstanceId]) {
                    this.sendJSONResponse(response, 404, { error: `Could not find service instance ${serviceInstanceId}` });
                    return;
                }

                var data = Object.assign({}, this.serviceInstances[serviceInstanceId].data);
                data.service_id = this.serviceInstances[serviceInstanceId].service_id;
                data.plan_id = this.serviceInstances[serviceInstanceId].plan_id;
                data.parameters = this.serviceInstances[serviceInstanceId].parameters;

                this.sendJSONResponse(response, 200, data);
            }
        ]
    }

    getServiceBinding() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            param('binding_id', 'Missing binding_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                let serviceInstanceId = request.params.instance_id;
                let bindingId = request.params.binding_id;
                if (!this.serviceInstances[serviceInstanceId]) {
                    this.sendJSONResponse(response, 404, { error: `Could not find service instance ${serviceInstanceId}` });
                    return;
                }
                if (!this.serviceInstances[serviceInstanceId].bindings[bindingId]) {
                    this.sendJSONResponse(response, 404, { error: `Could not find service binding ${bindingId}` });
                    return;
                }

                var data = Object.assign({}, this.serviceInstances[serviceInstanceId].bindings[bindingId].data);
                data.parameters = this.serviceInstances[serviceInstanceId].bindings[bindingId].parameters;

                this.sendJSONResponse(response, 200, data);
            }
        ]
    }

    getDashboardData() {
        return {
            title: 'Overview Broker',
            started: this.started,
            serviceInstances: this.serviceInstances,
            latestRequests: this.latestRequests.slice().reverse(),
            latestResponses: this.latestResponses.slice().reverse(),
            catalog: this.serviceBroker.getCatalog(),
            env: {
                BROKER_USERNAME: process.env.BROKER_USERNAME || 'admin',
                BROKER_PASSWORD: process.env.BROKER_PASSWORD || 'password',
                SYSLOG_DRAIN_URL: process.env.SYSLOG_DRAIN_URL,
                ROUTE_URL: process.env.ROUTE_URL,
                EXPOSE_VOLUME_MOUNT_SERVICE: process.env.EXPOSE_VOLUME_MOUNT_SERVICE,
                ENABLE_EXAMPLE_SCHEMAS: process.env.ENABLE_EXAMPLE_SCHEMAS,
                ASYNCHRONOUS_DELAY_IN_SECONDS: process.env.ASYNCHRONOUS_DELAY_IN_SECONDS,
                MAXIMUM_POLLING_DURATION_IN_SECONDS: process.env.MAXIMUM_POLLING_DURATION_IN_SECONDS,
                POLLING_INTERVAL_IN_SECONDS: process.env.POLLING_INTERVAL_IN_SECONDS,
                SERVICE_NAME: process.env.SERVICE_NAME,
                SERVICE_DESCRIPTION: process.env.SERVICE_DESCRIPTION
            }
        };
    }

    getHealth() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                let serviceInstanceId = request.params.instance_id;
                if (!this.serviceInstances[serviceInstanceId]) {
                    this.sendJSONResponse(response, 200, { alive: false });
                    return;
                }

                this.sendJSONResponse(response, 200, { alive: true });
            }
        ]
    }

    getInfo() {
        return [
            param('instance_id', 'Missing instance_id').exists(),
            (request, response, next) => {
                const errors = validationResult(request);
                if (!errors.isEmpty()) {
                    this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
                    return;
                }

                let serviceInstanceId = request.params.instance_id;
                if (!this.serviceInstances[serviceInstanceId]) {
                    this.sendJSONResponse(response, 404, { error: `Could not find service instance ${serviceInstanceId}` });
                    return;
                }

                let data = {
                    server_url: cfenv.getAppEnv().url,
                    npm_config_node_version: process.env.npm_config_node_version,
                    npm_package_version: process.env.npm_package_version,
                };
                this.sendJSONResponse(response, 200, data);
            }
        ]
    }

    getLogs(request, response) {
        request.checkParams('instance_id', 'Missing instance_id').notEmpty();
        var errors = request.validationErrors();
        if (errors) {
            this.sendJSONResponse(response, 400, { error: JSON.stringify(errors) });
            return;
        }

        let serviceInstanceId = request.params.instance_id;
        if (!this.serviceInstances[serviceInstanceId]) {
            this.sendJSONResponse(response, 404, { error: `Could not find service instance ${serviceInstanceId}` });
            return;
        }


        this.sendJSONResponse(response, 200, data);
    }

    listInstances(request, response) {
        var data = {};
        var serviceInstances = this.serviceInstances;
        Object.keys(serviceInstances).forEach(function(key) {
            data[key] = serviceInstances[key].data;
        });
        this.sendJSONResponse(response, 200, data);
    }

    clean(request, response) {
        this.serviceInstances = {};
        this.latestRequests = [];
        this.latestResponses = [];
        this.instanceOperations = {};
        this.bindingOperations = {};
        response.status(200).json({});
    }

    updateCatalog(request, response) {
        let data = request.body.catalog;
        let error = this.serviceBroker.setCatalog(data);
        if (error) {
            this.sendJSONResponse(response, 400, { error: JSON.stringify(error) });
            return;
        }
        this.sendJSONResponse(response, 200, {});
    }

    saveRequest(request) {
        this.latestRequests.push({
            timestamp: moment().toString(),
            data: {
                url: request.url,
                method: request.method,
                body: request.body,
                headers: request.headers
            }
        });
        if (this.latestRequests.length > this.numRequestsToSave) {
            this.latestRequests.shift();
        }
    }

    saveResponse(httpCode, data, headers) {
        this.latestResponses.push({
            timestamp: moment().toString(),
            data: {
                code: httpCode,
                headers: headers,
                body: data
            }
        });
        if (this.latestResponses.length > this.numResponsesToSave) {
            this.latestResponses.shift();
        }
    }

    sendJSONResponse(response, httpCode, data) {
        response.status(httpCode).json(data);
        this.saveResponse(httpCode, data, response.getHeaders());
    }

    sendResponse(response, httpCode, data) {
        response.status(httpCode).send(data);
        this.saveResponse(httpCode, data, response.getHeaders());
    }

    getServiceBroker() {
        return this.serviceBroker;
    }

}

module.exports = ServiceBrokerInterface;
