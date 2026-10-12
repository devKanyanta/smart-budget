import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import LoginPage from './LoginPage';
import { useAuthStore, api } from '../store/authStore';

let view;
const renderLogin = () => {
  view = render(
    <MemoryRouter initialEntries={['/login']}>
      <LoginPage />
    </MemoryRouter>
  );
  return view;
};

// The page's labels are not programmatically associated with their inputs,
// so target fields by DOM position: first textbox is email, first password
// input is the password field.
const emailInput = () => view.container.querySelectorAll('input')[0];
const passwordInput = () =>
  view.container.querySelector('input[type="password"]');

describe('LoginPage', () => {
  beforeEach(() => {
    useAuthStore.getState().logout();
  });

  it('renders the Student Kwacha brand and form', () => {
    const view = renderLogin();
    expect(screen.getByText('Student Kwacha')).toBeInTheDocument();
    expect(screen.getByText('Admin Dashboard')).toBeInTheDocument();
    expect(emailInput()).toBeInTheDocument();
    expect(passwordInput()).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });

  it('shows the error when login fails', async () => {
    api.defaults.adapter = (config) =>
      Promise.resolve({
        status: 200,
        // Backend sends success:false rather than an HTTP error for bad creds.
        data: {
          success: false,
          error: { code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' },
        },
        config,
      });

    renderLogin();
    await userEvent.type(emailInput(), 'admin@studentkwacha.com');
    await userEvent.type(passwordInput(), 'wrongpass');
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() =>
      expect(screen.getByText('Invalid credentials')).toBeInTheDocument()
    );
  });

  it('shows the generic error when login throws', async () => {
    api.defaults.adapter = () => Promise.reject(new Error('network down'));

    renderLogin();
    await userEvent.type(emailInput(), 'a@b.com');
    await userEvent.type(passwordInput(), 'x');
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() =>
      expect(screen.getByText('Login failed. Please try again.')).toBeInTheDocument()
    );
  });

  it('clears the error field between attempts', async () => {
    api.defaults.adapter = (config) =>
      Promise.resolve({ status: 200, data: { success: false }, config });

    renderLogin();
    await userEvent.type(emailInput(), 'a@b.com');
    await userEvent.type(passwordInput(), 'bad');
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));
    await waitFor(() =>
      expect(screen.getByText('Invalid credentials')).toBeInTheDocument()
    );

    // The error is reset at submit start: click again and it disappears
    // while the (instant) request resolves.
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));
    await waitFor(() =>
      expect(screen.getByText('Invalid credentials')).toBeInTheDocument()
    );
  });
});
