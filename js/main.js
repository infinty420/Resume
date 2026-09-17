/* ============================================================
 * 个人展示平台 · 全站可配置数据（改这里即可更新全站）
 * ============================================================ */
const SITE_CONFIG = {
  name: "刘俊材",
  school: "上海杉达学院",
  major: "计算机科学与技术",
  city: "上海",
  email: "1871550500@qq.com",
  phone: "", // 暂未公开，如需展示请填写
  github: "https://github.com/infinty420",
  repo: "https://github.com/infinty420/Resume.git",
  gitee: "",
  motto: ["HarmonyOS 应用开发", "ArkTS 全栈之路", "用代码解决真实问题", "独立产品闭环"],
};

/* 技能： name / level(0-100) / desc */
const SKILLS = [
  { name: "ArkTS / ArkUI", level: 90, desc: "鸿蒙主语言，声明式 UI" },
  { name: "HarmonyOS SDK", level: 85, desc: "Ability / 路由 / 持久化" },
  { name: "JavaScript / ES6+", level: 82, desc: "异步 / Promise / 模块化" },
  { name: "HTML / CSS", level: 88, desc: "响应式 / Flex / Grid" },
  { name: "Java", level: 70, desc: "OOP / 集合 / 多线程基础" },
  { name: "MySQL / 数据库", level: 68, desc: "CRUD / 表设计 / 索引" },
  { name: "Git / DevEco", level: 80, desc: "版本管理 / 上架流程" },
  { name: "REST API 对接", level: 78, desc: "网络请求 / JSON 解析" },
  { name: "UI / 原型设计", level: 65, desc: "Figma / 墨刀 / 切图" },
];

/* 项目：新增项目只需 push 一条，分类(cat)对应筛选按钮
 * cover 用 emoji + gradient 背景；featured 会在封面显示 ★ */
