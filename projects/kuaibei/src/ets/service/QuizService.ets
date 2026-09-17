// 自测服务：随机抽题、4 选项打乱、按内容判定、错题收集、自测计数
import { AppConstants } from '../common/AppConstants';
import { WordItem } from '../model/WordModel';
import { ReviewSchedulerService } from './ReviewSchedulerService';
import { StorageService } from './StorageService';
import { WordBookService } from './WordBookService';

export const QUIZ_MODE_EN_TO_CN: number = 0;
export const QUIZ_MODE_CN_TO_EN: number = 1;
export const QUIZ_MODE_DICTATION: number = 2;

export interface QuizResult {
  total: number;
  correct: number;
  wrong: number;
  wrongWords: WordItem[];
}

function shuffleList<T>(list: T[]): T[] {
  const result: T[] = list.slice(0);
  for (let i: number = result.length - 1; i > 0; i--) {
    const j: number = Math.floor(Math.random() * (i + 1));
    const temp: T = result[i];
    result[i] = result[j];
    result[j] = temp;
  }
  return result;
}

export class QuizService {
  private static instance: QuizService | null = null;
  private quizWords: WordItem[] = [];
  private currentIndex: number = 0;
  private mode: number = QUIZ_MODE_EN_TO_CN;
  private wrongWords: WordItem[] = [];
  private currentOptions: string[] = [];
  private quizCount: number = 0;

  static getInstance(): QuizService {
    if (QuizService.instance === null) {
      QuizService.instance = new QuizService();
    }
    return QuizService.instance;
  }

  async init(): Promise<void> {
    this.quizCount = await StorageService.getInstance().loadQuizCount();
  }

  getQuizCount(): number {
    return this.quizCount;
  }

  async incrementQuizCount(): Promise<void> {
    this.quizCount += 1;
    await StorageService.getInstance().saveQuizCount(this.quizCount);
  }

  startQuiz(bookId: string, mode: number, count: number): void {
    this.mode = mode;
    this.currentIndex = 0;
    this.wrongWords = [];
    this.currentOptions = [];

    const allWords: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    const scheduler: ReviewSchedulerService = ReviewSchedulerService.getInstance();
    const learned: WordItem[] = [];
    const fresh: WordItem[] = [];
    for (let i: number = 0; i < allWords.length; i++) {
      const reviewCount: number = scheduler.getProgress(bookId, allWords[i].word).reviewCount;
      if (reviewCount > 0) {
        learned.push(allWords[i]);
      } else {
        fresh.push(allWords[i]);
      }
    }
    const pool: WordItem[] = learned.length > 0 ? learned : fresh;
    const target: number = Math.min(count, pool.length);
    this.quizWords = shuffleList(pool).slice(0, target);
  }

  getMode(): number {
    return this.mode;
  }

  getTotal(): number {
    return this.quizWords.length;
  }

  getIndex(): number {
    return this.currentIndex;
  }

  isFinished(): boolean {
    return this.currentIndex >= this.quizWords.length;
  }

  isLastQuestion(): boolean {
    return this.quizWords.length > 0 && this.currentIndex >= this.quizWords.length - 1;
  }

  getCurrentWord(): WordItem | undefined {
    if (this.isFinished()) {
      return undefined;
    }
    return this.quizWords[this.currentIndex];
  }

  private correctAnswer(): string {
    const word: WordItem | undefined = this.getCurrentWord();
    if (word === undefined) {
      return '';
    }
    if (this.mode === QUIZ_MODE_CN_TO_EN || this.mode === QUIZ_MODE_DICTATION) {
      return word.word;
    }
    return word.meaning;
  }

  // 选择题选项：正确答案 + 3 个干扰项，整体打乱
  getOptions(bookId: string): string[] {
    const word: WordItem | undefined = this.getCurrentWord();
    if (word === undefined) {
      return [];
    }
    const answer: string = this.correctAnswer();
    const allWords: WordItem[] = WordBookService.getInstance().getBookWords(bookId);
    const distractors: string[] = [];
    const shuffledOthers: WordItem[] = shuffleList(allWords);
    for (let i: number = 0; i < shuffledOthers.length; i++) {
      const candidate: WordItem = shuffledOthers[i];
      if (candidate.word === word.word) {
        continue;
      }
      const optionText: string = this.mode === QUIZ_MODE_EN_TO_CN ? candidate.meaning : candidate.word;
      if (optionText === answer || distractors.indexOf(optionText) >= 0) {
        continue;
      }
      distractors.push(optionText);
      if (distractors.length >= AppConstants.QUIZ_OPTION_COUNT - 1) {
        break;
      }
    }
    const options: string[] = [answer];
    for (let i: number = 0; i < distractors.length; i++) {
      options.push(distractors[i]);
    }
    this.currentOptions = shuffleList(options);
    return this.currentOptions;
  }

  // 按答案内容判定，与按钮位置无关；错题收集
  checkAnswer(answer: string): boolean {
    const word: WordItem | undefined = this.getCurrentWord();
    if (word === undefined) {
      return false;
    }
    let isCorrect: boolean = false;
    if (this.mode === QUIZ_MODE_DICTATION || this.mode === QUIZ_MODE_CN_TO_EN) {
      isCorrect = answer.trim().toLowerCase() === word.word.trim().toLowerCase();
    } else {
      isCorrect = answer.trim() === word.meaning.trim();
    }
    if (!isCorrect) {
      let exists: boolean = false;
      for (let i: number = 0; i < this.wrongWords.length; i++) {
        if (this.wrongWords[i].word === word.word) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        this.wrongWords.push(word);
      }
    }
    return isCorrect;
  }

  next(): void {
    this.currentIndex += 1;
    this.currentOptions = [];
  }

  getResult(): QuizResult {
    const result: QuizResult = {
      total: this.quizWords.length,
      correct: this.quizWords.length - this.wrongWords.length,
      wrong: this.wrongWords.length,
      wrongWords: this.wrongWords.slice(0),
    };
    return result;
  }
}
