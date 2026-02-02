import * as admin from 'firebase-admin';
import * as bcrypt from 'bcrypt';
import * as path from 'path';

// Initialize Firebase Admin
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

// Authority Codes - Unique per department/area
const authorityCodes = [
    { code: 'POLICE-MUM-001', department: 'Police', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'POLICE-MUM-002', department: 'Police', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'FIRE-MUM-001', department: 'Fire Department', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'HOSPITAL-MUM-001', department: 'Hospital (Government)', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'HOSPITAL-MUM-002', department: 'Hospital (Private)', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'RAILWAYS-MUM-001', department: 'Railways', area: 'Mumbai Central', areaId: 'mumbai-central', isActive: true, usedBy: [] },
    { code: 'POLICE-DEL-001', department: 'Police', area: 'Delhi South', areaId: 'delhi-south', isActive: true, usedBy: [] },
    { code: 'FIRE-DEL-001', department: 'Fire Department', area: 'Delhi South', areaId: 'delhi-south', isActive: true, usedBy: [] },
    { code: 'HOSPITAL-DEL-001', department: 'Hospital (Government)', area: 'Delhi South', areaId: 'delhi-south', isActive: true, usedBy: [] },
];

// Test Users with phoneVerified: true
interface TestUser {
    phone: string;
    email: string;
    password: string;
    fullName: string;
    role: string;
    registeredArea?: string;
    registeredAreaId?: string;
    department?: string;
    authorityCode?: string;
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
        registeredArea: 'Mumbai Central',
        registeredAreaId: 'mumbai-central',
    },
    {
        phone: '9876543212',
        email: 'authority@test.com',
        password: 'test123',
        fullName: 'Test Authority',
        role: 'authority',
        registeredArea: 'Mumbai Central',
        registeredAreaId: 'mumbai-central',
        department: 'Police',
        authorityCode: 'POLICE-MUM-001',
    },
];

// Area Resources (initial state)
const areaResources = [
    {
        areaId: 'mumbai-central',
        areaName: 'Mumbai Central',
        ambulances: 5,
        fireEngines: 3,
        policeUnits: 10,
        medicalTeams: 4,
        updatedAt: new Date(),
        updatedBy: 'system',
    },
    {
        areaId: 'delhi-south',
        areaName: 'Delhi South',
        ambulances: 4,
        fireEngines: 2,
        policeUnits: 8,
        medicalTeams: 3,
        updatedAt: new Date(),
        updatedBy: 'system',
    },
];

async function seedDatabase() {
    console.log('🔥 Starting database seed...\n');

    // Step 1: Delete ALL existing users
    console.log('🗑️  Deleting all existing users...');
    const usersSnapshot = await db.collection('users').get();
    const deletePromises = usersSnapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`   Deleted ${usersSnapshot.size} users\n`);

    // Step 2: Seed Authority Codes
    console.log('🔐 Seeding authority codes...');
    for (const code of authorityCodes) {
        await db.collection('authority_codes').doc(code.code).set(code);
        console.log(`   ✅ ${code.code} (${code.department}, ${code.area})`);
    }
    console.log('');

    // Step 3: Seed Area Resources
    console.log('📦 Seeding area resources...');
    for (const resource of areaResources) {
        await db.collection('area_resources').doc(resource.areaId).set(resource);
        console.log(`   ✅ ${resource.areaName}: ${resource.ambulances} ambulances, ${resource.policeUnits} police`);
    }
    console.log('');

    // Step 4: Seed Test Users with phoneVerified: true
    console.log('👤 Seeding test users (phoneVerified: true)...');
    for (const user of testUsers) {
        const passwordHash = await bcrypt.hash(user.password, 10);
        const userRef = db.collection('users').doc();
        const now = new Date();

        await userRef.set({
            id: userRef.id,
            email: user.email,
            passwordHash,
            fullName: user.fullName,
            phone: user.phone,
            role: user.role,
            registeredArea: user.registeredArea || null,
            registeredAreaId: user.registeredAreaId || null,
            department: user.department || null,
            authorityCode: user.authorityCode || null,
            phoneVerified: true,  // Pre-verified for testing
            isVerified: true,
            isActive: true,
            verificationCount: 0,
            reputationScore: 0,
            createdAt: now,
            updatedAt: now,
        });

        console.log(`   ✅ ${user.role.toUpperCase()}: ${user.phone} / ${user.password}${user.registeredArea ? ` (${user.registeredArea})` : ''}`);
    }

    console.log('\n🎉 Database seeding complete!');
    console.log('\n📋 Login credentials:');
    console.log('   Citizen:   9876543210 / test123');
    console.log('   Volunteer: 9876543211 / test123 (Mumbai Central)');
    console.log('   Authority: 9876543212 / test123 (Mumbai Central, Police)');
    console.log('\n🔐 Authority Codes for Registration:');
    authorityCodes.forEach(c => console.log(`   ${c.code} → ${c.department} (${c.area})`));
}

seedDatabase()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error('❌ Error seeding database:', error);
        process.exit(1);
    });