const PROJECTS = [
  {
    id: "kuaiji",
    name: "快背单词",
    en: "QuickMem Words",
    emoji: "📖",
    gradient: "linear-gradient(135deg,#6366f1,#22d3ee)",
    cat: "harmonyos",
    catLabel: "HarmonyOS",
    featured: true,
    status: "已上架 · 华为应用市场",
    tech: ["ArkTS", "ArkUI", "Preferences", "TTS 朗读", "rawfile 离线词库", "艾宾浩斯调度"],
    brief: "已上架的鸿蒙离线背词应用：首页 / 背词 / 自测 / 统计 / 设置五大 Tab，内置高考 / 四级 / 考研三套离线词书，艾宾浩斯间隔 [1, 2, 4, 7, 15, 30] 天编排复习，到期优先 + 新词补足组建学习队列。",
    highlights: [
      "艾宾浩斯复习调度：认识升级（最高 6 级掌握）、不认识归零当日重学，到期复习优先、新词补足每日目标",
      "三套内置离线词书（高考 / 四级 / 考研，rawfile JSON），支持 TXT / JSON 自助导入词书、同名覆盖、去重",
      "每日一词（日期哈希确定性选取）+ TTS 朗读、签到打卡 + 连续天数、成就解锁弹窗",
      "统计页：近 7 天学习柱状、正确率、遗忘词（超 7 天未复习）、日均量；设置页支持换肤、字号、日目标、数据重置",
      "Preferences 持久化：设置 / 签到 / 复习记录 / 单词进度 / 导入词书 / 成就 / 自测计数，云备份 Ability 兜底",
      "独立完成应用签名、AGC 上架、审核与多轮版本迭代（包名 com.example.firstt，v1.0.0）",
    ],
    role: "独立开发（需求 / 设计 / 编码 / 上架全流程）",
    arch: [
      "pages/Index.ets —— 入口：异步初始化 7 大服务 + 底部 5 Tab 容器",
      "view/HomePage.ets —— 学习指标、今日任务、每日一词、词书切换、签到",
      "view/StudyPage.ets —— 学习队列：到期复习词优先展示",
      "view/QuizPage.ets —— 四选一自测（5 / 10 / 20 题档）",
      "view/StatsPage.ets —— 7 天趋势、正确率、遗忘词统计",
      "service/ReviewSchedulerService.ets —— 艾宾浩斯调度核心",
      "service/WordBookService.ets —— rawfile 词书加载 + 导入解析",
      "service/StorageService.ets —— Preferences 持久化",
      "service/CheckInService / AchievementService / QuizService / TtsService",
    ],
    files: ["StudyPage", "QuizPage", "StatsPage", "ReviewScheduler", "WordBook", "Storage", "Tts", "CheckIn", "Achievement"],
    shots: [
      { src: "images/kuaibei-home.jpeg", caption: "首页：学习指标 + 每日一词 + 词书切换" },
      { src: "images/kuaibei-home-v2.jpeg", caption: "首页 v2：签到打卡与任务入口" },
      { src: "images/kuaibei-stats.jpeg", caption: "统计页：学习趋势与正确率" },
    ],
    sourceDir: "C:\\Users\\infinty\\firstt",
    demo: "#",
    code: "#",
  },
  {
    id: "query",
    name: "Query Software",
    en: "Public Resource Search",
    emoji: "🔍",
    gradient: "linear-gradient(135deg,#a855f7,#ec4899)",
    cat: "harmonyos",
    catLabel: "HarmonyOS",
    featured: true,
    status: "已完成 · 持续迭代",
    tech: ["ArkTS", "Axios", "WebView", "分布式"],
    brief: "公共资源查询鸿蒙 App：聚合多源公开数据，一键检索图书、讲座、场馆等校园与城市资源。",
    highlights: ["聚合图书 / 讲座 / 场馆等多源公共资源，统一搜索入口", "关键词联想 + 搜索历史 + 收藏夹，检索效率翻倍", "网络层统一封装，加载失败重试与缓存策略完备", "适配折叠屏与平板，一套代码多端运行"],
    role: "主导开发（架构 / 核心搜索模块 / 联调）",
    demo: "#",
    code: "#",
  },
  {
    id: "campus",
    name: "杉达校园助手",
    en: "Campus Helper",
    emoji: "🏫",
    gradient: "linear-gradient(135deg,#22d3ee,#34d399)",
    cat: "tool",
    catLabel: "工具效率",
    featured: false,
    status: "课程设计 · 优秀",
    tech: ["ArkTS", "日历API", "通知"],
    brief: "课程表 + 空教室查询 + 社团活动聚合的校园效率工具，获课程设计优秀。",
    highlights: ["一键导入课程表，桌面卡片实时显示下节课", "空教室查询：按教学楼 / 时间段过滤", "社团活动发布与报名，支持推送提醒"],
    role: "独立开发",
    demo: "#",
    code: "#",
  },
  {
    id: "webnav",
    name: "极简开发者导航",
    en: "Dev Navigator",
    emoji: "🧭",
    gradient: "linear-gradient(135deg,#f59e0b,#ef4444)",
    cat: "web",
    catLabel: "Web",
    featured: false,
    status: "已上线 · 个人站点",
    tech: ["HTML", "CSS", "JavaScript"],
    brief: "为开发者打造的极简网址导航：分类收录、快捷搜索、一键换肤，纯前端零后端。",
    highlights: ["localStorage 持久化自定义链接", "支持 / 快捷键聚焦搜索", "暗色 / 浅色主题一键切换"],
    role: "独立开发",
    demo: "#",
    code: "#",
  },
  {
    id: "algo",
    name: "算法可视化小站",
    en: "Algo Visualizer",
    emoji: "📊",
    gradient: "linear-gradient(135deg,#10b981,#6366f1)",
    cat: "study",
    catLabel: "学习成长",
    featured: false,
    status: "学习项目 · 开源",
    tech: ["JavaScript", "Canvas"],
    brief: "冒泡 / 快排 / 二分查找动画演示，帮助理解数据结构与算法，配套学习笔记。",
    highlights: ["Canvas 逐帧动画，可调速播放", "同步展示代码执行行，高亮当前步骤", "输出 20+ 篇算法学习笔记"],
    role: "独立开发",
    demo: "#",
    code: "#",
  },
  {
    id: "todo",
    name: "专注番茄钟",
    en: "Focus Timer",
    emoji: "🍅",
    gradient: "linear-gradient(135deg,#ec4899,#f43f5e)",
    cat: "tool",
    catLabel: "工具效率",
    featured: false,
    status: "练手项目 · 已完成",
    tech: ["ArkTS", "后台任务"],
    brief: "番茄工作法计时器：专注统计、休息提醒、白噪音，第一个鸿蒙练手作品。",
    highlights: ["前后台计时不丢失，锁屏依然精准", "专注时长周报统计", "鸿蒙实况窗 / 通知栏进度展示"],
    role: "独立开发",
    demo: "#",
    code: "#",
  },
];

