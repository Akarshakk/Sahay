/**
 * Enhanced Mock Server for CivicSync - No Database Required
 * 
 * Provides mock endpoints for:
 * - Authentication (register, login)
 * - Twitter-like Feed (create, nearby, trending, verify)
 * - Real-time Chat (messages, reactions)
 * - Incidents
 * 
 * Run: node src/main-mock.js
 */

const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  },
});

app.use(cors());
app.use(express.json());

// Mock data stores
let posts = [
  {
    _id: '507f1f77bcf86cd799439011',
    content: 'Broken streetlight on Main Street causing safety concerns at night',
    category: 'infrastructure',
    authorId: 'user-1',
    authorName: 'John Doe',
    location: { type: 'Point', coordinates: [77.2090, 28.6139] },
    address: '123 Main St, Delhi',
    mediaUrls: [],
    verificationCount: 3,
    isPromoted: false,
    distance: 450.5,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
  },
  {
    _id: '507f1f77bcf86cd799439012',
    content: 'Pothole on highway causing traffic issues. Multiple vehicles damaged.',
    category: 'infrastructure',
    authorId: 'user-2',
    authorName: 'Jane Smith',
    location: { type: 'Point', coordinates: [77.2095, 28.6145] },
    address: 'Highway 1, Delhi',
    mediaUrls: [],
    verificationCount: 7,
    isPromoted: true,
    promotedIncidentId: 'incident-1',
    distance: 680.2,
    createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
  },
  {
    _id: '507f1f77bcf86cd799439013',
    content: 'Garbage not collected for 3 days. Health hazard developing.',
    category: 'environment',
    authorId: 'user-3',
    authorName: 'Amit Kumar',
    location: { type: 'Point', coordinates: [77.2080, 28.6130] },
    address: 'Sector 15, Delhi',
    mediaUrls: [],
    verificationCount: 2,
    isPromoted: false,
    distance: 320.8,
    createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
  },
];

let messages = {};
let authToken = 'mock-jwt-token-12345';

// Socket.IO connection
io.on('connection', (socket) => {
  console.log('🔌 Client connected:', socket.id);

  socket.on('joinLocation', (data) => {
    console.log('📍 Client joined location:', data);
    socket.join('location-feed');
  });

  socket.on('disconnect', () => {
    console.log('❌ Client disconnected:', socket.id);
  });
});

// Health check
app.get('/api/v1/health', (req, res) => {
  res.json({
    status: 'ok',
    mode: 'mock',
    timestamp: new Date().toISOString(),
    features: {
      auth: true,
      feed: true,
      chat: true,
      websocket: true,
    },
  });
});

// Auth endpoints
app.post('/api/v1/auth/register', (req, res) => {
  console.log('📝 Register:', req.body.email);
  res.json({
    success: true,
    data: {
      token: authToken,
      user: {
        id: 'user-' + Date.now(),
        email: req.body.email,
        fullName: req.body.fullName,
        role: req.body.role || 'citizen',
      },
    },
  });
});

app.post('/api/v1/auth/login', (req, res) => {
  console.log('🔐 Login:', req.body.email);
  res.json({
    success: true,
    data: {
      token: authToken,
      user: {
        id: 'user-123',
        email: req.body.email,
        fullName: 'Mock User',
        role: 'volunteer',
      },
    },
  });
});

// Feed endpoints
app.post('/api/v1/feed/create', (req, res) => {
  console.log('📝 Create post:', req.body.category);
  
  const newPost = {
    _id: 'post-' + Date.now(),
    content: req.body.content,
    category: req.body.category,
    authorId: 'user-123',
    authorName: 'You',
    location: {
      type: 'Point',
      coordinates: [req.body.longitude, req.body.latitude],
    },
    address: req.body.address,
    mediaUrls: req.body.mediaUrls || [],
    verificationCount: 0,
    isPromoted: false,
    distance: 0,
    createdAt: new Date().toISOString(),
  };
  
  posts.unshift(newPost);
  
  // Broadcast to WebSocket clients
  io.to('location-feed').emit('newPost', {
    type: 'NEW_POST',
    data: newPost,
  });
  
  res.json({
    success: true,
    message: 'Post created successfully',
    data: newPost,
  });
});

app.get('/api/v1/feed', (req, res) => {
  console.log('🔍 Get feed:', req.query.latitude, req.query.longitude);
  
  res.json({
    success: true,
    data: posts,
    meta: {
      total: posts.length,
      radius: parseInt(req.query.radius) || 2000,
      center: {
        lat: parseFloat(req.query.latitude),
        lng: parseFloat(req.query.longitude),
      },
    },
  });
});

