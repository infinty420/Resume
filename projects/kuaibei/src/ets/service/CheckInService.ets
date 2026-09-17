// 签到服务：北京时间自然日签到、连续 streak 计算、签到记录持久化
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CheckInRecord, createCheckInRecord } from '../model/WordModel';
import { isYesterday, todayKey } from '../common/DateUtils';
import { StorageService } from './StorageService';

const LOG_DOMAIN: number = 0x0003;
const TAG: string = 'CheckInService';

export class CheckInService {
  private static instance: CheckInService | null = null;
  private records: CheckInRecord[] = [];

  static getInstance(): CheckInService {
    if (CheckInService.instance === null) {
      CheckInService.instance = new CheckInService();
    }
    return CheckInService.instance;
  }

  async init(): Promise<void> {
    this.records = await StorageService.getInstance().loadCheckIns();
  }

  getRecords(): CheckInRecord[] {
    return this.records;
  }

  private findLatestRecord(): CheckInRecord | undefined {
    let latest: CheckInRecord | undefined = undefined;
    for (let i: number = 0; i < this.records.length; i++) {
      const current: CheckInRecord = this.records[i];
      if (latest === undefined || current.dateKey > latest.dateKey) {
        latest = current;
      }
    }
    return latest;
  }

  hasCheckedInToday(): boolean {
    const today: string = todayKey();
    for (let i: number = 0; i < this.records.length; i++) {
      if (this.records[i].dateKey === today) {
        return true;
      }
    }
    return false;
  }

  // 签到成功返回 true；同日重复签到返回 false
  async checkIn(learnedCount: number): Promise<boolean> {
    const today: string = todayKey();
    if (this.hasCheckedInToday()) {
      return false;
    }
    let streak: number = 1;
    const latest: CheckInRecord | undefined = this.findLatestRecord();
    if (latest !== undefined && isYesterday(latest.dateKey, today)) {
      streak = latest.streak + 1;
    }
    const record: CheckInRecord = createCheckInRecord(today, streak, learnedCount);
    this.records.push(record);
    const saved: boolean = await StorageService.getInstance().saveCheckIns(this.records);
    if (!saved) {
      // 持久化失败回滚内存记录，保证内存与磁盘一致，避免按钮态卡死
      this.records.pop();
      hilog.error(LOG_DOMAIN, TAG, 'checkIn persist failed, rolled back');
      return false;
    }
    return true;
  }

  // 当前连续签到天数：今日已签取今日 streak；昨日签过 streak 延续；断签为 0
  getCurrentStreak(): number {
    const today: string = todayKey();
    const latest: CheckInRecord | undefined = this.findLatestRecord();
    if (latest === undefined) {
      return 0;
    }
    if (latest.dateKey === today || isYesterday(latest.dateKey, today)) {
      return latest.streak;
    }
    return 0;
  }

  getTotalCheckInDays(): number {
    return this.records.length;
  }

  getBestStreak(): number {
    let best: number = 0;
    for (let i: number = 0; i < this.records.length; i++) {
      if (this.records[i].streak > best) {
        best = this.records[i].streak;
      }
    }
    return best;
  }

  // 更新今日签到记录中的学习词数（签到后学习的数据快照）
  async updateTodayLearned(learnedCount: number): Promise<void> {
    const today: string = todayKey();
    for (let i: number = 0; i < this.records.length; i++) {
      if (this.records[i].dateKey === today) {
        this.records[i].learned = learnedCount;
        await StorageService.getInstance().saveCheckIns(this.records);
        return;
      }
    }
  }

  // 返回某年某月（month 从 0 开始）已签到的日期键集合
  getMonthCheckInKeys(year: number, month: number): string[] {
    const monthPart: string = month + 1 < 10 ? `0${month + 1}` : `${month + 1}`;
    const prefix: string = `${year}-${monthPart}`;
    const keys: string[] = [];
    for (let i: number = 0; i < this.records.length; i++) {
      if (this.records[i].dateKey.substring(0, 7) === prefix) {
        keys.push(this.records[i].dateKey);
      }
    }
    return keys;
  }
}
