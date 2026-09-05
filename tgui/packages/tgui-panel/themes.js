/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const THEMES = ['fallout', 'dark', 'light'];

const COLOR_DARK_BG = '#202020';
const COLOR_DARK_BG_DARKER = '#171717';
const COLOR_DARK_TEXT = '#a4bad6';

const COLOR_FALLOUT_BG = '#050c05';
const COLOR_FALLOUT_BG_DARKER = '#030a03';
const COLOR_FALLOUT_TEXT = '#a0d0a0';
const COLOR_FALLOUT_PHOSPHOR = '#4cff4c';
const COLOR_FALLOUT_BTN = '#0a1f0a';

let setClientThemeTimer = null;

/**
 * Darkmode preference, originally by Kmc2000.
 *
 * This lets you switch client themes by using winset.
 *
 * If you change ANYTHING in interface/skin.dmf you need to change it here.
 *
 * There's no way round it. We're essentially changing the skin by hand.
 * It's painful but it works, and is the way Lummox suggested.
 */
export const setClientTheme = name => {
  // Transmit once for fast updates and again in a little while in case we won
  // the race against statbrowser init.
  clearInterval(setClientThemeTimer);
  Byond.command(`.output statbrowser:set_theme ${name}`);
  setClientThemeTimer = setTimeout(() => {
    Byond.command(`.output statbrowser:set_theme ${name}`);
  }, 1500);

  if (name === 'light') {
    return Byond.winset({
      // Main windows
      'infowindow.background-color': 'none',
      'infowindow.text-color': '#000000',
      'info.background-color': 'none',
      'info.text-color': '#000000',
      'browseroutput.background-color': 'none',
      'browseroutput.text-color': '#000000',
      'outputwindow.background-color': 'none',
      'outputwindow.text-color': '#000000',
      'mainwindow.background-color': 'none',
      'split.background-color': 'none',
      // Status and verb tabs
      'output.background-color': 'none',
      'output.text-color': '#000000',
      'statwindow.background-color': 'none',
      'statwindow.text-color': '#000000',
      // Say, OOC, me Buttons etc.
      'saybutton.background-color': 'none',
      'saybutton.text-color': '#000000',
      'asset_cache_browser.background-color': 'none',
      'asset_cache_browser.text-color': '#000000',
      'tooltip.background-color': 'none',
      'tooltip.text-color': '#000000',
      // Fork-specific top-nav buttons (skin.dmf element names)
      'setoocstatus.background-color': 'none',
      'setoocstatus.text-color': '#000000',
      'tgwiki.background-color': 'none',
      'tgwiki.text-color': '#000000',
      'changelog.background-color': 'none',
      'changelog.text-color': '#000000',
      'github.background-color': 'none',
      'github.text-color': '#000000',
      'discord.background-color': 'none',
      'discord.text-color': '#000000',
    });
  }
  if (name === 'fallout') {
    Byond.winset({
      // Main windows
      'infowindow.background-color': COLOR_FALLOUT_BG,
      'infowindow.text-color': COLOR_FALLOUT_TEXT,
      'info.background-color': COLOR_FALLOUT_BG,
      'info.text-color': COLOR_FALLOUT_TEXT,
      'browseroutput.background-color': COLOR_FALLOUT_BG,
      'browseroutput.text-color': COLOR_FALLOUT_TEXT,
      'outputwindow.background-color': COLOR_FALLOUT_BG,
      'outputwindow.text-color': COLOR_FALLOUT_TEXT,
      'mainwindow.background-color': COLOR_FALLOUT_BG,
      'split.background-color': COLOR_FALLOUT_BG,
      // Status and verb tabs
      'output.background-color': COLOR_FALLOUT_BG_DARKER,
      'output.text-color': COLOR_FALLOUT_TEXT,
      'statwindow.background-color': COLOR_FALLOUT_BG_DARKER,
      'statwindow.text-color': COLOR_FALLOUT_TEXT,
      // Say, OOC, me buttons etc.
      'saybutton.background-color': COLOR_FALLOUT_BTN,
      'saybutton.text-color': COLOR_FALLOUT_PHOSPHOR,
      'asset_cache_browser.background-color': COLOR_FALLOUT_BG,
      'asset_cache_browser.text-color': COLOR_FALLOUT_TEXT,
      'tooltip.background-color': COLOR_FALLOUT_BG_DARKER,
      'tooltip.text-color': COLOR_FALLOUT_PHOSPHOR,
      // Fork-specific top-nav buttons (skin.dmf element names)
      'setoocstatus.background-color': COLOR_FALLOUT_BG_DARKER,
      'setoocstatus.text-color': COLOR_FALLOUT_PHOSPHOR,
      'tgwiki.background-color': COLOR_FALLOUT_BG_DARKER,
      'tgwiki.text-color': COLOR_FALLOUT_PHOSPHOR,
      'changelog.background-color': COLOR_FALLOUT_BG_DARKER,
      'changelog.text-color': COLOR_FALLOUT_PHOSPHOR,
      'github.background-color': COLOR_FALLOUT_BG_DARKER,
      'github.text-color': COLOR_FALLOUT_PHOSPHOR,
      'discord.background-color': COLOR_FALLOUT_BG_DARKER,
      'discord.text-color': COLOR_FALLOUT_PHOSPHOR,
      // Chat input box
      'input.background-color': COLOR_FALLOUT_BG_DARKER,
      'input.text-color': COLOR_FALLOUT_TEXT,
      'input.font-family': '"Courier New"',
      'input.font-size': 12,
      // Ensure saybutton is NOT flat so background-color applies
      'saybutton.is-flat': false,
    });
  }
  if (name === 'dark') {
    Byond.winset({
      // Main windows
      'infowindow.background-color': COLOR_DARK_BG,
      'infowindow.text-color': COLOR_DARK_TEXT,
      'info.background-color': COLOR_DARK_BG,
      'info.text-color': COLOR_DARK_TEXT,
      'browseroutput.background-color': COLOR_DARK_BG,
      'browseroutput.text-color': COLOR_DARK_TEXT,
      'outputwindow.background-color': COLOR_DARK_BG,
      'outputwindow.text-color': COLOR_DARK_TEXT,
      'mainwindow.background-color': COLOR_DARK_BG,
      'split.background-color': COLOR_DARK_BG,
      // Status and verb tabs
      'output.background-color': COLOR_DARK_BG_DARKER,
      'output.text-color': COLOR_DARK_TEXT,
      'statwindow.background-color': COLOR_DARK_BG_DARKER,
      'statwindow.text-color': COLOR_DARK_TEXT,
      // Say, OOC, me Buttons etc.
      'saybutton.background-color': COLOR_DARK_BG,
      'saybutton.text-color': COLOR_DARK_TEXT,
      'asset_cache_browser.background-color': COLOR_DARK_BG,
      'asset_cache_browser.text-color': COLOR_DARK_TEXT,
      'tooltip.background-color': COLOR_DARK_BG,
      'tooltip.text-color': COLOR_DARK_TEXT,
      // Fork-specific top-nav buttons (skin.dmf element names)
      'setoocstatus.background-color': COLOR_DARK_BG,
      'setoocstatus.text-color': COLOR_DARK_TEXT,
      'tgwiki.background-color': COLOR_DARK_BG,
      'tgwiki.text-color': COLOR_DARK_TEXT,
      'changelog.background-color': COLOR_DARK_BG,
      'changelog.text-color': COLOR_DARK_TEXT,
      'github.background-color': COLOR_DARK_BG,
      'github.text-color': COLOR_DARK_TEXT,
      'discord.background-color': COLOR_DARK_BG,
      'discord.text-color': COLOR_DARK_TEXT,
    });
  }
};