/* 成长经历 */
const TIMELINE = [
  { date: "2026.06 — 至今", title: "持续深耕鸿蒙生态 · 冲击 NEXT 全栈", desc: "学习 HarmonyOS NEXT 分布式能力与 AI 框架，计划再上架 1 款效率工具，维护快背单词用户反馈迭代。" },
  { date: "2026.03", title: "「快背单词」上架华为应用市场", desc: "从 0 到 1 独立负责需求、设计、开发、上架审核全流程，首个正式上架作品，上线后收集用户反馈完成 3 次迭代。" },
  { date: "2025.12", title: "主导开发「Query Software」公共资源查询 App", desc: "负责整体架构与核心搜索模块，聚合多源公开数据，攻克网络封装、缓存与多端适配难题。" },
  { date: "2025.10", title: "全面转向 HarmonyOS 开发", desc: "系统学习 ArkTS、ArkUI、Stage 模型，完成番茄钟、校园助手等练手项目，打牢移动端基础。" },
  { date: "2025.09", title: "入学上海杉达学院 · 计算机科学与技术", desc: "开启 CS 之旅：C 语言、数据结构、计算机网络，同时自学 HTML / CSS / JavaScript，做出生涯第一个网页。" },
];

/* ================= 渲染逻辑（一般不需要改） ================= */
const $ = (s) => document.querySelector(s);

/* 姓名同步 */
["userName", "cardName", "footName"].forEach((id) => {
  const el = document.getElementById(id);
  if (el) el.textContent = SITE_CONFIG.name;
});
document.getElementById("year").textContent = new Date().getFullYear();

/* 打字机 */
(() => {
  const el = $("#typing");
  const words = SITE_CONFIG.motto;
  let w = 0, c = 0, del = false;
  (function tick() {
    const word = words[w];
    el.textContent = word.slice(0, c);
    if (!del && c < word.length) { c++; setTimeout(tick, 110); }
    else if (!del) { del = true; setTimeout(tick, 1400); }
    else if (c > 0) { c--; setTimeout(tick, 45); }
    else { del = false; w = (w + 1) % words.length; setTimeout(tick, 300); }
  })();
})();

/* 数字滚动 */
(() => {
  const io = new IntersectionObserver((es) => es.forEach((e) => {
    if (!e.isIntersecting) return;
    const el = e.target, end = +el.dataset.count; let cur = 0;
    const step = () => { cur += Math.max(1, Math.ceil(end / 40)); if (cur >= end) cur = end; el.textContent = cur; if (cur < end) requestAnimationFrame(step); };
    step(); io.unobserve(el);
  }), { threshold: 0.6 });
  document.querySelectorAll("[data-count]").forEach((el) => io.observe(el));
})();

/* 技能渲染 */
$("#skillsGrid").innerHTML = SKILLS.map((s) => `
  <div class="card skill-card reveal">
    <h4>${s.name}<em>${s.level}%</em></h4>
    <p>${s.desc}</p>
    <div class="bar"><i data-w="${s.level}"></i></div>
  </div>`).join("");

/* 项目渲染 + 筛选 */
function renderProjects(filter = "all") {
  const list = PROJECTS.filter((p) => filter === "all" || p.cat === filter);
  $("#projectsGrid").innerHTML = list.map((p) => `
    <article class="card proj reveal vis" data-id="${p.id}">
      <div class="proj-cover" style="background:${p.gradient}"><span>${p.emoji}</span>
        <span class="proj-flag">${p.catLabel}</span>
        ${p.featured ? `<span class="proj-stars">★ 主打</span>` : ""}
      </div>
      <div class="proj-body">
        <h3>${p.name} <small style="color:var(--muted);font-weight:400">· ${p.en}</small></h3>
        <p>${p.brief}</p>
        <div class="proj-tech">${p.tech.map((t) => `<span>${t}</span>`).join("")}</div>
        <div class="proj-foot"><span>📌 ${p.status}</span><b>查看详情 →</b></div>
      </div>
    </article>`).join("");
  document.querySelectorAll(".proj").forEach((el) =>
    el.addEventListener("click", () => openModal(el.dataset.id)));
}
renderProjects();
$("#filterRow").addEventListener("click", (e) => {
  const btn = e.target.closest(".filter");
  if (!btn) return;
  document.querySelectorAll(".filter").forEach((b) => b.classList.remove("active"));
  btn.classList.add("active");
  renderProjects(btn.dataset.filter);
});

