// Direct PostgreSQL migration runner for Supabase
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Use IPv6 address directly since DNS returns only IPv6
const config = {
    host: '2406:da1a:6b0:f60d:7d92:b2df:e8c5:d06f',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: 'Anik232001@@',
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 30000
};

async function runMigrations() {
    console.log('Supabase Migration Runner');
    console.log('=========================\n');
    console.log('Connecting via IPv6...');

    const client = new Client(config);

    try {
        await client.connect();
        console.log('Connected successfully!\n');

        const migrations = [
            { name: 'Complete Schema', file: '01_complete_schema.sql' },
            { name: 'Push Notifications', file: '02_push_notifications.sql' },
            { name: 'Notifications System', file: '03_notifications.sql' },
            { name: 'Auth Profile Triggers', file: '04_auth_profile_triggers.sql' }
        ];

        for (const migration of migrations) {
            console.log('Running: ' + migration.name);
            const filePath = path.join(__dirname, 'supabase/migrations', migration.file);
            const sql = fs.readFileSync(filePath, 'utf8');

            try {
                await client.query(sql);
                console.log('  [OK] Completed\n');
            } catch (err) {
                console.log('  [!] ' + err.message.substring(0, 100) + '\n');
            }
        }

        // Verify tables
        console.log('========== VERIFYING TABLES ==========');
        const result = await client.query(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
        );

        console.log('Tables in database:');
        result.rows.forEach(function (row) {
            console.log('  [OK] ' + row.table_name);
        });

        console.log('\n========== MIGRATION COMPLETE ==========');

    } catch (error) {
        console.error('Error: ' + error.message);
        if (error.code) console.error('Code: ' + error.code);
    } finally {
        await client.end();
        console.log('\nConnection closed');
    }
}

runMigrations();
