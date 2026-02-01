import * as admin from 'firebase-admin';
import * as bcrypt from 'bcrypt';
import * as path from 'path';

// Initialize Firebase Admin (use existing app if already initialized)
let app: admin.app.App;
try {
    app = admin.app();
} catch {
    const serviceAccountPath = path.resolve(process.cwd(), 'sahay-ai-firebase.json');
    console.log('Loading service account from:', serviceAccountPath);
    try {
        const serviceAccount = require(serviceAccountPath);
        app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
    } catch (error) {
        console.error('Failed to load service account:', error);
        process.exit(1);
    }
}

const db = admin.firestore(app);

interface TestUser {
    phone: string;
    email: string;
    password: string;
    fullName: string;
    role: string;
}

const testUsers: TestUser[] = [
    {
        phone: '9876543210',
        email: 'citizen@test.com',
        password: 'test123',
        fullName: 'Test Citizen',
        role: 'citizen',
    },
    {
        phone: '9876543211',
        email: 'volunteer@test.com',
        password: 'test123',
        fullName: 'Test Volunteer',
        role: 'volunteer',
    },
    {
        phone: '9876543212',
        email: 'authority@test.com',
        password: 'test123',
        fullName: 'Test Authority',
        role: 'authority',
    },
];

async function seedTestUsers() {
    console.log('🌱 Seeding test users...\n');

    for (const user of testUsers) {
        // Check if user already exists by phone
        const existing = await db.collection('users')
            .where('phone', '==', user.phone)
            .limit(1)
            .get();

        if (!existing.empty) {
            console.log(`⏭️  User with phone ${user.phone} already exists, skipping...`);
            continue;
        }

        // Hash password
        const passwordHash = await bcrypt.hash(user.password, 10);

        // Create user document
        const userRef = db.collection('users').doc();
        const now = new Date();

        await userRef.set({
            id: userRef.id,
            email: user.email,
            passwordHash,
            fullName: user.fullName,
            phone: user.phone,
            role: user.role,
            isVerified: true,
            isActive: true,
            verificationCount: 0,
            reputationScore: 0,
            createdAt: now,
            updatedAt: now,
        });

        console.log(`✅ Created ${user.role}: ${user.phone} / ${user.password}`);
    }

    console.log('\n🎉 Test users seeded successfully!');
    console.log('\n📋 Login credentials:');
    console.log('   Citizen:   9876543210 / test123');
    console.log('   Volunteer: 9876543211 / test123');
    console.log('   Authority: 9876543212 / test123');
}

seedTestUsers()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error('❌ Error seeding users:', error);
        process.exit(1);
    });
