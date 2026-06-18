/**
 * Lightweight i18n module for AglusNVR
 * Svelte 5 reactive — state.currentLang is $state, t() reads it directly
 */

import zh from './zh.json';
import en from './en.json';
import ptBR from './pt-BR.json';

type Translations = Record<string, string>;

const locales: Record<string, Translations> = {
  'pt-BR': ptBR as Translations,
  en: en as Translations,
  zh: zh as Translations,
};

// $state object — components import and read state.currentLang for reactive tracking
// t() also reads state.currentLang, so any template calling t() re-evaluates on lang change
export const state = $state({ currentLang: 'pt-BR' });

function detectLanguage(): string {
  const saved = localStorage.getItem('aglus_nvr_lang');
  if (saved && locales[saved]) return saved;

  return 'pt-BR';
}

export function initI18n(): void {
  state.currentLang = detectLanguage();
}

export function setLang(lang: string): void {
  if (!locales[lang]) return;
  state.currentLang = lang;
  localStorage.setItem('aglus_nvr_lang', lang);
}

export function t(key: string, params?: Record<string, string | number>): string {
  // Read state.currentLang ($state) and USE the value — compiler cannot optimize away
  const lang = state.currentLang;
  const dict = locales[lang] || locales['pt-BR'];
  let value = dict[key];

  if (value === undefined) {
    // Fallback padrão do projeto: português do Brasil.
    value = locales['pt-BR'][key];
  }

  if (value === undefined) {
    return key;
  }

  if (params) {
    for (const [k, v] of Object.entries(params)) {
      value = value.replace(`{${k}}`, String(v));
    }
  }

  return value;
}
