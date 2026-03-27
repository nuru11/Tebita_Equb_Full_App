const { config: loadEnv } = require('dotenv');

loadEnv();

// Build DATABASE_URL from DB_* if not set (password URL-encoded for special chars)
if (!process.env.DATABASE_URL && process.env.DB_HOST && process.env.DB_USER && process.env.DB_NAME) {
  const pass = process.env.DB_PASS ? encodeURIComponent(process.env.DB_PASS) : '';
  const port = process.env.DB_PORT || '3306';
  process.env.DATABASE_URL = `mysql://${process.env.DB_USER}:${pass}@${process.env.DB_HOST}:${port}/${process.env.DB_NAME}`;
}

const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'change-me-in-production',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'change-me-in-production',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  database: {
    url: process.env.DATABASE_URL,
  },
  afromessage: {
    baseUrl: process.env.AFRO_BASE_URL || 'https://api.afromessage.com/api/send',
    token: process.env.AFRO_TOKEN || 'eyJhbGciOiJIUzI1NiJ9.eyJpZGVudGlmaWVyIjoia3Y5TVg1Nkg1MGhQR1VQR2pQYkVVczJpMTZnM3ZKd3IiLCJleHAiOjE4ODYyMzczMDUsImlhdCI6MTcyODQ3MDkwNSwianRpIjoiZGM1YzEwMzItOTIzNy00Mzg5LWIxOTYtZjgzYzVhNTAwYTQ3In0.LjqwP7ufE3eIIRmtFMdbH49ut09AMNk_EMNjk0yGIG0',
    from: process.env.AFRO_FROM || 'e80ad9d8-adf3-463f-80f4-7c4b39f7f164',
    sender: process.env.AFRO_SENDER || 'Addisway',
  },
};

module.exports = { config };
