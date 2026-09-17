// 成就系统数据模型：里程碑定义与解锁记录

export interface AchievementDef {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: string;
  threshold: number;
}

export interface AchievementState {
  unlockedIds: string[];
}

export function createAchievementState(): AchievementState {
  const state: AchievementState = {
    unlockedIds: [],
  };
  return state;
}

// 成就定义表：按类型分组，阈值递增
export const ACHIEVEMENT_DEFS: AchievementDef[] = [
  // 掌握单词数
  { id: 'master_10', title: '初窥门径', description: '掌握 10 个单词', icon: '🌱', category: 'mastered', threshold: 10 },
  { id: 'master_50', title: '渐入佳境', description: '掌握 50 个单词', icon: '🌿', category: 'mastered', threshold: 50 },
  { id: 'master_100', title: '百词斩', description: '掌握 100 个单词', icon: '🌳', category: 'mastered', threshold: 100 },
  { id: 'master_300', title: '词汇大师', description: '掌握 300 个单词', icon: '🏆', category: 'mastered', threshold: 300 },
  // 连续签到
  { id: 'streak_3', title: '三日打卡', description: '连续签到 3 天', icon: '🔥', category: 'streak', threshold: 3 },
  { id: 'streak_7', title: '一周坚持', description: '连续签到 7 天', icon: '⚡', category: 'streak', threshold: 7 },
  { id: 'streak_21', title: '习惯养成', description: '连续签到 21 天', icon: '💎', category: 'streak', threshold: 21 },
  { id: 'streak_30', title: '月度达人', description: '连续签到 30 天', icon: '👑', category: 'streak', threshold: 30 },
  // 累计复习次数
  { id: 'review_100', title: '勤奋学子', description: '累计复习 100 次', icon: '📖', category: 'reviews', threshold: 100 },
  { id: 'review_500', title: '孜孜不倦', description: '累计复习 500 次', icon: '📚', category: 'reviews', threshold: 500 },
  { id: 'review_1000', title: '学海无涯', description: '累计复习 1000 次', icon: '🎓', category: 'reviews', threshold: 1000 },
  // 自测完成次数
  { id: 'quiz_10', title: '小试牛刀', description: '完成 10 次自测', icon: '✏️', category: 'quizzes', threshold: 10 },
  { id: 'quiz_50', title: '测验能手', description: '完成 50 次自测', icon: '📝', category: 'quizzes', threshold: 50 },
  { id: 'quiz_100', title: '考试达人', description: '完成 100 次自测', icon: '🎯', category: 'quizzes', threshold: 100 },
];
