import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Kienlongbank Account Management', () => {
  render(<App />);
  const headingElement = screen.getByText(/Kienlongbank Account Management/i);
  expect(headingElement).toBeInTheDocument();
});
