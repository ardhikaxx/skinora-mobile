const API_KEY = 'AIzaSyCJ9n6wWrcZmqh-6a5EBCPbEtUZeDHNouI';
const ID = 'https://identitytoolkit.googleapis.com/v1';
const PROJECT = 'skinora-app';
const FS = 'https://firestore.googleapis.com/v1/projects/' + PROJECT + '/databases/(default)/documents';

const ADMIN = {
  email: 'admin@gmail.com',
  password: 'Admin123!',
  role: 'admin',
  name: 'Admin Skinora',
  phone: '081111111111',
  status: 'aktif',
};

const OLD_DOCS = [
  'OBXBrnEVGbPpcaIhn3DMPnaIy3T2',
  'UTJhXnNioecBR424ZMQqCRhdxj13',
  'kBFfcWT2z1XE9pKwrPRRvkgCoGA2',
];

const DOCTORS = [
  {
    email: 'anita.dewi@gmail.com',
    password: 'Dokter123!',
    role: 'dokter',
    name: 'dr. Anita Dewi, Sp.KK',
    phone: '081222222221',
    status: 'terverifikasi',
    specialization: 'Estetika Kulit',
    experience: '8 tahun',
    str: 'STR-001-2020',
    bio: 'Dokter spesialis estetika kulit.',
  },
  {
    email: 'andi.pratama@gmail.com',
    password: 'Dokter123!',
    role: 'dokter',
    name: 'dr. Andi Pratama, Sp.KK',
    phone: '081222222222',
    status: 'terverifikasi',
    specialization: 'Jerawat',
    experience: '6 tahun',
    str: 'STR-002-2021',
    bio: 'Fokus penanganan jerawat dan inflamasi.',
  },
  {
    email: 'sari.wulandari@gmail.com',
    password: 'Dokter123!',
    role: 'dokter',
    name: 'dr. Sari Wulandari, Sp.KK',
    phone: '081222222223',
    status: 'terverifikasi',
    specialization: 'Anti-Aging',
    experience: '10 tahun',
    str: 'STR-003-2018',
    bio: 'Spesialis anti-aging dan regenerasi kulit.',
  },
];

function fields(o) {
  const f = {};
  for (const [k, v] of Object.entries(o)) {
    if (v == null) f[k] = { nullValue: null };
    else if (typeof v === 'boolean') f[k] = { booleanValue: v };
    else if (typeof v === 'number') f[k] = { integerValue: String(v) };
    else if (typeof v === 'string') f[k] = { stringValue: v };
    else if (v.timestampValue) f[k] = { timestampValue: v.timestampValue };
    else if (typeof v === 'object') f[k] = { mapValue: { fields: fields(v) } };
  }
  return f;
}

async function signIn(email, password) {
  const r = await fetch(ID + '/accounts:signInWithPassword?key=' + API_KEY, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!r.ok) throw new Error('signIn ' + email + ': ' + JSON.stringify(j));
  return { uid: j.localId, idToken: j.idToken };
}

async function signUp(email, password) {
  const r = await fetch(ID + '/accounts:signUp?key=' + API_KEY, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!r.ok) throw new Error('signUp ' + email + ': ' + JSON.stringify(j));
  return { uid: j.localId, idToken: j.idToken };
}

async function ensureAuth(email, password) {
  try {
    return await signIn(email, password);
  } catch {
    return signUp(email, password);
  }
}

