const mongoose = require('mongoose');
const { env } = require('./env');

const connectDatabase = async () => {
  mongoose.set('strictQuery', true);
  await mongoose.connect(env.mongoUri, {
    serverSelectionTimeoutMS: env.mongoServerSelectionTimeoutMs,
  });
};

module.exports = { connectDatabase };
