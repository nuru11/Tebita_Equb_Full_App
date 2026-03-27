const { config } = require('./config');
const { createApp } = require('./app');
const { enforceOverdueMemberRemoval } = require('./lib/penalty');

const app = createApp();
const port = config.port;

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

async function runPenaltyEnforcer() {
  try {
    const result = await enforceOverdueMemberRemoval();
    if (result?.removed) {
      console.log(`Penalty enforcer: removed ${result.removed} members`);
    }
  } catch (e) {
    console.error('Penalty enforcer failed', e);
  }
}

// Run on startup and then periodically (hourly) to approximate “daily” enforcement even on shared hosting.
runPenaltyEnforcer();
setInterval(runPenaltyEnforcer, 60 * 60 * 1000);
