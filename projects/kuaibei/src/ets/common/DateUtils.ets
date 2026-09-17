// 北京时间日期工具：统一以 UTC+8 自然日作为签到与复习调度基准

export interface CalendarCell {
  dateKey: string;
  day: number;
  inMonth: boolean;
  isToday: boolean;
}

export interface DayLearnCount {
  dateKey: string;
  label: string;
  count: number;
}

const BEIJING_OFFSET_MS: number = 8 * 60 * 60 * 1000;

function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

// 返回北京时间对应的 Date 对象（其 UTC 字段即北京时间字段）
function beijingDate(baseTime: number): Date {
  return new Date(baseTime + BEIJING_OFFSET_MS);
}

export function formatDateKey(date: Date): string {
  return `${date.getUTCFullYear()}-${pad2(date.getUTCMonth() + 1)}-${pad2(date.getUTCDate())}`;
}

export function todayKey(): string {
  return formatDateKey(beijingDate(Date.now()));
}

export function dateKeyFromTime(time: number): string {
  return formatDateKey(beijingDate(time));
}

// 在日期键上加减天数
export function addDays(dateKey: string, days: number): string {
  const parts: string[] = dateKey.split('-');
  const year: number = Number(parts[0]);
  const month: number = Number(parts[1]);
  const day: number = Number(parts[2]);
  const utc: Date = new Date(Date.UTC(year, month - 1, day));
  const next: Date = new Date(utc.getTime() + days * 24 * 60 * 60 * 1000);
  return formatDateKey(next);
}

// 两个日期键相差的天数（keyA - keyB）
export function diffDays(keyA: string, keyB: string): number {
  const partsA: string[] = keyA.split('-');
  const partsB: string[] = keyB.split('-');
  const timeA: number = Date.UTC(Number(partsA[0]), Number(partsA[1]) - 1, Number(partsA[2]));
  const timeB: number = Date.UTC(Number(partsB[0]), Number(partsB[1]) - 1, Number(partsB[2]));
  return Math.round((timeA - timeB) / (24 * 60 * 60 * 1000));
}

export function isYesterday(lastKey: string, today: string): boolean {
  return diffDays(today, lastKey) === 1;
}

export function isSameDay(keyA: string, keyB: string): boolean {
  return keyA === keyB;
}

// 生成某月日历网格（周日开头，6 行 × 7 列 = 42 格）
export function buildMonthCalendar(year: number, month: number): CalendarCell[] {
  const cells: CalendarCell[] = [];
  const today: string = todayKey();
  const firstOfMonth: Date = new Date(Date.UTC(year, month, 1));
  const firstWeekDay: number = firstOfMonth.getUTCDay();
  const gridStart: Date = new Date(firstOfMonth.getTime() - firstWeekDay * 24 * 60 * 60 * 1000);
  for (let i: number = 0; i < 42; i++) {
    const cellDate: Date = new Date(gridStart.getTime() + i * 24 * 60 * 60 * 1000);
    const key: string = formatDateKey(cellDate);
    const cell: CalendarCell = {
      dateKey: key,
      day: cellDate.getUTCDate(),
      inMonth: cellDate.getUTCMonth() === month,
      isToday: key === today,
    };
    cells.push(cell);
  }
  return cells;
}

export function currentBeijingYearMonth(): number[] {
  const now: Date = beijingDate(Date.now());
  return [now.getUTCFullYear(), now.getUTCMonth()];
}

// 近 7 天日期键（含今天，旧 → 新）
export function recent7DayKeys(): string[] {
  const today: string = todayKey();
  const keys: string[] = [];
  for (let i: number = 6; i >= 0; i--) {
    keys.push(addDays(today, -i));
  }
  return keys;
}

export function weekdayLabel(dateKey: string): string {
  const parts: string[] = dateKey.split('-');
  const date: Date = new Date(Date.UTC(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])));
  const labels: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  return labels[date.getUTCDay()];
}
