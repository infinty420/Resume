// 成就服务：检测解锁条件、持久化解锁状态、提供查询
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/AppConstants';
import {
  ACHIEVEMENT_DEFS,
  AchievementDef,
  AchievementState,
  createAchievementState,
} from '../model/AchievementModel';
import { StorageService } from './StorageService';

const LOG_DOMAIN: number = 0x0007;
const TAG: string = 'AchievementService';

export interface AchievementView {
  def: AchievementDef;
  unlocked: boolean;
}

export class AchievementService {
  private static instance: AchievementService | null = null;
  private state: AchievementState = createAchievementState();
  private newlyUnlocked: AchievementDef[] = [];

  static getInstance(): AchievementService {
    if (AchievementService.instance === null) {
      AchievementService.instance = new AchievementService();
    }
    return AchievementService.instance;
  }

  async init(): Promise<void> {
    this.state = await this.loadState();
    hilog.info(LOG_DOMAIN, TAG, 'init, unlocked: %{public}d', this.state.unlockedIds.length);
  }

  private async loadState(): Promise<AchievementState> {
    const raw: string = await StorageService.getInstance().readAchievementData();
    if (raw.length === 0) {
      return createAchievementState();
    }
    try {
      const parsed: AchievementState = JSON.parse(raw) as AchievementState;
      const ids: string[] = Array.isArray(parsed.unlockedIds) ? parsed.unlockedIds : [];
      const state: AchievementState = {
        unlockedIds: ids.filter((id: string) => typeof id === 'string' && id.length > 0),
      };
      return state;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'loadState failed: %{public}s', JSON.stringify(err));
      return createAchievementState();
    }
  }

  private async saveState(): Promise<void> {
    await StorageService.getInstance().writeAchievementData(JSON.stringify(this.state));
  }

  isUnlocked(id: string): boolean {
    return this.state.unlockedIds.indexOf(id) >= 0;
  }

  getUnlockedCount(): number {
    return this.state.unlockedIds.length;
  }

  getTotalCount(): number {
    return ACHIEVEMENT_DEFS.length;
  }

  getAllAchievements(): AchievementView[] {
    const views: AchievementView[] = [];
    for (let i: number = 0; i < ACHIEVEMENT_DEFS.length; i++) {
      const def: AchievementDef = ACHIEVEMENT_DEFS[i];
      const view: AchievementView = {
        def: def,
        unlocked: this.isUnlocked(def.id),
      };
      views.push(view);
    }
    return views;
  }

  // 返回上次检查后新解锁的成就，用于 UI 提示
  popNewlyUnlocked(): AchievementDef[] {
    const result: AchievementDef[] = this.newlyUnlocked;
    this.newlyUnlocked = [];
    return result;
  }

  // 核心检测：根据当前指标值判定是否解锁新成就
  async checkAndUnlock(masteredCount: number, streak: number, totalReviews: number, quizCount: number): Promise<void> {
    const metrics: Record<string, number> = {};
    metrics['mastered'] = masteredCount;
    metrics['streak'] = streak;
    metrics['reviews'] = totalReviews;
    metrics['quizzes'] = quizCount;

    let changed: boolean = false;
    for (let i: number = 0; i < ACHIEVEMENT_DEFS.length; i++) {
      const def: AchievementDef = ACHIEVEMENT_DEFS[i];
      if (this.isUnlocked(def.id)) {
        continue;
      }
      const value: number = metrics[def.category] !== undefined ? metrics[def.category] : 0;
      if (value >= def.threshold) {
        this.state.unlockedIds.push(def.id);
        this.newlyUnlocked.push(def);
        changed = true;
        hilog.info(LOG_DOMAIN, TAG, 'unlocked: %{public}s', def.id);
      }
    }
    if (changed) {
      await this.saveState();
    }
  }
}
