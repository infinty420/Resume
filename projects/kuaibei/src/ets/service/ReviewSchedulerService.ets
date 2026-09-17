// 复习调度服务：艾宾浩斯遗忘曲线、学习队列、复习记录与单词进度持久化
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/AppConstants';
import {
  DayLearnCount,
  addDays,
  dateKeyFromTime,
  diffDays,
  recent7DayKeys,
  todayKey,
  weekdayLabel,
} from '../common/DateUtils';
import {
  ReviewRecord,
  WordItem,
  WordProgress,
  cloneProgress,
  createReviewRecord,
  createWordProgress,
} from '../model/WordModel';
import { StorageService, ProgressEntry } from './StorageService';
import { WordBookService } from './WordBookService';

const LOG_DOMAIN: number = 0x0004;
const TAG: string = 'ReviewScheduler';

function buildProgressKey(bookId: string, word: string): string {
  return `${bookId}/${word}`;
}

function recordDateKey(isoDate: string): string {
  try {
    return dateKeyFromTime(new Date(isoDate).getTime());
  } catch (err) {
    return '';
  }
}

export class ReviewSchedulerService {
  private static instance: ReviewSchedulerService | null = null;
  private progressEntries: ProgressEntry[] = [];
  private reviewRecords: ReviewRecord[] = [];

  static getInstance(): ReviewSchedulerService {
    if (ReviewSchedulerService.instance === null) {
      ReviewSchedulerService.instance = new ReviewSchedulerService();
    }
    return ReviewSchedulerService.instance;
  }

  async init(): Promise<void> {
    const storage: StorageService = StorageService.getInstance();
    this.progressEntries = await storage.loadProgressEntries();
    this.reviewRecords = await storage.loadReviewRecords();
  }

  private findEntryIndex(key: string): number {
    for (let i: number = 0; i < this.progressEntries.length; i++) {
      if (this.progressEntries[i].key === key) {
        return i;
      }
    }
    return -1;
  }

  getProgress(bookId: string, word: string): WordProgress {
    const index: number = this.findEntryIndex(buildProgressKey(bookId, word));
    if (index < 0) {
      return createWordProgress();
    }
    return cloneProgress(this.progressEntries[index].progress);
  }

  // 处理一次复习判定：认识升级、不认识归零，持久化进度并写复习记录
  async processReview(bookId: string, wordItem: WordItem, wasCorrect: boolean): Promise<void> {
    const key: string = buildProgressKey(bookId, wordItem.word);
    const current: WordProgress = this.getProgress(bookId, wordItem.word);
    const levelBefore: number = current.ebbinghausLevel;
    const today: string = todayKey();

    let levelAfter: number = 0;
    let nextReviewDate: string = '';
    let mastered: boolean = false;
    if (wasCorrect) {
      levelAfter = Math.min(levelBefore + 1, AppConstants.MASTER_LEVEL);
      const intervalIndex: number = Math.min(levelBefore, AppConstants.EBBINGHAUS_DAYS.length - 1);
      nextReviewDate = addDays(today, AppConstants.EBBINGHAUS_DAYS[intervalIndex]);
      mastered = levelAfter >= AppConstants.MASTER_LEVEL;
    } else {
      // 不认识：等级归零，当日到期需再次复习（计入"今日待复习"）
      levelAfter = 0;
      nextReviewDate = today;
      mastered = false;
    }

    const updated: WordProgress = {
      ebbinghausLevel: levelAfter,
      reviewCount: current.reviewCount + 1,
      mastered: mastered,
      lastReviewDate: today,
      nextReviewDate: mastered ? '' : nextReviewDate,
    };
    const entry: ProgressEntry = { key: key, progress: updated };
    const existIndex: number = this.findEntryIndex(key);
    if (existIndex >= 0) {
      this.progressEntries[existIndex] = entry;
    } else {
      this.progressEntries.push(entry);
    }

    const record: ReviewRecord = createReviewRecord(
      `r_${Date.now()}_${this.reviewRecords.length}`,
      bookId,
      wordItem.word,
      wordItem.meaning,
      wasCorrect,
      new Date().toISOString(),
      levelBefore,
      levelAfter,
    );
    this.reviewRecords.push(record);

    const storage: StorageService = StorageService.getInstance();
    const progressSaved: boolean = await storage.saveProgressEntries(this.progressEntries);
    const recordSaved: boolean = await storage.saveReviewRecords(this.reviewRecords);
    if (!progressSaved || !recordSaved) {
      hilog.error(LOG_DOMAIN, TAG, 'persist failed: progress=%{public}s record=%{public}s',
        String(progressSaved), String(recordSaved));
    }
  }

  // 今日到期待复习词（nextReviewDate <= 今天且未掌握）
  getTodayReviewList(bookId: string): WordItem[] {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    const today: string = todayKey();
    const due: WordItem[] = [];
    for (let i: number = 0; i < words.length; i++) {
      const progress: WordProgress = this.getProgress(bookId, words[i].word);
      if (progress.mastered) {
        continue;
      }
      if (progress.nextReviewDate.length > 0 && progress.nextReviewDate <= today) {
        due.push(words[i]);
      }
    }
    return due;
  }

