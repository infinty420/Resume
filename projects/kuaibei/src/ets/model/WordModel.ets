// 单词数据模型层：词书、单词、学习进度、复习记录、签到记录、用户设置

export interface WordItem {
  id: string;
  word: string;
  phonetic: string;
  meaning: string;
  example: string;
}

export interface WordBookItem {
  id: string;
  name: string;
  description: string;
  isBuiltIn: boolean;
  words: WordItem[];
}

// 单个单词的艾宾浩斯学习进度，按 bookId/word 维度持久化
export interface WordProgress {
  ebbinghausLevel: number;
  reviewCount: number;
  mastered: boolean;
  lastReviewDate: string;
  nextReviewDate: string;
}

export interface ReviewRecord {
  id: string;
  wordBookId: string;
  word: string;
  meaning: string;
  wasCorrect: boolean;
  reviewDate: string;
  levelBefore: number;
  levelAfter: number;
}

export interface CheckInRecord {
  dateKey: string;
  streak: number;
  learned: number;
}

// 0=跟随系统 1=浅色 2=深色
export interface UserSettings {
  themeMode: number;
  fontScale: number;
  dailyTarget: number;
  currentBookId: string;
}

export interface BuiltInBookDef {
  id: string;
  name: string;
  description: string;
  rawFile: string;
}

export function createWord(id: string, word: string, phonetic: string, meaning: string, example: string): WordItem {
  const item: WordItem = {
    id: id,
    word: word,
    phonetic: phonetic,
    meaning: meaning,
    example: example,
  };
  return item;
}

export function createWordBook(id: string, name: string, description: string, isBuiltIn: boolean,
  words: WordItem[]): WordBookItem {
  const book: WordBookItem = {
    id: id,
    name: name,
    description: description,
    isBuiltIn: isBuiltIn,
    words: words,
  };
  return book;
}

export function createWordProgress(): WordProgress {
  const progress: WordProgress = {
    ebbinghausLevel: 0,
    reviewCount: 0,
    mastered: false,
    lastReviewDate: '',
    nextReviewDate: '',
  };
  return progress;
}

export function createReviewRecord(id: string, wordBookId: string, word: string, meaning: string,
  wasCorrect: boolean, reviewDate: string, levelBefore: number, levelAfter: number): ReviewRecord {
  const record: ReviewRecord = {
    id: id,
    wordBookId: wordBookId,
    word: word,
    meaning: meaning,
    wasCorrect: wasCorrect,
    reviewDate: reviewDate,
    levelBefore: levelBefore,
    levelAfter: levelAfter,
  };
  return record;
}

export function createCheckInRecord(dateKey: string, streak: number, learned: number): CheckInRecord {
  const record: CheckInRecord = {
    dateKey: dateKey,
    streak: streak,
    learned: learned,
  };
  return record;
}

export function createDefaultSettings(currentBookId: string): UserSettings {
  const settings: UserSettings = {
    themeMode: 0,
    fontScale: 1.0,
    dailyTarget: 20,
    currentBookId: currentBookId,
  };
  return settings;
}

// 进度快照复制，避免直接修改持久化缓存对象
export function cloneProgress(progress: WordProgress): WordProgress {
  const clone: WordProgress = {
    ebbinghausLevel: progress.ebbinghausLevel,
    reviewCount: progress.reviewCount,
    mastered: progress.mastered,
    lastReviewDate: progress.lastReviewDate,
    nextReviewDate: progress.nextReviewDate,
  };
  return clone;
}
