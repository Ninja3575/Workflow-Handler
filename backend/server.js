import express from 'express';
import cors from 'cors';
import { WebSocketServer } from 'ws';

const app = express();
app.use(cors());
app.use(express.json());

// ----- In-memory store -----
let requests = []; // each: { id, userId, receiverId, items:[{name,status}], status, createdAt, updatedAt }
let nextId = 1;

// Simple broadcast to any future WS clients (not required for polling flow)
const PORT = process.env.PORT || 4000;
const server = app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));
const wss = new WebSocketServer({ server });
const broadcast = (type, payload) => {
  const msg = JSON.stringify({ type, payload });
  wss.clients.forEach((c) => c.readyState === 1 && c.send(msg));
};

// ---- Helpers ----
const computeStatus = (items) => {
  const total = items.length;
  const confirmed = items.filter(i => i.status === 'confirmed').length;
  const rejected = items.filter(i => i.status === 'not_available').length;
  if (confirmed === total) return 'Confirmed';
  if (confirmed > 0 || rejected > 0) return 'Partially Fulfilled';
  return 'Pending';
};

// ---- Routes ----
app.get('/', (_req, res) => res.json({ ok: true }));

// Create new request
// body: { userId, items:["Item A","Item B"], receiverId? }
app.post('/requests', (req, res) => {
  const { userId, items, receiverId } = req.body;
  if (!userId || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'userId and non-empty items[] required' });
  }
  const now = new Date().toISOString();
  const r = {
    id: String(nextId++),
    userId,
    receiverId: receiverId || 'receiver-1',
    items: items.map(name => ({ name, status: 'pending' })),
    status: 'Pending',
    createdAt: now,
    updatedAt: now
  };
  requests.unshift(r);
  broadcast('requestsUpdated', { id: r.id });
  res.json(r);
});

// Fetch requests by role
// end user:  GET /requests?role=enduser&userId=USER
// receiver:  GET /requests?role=receiver&receiverId=RID
app.get('/requests', (req, res) => {
  const { role, userId, receiverId } = req.query;
  if (role === 'enduser' && userId) {
    return res.json(requests.filter(r => r.userId === userId));
  }
  if (role === 'receiver' && receiverId) {
    return res.json(requests.filter(r => r.receiverId === receiverId && r.status !== 'Confirmed'));
  }
  res.json(requests);
});

// Receiver confirms items
// body: { receiverId, results:[{ index, available }] }
app.patch('/requests/:id/confirm', (req, res) => {
  const { id } = req.params;
  const { receiverId, results } = req.body;
  const r = requests.find(x => x.id === id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  if (!receiverId || !Array.isArray(results)) return res.status(400).json({ error: 'receiverId and results[] required' });

  // Apply confirmations
  results.forEach(({ index, available }) => {
    if (index >= 0 && index < r.items.length) {
      r.items[index].status = available ? 'confirmed' : 'not_available';
    }
  });

  // Determine status & handle partial reassignment
  r.status = computeStatus(r.items);

  // If partially fulfilled, "reassign" any not_available items to another receiver
  if (r.status === 'Partially Fulfilled') {
    const hasNotAvailable = r.items.some(i => i.status === 'not_available');
    if (hasNotAvailable) {
      // create a follow-up request carrying only unconfirmed items
      const now = new Date().toISOString();
      const followUpItems = r.items
        .filter(i => i.status === 'not_available')
        .map(i => ({ name: i.name, status: 'pending' }));
      if (followUpItems.length > 0) {
        const followUp = {
          id: String(nextId++),
          userId: r.userId,
          receiverId: 'receiver-2',
          items: followUpItems,
          status: 'Pending',
          createdAt: now,
          updatedAt: now
        };
        requests.unshift(followUp);
      }
    }
  }

  r.updatedAt = new Date().toISOString();
  broadcast('requestsUpdated', { id: r.id });
  res.json(r);
});
