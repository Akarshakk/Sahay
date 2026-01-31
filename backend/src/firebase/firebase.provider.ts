import { Provider } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

export const FIREBASE_APP = 'FIREBASE_APP';

export const firebaseProvider: Provider = {
  provide: FIREBASE_APP,
  useFactory: () => {
    // Try to load from JSON file first (recommended for development)
    const credentialPath = path.join(process.cwd(), 'sahay-ai-firebase.json');

    if (fs.existsSync(credentialPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(credentialPath, 'utf8'));
      return admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    // Fallback to environment variables (for production deployment)
    const firebaseConfig = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    };

    if (!firebaseConfig.projectId || !firebaseConfig.clientEmail || !firebaseConfig.privateKey) {
      throw new Error(
        'Firebase credentials not found. Please either:\n' +
        '1. Place your Firebase service account JSON file as "sahay-ai-firebase.json" in the backend folder, OR\n' +
        '2. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in your .env file'
      );
    }

    return admin.initializeApp({
      credential: admin.credential.cert(firebaseConfig),
    });
  },
};