async function createUserDoc(uid, idToken, profile, opts = {}) {
  const body = JSON.stringify({ fields: fields(profile) });
  // Coba POST create dulu, fallback PATCH
  const attempts = [
    {
      url: FS + '/users?documentId=' + encodeURIComponent(uid),
      method: 'POST',
    },
    { url: FS + '/users/' + uid, method: 'PATCH' },
  ];
  if (opts.preferPatch) attempts.reverse();

  let lastErr = '';
  for (const a of attempts) {
    const r = await fetch(a.url, {
      method: a.method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + idToken,
      },
      body,
    });
    const text = await r.text();
    if (r.ok) {
      console.log('fs users/' + uid, 'role=' + profile.role.stringValue, 'via', a.method, 'OK');
      return;
    }
    lastErr = a.method + ' ' + r.status + ' ' + text;
    // 409 already exists → PATCH overwrite path handled by second attempt
    if (r.status === 403) {
      console.warn('403 on', a.method, '— retry after short wait');
      await new Promise((res) => setTimeout(res, 1500));
      const r2 = await fetch(a.url, {
        method: a.method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer ' + idToken,
        },
        body,
      });
      const t2 = await r2.text();
      if (r2.ok) {
        console.log('fs users/' + uid, 'role=' + profile.role.stringValue, 'via retry', a.method, 'OK');
        return;
      }
      lastErr = a.method + ' retry ' + r2.status + ' ' + t2;
    }
  }
  throw new Error('fs ' + profile.email.stringValue + ': ' + lastErr);
}

function buildProfile(a, uid) {
  const now = new Date().toISOString();
  return {
    uid: { stringValue: uid },
    name: { stringValue: a.name },
    email: { stringValue: a.email.toLowerCase() },
    phone: { stringValue: a.phone },
    role: { stringValue: a.role },
    status: { stringValue: a.status },
    address: { stringValue: '' },
    birthDate: { stringValue: '' },
    gender: { stringValue: '' },
    specialization: { stringValue: a.specialization || '' },
    experience: { stringValue: a.experience || '' },
    str: { stringValue: a.str || '' },
    bio: { stringValue: a.bio || '' },
    isAvailable: { booleanValue: true },
    settings: {
      mapValue: {
        fields: {
          notificationsEnabled: { booleanValue: true },
          morningReminder: { stringValue: '' },
          eveningReminder: { stringValue: '' },
        },
      },
    },
    createdBy: { stringValue: uid },
    createdAt: { timestampValue: now },
    updatedAt: { timestampValue: now },
  };
}

// helper: profile dalam bentuk plain object untuk fields()
function plainProfile(a, uid) {
  return {
    uid,
    name: a.name,
    email: a.email.toLowerCase(),
    phone: a.phone,
    role: a.role,
    status: a.status,
    address: '',
    birthDate: '',
    gender: '',
    specialization: a.specialization || '',
    experience: a.experience || '',
    str: a.str || '',
    bio: a.bio || '',
    isAvailable: true,
    settings: { notificationsEnabled: true, morningReminder: '', eveningReminder: '' },
    createdBy: uid,
    createdAt: { timestampValue: new Date().toISOString() },
    updatedAt: { timestampValue: new Date().toISOString() },
  };
}

(async () => {
  // 1) Admin auth + doc
  const adminAuth = await ensureAuth(ADMIN.email, ADMIN.password);
  console.log('auth admin', adminAuth.uid);
  await createUserDoc(
    adminAuth.uid,
    adminAuth.idToken,
    plainProfile(ADMIN, adminAuth.uid),
    { preferPatch: false }
  );

  // 2) Hapus doc dokter lama (hanya admin boleh delete)
  for (const id of OLD_DOCS) {
    const r = await fetch(FS + '/users/' + id, {
      method: 'DELETE',
      headers: { Authorization: 'Bearer ' + adminAuth.idToken },
    });
    if (r.ok || r.status === 404) console.log('deleted old doc', id, r.status);
    else console.warn('delete old', id, r.status, await r.text());
  }

  // 3) Dokter baru
  for (const d of DOCTORS) {
    const auth = await ensureAuth(d.email, d.password);
    console.log('auth', d.email, auth.uid);
    await createUserDoc(auth.uid, auth.idToken, plainProfile(d, auth.uid), {
      preferPatch: false,
    });
  }

  console.log('ALL_OK');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
