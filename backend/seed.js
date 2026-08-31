require('dotenv').config();
const db = require('./db');

console.log('Seeding demo data...');
db.seedDemoData();
console.log('Demo data seeded successfully.');
console.log('Seed users:');
console.log('  admin@pharmalink.demo / Admin123!');
console.log('  coordinator@pharmalink.demo / Coord123!');
console.log('  pharmacy@pharmalink.demo / Pharm123!');