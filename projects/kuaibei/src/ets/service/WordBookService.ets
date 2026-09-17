// 词书服务：从 rawfile 加载内置词书、管理用户导入词书
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/AppConstants';
import {
  BuiltInBookDef,
  WordBookItem,
  WordItem,
  createWord,
  createWordBook,
} from '../model/WordModel';
import { StorageService } from './StorageService';

const LOG_DOMAIN: number = 0x0002;
const TAG: string = 'WordBookService';

interface RawWord {
  id: string;
  word: string;
  phonetic: string;
  meaning: string;
  example: string;
}

export interface ImportedBookData {
  id: string;
  name: string;
  description: string;
  words: WordItem[];
}

function dedupeWords(words: WordItem[]): WordItem[] {
  const result: WordItem[] = [];
  const seen: string[] = [];
  for (let i: number = 0; i < words.length; i++) {
    const item: WordItem = words[i];
    const key: string = item.word.trim().toLowerCase();
    if (key.length === 0 || seen.indexOf(key) >= 0) {
      continue;
    }
    seen.push(key);
    result.push(item);
  }
  return result;
}

export class WordBookService {
  private static instance: WordBookService | null = null;
  private books: WordBookItem[] = [];

  static getInstance(): WordBookService {
    if (WordBookService.instance === null) {
      WordBookService.instance = new WordBookService();
    }
    return WordBookService.instance;
  }

  async init(context: common.Context): Promise<void> {
    const loaded: WordBookItem[] = [];
    for (let i: number = 0; i < AppConstants.BUILT_IN_BOOKS.length; i++) {
      const def: BuiltInBookDef = AppConstants.BUILT_IN_BOOKS[i];
      const book: WordBookItem = await this.loadBuiltInBook(context, def);
      loaded.push(book);
    }
    const imported: WordBookItem[] = await StorageService.getInstance().loadImportedBooks();
    for (let i: number = 0; i < imported.length; i++) {
      loaded.push(imported[i]);
    }
    this.books = loaded;
    hilog.info(LOG_DOMAIN, TAG, 'books loaded: %{public}d', this.books.length);
  }

