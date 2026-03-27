const { config } = require('./index');

/**
 * sequelize-cli config file.
 * Uses the same DATABASE_URL that the app uses (src/config/index.js).
 */
module.exports = {
  development: {
    url: config.database.url,
    dialect: 'mysql',
    logging: false,
  },
  test: {
    url: config.database.url,
    dialect: 'mysql',
    logging: false,
  },
  production: {
    url: config.database.url,
    dialect: 'mysql',
    logging: false,
  },
};

