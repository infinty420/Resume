// TTS 语音服务：基于 CoreSpeechKit 朗读英文单词，失败全程静默降级
import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_DOMAIN: number = 0x0005;
const TAG: string = 'TtsService';

export class TtsService {
  private static instance: TtsService | null = null;
  private engine: textToSpeech.TextToSpeechEngine | null = null;
  private ready: boolean = false;

  static getInstance(): TtsService {
    if (TtsService.instance === null) {
      TtsService.instance = new TtsService();
    }
    return TtsService.instance;
  }

  async init(): Promise<void> {
    if (this.ready || this.engine !== null) {
      return;
    }
    // 先查询设备支持的音色列表，英文 en-US 对应 person: 8
    let availablePerson: number = 8;
    let voiceInstalled: boolean = false;
    try {
      const query: textToSpeech.VoiceQuery = {
        requestId: `voice_${Date.now()}`,
        online: 1,
      };
      const voices: textToSpeech.VoiceInfo[] = await textToSpeech.listVoices(query);
      for (let i: number = 0; i < voices.length; i++) {
        if (voices[i].language.indexOf('en') >= 0) {
          availablePerson = voices[i].person;
          voiceInstalled = voices[i].status === 'INSTALLED';
          break;
        }
      }
      hilog.info(LOG_DOMAIN, TAG, 'listVoices: %{public}d voices, en person=%{public}d installed=%{public}s',
        voices.length, availablePerson, String(voiceInstalled));
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, 'listVoices failed, use default person 8: %{public}s', JSON.stringify(err));
    }

    // 若英文音色未安装，先下载
    if (!voiceInstalled) {
      try {
        await this.downloadVoice(availablePerson);
        hilog.info(LOG_DOMAIN, TAG, 'voice download completed');
      } catch (err) {
        hilog.warn(LOG_DOMAIN, TAG, 'voice download failed, try createEngine anyway: %{public}s', JSON.stringify(err));
      }
    }

    // 多种参数组合降级尝试，兼容不同设备的 HiAI TTS 服务
    const strategies: textToSpeech.CreateEngineParams[] = [];
    const extra1: Record<string, Object> = {};
    extra1.style = 'interaction-broadcast';
    extra1.locate = 'CN';
    extra1.name = 'WordAppEngine';
    // 策略1：官方推荐参数，person 用英文音色
    strategies.push({
      language: 'en-US',
      person: availablePerson,
      online: 1,
      extraParams: extra1,
    });
    // 策略2：无 extraParams
    strategies.push({ language: 'en-US', person: availablePerson, online: 1 } as textToSpeech.CreateEngineParams);
    // 策略3：仅 person + language
    strategies.push({ language: 'en-US', person: availablePerson } as textToSpeech.CreateEngineParams);

    for (let i: number = 0; i < strategies.length; i++) {
      try {
        const engine: textToSpeech.TextToSpeechEngine = await textToSpeech.createEngine(strategies[i]);
        const listener: textToSpeech.SpeakListener = {
          onStart: (requestId: string, response: textToSpeech.StartResponse): void => {
          },
          onComplete: (requestId: string, response: textToSpeech.CompleteResponse): void => {
          },
          onStop: (requestId: string, response: textToSpeech.StopResponse): void => {
          },
          onError: (requestId: string, errorCode: number, errorMessage: string): void => {
            hilog.error(LOG_DOMAIN, TAG,
              'tts speak error: %{public}s %{public}d %{public}s', requestId, errorCode, errorMessage);
          },
        };
        engine.setListener(listener);
        this.engine = engine;
        this.ready = true;
        hilog.info(LOG_DOMAIN, TAG, 'tts engine ready (strategy %{public}d)', i + 1);
        return;
      } catch (err) {
        hilog.warn(LOG_DOMAIN, TAG, 'tts init strategy %{public}d failed: %{public}s',
          i + 1, JSON.stringify(err));
      }
    }
    this.ready = false;
    hilog.error(LOG_DOMAIN, TAG, 'tts init failed: all strategies exhausted');
  }

  private downloadVoice(person: number): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (err: Error) => void) => {
      const downloadParams: textToSpeech.VoiceDownload = {
        requestId: `dl_${Date.now()}`,
        language: 'en-US',
        person: person,
        style: 'interaction-broadcast',
      };
      textToSpeech.downloadVoice(downloadParams, (err: BusinessError | undefined, response: textToSpeech.DownloadResponse) => {
        if (err) {
          // 1002300010 = 音色已下载，视为成功
          if (err.code === 1002300010) {
            resolve();
          } else {
            reject(new Error(`downloadVoice failed: ${err.code} ${err.message}`));
          }
        } else {
          hilog.info(LOG_DOMAIN, TAG, 'downloadVoice response: %{public}s', JSON.stringify(response));
          resolve();
        }
      });
    });
  }

  async speak(text: string): Promise<void> {
    const engine: textToSpeech.TextToSpeechEngine | null = this.engine;
    if (!this.ready || engine === null || text.trim().length === 0) {
      return;
    }
    try {
      const speakParam: textToSpeech.SpeakParams = {
        requestId: `utter_${Date.now()}`,
      };
      await engine.speak(text.trim(), speakParam);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'tts speak failed: %{public}s', JSON.stringify(err));
    }
  }

  shutdown(): void {
    const engine: textToSpeech.TextToSpeechEngine | null = this.engine;
    try {
      if (engine !== null) {
        engine.shutdown();
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'tts shutdown failed: %{public}s', JSON.stringify(err));
    }
    this.engine = null;
    this.ready = false;
  }
}