  private async loadBuiltInBook(context: common.Context, def: BuiltInBookDef): Promise<WordBookItem> {
    try {
      const buffer: Uint8Array = await context.resourceManager.getRawFileContent(def.rawFile);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const text: string = decoder.decodeToString(buffer);
      const words: WordItem[] = this.parseWordArray(text, def.id);
      return createWordBook(def.id, def.name, def.description, true, words);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'load %{public}s failed: %{public}s', def.id, JSON.stringify(err));
      throw new Error(`词书「${def.name}」加载失败，请重启应用重试`);
    }
  }

  private parseWordArray(text: string, bookId: string): WordItem[] {
    const parsed: RawWord[] = JSON.parse(text) as RawWord[];
    if (!(parsed instanceof Array)) {
      throw new Error('词库格式错误');
    }
    const words: WordItem[] = [];
    for (let i: number = 0; i < parsed.length; i++) {
      const item: RawWord = parsed[i];
      const wordText: string = typeof item.word === 'string' ? item.word.trim() : '';
      if (wordText.length === 0) {
        continue;
      }
      words.push(createWord(
        typeof item.id === 'string' && item.id.length > 0 ? item.id : `${bookId}_${i}`,
        wordText,
        typeof item.phonetic === 'string' ? item.phonetic : '',
        typeof item.meaning === 'string' ? item.meaning : '暂无释义',
        typeof item.example === 'string' ? item.example : '',
      ));
    }
    return words;
  }

  getAllBooks(): WordBookItem[] {
    return this.books;
  }

  getBook(bookId: string): WordBookItem | undefined {
    for (let i: number = 0; i < this.books.length; i++) {
      if (this.books[i].id === bookId) {
        return this.books[i];
      }
    }
    return undefined;
  }

  getBookWords(bookId: string): WordItem[] {
    const book: WordBookItem | undefined = this.getBook(bookId);
    return book ? book.words : [];
  }

  // 每日一词：根据日期键确定性地从当前词书选取一个单词
  getDailyWord(bookId: string, dateKey: string): WordItem | undefined {
    const words: WordItem[] = this.getBookWords(bookId);
    if (words.length === 0) {
      return undefined;
    }
    let hash: number = 0;
    for (let i: number = 0; i < dateKey.length; i++) {
      hash = (hash * 31 + dateKey.charCodeAt(i)) % 2147483647;
    }
    const index: number = hash >= 0 ? hash % words.length : (-hash) % words.length;
    return words[index];
  }

  sanitizeBookId(value: string): string {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return `import_${Date.now()}`;
    }
    return trimmed.replace(/\s+/g, '_');
  }

  // TXT 格式：每行 word-meaning-phonetic-example（分隔符 - | , ； ;）
  parseImportedText(raw: string, id: string, name: string, description: string): ImportedBookData {
    const lines: string[] = raw.split(/\r?\n/);
    const words: WordItem[] = [];
    for (let i: number = 0; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (line.length === 0) {
        continue;
      }
      const parts: string[] = line.split(/\s*[-|,；;]\s*/);
      const wordText: string = parts.length > 0 ? parts[0].trim() : '';
      if (wordText.length === 0) {
        continue;
      }
      const meaning: string = parts.length > 1 && parts[1].trim().length > 0 ? parts[1].trim() : '暂无释义';
      const phonetic: string = parts.length > 2 ? parts[2].trim() : '';
      const example: string = parts.length > 3 && parts[3].trim().length > 0
        ? parts[3].trim() : `Example for ${wordText}.`;
      words.push(createWord(`${id}_${i}`, wordText, phonetic, meaning, example));
    }
    const data: ImportedBookData = {
      id: id,
      name: name,
      description: description,
      words: dedupeWords(words),
    };
    return data;
  }

  parseImportedJson(raw: string, id: string, name: string, description: string): ImportedBookData {
    const parsed: RawWord[] = JSON.parse(raw) as RawWord[];
    if (!(parsed instanceof Array)) {
      throw new Error('JSON 格式应为单词数组');
    }
    const words: WordItem[] = [];
    for (let i: number = 0; i < parsed.length; i++) {
      const item: RawWord = parsed[i];
      const wordText: string = typeof item.word === 'string' ? item.word.trim() : '';
      if (wordText.length === 0) {
        continue;
      }
      words.push(createWord(
        typeof item.id === 'string' && item.id.length > 0 ? item.id : `${id}_${i}`,
        wordText,
        typeof item.phonetic === 'string' ? item.phonetic : '',
        typeof item.meaning === 'string' && item.meaning.trim().length > 0 ? item.meaning : '暂无释义',
        typeof item.example === 'string' && item.example.trim().length > 0
          ? item.example : `Example for ${wordText}.`,
      ));
    }
    const data: ImportedBookData = {
      id: id,
      name: name,
      description: description,
      words: dedupeWords(words),
    };
    return data;
  }

  // 导入词书：同名 id 覆盖，持久化到 preferences
  async addImportedBook(data: ImportedBookData): Promise<WordBookItem> {
    const book: WordBookItem = createWordBook(data.id, data.name, data.description, false, data.words);
    const nextBooks: WordBookItem[] = [];
    let replaced: boolean = false;
    for (let i: number = 0; i < this.books.length; i++) {
      if (this.books[i].id === book.id && !this.books[i].isBuiltIn) {
        nextBooks.push(book);
        replaced = true;
      } else {
        nextBooks.push(this.books[i]);
      }
    }
    if (!replaced) {
      nextBooks.push(book);
    }
    const importedOnly: WordBookItem[] = [];
    for (let i: number = 0; i < nextBooks.length; i++) {
      if (!nextBooks[i].isBuiltIn) {
        importedOnly.push(nextBooks[i]);
      }
    }
    const saved: boolean = await StorageService.getInstance().saveImportedBooks(importedOnly);
    if (!saved) {
      throw new Error('词书保存失败，请检查存储空间后重试');
    }
    this.books = nextBooks;
    return book;
  }
}