/* 弹窗（含截图画廊 + 架构清单 + 源码目录） */
function openModal(id) {
  const p = PROJECTS.find((x) => x.id === id);
  if (!p) return;
  $("#modalBody").innerHTML = `
    <div class="m-cover" style="background:${p.gradient}"><span>${p.emoji}</span></div>
    <p class="eyebrow">${p.catLabel} · ${p.status}</p>
    <h2>${p.name}</h2>
    <p>${p.brief}</p>
    ${p.shots ? `<h4>📸 应用截图</h4><div class="shot-grid">${p.shots.map((s) => `
      <figure><img src="${s.src}" alt="${s.caption}" loading="lazy" /><figcaption>${s.caption}</figcaption></figure>`).join("")}</div>` : ""}
    <h4>✨ 项目亮点</h4>
    <ul>${p.highlights.map((h) => `<li>${h}</li>`).join("")}</ul>
    ${p.arch ? `<h4>🧩 核心模块（源码对照）</h4><ul class="arch-list">${p.arch.map((a) => `<li><code>${a}</code></li>`).join("")}</ul>
    <p class="muted">📁 本地源码目录：<code>${p.sourceDir}</code></p>` : ""}
    <h4>🧑‍💻 我的职责</h4><p>${p.role}</p>
    <h4>🛠 技术栈</h4>
    <div class="proj-tech">${p.tech.map((t) => `<span>${t}</span>`).join("")}</div>
    <div class="m-actions">
      <a class="btn btn-primary btn-small" href="${p.demo}" target="_blank">🔗 演示 / 下载</a>
      <a class="btn btn-ghost btn-small" href="${p.code}" target="_blank">💻 查看源码</a>
    </div>`;
  $("#modalMask").classList.add("show");
  document.body.style.overflow = "hidden";
}
function closeModal() { $("#modalMask").classList.remove("show"); document.body.style.overflow = ""; }
$("#modalClose").addEventListener("click", closeModal);
$("#modalMask").addEventListener("click", (e) => { if (e.target.id === "modalMask") closeModal(); });
document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeModal(); });

/* 时间线 */
$("#timeline").innerHTML = TIMELINE.map((t) => `
  <div class="tl-item reveal">
    <div class="tl-date">${t.date}</div>
    <div class="card"><h4>${t.title}</h4><p>${t.desc}</p></div>
  </div>`).join("");

/* 联系方式（自动跳过未填写的项） */
const CONTACTS = [
  { icon: "📧", label: "邮箱", value: SITE_CONFIG.email, href: `mailto:${SITE_CONFIG.email}` },
  ...(SITE_CONFIG.phone ? [{ icon: "📱", label: "电话", value: SITE_CONFIG.phone, href: `tel:${SITE_CONFIG.phone.replace(/-/g, "")}` }] : []),
  { icon: "🐙", label: "GitHub", value: SITE_CONFIG.github, href: SITE_CONFIG.github },
  ...(SITE_CONFIG.gitee ? [{ icon: "🦄", label: "Gitee", value: SITE_CONFIG.gitee, href: SITE_CONFIG.gitee }] : []),
  { icon: "📦", label: "本站源码", value: SITE_CONFIG.repo, href: SITE_CONFIG.repo },
];
$("#contactItems").innerHTML = CONTACTS.map((c) => `<a href="${c.href}" target="_blank"><span class="ci">${c.icon}</span><span><b>${c.label}</b><br><small class="muted">${c.value}</small></span></a>`).join("");

/* 留言表单 → 调起邮件 */
$("#msgForm").addEventListener("submit", (e) => {
  e.preventDefault();
  const f = new FormData(e.target);
  const subject = encodeURIComponent(`【作品集留言】来自 ${f.get("name")}`);
  const body = encodeURIComponent(`${f.get("msg")}\n\n—— ${f.get("name")}（${f.get("contact")}）`);
  location.href = `mailto:${SITE_CONFIG.email}?subject=${subject}&body=${body}`;
  alert("正在为你打开邮件客户端发送留言，感谢联系！");
});

/* 主题 / 导航 / 回到顶部 / 打印 */
$("#themeBtn").addEventListener("click", () => {
  const html = document.documentElement;
  html.dataset.theme = html.dataset.theme === "dark" ? "light" : "dark";
  $("#themeBtn").textContent = html.dataset.theme === "dark" ? "◐" : "☀";
});
$("#hamburger").addEventListener("click", () => $("#navLinks").classList.toggle("open"));
document.querySelectorAll("#navLinks a").forEach((a) =>
  a.addEventListener("click", () => {
    $("#navLinks").classList.remove("open");
    document.querySelectorAll("#navLinks a").forEach((x) => x.classList.remove("active"));
    a.classList.add("active");
  }));
$("#backTop").addEventListener("click", () => scrollTo({ top: 0, behavior: "smooth" }));
$("#printBtn").addEventListener("click", (e) => { e.preventDefault(); print(); });

/* 滚动显现 + 技能条 */
const revealIO = new IntersectionObserver((es) => es.forEach((e) => {
  if (!e.isIntersecting) return;
  e.target.classList.add("vis");
  e.target.querySelectorAll(".bar i").forEach((b) => (b.style.width = b.dataset.w + "%"));
  revealIO.unobserve(e.target);
}), { threshold: 0.15 });
document.querySelectorAll(".reveal").forEach((el) => revealIO.observe(el));