app.post('/api/v1/feed/:postId/verify', (req, res) => {
  const { postId } = req.params;
  console.log('✅ Verify post:', postId);
  
  const post = posts.find(p => p._id === postId);
  if (post) {
    post.verificationCount++;
    
    const promoted = post.verificationCount >= 5 && !post.isPromoted;
    if (promoted) {
      post.isPromoted = true;
      post.promotedIncidentId = 'incident-' + Date.now();
      post.promotedAt = new Date().toISOString();
    }
    
    // Broadcast to WebSocket clients
    io.to('location-feed').emit('postVerified', {
      type: 'POST_VERIFIED',
      postId,
      verificationCount: post.verificationCount,
      promoted,
    });
    
    res.json({
      success: true,
      promoted,
      incidentId: promoted ? post.promotedIncidentId : undefined,
      post,
    });
  } else {
    res.status(404).json({ success: false, message: 'Post not found' });
  }
});

app.get('/api/v1/feed/trending', (req, res) => {
  console.log('📈 Get trending posts');
  
  const trending = [...posts]
    .sort((a, b) => b.verificationCount - a.verificationCount)
    .slice(0, 10);
  
  res.json({
    success: true,
    data: trending,
  });
});

// Chat endpoints
app.post('/api/v1/chat/:postId/messages', (req, res) => {
  const { postId } = req.params;
  const { message } = req.body;
  console.log('💬 Send message to post:', postId);
  
  if (!messages[postId]) {
    messages[postId] = [];
  }
  
  const newMessage = {
    _id: 'msg-' + Date.now(),
    postId,
    authorId: 'user-123',
    authorName: 'You',
    message,
    reactions: [],
    createdAt: new Date().toISOString(),
  };
  
  messages[postId].push(newMessage);
  
  // Broadcast to WebSocket clients
  io.to('location-feed').emit('newChatMessage', {
    type: 'NEW_CHAT_MESSAGE',
    data: newMessage,
    postId,
  });
  
  res.json({
    success: true,
    message: 'Message sent',
    data: newMessage,
  });
});

app.get('/api/v1/chat/:postId/messages', (req, res) => {
  const { postId } = req.params;
  console.log('📖 Get messages for post:', postId);
  
  // Generate mock messages if none exist
  if (!messages[postId]) {
    messages[postId] = [
      {
        _id: 'msg-1',
        postId,
        authorId: 'user-2',
        authorName: 'Alice',
        message: 'I saw this too! It\'s been like this for days.',
        reactions: ['user-3', 'user-4'],
        createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
      },
      {
        _id: 'msg-2',
        postId,
        authorId: 'user-3',
        authorName: 'Bob',
        message: 'We should report this to the authorities.',
        reactions: ['user-2'],
        createdAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
      },
    ];
  }
  
  res.json({
    success: true,
    data: messages[postId],
    count: messages[postId].length,
  });
});

app.post('/api/v1/chat/messages/:messageId/react', (req, res) => {
  const { messageId } = req.params;
  console.log('❤️ React to message:', messageId);
  
  // Find the message in all posts
  let found = null;
  for (const postId in messages) {
    const msg = messages[postId].find(m => m._id === messageId);
    if (msg) {
      if (!msg.reactions.includes('user-123')) {
        msg.reactions.push('user-123');
      }
      found = msg;
      
      // Broadcast to WebSocket clients
      io.to('location-feed').emit('messageReaction', {
        type: 'MESSAGE_REACTION',
        data: {
          messageId,
          userId: 'user-123',
          reactionCount: msg.reactions.length,
        },
      });
      break;
    }
  }
  
  res.json({
    success: true,
    message: 'Reaction added',
    data: { reactionCount: found ? found.reactions.length : 1 },
  });
});

// Incidents endpoints
app.get('/api/v1/incidents/nearby', (req, res) => {
  console.log('🚨 Get nearby incidents');
  
  res.json({
    success: true,
    data: posts.filter(p => p.isPromoted),
  });
});

// User endpoints
app.get('/api/v1/users/me', (req, res) => {
  res.json({
    success: true,
    data: {
      id: 'user-123',
      email: 'mock@example.com',
      fullName: 'Mock User',
      role: 'volunteer',
      verificationCount: 15,
    },
  });
});

app.put('/api/v1/users/me/location', (req, res) => {
  console.log('📍 Update location:', req.body.latitude, req.body.longitude);
  res.json({ success: true });
});

// Start server
const PORT = 3000;
server.listen(PORT, () => {
  console.log('\n' + '='.repeat(60));
  console.log('🚀 CivicSync Mock API Server');
  console.log('='.repeat(60));
  console.log(`📡 HTTP Server: http://localhost:${PORT}`);
  console.log(`🔌 WebSocket Server: ws://localhost:${PORT}`);
  console.log(`📚 Health Check: http://localhost:${PORT}/api/v1/health`);
  console.log('\n✨ Features Available:');
  console.log('   ✅ Authentication (register, login)');
  console.log('   ✅ Twitter-like Feed (create, nearby, trending, verify)');
  console.log('   ✅ Real-time Chat (messages, reactions)');
  console.log('   ✅ WebSocket broadcasts');
  console.log('\n⚠️  Note: This is a mock server with in-memory data');
  console.log('   For full features with databases, run: docker compose up -d');
  console.log('='.repeat(60) + '\n');
});
