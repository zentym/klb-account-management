const express = require('express');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080'; // API Gateway endpoint

// Proxy API requests to backend
app.use('/api', createProxyMiddleware({
    target: BACKEND_URL,
    changeOrigin: true,
    logLevel: 'debug'
}));

// Serve static files from the React build folder
app.use(express.static(path.join(__dirname, 'build')));

// Serve React app for all non-API routes
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'build/index.html'));
});

app.listen(PORT, () => {
    console.log(`Frontend server is running on port ${PORT}`);
    console.log(`Proxying API requests to: ${BACKEND_URL}`);
});