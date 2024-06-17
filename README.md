## DARS
Diff Aws Resource Script  
<br>

## これは何か???
AWSリソース特化型diffツール  
<br>

## 何に使うのか???
リソース間の  
・設定差異比較(diff)  
・設定値出力(conf)  
・設定差異ファイル出力(html)  
<br>

## なぜ作ったのか???
マネジメントコンソールでの設定値確認が辛いから、、、  
<br>

## 何が嬉しいのか???
・繰り返し可能な設定差異比較  
・AWSサービス毎に異なるコマンド差異の吸収  
・余計な出力の抑制  
・設定値出力  
・設定値確認の証跡残し  
<br>

## 使用例
### < 事前準備編 >
#### profile入力
dars.sh内にprofileを入力  
`export AWS_DEFAULT_PROFILE=xxx  # Enter your profile`  
#### イメージビルド
`docker build . -t dars`
#### コンテナ起動
`docker run --name dars -v /root/.aws:/root/.aws -w /root -it dars /bin/bash`
#### コンテナ再開と接続
`docker start -ai dars`
<br>

### < 実行編 >
#### 差異比較(diff)
`./dars.sh cloudfront.distribution distribution-id-1 distribution-id-2 diff`
#### 設定値出力(conf)
`./dars.sh cloudfront.distribution distribution-id-1 distribution-id-2 conf`
#### 差異比較結果出力(html)
`./dars.sh cloudfront.distribution distribution-id-1 distribution-id-2 html`
#### バッチモード
1. 空白区切りで引数を記載を記載したファイルを作成
2. `./batch-dars.sh 作成したファイルパス`
<br>

## 免責
ローカル実行を想定しています。  
維持管理予定はありませんのでご自由に使用、改変頂いて構いません。  
※リソースの設定を変更するような処理は含まれていませんのでご安心を。  
