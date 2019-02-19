interface LanguageMeta {
  lightWeight: boolean;
  staticTyping: boolean;
}

interface Language{
  meta: LanguageMeta
  name: string;
  path: string;
  impression: string;
}

export {
  LanguageMeta,
  Language,
}