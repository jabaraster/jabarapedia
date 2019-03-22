type Failable<S, F> = {
  success: S | null;
  fail: F | null
}

interface LanguageMeta {
  lightWeight: boolean;
  staticTyping: boolean;
  functional: boolean;
  objectOriented: boolean;
}

interface Language{
  meta: LanguageMeta
  name: string;
  path: string;
  impression: string;
}

function success<S, F>(success: S): Failable<S, F> {
  return {
    success,
    fail: null
  }
}

function fail<S, F>(fail: F): Failable<S, F> {
  return {
    success: null,
    fail,
  }
}

type Empty = {}
const empty: Empty = {}

export {
  Empty,
  empty,
  Failable,
  success,
  fail,
  LanguageMeta,
  Language,
}