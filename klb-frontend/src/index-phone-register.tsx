import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import CompletePhoneApp from './CompletePhoneApp';

// Complete Phone Banking App Demo
// Bao gồm: Đăng ký → Đăng nhập → Dashboard

const root = ReactDOM.createRoot(
    document.getElementById('root') as HTMLElement
);

root.render(
    <React.StrictMode>
        <CompletePhoneApp />
    </React.StrictMode>
);
