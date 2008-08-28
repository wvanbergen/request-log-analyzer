=begin
index:eJ

= Ruby/ProgressBar: プログレスバーをテキストで表示する Ruby用のライブラリ

最終更新日: 2005-05-22 00:28:53


--

Ruby/ProgressBar はプログレスバーをテキストで表示する Ruby用
のライブラリです。処理の進捗状況をパーセント、プログレスバー、
および推定残り時間として表示します。

最新版は
((<URL:http://namazu.org/~satoru/ruby-progressbar/>))
から入手可能です

== 使用例

  % irb --simple-prompt -r progressbar
  >> pbar = ProgressBar.new("test", 100)
  => (ProgressBar: 0/100)
  >> 100.times {sleep(0.1); pbar.inc}; pbar.finish
  test:          100% |oooooooooooooooooooooooooooooooooooooooo| Time: 00:00:10
  => nil

  >> pbar = ProgressBar.new("test", 100)
  => (ProgressBar: 0/100)
  >> (1..100).each{|x| sleep(0.1); pbar.set(x)}; pbar.finish
  test:           67% |oooooooooooooooooooooooooo              | ETA:  00:00:03

== API

--- ProgressBar#new (title, total, out = STDERR)
    プログレスバーの初期状態を表示し、新しい ProgressBarオブ
    ジェクトを返す。((|title|)) で見出しを、((|total|)) で処
    理の総計を、((|out|)) で出力先の IO を設定する。

    プログレスバーの表示は、前回の表示から進捗が 1%以上あっ
    たとき、あるいは 1秒以上経過した場合に更新されます。

--- ProgressBar#inc (step = 1)
    内部のカウンタを ((|step|)) 数だけ進めて、プログレスバー
    の表示を更新する。バーの右側には推定残り時間を表示する。
    カウンタは ((|total|)) を越えて進むことはない。

--- ProgressBar#set (count)
    カウンタの値を ((|count|)) に設定し、プログレスバーの
    表示を更新する。バーの右側には推定残り時間を表示する。
    ((|count|)) にマイナスの値あるいは ((|total|)) より大き
    い値を渡すと例外が発生する。

--- ProgressBar#finish
    プログレスバーを停止し、プログレスバーの表示を更新する。
    プログレスバーの右側には経過時間を表示する。
    このとき、プログレスバーは 100% で終了する。

--- ProgressBar#halt
    プログレスバーを停止し、プログレスバーの表示を更新する。
    プログレスバーの右側には経過時間を表示する。
    このとき、プログレスバーはその時点のパーセンテージで終了する。

--- ProgressBar#format=
    プログレスバー表示のフォーマットを設定する。
    未変更時は "%-14s %3d%% %s %s"

--- ProgressBar#format_arguments=
    プログレスバー表示に使う関数を設定する。
    未変更時は [:title, :percentage, :bar, :stat]
    ファイル転送時には :stat の変わりに :stat_for_file_transfer
    を使うと転送バイト数と転送速度を表示できる。

--- ProgressBar#file_transfer_mode
    プログレスバー表示に :stat の変わりに :stat_for_file_transfer
    を使い、転送バイト数と転送速度を表示する。


ReverseProgressBar というクラスも提供されます。機能は
ProgressBar とまったく同じですが、プログレスバーの進行方向が
逆になっています。

== 制限事項

進捗状況を処理の総計に対する割合として計算するため、処理の総
計が事前にわからない状況では使えません。また、進捗の流れが均
一でないときには残り時間の推定は正しく行えません。

== ダウンロード

Ruby のライセンスに従ったフリーソフトウェアとして公開します。
完全に無保証です。

  * ((<URL:http://namazu.org/~satoru/ruby-progressbar/ruby-progressbar-0.9.tar.gz>))
  * ((<URL:http://cvs.namazu.org/ruby-progressbar/>))

--

- ((<Satoru Takabayashi|URL:http://namazu.org/~satoru/>)) -
=end
