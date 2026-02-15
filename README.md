# ACC MILS + ACG (Simulink)

## 最短実行
新規MATLABセッションで以下だけ実行してください。

```matlab
run('scripts/run_all.m')
```

これで以下を自動実行します：
- フォルダ作成（model/data/scripts/results/build/scenarios）
- Data Dictionary作成（`data/acc_params.sldd`）
- モデル自動生成（`model/acc_mils.slx`）
- シナリオ作成・MILS実行
- 結果PNG保存（`results/speed.png`, `results/distance.png`, `results/accel.png`）
- Simulink Coder利用可能時は`slbuild`実行（grt）

## MILSの再実行（パラメータ上書き）

```matlab
run_mils(struct('vSet',27,'Th',1.2))
run_mils(struct('scenario','cut_in','vSet',26))
```

## シナリオ追加
- `scenarios/+scenario/<name>.m` を追加
- インターフェースは `sc = scenario.<name>(dt, StopTime, overrides)`
- 必ず `sc.vL_ts`（timeseries）を返す

## よくある失敗への対策
- **辞書紐付けエラー**: `make_model_02.m`で`DataDictionary`をフルパス設定しています。
- **To Workspace形式不一致**: `Structure With Time`を固定設定し、`run_mils.m`側も同形式で読んでいます。
- **外部入力注入の不整合**: モデル側は `From Workspace(vL_ts)` 固定、`run_mils.m`は `simIn.setVariable('vL_ts', ...)` で注入します。
- **slbuildターゲットエラー**: `codegen_04.m`で`SystemTargetFile='grt.tlc'`を明示、さらに`license('test','Simulink_Coder')`で事前判定して未導入環境は明示スキップします。
- **貼り付け由来の不可視文字エラー**: `run_all.m` は実行前に `scripts/*.m` の BOM/非ASCII を自動除去します。テキストエディタ経由のコピペで混入した文字が原因でも復旧しやすくしています。

- **ファイル名エラー（先頭数字）**: `run_all.m` は legacy 名 (`00_setup.m` 等) が残っていた場合に、MATLAB有効名 (`setup_00.m` 等) へ自動リネームしてから実行します。

- **DataDictionary名が無効エラー**: `make_model_02.m` はまずフルパスで辞書紐付けを試し、失敗時は `acc_params.sldd` のファイル名指定へ自動フォールバックします。

- **Unit Delay に OutDataTypeStr が無いエラー**: 互換性のため `make_model_02.m` では `mode_z1` の Unit Delay に `OutDataTypeStr` を設定しない実装にしています。


- **再実行時の残留状態**: `run_all.m` は実行前に `acc_mils` モデル/開いている辞書/主要ログ変数（`vL_ts`,`vE_log`,`d_log`,`aCmd_log`）を軽くクリーンして再現性を上げています。

- **'SubSystem block に Script パラメーターがない' エラー**: `make_model_02.m` は `MATLAB Function` の `Script` 設定に失敗した場合、自動で `MATLAB Fcn + Mux/Demux` 構成へフォールバックします。
