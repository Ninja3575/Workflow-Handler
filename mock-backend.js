const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 4000;

// Middleware
app.use(cors());
app.use(express.json());

// Mock data storage
let requests = [];
let requestIdCounter = 1;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Mock backend is running' });
});

// Get requests for end users
app.get('/requests', (req, res) => {
  const { role, userId, receiverId } = req.query;
  
  let filteredRequests = requests;
  
  if (role === 'enduser') {
    filteredRequests = requests.filter(req => req.userId === userId);
  } else if (role === 'receiver') {
    filteredRequests = requests.filter(req => req.receiverId === receiverId);
  }
  
  res.json(filteredRequests);
});

// Create a new request
app.post('/requests', (req, res) => {
  const { userId, items, receiverId } = req.body;
  
  if (!userId || !items || !Array.isArray(items)) {
    return res.status(400).json({ error: 'Invalid request data' });
  }
  
  const requestItems = items.map(item => ({
    name: item,
    status: 'pending'
  }));
  
  const newRequest = {
    id: (requestIdCounter++).toString(),
    userId: userId,
    receiverId: receiverId || 'receiver-1',
    items: requestItems,
    status: 'Pending',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  
  requests.push(newRequest);
  res.json(newRequest);
});

// Submit confirmation for a request
app.patch('/requests/:id/confirm', (req, res) => {
  const { id } = req.params;
  const { receiverId, results } = req.body;
  
  const requestIndex = requests.findIndex(req => req.id === id);
  if (requestIndex === -1) {
    return res.status(404).json({ error: 'Request not found' });
  }
  
  const request = requests[requestIndex];
  
  // Update item statuses based on results
  results.forEach(result => {
    const { index, available } = result;
    if (index >= 0 && index < request.items.length) {
      request.items[index].status = available ? 'confirmed' : 'not_available';
    }
  });
  
  // Determine reassignment for items marked not available
  const notAvailable = request.items.filter(item => item.status === 'not_available');
  const confirmedCount = request.items.filter(item => item.status === 'confirmed').length;
  const totalCount = request.items.length;

  // If there are not available items, create a new request assigned to another receiver
  if (notAvailable.length > 0) {
    const nextReceiver = (request.receiverId === 'receiver-1') ? 'receiver-2' : 'receiver-1';
    const reassignedItems = notAvailable.map(i => ({ name: i.name, status: 'pending' }));
    const reassignedRequest = {
      id: (requestIdCounter++).toString(),
      userId: request.userId,
      receiverId: nextReceiver,
      items: reassignedItems,
      status: 'Pending',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    requests.push(reassignedRequest);
  }

  // Update overall request status
  if (confirmedCount === 0 && notAvailable.length === 0) {
    request.status = 'Pending';
  } else if (confirmedCount === totalCount) {
    request.status = 'Confirmed';
  } else {
    request.status = 'Partially Fulfilled';
  }
  
  request.updatedAt = new Date().toISOString();
  
  res.json(request);
});

// Start server
app.listen(PORT, () => {
  console.log(`Mock backend server running on http://localhost:${PORT}`);
  console.log('Available endpoints:');
  console.log('  GET  /health - Health check');
  console.log('  GET  /requests - Get requests');
  console.log('  POST /requests - Create request');
  console.log('  PATCH /requests/:id/confirm - Confirm request');
});
