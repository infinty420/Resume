// 持久化存储服务：基于 preferences 的键值存储，JSON 序列化保存学习数据
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { AppConstants } from '../common/AppConstants';
import {
  CheckInRecord,
  ReviewRecord,
  UserSettings,
  WordBookItem,
  WordItem,
  WordProgress,
  createCheckInRecord,
  createDefaultSettings,
  createReviewRecord,
  createWord,
  createWordBook,
  createWordProgress,
} from '../model/WordModel';

const LOG_DOMAIN: number = 0x0001;
const TAG: string = 'StorageService';

// 单词进度持久化条目，key 格式：bookId/word
export interface ProgressEntry {
  key: string;
  progress: WordProgress;
}

interface RawWord {
  id: string;
  word: string;
  phonetic: string;
  meaning: string;
  example: string;
}

interface RawBook {
  id: string;
  name: string;
  description: string;
  isBuiltIn: boolean;
  words: RawWord[];
}

export class StorageService {
  private static instance: StorageService | null = null;
  private prefs: preferences.Preferences | null = null;

  static getInstance(): StorageService {
    if (StorageService.instance === null) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }

  async init(context: common.Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, AppConstants.STORE_NAME);
      hilog.info(LOG_DOMAIN, TAG, 'preferences initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(err));
      throw new Error('本地存储初始化失败，请重试');
    }
  }

  private async readString(key: string): Promise<string> {
    if (this.prefs === null) {
      return '';
    }
    try {
      const value: string = await this.prefs.get(key, '') as string;
      return value;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'read %{public}s failed: %{public}s', key, JSON.stringify(err));
      return '';
    }
  }

  private async writeString(key: string, value: string): Promise<boolean> {
    if (this.prefs === null) {
      hilog.error(LOG_DOMAIN, TAG, 'write failed: prefs is null');
      return false;
    }
    try {
      await this.prefs.put(key, value);
      await this.prefs.flush();
      return true;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'write %{public}s failed: %{public}s', key, JSON.stringify(err));
      return false;
    }
  }

  async loadSettings(): Promise<UserSettings> {
    const raw: string = await this.readString(AppConstants.KEY_SETTINGS);
    if (raw.length === 0) {
      return createDefaultSettings('');
    }
    try {
      const parsed: UserSettings = JSON.parse(raw) as UserSettings;
      const settings: UserSettings = {
        themeMode: typeof parsed.themeMode === 'number' ? parsed.themeMode : 0,
        fontScale: typeof parsed.fontScale === 'number' ? parsed.fontScale : AppConstants.DEFAULT_FONT_SCALE,
        dailyTarget: typeof parsed.dailyTarget === 'number' && parsed.dailyTarget > 0
          ? parsed.dailyTarget : AppConstants.DEFAULT_DAILY_TARGET,
        currentBookId: typeof parsed.currentBookId === 'string' ? parsed.currentBookId : '',
      };
      return settings;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadSettings parse failed: %{public}s', JSON.stringify(err));
      return createDefaultSettings('');
    }
  }

  async saveSettings(settings: UserSettings): Promise<boolean> {
    return await this.writeString(AppConstants.KEY_SETTINGS, JSON.stringify(settings));
  }

  async loadCheckIns(): Promise<CheckInRecord[]> {
    const raw: string = await this.readString(AppConstants.KEY_CHECK_INS);
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: CheckInRecord[] = JSON.parse(raw) as CheckInRecord[];
      const records: CheckInRecord[] = [];
      for (let i: number = 0; i < parsed.length; i++) {
        const item: CheckInRecord = parsed[i];
        if (typeof item.dateKey === 'string' && item.dateKey.length > 0) {
          records.push(createCheckInRecord(item.dateKey,
            typeof item.streak === 'number' ? item.streak : 0,
            typeof item.learned === 'number' ? item.learned : 0));
        }
      }
      return records;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadCheckIns parse failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async saveCheckIns(records: CheckInRecord[]): Promise<boolean> {
    return await this.writeString(AppConstants.KEY_CHECK_INS, JSON.stringify(records));
  }

  async loadReviewRecords(): Promise<ReviewRecord[]> {
    const raw: string = await this.readString(AppConstants.KEY_REVIEW_RECORDS);
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: ReviewRecord[] = JSON.parse(raw) as ReviewRecord[];
      const records: ReviewRecord[] = [];
      for (let i: number = 0; i < parsed.length; i++) {
        const item: ReviewRecord = parsed[i];
        records.push(createReviewRecord(
          typeof item.id === 'string' ? item.id : '',
          typeof item.wordBookId === 'string' ? item.wordBookId : '',
          typeof item.word === 'string' ? item.word : '',
          typeof item.meaning === 'string' ? item.meaning : '',
          item.wasCorrect === true,
          typeof item.reviewDate === 'string' ? item.reviewDate : '',
          typeof item.levelBefore === 'number' ? item.levelBefore : 0,
          typeof item.levelAfter === 'number' ? item.levelAfter : 0,
        ));
      }
      return records;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadReviewRecords parse failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async saveReviewRecords(records: ReviewRecord[]): Promise<boolean> {
    // 仅保留最近 1000 条，避免无限增长
    const start: number = records.length > 1000 ? records.length - 1000 : 0;
    const trimmed: ReviewRecord[] = records.slice(start);
    return await this.writeString(AppConstants.KEY_REVIEW_RECORDS, JSON.stringify(trimmed));
  }

  async loadProgressEntries(): Promise<ProgressEntry[]> {
    const raw: string = await this.readString(AppConstants.KEY_WORD_PROGRESS);
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: ProgressEntry[] = JSON.parse(raw) as ProgressEntry[];
      const entries: ProgressEntry[] = [];
      for (let i: number = 0; i < parsed.length; i++) {
        const item: ProgressEntry = parsed[i];
        if (typeof item.key !== 'string' || item.key.length === 0) {
          continue;
        }
        const source: WordProgress = item.progress ? item.progress : createWordProgress();
        entries.push({
          key: item.key,
          progress: {
            ebbinghausLevel: typeof source.ebbinghausLevel === 'number' ? source.ebbinghausLevel : 0,
            reviewCount: typeof source.reviewCount === 'number' ? source.reviewCount : 0,
            mastered: source.mastered === true,
            lastReviewDate: typeof source.lastReviewDate === 'string' ? source.lastReviewDate : '',
            nextReviewDate: typeof source.nextReviewDate === 'string' ? source.nextReviewDate : '',
          },
        });
      }
      return entries;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadProgressEntries parse failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async saveProgressEntries(entries: ProgressEntry[]): Promise<boolean> {
    return await this.writeString(AppConstants.KEY_WORD_PROGRESS, JSON.stringify(entries));
  }

  async loadImportedBooks(): Promise<WordBookItem[]> {
    const raw: string = await this.readString(AppConstants.KEY_IMPORTED_BOOKS);
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: RawBook[] = JSON.parse(raw) as RawBook[];
      const books: WordBookItem[] = [];
      for (let i: number = 0; i < parsed.length; i++) {
        const rawBook: RawBook = parsed[i];
        if (typeof rawBook.id !== 'string' || rawBook.id.length === 0) {
          continue;
        }
        const words: WordItem[] = [];
        if (rawBook.words instanceof Array) {
          for (let j: number = 0; j < rawBook.words.length; j++) {
            const rawWord: RawWord = rawBook.words[j];
            words.push(createWord(
              typeof rawWord.id === 'string' ? rawWord.id : `${rawBook.id}_${j}`,
              typeof rawWord.word === 'string' ? rawWord.word : '',
              typeof rawWord.phonetic === 'string' ? rawWord.phonetic : '',
              typeof rawWord.meaning === 'string' ? rawWord.meaning : '暂无释义',
              typeof rawWord.example === 'string' ? rawWord.example : '',
            ));
          }
        }
        books.push(createWordBook(
          rawBook.id,
          typeof rawBook.name === 'string' ? rawBook.name : '导入词书',
          typeof rawBook.description === 'string' ? rawBook.description : '用户导入词表',
          false,
          words,
        ));
      }
      return books;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadImportedBooks parse failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async saveImportedBooks(books: WordBookItem[]): Promise<boolean> {
    return await this.writeString(AppConstants.KEY_IMPORTED_BOOKS, JSON.stringify(books));
  }

  async readAchievementData(): Promise<string> {
    return await this.readString(AppConstants.KEY_ACHIEVEMENTS);
  }

  async writeAchievementData(data: string): Promise<void> {
    await this.writeString(AppConstants.KEY_ACHIEVEMENTS, data);
  }

  async loadQuizCount(): Promise<number> {
    const raw: string = await this.readString(AppConstants.KEY_QUIZ_COUNT);
    if (raw.length === 0) {
      return 0;
    }
    const value: number = Number(raw);
    return isNaN(value) ? 0 : value;
  }

  async saveQuizCount(count: number): Promise<void> {
    await this.writeString(AppConstants.KEY_QUIZ_COUNT, String(count));
  }

  async resetAll(): Promise<boolean> {
    if (this.prefs === null) {
      return false;
    }
    try {
      await this.prefs.clear();
      await this.prefs.flush();
      hilog.info(LOG_DOMAIN, TAG, 'all data reset');
      return true;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'resetAll failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }
}
