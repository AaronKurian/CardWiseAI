require('dotenv').config();

const { app } = require('./src/app');
const { connectDatabase } = require('./src/config/database');
const { env } = require('./src/config/env');

const startServer = async () => {
  await connectDatabase();

  app.listen(env.port, () => {
    console.log(`CardWise backend listening on port ${env.port}`);
  });
};

startServer().catch((error) => {
  console.error('Failed to start server', error);
  process.exit(1);
});
