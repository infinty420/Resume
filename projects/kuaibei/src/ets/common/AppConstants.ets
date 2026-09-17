import { BuiltInBookDef } from '../model/WordModel';

// 应用全局常量：艾宾浩斯间隔、持久化键名、内置词书清单
export class AppConstants {
  static readonly EBBINGHAUS_DAYS: number[] = [1, 2, 4, 7, 15, 30];
  static readonly MASTER_LEVEL: number = 6;

  static readonly STORE_NAME: string = 'word_app_prefs';
  static readonly KEY_SETTINGS: string = 'user_settings';
  static readonly KEY_CHECK_INS: string = 'check_ins';
  static readonly KEY_REVIEW_RECORDS: string = 'review_records';
  static readonly KEY_WORD_PROGRESS: string = 'word_progress_map';
  static readonly KEY_IMPORTED_BOOKS: string = 'imported_books';
  static readonly KEY_ACHIEVEMENTS: string = 'achievements';
  static readonly KEY_QUIZ_COUNT: string = 'quiz_count';

  static readonly DEFAULT_DAILY_TARGET: number = 20;
  static readonly DEFAULT_FONT_SCALE: number = 1.0;
  static readonly MIN_FONT_SCALE: number = 0.9;
  static readonly MAX_FONT_SCALE: number = 1.4;
  static readonly MAX_DAILY_TARGET: number = 200;

  static readonly QUIZ_COUNTS: number[] = [5, 10, 20];
  static readonly QUIZ_OPTION_COUNT: number = 4;

  static readonly BUILT_IN_BOOKS: BuiltInBookDef[] = [
    {
      id: 'gaokao',
      name: '高考核心词汇',
      description: '高中英语必备单词',
      rawFile: 'words/gaokao.json',
    },
    {
      id: 'cet4',
      name: '四级核心词汇',
      description: '大学英语四级必备词汇',
      rawFile: 'words/cet4.json',
    },
    {
      id: 'kaoyan',
      name: '考研核心词汇',
      description: '研究生考试必备单词',
      rawFile: 'words/kaoyan.json',
    },
  ];
}
