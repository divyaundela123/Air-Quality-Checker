require('dotenv').config();
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');
dns.setServers(['8.8.8.8', '8.8.4.4']);

const mongoose = require('mongoose');

async function main() {
  console.log('SRV_URI set:', !!process.env.MONGODB_URI);
  console.log('DIRECT_URI set:', !!process.env.MONGODB_DIRECT_URI);

  // Try SRV DNS records directly
  dns.resolveSrv('_mongodb._tcp.cluster0.gus43ow.mongodb.net', (err, addrs) => {
    if (err) console.log('SRV DNS lookup FAILED:', err.code, err.message);
    else console.log('SRV DNS lookup OK:', JSON.stringify(addrs));
  });
  dns.resolveTxt('cluster0.gus43ow.mongodb.net', (err, addrs) => {
    if (err) console.log('TXT DNS lookup FAILED:', err.code, err.message);
    else console.log('TXT DNS lookup OK:', JSON.stringify(addrs));
  });

  try {
    console.log('\nConnecting via Direct URI...');
    await mongoose.connect(process.env.MONGODB_DIRECT_URI, {
      serverSelectionTimeoutMS: 15000,
      family: 4,
    });
    console.log('DIRECT CONNECT OK, db =', mongoose.connection.name);
    process.exit(0);
  } catch (e) {
    console.log('DIRECT CONNECT FAILED:');
    console.log('  name:', e.name);
    console.log('  message:', e.message);
    if (e.reason) console.log('  reason:', JSON.stringify(e.reason, null, 2));
    process.exit(1);
  }
}

main();
