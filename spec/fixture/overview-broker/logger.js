class Logger {

    debug(message) {
        if (process.env.NODE_ENV == 'testing') {
            return;
        }
        console.log(message);
    }

}

module.exports = Logger;
