/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { storage } from 'common/storage';
import { setClientTheme } from '../themes';
import { loadSettings, updateSettings } from './actions';
import { selectSettings } from './selectors';
import { FONTS_DISABLED } from './constants';

// ── Synchronous early theme application ─────────────────────────────────────
// Read localStorage directly (synchronous) and apply the correct BYOND winset
// colors BEFORE the async storage.get resolves. This eliminates the flash of
// wrong skin colors that would otherwise appear during the Redux boot cycle.
// Mirrors the dark→fallout migration that the reducer applies asynchronously.
(function applyThemeEarly() {
  try {
    const raw = window.localStorage && window.localStorage.getItem('panel-settings');
    const parsed = raw ? JSON.parse(raw) : null;
    const theme = (parsed && parsed.theme && parsed.theme !== 'dark')
      ? parsed.theme
      : 'fallout';
    setClientTheme(theme);
  } catch (_) {
    setClientTheme('fallout');
  }
}());

const setGlobalFontSize = fontSize => {
  document.documentElement.style
    .setProperty('font-size', fontSize + 'px');
  document.body.style
    .setProperty('font-size', fontSize + 'px');
};

const setGlobalFontFamily = fontFamily => {
  if (fontFamily === FONTS_DISABLED) fontFamily = null;

  document.documentElement.style
    .setProperty('font-family', fontFamily);
  document.body.style
    .setProperty('font-family', fontFamily);
};

export const settingsMiddleware = store => {
  let initialized = false;
  return next => action => {
    const { type, payload } = action;
    if (!initialized) {
      initialized = true;
      // Apply the default theme immediately (synchronously) so the UI is
      // already in the right color palette before storage resolves.
      const initialTheme = selectSettings(store.getState()).theme;
      setClientTheme(initialTheme);
      storage.get('panel-settings').then(settings => {
        store.dispatch(loadSettings(settings));
      });
    }
    if (type === updateSettings.type || type === loadSettings.type) {
      // Pass action first so the reducer updates state before we read it
      next(action);
      const settings = selectSettings(store.getState());
      // Always apply the active theme (covers null-payload / first-ever load)
      setClientTheme(settings.theme);
      // Update global UI font size
      setGlobalFontSize(settings.fontSize);
      setGlobalFontFamily(settings.fontFamily);
      // Save settings to the web storage
      storage.set('panel-settings', settings);
      return;
    }
    return next(action);
  };
};
