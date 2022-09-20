let should = require('should'),
    request = require('supertest'),
    app = require('./../app');

describe('Extensions', function() {

    var server = null;
    var catalog = null;

    before(function(done) {
        app.start(function(s, sbInterface) {
            let serviceBroker = sbInterface.getServiceBroker();
            catalog = serviceBroker.getCatalog();
            server = s;
            done();
        });
    });

    after(function(done) {
        server.close(() => {
            done();
        });
    });

    describe('health', function() {

        it('should fetch discovery doc', function(done) {
            request(server)
                .get('/health')
                .expect(200)
                .then(response => {
                    done();
                });
        });

    });

    describe('info', function() {

        it('should fetch discovery doc', function(done) {
            request(server)
                .get('/info')
                .expect(200)
                .then(response => {
                    done();
                });
        });

    });

});
