import { describe, it, expect, beforeEach } from 'vitest';
import { useAuthStore } from './authStore';

// Reuse the store's axios instance but with a mock adapter so no network is hit.
import { api } from './authStore';

const TOKEN = 'test-token-123';

describe('authStore', () => {
  beforeEach(() => {
    useAuthStore.getState().logout();
    api.defaults.adapter = 'http'; // replaced below per test
  });

  it('starts logged out with no token', () => {
    expect(useAuthStore.getState().token).toBeNull();
    expect(useAuthStore.getState().user).toBeNull();
  });

  it('stores token and user on successful login', async () => {
    api.defaults.adapter = (config) =>
      Promise.resolve({
        status: 200,
        data: {
          success: true,
          data: { accessToken: TOKEN, user: { id: 'u1', email: 'admin@studentkwacha.com' } },
        },
        config,
      });

    const ok = await useAuthStore.getState().login('admin@studentkwacha.com', 'admin123');
    expect(ok).toBe(true);
    expect(useAuthStore.getState().token).toBe(TOKEN);
    expect(useAuthStore.getState().user.email).toBe('admin@studentkwacha.com');
    expect(localStorage.getItem('admin_token')).toBe(TOKEN);
  });

  it('returns false on unsuccessful login and stores nothing', async () => {
    api.defaults.adapter = (config) =>
      Promise.resolve({ status: 200, data: { success: false }, config });

    const ok = await useAuthStore.getState().login('admin@studentkwacha.com', 'wrong');
    expect(ok).toBe(false);
    expect(useAuthStore.getState().token).toBeNull();
    expect(localStorage.getItem('admin_token')).toBeNull();
  });

  it('surfaces login rejections to the caller', async () => {
    api.defaults.adapter = () =>
      Promise.reject(new Error('network down'));

    await expect(
      useAuthStore.getState().login('a@b.com', 'x')
    ).rejects.toThrow('network down');
    expect(useAuthStore.getState().token).toBeNull();
  });

  it('logout clears token and persisted storage', async () => {
    api.defaults.adapter = (config) =>
      Promise.resolve({
        status: 200,
        data: { success: true, data: { accessToken: TOKEN, user: { id: 'u1' } } },
        config,
      });
    await useAuthStore.getState().login('a@b.com', 'x');

    useAuthStore.getState().logout();
    expect(useAuthStore.getState().token).toBeNull();
    expect(useAuthStore.getState().user).toBeNull();
    expect(localStorage.getItem('admin_token')).toBeNull();
  });
});
