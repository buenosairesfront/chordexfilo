[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **中文** · [हिन्दी](README.hi.md)

# Chordex Filo

Chordex 系列里那个“坏掉的兄弟”：为
[monome norns](https://monome.org/docs/norns/) 制作的**单音 lo-fi** 合成器。
只有一个声部，外加一团从记忆中不断重复它的**颗粒云**。在和弦模式下，
每个颗粒各自选取和弦中的一个音：一个声部听起来像被拆散的和弦。
破碎、深沉、肮脏，4 个库 × 8 个预设，共 32 种音色。它没有琶音器，
取而代之的是 **FALLA（故障）**：按住 K2 的时候，总有东西会坏掉。

![Chordex Filo](docs/sheet.png)

**屏幕就是声音：**

- **左侧：** 声部。OSC、SUB、NUBE（云）和 POLVO（尘）是亮度随电平变化的圆圈，
  向滤波器发射粒子。滤波器里的点是截止频率，圆环是共振。下方是 10 个推子。
- **中间：** 点组成的圆环是记忆（刚响过的部分会发亮），短线标出当前位置，
  弧线是颗粒：越靠外音越高。内部是干声波形和 12 音轮上的和弦。
  加大 ROTO，整个画面会变成阶梯状并闪烁。
- **右侧：** 库和预设、示波器、频谱，以及按住 K2 时播放的故障动画。

## 特性

- **单音**：后音优先。连奏时声部滑到新音，不重新起音
- **4 个库 × 8 个预设**
  - **ROTO**（破碎）：MODEM、GLITCH、8 BITS、CD RAYADO、CORTO、ESQUIRLAS、
    FALLA、SIERRA
  - **ABISMO**（深渊）：FOSA、SUBSUELO、CALDERA、BALLENA、TUNEL、LODO、DRONE、
    ECLIPSE
  - **CINTA**（磁带）：VHS、CASETE、WALKMAN、BOBINA、DICTAFONO、RADIO AM、
    DERRETIDO、TECLADO
  - **NUBE**（云）：NIEBLA、ENJAMBRE、LLOVIZNA、MAREA、ESPEJO、CORO ROTO、
    CENIZA、AURORA
- **声部**：一个从锯齿波过渡到脉冲波的振荡器、超低音、磁带饱和与抖晃、
  带包络的共振滤波器、滑音
- **颗粒云**：声部始终被录进一段 5 秒的记忆，颗粒从中读取。
  大小、密度、记忆（往回找多远）和混沌（八度、反向颗粒、错乱、声像）
- **和弦模式**：每个颗粒从和弦的四个音里选一个。
  **10 种和弦**：maj、min、dim、aug、7、maj7、min7、m7b5、sus2、sus4
- **FALLA**（按住 K2），与速度同步，4 种类型：
  - **CAIDA**（坠落）：磁带减速，音高垮下去然后熄灭
  - **TARTAMUDEO**（结巴）：磁头停住，重复最后一小段
  - **MORDIDA**（咬）：破碎开到最大，并按节拍切断
  - **POZO**（深井）：低一个八度，滤波器关闭，大厅混响打开
- **roto**：更低的采样率、更少的位数和断音。**polvo**：嘶声、爆豆声、
  交流哼声和高频损失，都跟随声音变化
- **效果**：与速度同步的磁带回声和暗色大厅混响
- **保持**（K1）
- 跟随输入的 MIDI 时钟来决定故障和回声的速度
- 所有设置自动保存

<!-- u-ma:family -->
## Chordex 系列

操作相同，引擎不同。也来试试其他几款：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md)**<br>80 年代复音合成器，配 outrun 日落画面<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md)**<br>4 算子 FM，画成一朵花<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md)**<br>管弦乐弦乐，呈现真实的拉弦运动<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md)**<br>波表：8 个库、每库 8 个波形，画成 3D 波表<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md)**<br>芯片音乐：8 种游戏机芯片 × 8 个预设，画成 tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |
| <a href="https://github.com/buenosairesfront/chordexabnt/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexabnt/main/docs/1_warm_pad.png" width="200" alt="Chordex ABNT"></a> | **[Chordex ABNT](https://github.com/buenosairesfront/chordexabnt/blob/main/README.zh.md)**<br>铺底、氛围、主奏和纹理：4 个系列 × 8 个预设，用“运动”取代琶音器<br>`;install https://github.com/buenosairesfront/chordexabnt` |

**更多 U-MA 作品：** 所有乐器和工具汇集一处 → [U-MA 作品集](https://github.com/buenosairesfront/U-ma/blob/main/README.zh.md)
<!-- /u-ma:family -->

## 需求

- norns（shield、standard 或 fates）
- 一台 MIDI 键盘或控制器

## 安装

在 maiden 中：

```
;install https://github.com/buenosairesfront/chordexfilo
```

然后**重启 norns**（SYSTEM > RESTART），让新引擎 `Filo` 完成编译，
再从 SELECT 加载 **chordexfilo**。

## 控制

| 控制 | 作用 |
|---|---|
| E1 | 截止频率（亮度） |
| E2 | 选择推子（名称会显示片刻） |
| E3 | 调节推子 |
| K3 + E1 | 预设（32 个排成一列：ROTO 1–8、ABISMO、CINTA、NUBE） |
| K3 + E2 | 大厅混响 |
| K3 + E3 | 和弦类型 |
| 按住 K3（不转动旋钮） | 和弦模式 开/关 |
| 按住 K2 | 故障（按住期间持续） |
| K2 + E1 | 故障深度 |
| K2 + E2 | 故障类型 |
| K2 + E3 | 故障速度（1/2 到 1/32） |
| 按住 K1 | 保持 开/关（右上角的菱形） |

**推子：** 起音、释音、共振、颗粒大小、密度、记忆、混沌、roto（破碎）、
polvo（尘）、回声。

**PARAMETERS 菜单：** MIDI 通道（默认 1；0 = 全部）、库、预设、
波形（锯齿–脉冲）、超低音、滑音、八度、抖晃、饱和、云（干声–颗粒）、
衰减、延音、滤波器包络、回声反馈与时间、音量，以及上面的全部参数。

## arc 与 crow

两者都是可选的：不连接 arc 或 crow 时没有任何变化。

**arc**（4 个环，画成旋钮）：1 截止频率 · 2 颗粒大小 · 3 故障深度 · 4 大厅混响

**crow**：IN1 = 音高（V/oct，0 V = C4），IN2 = 门限（触发与释放） · OUT1 = 当前音（V/oct） · OUT2 = 包络（0–8 V，跟随声音的起音和释音） · OUT3 = 与速度同步的 LFO · OUT4 = 每个音一个脉冲。可在 PARAMETERS > ARC / CROW 中关闭。

**速度：** 首次启动时内部速度为 50 BPM。如果有 MIDI 时钟输入（任意 MIDI 端口），则以它为准。

## 画廊

| | |
|---|---|
| ![ROTO](docs/1_modem.png) ROTO · MODEM · maj7 | ![ABISMO](docs/2_fosa.png) ABISMO · FOSA · min7 |
| ![CINTA](docs/3_vhs.png) CINTA · VHS · maj7 | ![NUBE](docs/4_niebla.png) NUBE · NIEBLA · min |
| ![FALLA](docs/5_falla.png) 故障 TARTAMUDEO（按住 K2） | ![preset](docs/6_preset.png) 选择预设（K3 + E1） |

## 致谢

由 [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA 制作。
以 MIT 许可证发布。
