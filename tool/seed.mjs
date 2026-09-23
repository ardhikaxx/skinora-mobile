/**
 * Seed data demo ke Firestore (emulator / production).
 *
 * Prasyarat:
 *   - Firebase CLI login / emulator jalan
 *   - GOOGLE_APPLICATION_CREDENTIALS di-set bila pakai production
 *     (jangan commit credential ke repo)
 *
 * Pakai:
 *   node tool/seed.mjs            # seed ke emulator (default)
 *   PROJECT_ID=skinora-app node tool/seed.mjs
 */
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'node:fs';

const projectId = process.env.PROJECT_ID || 'skinora-app';
const useEmulator = process.env.FIRESTORE_EMULATOR_HOST != null;

initializeApp({
  projectId,
  credential: useEmulator
    ? undefined
    : process.env.GOOGLE_APPLICATION_CREDENTIALS && existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)
      ? cert(JSON.parse(readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8')))
      : applicationDefault(),
});

const db = getFirestore();
const now = () => Timestamp.now();

async function setDoc(ref, data) {
  await ref.set({ ...data, createdAt: now(), updatedAt: now() });
}

async function seedSpecializations() {
  const col = db.collection('specializations');
  const items = [
    { name: 'Estetika Kulit', isActive: true },
    { name: 'Jerawat', isActive: true },
    { name: 'Anti-Aging', isActive: true },
    { name: 'Alergi & Eksim', isActive: true },
    { name: 'Pigmen & Flek', isActive: true },
  ];
  for (const item of items) {
    const q = await col.where('name', '==', item.name).limit(1).get();
    if (q.empty) {
      await setDoc(col.doc(), { ...item, createdBy: 'seed' });
    }
  }
}

async function seedArticles() {
  const col = db.collection('articles');
  const items = [
    {
      title: 'Mengenal Tipe Kulit Wajah',
      category: 'Kulit',
      date: '2026-08-01',
      content: 'Kulit normal, kering, berminyak, dan kombinasi memiliki karakter berbeda.',
      status: 'diterbitkan',
    },
    {
      title: 'Rutinitas Skincare Pagi yang Benar',
      category: 'Skincare',
      date: '2026-08-05',
      content: 'Bersihkan, toner, serum, moisturizer, sunscreen.',
      status: 'diterbitkan',
    },
    {
      title: 'Cara Menangani Jerawat Meradang',
      category: 'Jerawat',
      date: '2026-08-10',
      content: 'Jangan memencet jerawat; gunakan bahan aktif sesuai anjuran dokter.',
      status: 'diterbitkan',
    },
  ];
  for (const item of items) {
    const q = await col.where('title', '==', item.title).limit(1).get();
    if (q.empty) {
      await setDoc(col.doc(), { ...item, createdBy: 'seed', updatedBy: 'seed' });
    }
  }
}

async function seedAdmin() {
  // Dokumen admin placeholder — role admin dibuat setelah Auth register asli.
  // Untuk seed aman, tulis dokumen dengan uid dummy bila belum ada.
  const uid = process.env.ADMIN_UID || 'seed-admin-uid';
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    await setDoc(ref, {
      uid,
      name: 'Admin Skinora',
      email: 'admin@skinora.test',
      phone: '',
      role: 'admin',
      status: 'aktif',
      settings: {
        notificationsEnabled: true,
        morningReminder: '',
        eveningReminder: '',
      },
      createdBy: 'seed',
    });
  }
}

async function main() {
  console.log(`Seeding project: ${projectId}${useEmulator ? ' (emulator)' : ''}`);
  await seedSpecializations();
  await seedArticles();
  await seedAdmin();
  console.log('Seed selesai.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
