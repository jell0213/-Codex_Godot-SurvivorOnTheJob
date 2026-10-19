# 五波生存 · Five Waves

以 **Godot 4.7.2 Standard（GDScript）** 製作的 2D 倖存者原型。無外部套件、圖片、音效或動畫資源，角色、敵人、子彈和場地皆使用 Godot 原生繪圖；不含擊中特效、粒子、閃光或鏡頭震動。

## 開啟遊戲

用 Godot 4.7.2 匯入根目錄的 `project.godot`，按 **F6** 執行主場景（開啟 `scenes/main.tscn`），或按 **F5** 執行專案。

雲端終端需先啟用已安裝的版本與可寫入的設定目錄：

```bash
export PATH="/workspace/bin:$PATH"
export XDG_CACHE_HOME=/workspace/.cache
export XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/.local/share
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
cd /workspace/-Codex_Godot-SurvivorOnTheJob
godot --version   # 4.7.2.stable.official.ed1daf0bf
godot --path .
```

最後一行需要桌面顯示環境。純終端可使用下方無視窗測試；不會提供可操作的遊戲視窗。

## 操作與規則

| 情境 | 操作 |
| --- | --- |
| 戰鬥 | ↑ ↓ ← → 移動；斜向移動不會更快 |
| 攻擊 | 自動對 340 單位範圍內最近的敵人射擊，不需按鍵 |
| 升級 | ← 攻擊力、→ 攻擊速度；也可用滑鼠點選 |
| 勝利／死亡 | ↑ 或點選「重新開始」；不選擇便停留在結果畫面 |

- 玩家生命 100、移速 235、初始子彈傷害 20、每 0.48 秒一發。子彈為直線、單體、不追蹤、不穿透，超出射程消失。
- 接觸敵人扣血，受傷後有 0.75 秒傷害保護。沒有受傷閃爍。
- 每擊敗一名敵人直接獲得 1 經驗；首次升級需 5 經驗，之後每級需求增加 3。沒有拾取物或額外技能。
- 升級時戰鬥、子彈和出怪暫停。攻擊力每次 **+8**；攻擊速度每次 **×1.2**（射擊間隔 ÷1.2）。
- 清空當波全部敵人後進入下一波，波次間隔 1.8 秒；第五波全數擊敗即勝利。最後一擊直接顯示結果。
- 生命歸零即結束；重新開始會清除敵人、子彈、升級、經驗與計時。

| 波次 | 敵人數 | 生命 | 移速 | 接觸傷害 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 8 | 26 | 64 | 8 |
| 2 | 12 | 36 | 73 | 9 |
| 3 | 16 | 50 | 82 | 10 |
| 4 | 22 | 64 | 91 | 11 |
| 5 | 28 | 82 | 100 | 12 |

敵人從場地四周出現，與玩家至少相距 180 單位，持續追逐玩家。總共 86 名敵人。生命與經驗顯示於介面，不依賴顏色判讀。

## 專案結構與調整

- `scripts/game.gd`：五波數值、自動瞄準、出怪、經驗、遊戲狀態與重開。
- `scripts/actors/`：角色移動、接觸傷害及子彈掃掠碰撞。
- `scripts/hud.gd`：原生 Control 介面、升級及結果選單。
- `scenes/player.tscn`、`scenes/enemy.tscn`：獨立角色場景，Inspector 的 `Visual Scene` 可更換外觀。
- `scripts/visuals/`：外觀介面與原生幾何外觀。未來 Spine 接入方式見 [docs/spine-integration.md](docs/spine-integration.md)。

目前沒有安裝 Spine runtime，也沒有假設其節點 API；核心玩法不需要 Spine 即可執行。

## 驗證

在專案根目錄、完成上述環境變數設定後執行：

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/game_test.gd
godot --headless --path . --fixed-fps 60 --script tests/playthrough_test.gd
godot --headless --path . --quit-after 180
```

`game_test.gd` 使用真實遊戲節點與物理查詢，檢查移動、射程、最近目標、子彈命中、冷卻、受傷保護、經驗、兩種升級、波次完成、死亡與重開；波次流程部分直接造成傷害，以隔離狀態轉換測試。

`playthrough_test.gd` 以固定亂數種子、正常方向輸入與躲避策略完成五波，實際等待出怪、開火、子彈命中及升級，不改動玩家／敵人能力值。這是功能驗證，不代表所有隨機局面或平衡都經過測試。介面尚需在桌面環境進行人工視覺與操作確認。