  getNewWordList(bookId: string, count: number): WordItem[] {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    const fresh: WordItem[] = [];
    for (let i: number = 0; i < words.length; i++) {
      const progress: WordProgress = this.getProgress(bookId, words[i].word);
      if (progress.reviewCount === 0) {
        fresh.push(words[i]);
        if (fresh.length >= count) {
          break;
        }
      }
    }
    return fresh;
  }

  // 学习队列：到期复习词优先，新词补足至每日目标
  getStudyQueue(bookId: string, dailyTarget: number): WordItem[] {
    const due: WordItem[] = this.getTodayReviewList(bookId);
    const queue: WordItem[] = due.slice(0);
    if (queue.length >= dailyTarget) {
      return queue.slice(0, dailyTarget);
    }
    const need: number = dailyTarget - queue.length;
    const fresh: WordItem[] = this.getNewWordList(bookId, need);
    for (let i: number = 0; i < fresh.length; i++) {
      queue.push(fresh[i]);
    }
    return queue;
  }

  getMasteredCount(bookId: string): number {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    let count: number = 0;
    for (let i: number = 0; i < words.length; i++) {
      if (this.getProgress(bookId, words[i].word).mastered) {
        count += 1;
      }
    }
    return count;
  }

  getDueCount(bookId: string): number {
    return this.getTodayReviewList(bookId).length;
  }

  getNewWordCount(bookId: string): number {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    let count: number = 0;
    for (let i: number = 0; i < words.length; i++) {
      if (this.getProgress(bookId, words[i].word).reviewCount === 0) {
        count += 1;
      }
    }
    return count;
  }

  getLearningCount(bookId: string): number {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    let count: number = 0;
    for (let i: number = 0; i < words.length; i++) {
      const progress: WordProgress = this.getProgress(bookId, words[i].word);
      if (progress.reviewCount > 0 && !progress.mastered) {
        count += 1;
      }
    }
    return count;
  }

  // 遗忘词：超过 7 天未复习且未掌握
  getForgottenCount(bookId: string): number {
    const words: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    const today: string = todayKey();
    let count: number = 0;
    for (let i: number = 0; i < words.length; i++) {
      const progress: WordProgress = this.getProgress(bookId, words[i].word);
      if (progress.mastered || progress.lastReviewDate.length === 0) {
        continue;
      }
      if (diffDays(today, progress.lastReviewDate) >= 7) {
        count += 1;
      }
    }
    return count;
  }

  getTodayLearnedCount(): number {
    const today: string = todayKey();
    let count: number = 0;
    for (let i: number = 0; i < this.reviewRecords.length; i++) {
      if (recordDateKey(this.reviewRecords[i].reviewDate) === today) {
        count += 1;
      }
    }
    return count;
  }

  // 近 7 天每日学习量（旧 → 新）
  getRecent7DaysCounts(): DayLearnCount[] {
    const keys: string[] = recent7DayKeys();
    const result: DayLearnCount[] = [];
    for (let i: number = 0; i < keys.length; i++) {
      let count: number = 0;
      for (let j: number = 0; j < this.reviewRecords.length; j++) {
        if (recordDateKey(this.reviewRecords[j].reviewDate) === keys[i]) {
          count += 1;
        }
      }
      const dayCount: DayLearnCount = {
        dateKey: keys[i],
        label: weekdayLabel(keys[i]),
        count: count,
      };
      result.push(dayCount);
    }
    return result;
  }

  getTotalReviewCount(): number {
    return this.reviewRecords.length;
  }

  getCorrectCount(): number {
    let count: number = 0;
    for (let i: number = 0; i < this.reviewRecords.length; i++) {
      if (this.reviewRecords[i].wasCorrect) {
        count += 1;
      }
    }
    return count;
  }

  getWrongCount(): number {
    let count: number = 0;
    for (let i: number = 0; i < this.reviewRecords.length; i++) {
      if (!this.reviewRecords[i].wasCorrect) {
        count += 1;
      }
    }
    return count;
  }

  getAccuracyRate(): number {
    const total: number = this.reviewRecords.length;
    if (total === 0) {
      return 0;
    }
    return Math.round((this.getCorrectCount() / total) * 100);
  }

  getAveragePerDay(): number {
    const total: number = this.reviewRecords.length;
    if (total === 0) {
      return 0;
    }
    const today: string = todayKey();
    let earliest: string = this.reviewRecords[0].reviewDate;
    for (let i: number = 1; i < this.reviewRecords.length; i++) {
      const key: string = recordDateKey(this.reviewRecords[i].reviewDate);
      if (key.length > 0 && key < earliest) {
        earliest = key;
      }
    }
    const earliestKey: string = recordDateKey(earliest);
    if (earliestKey.length === 0) {
      return total;
    }
    const days: number = diffDays(today, earliestKey) + 1;
    if (days <= 0) {
      return total;
    }
    return Math.round((total / days) * 10) / 10;
  }
}
