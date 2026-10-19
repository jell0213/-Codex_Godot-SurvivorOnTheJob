# 之後接入 Spine 動畫

目前所有外觀都由 `PrimitiveVisual2D` 產生，遊戲沒有任何圖片或音效。碰撞、生命、移動、瞄準與傷害皆位於角色根節點；外觀位於子節點，替換外觀不需改動戰鬥程式。

## 替換步驟

1. 取得資源後，選用確認支援 **Godot 4.7.2** 的 Spine Godot runtime，並確認 Spine 編輯器匯出版本與 runtime 相容。依所選 runtime 的官方文件與授權條款整合；本專案不預裝未驗證的擴充套件。
2. 建立例如 `scenes/visuals/player_spine.tscn`，以 `Node2D` 為根，掛上繼承 `CharacterVisual2D` 的 adapter 腳本；把所選 runtime 的骨架節點放在根節點下面。
3. 在 adapter 內將下表的呼叫轉送至實際 runtime API。原點設在角色中心；縮放、骨架朝向修正只調整視覺子樹，勿縮放 `CharacterBody2D` 或碰撞形狀。
4. 開啟 `scenes/player.tscn` 或 `scenes/enemy.tscn`，將根節點的 **Visual Scene** 從 `primitive_visual.tscn` 改成 adapter 場景。兩者可各自指定不同外觀。
5. 重跑現有測試，並在桌面確認動畫、朝向及暫停。骨架和動畫不得自行移動角色、生成子彈或計算傷害。

## Adapter 呼叫契約

| 方法 | 用途 |
| --- | --- |
| `configure(is_player: bool)` | 一次性角色類型設定，在節點加入場景後呼叫 |
| `set_motion(motion: StringName)` | 目前使用 `idle`、`walk`、`death`；adapter 應避免相同狀態每幀重播 |
| `set_facing(direction: Vector2)` | 非零方向向量，用於翻轉或指定朝向；射擊時優先朝向目標 |
| `set_playback_paused(paused: bool)` | 升級、結果畫面停止外觀動畫；選完升級後恢復 |
| `play_attack()` | 每次實際發射子彈時呼叫，供日後觸發射擊動畫 |

實作骨架（runtime 的具體方法請依官方文件填入）：

```gdscript
extends CharacterVisual2D

var current_motion: StringName = &""

func set_motion(motion: StringName) -> void:
    if current_motion == motion:
        return
    current_motion = motion
    # 將 motion 映射至骨架的 idle / walk 動畫。

func set_facing(direction: Vector2) -> void:
    if absf(direction.x) > 0.01:
        # 根據資源原始朝向調整視覺子節點的水平翻轉。
        pass

func play_attack() -> void:
    # 使用獨立動畫軌或一次性動畫，不影響遊戲開火時機。
    pass
```

目前角色沒有原生逐格動畫，也沒有擊中／死亡特效。敵人死亡時會收到 `death` 狀態，隨即移除節點；若日後要播完整死亡動畫，需將純視覺殘影移至獨立節點，並在動畫結束後釋放，不能讓已死亡敵人繼續參與碰撞或波次計數。

目前升級與結束透過遊戲狀態停止戰鬥 tick，沒有暫停整棵 SceneTree。接入自動播放的 Spine／AnimationPlayer 時，需同步處理 adapter 的播放暫停；外觀介面已保留 `set_playback_paused()`，由遊戲在升級／結束與恢復戰鬥時呼叫。
