const { Sequelize } = require('sequelize');

const { config } = require('../config');

if (!config.database.url) {
  throw new Error('DATABASE_URL is not set');
}

const sequelize = new Sequelize(config.database.url, {
  dialect: 'mysql',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000,
  },
});

const { initModels } = require('../models');

const models = initModels(sequelize);

module.exports = { sequelize, ...models };

