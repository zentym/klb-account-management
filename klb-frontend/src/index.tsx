import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { CustomAuthProvider } from './components/CustomAuthProvider';

// Main Banking App với custom-login làm trang login chính
// Flow: Custom Login → Dashboard với full banking features

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <CustomAuthProvider>
      <App />
    </CustomAuthProvider>
  </React.StrictMode>
);
