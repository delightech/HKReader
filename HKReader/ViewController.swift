//
//  ViewController.swift
//  HKReader
//
//  Created by Johnny on 2017/02/25.
//  Copyright © 2017 Johnny. All rights reserved.
//

import UIKit

class ViewController: UIViewController, XMLParserDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // ニュース記事のURLを格納する変数
    var newsUrl = ""
    // ニュース記事のタイトルを格納する変数
    var newsTitle = ""
    var _elementName: String = ""
    var _items: [Item]! = []
    var _item: Item? = nil
    @IBOutlet var table :UITableView!
    var refreshControl:UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ヘッダ部分にタイトルを記載
        self.title = "HKReader"
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(ViewController.refresh), for: UIControlEvents.valueChanged)
        self.table.addSubview(refreshControl)
        
        //Table ViewのDataSource参照先指定
        table.dataSource = self
        // Table Viewのタップ時のdelegate先を指定
        table.delegate = self
        
        loadRss()
    }
    
    func loadRss() {
        //print("load data")
        let url = URL(string: "https://news.ycombinator.com/rss")
        let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data == nil {
                print("dataTaskWithRequest error: \(error)")
                return
            }
            
            let parser = XMLParser(data: data!)
            parser.delegate = self
            parser.parse()
        })
        
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // テーブルビューのセルの数をnewsDataArrayに格納しているデータの数で設定
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return _items.count
    }
    
    // セルに表示する内容を設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // story boardで設定したCellを取得
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
        
        // ニュース記事データを取得（配列の"indexPath.row"番目の要素を取得）
        let item = _items[indexPath.row]
        // タイトル、説明をCellにセット
        cell.textLabel!.text = item.title
        cell.textLabel!.numberOfLines = 3
        //cell.detailTextLabel!.text = item.description
        cell.detailTextLabel!.text = item.pubDate
        return cell
    }
    
    // テーブルビューのセルがタップされた時の処理を追加
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = _items[indexPath.row]
        // StringをNSURLに変換
        //let url = NSURL(string:item.guid)
        //UIApplication.sharedApplication().openURL(url!)
        
        newsUrl = item.link
        //newsTitle = (item.title as NSString).substring(to: 15) + "..."
        newsTitle = item.title
        // WebViewController画面へ遷移
        performSegue(withIdentifier: "toWebView", sender: self)
    }
    
    // WebViewControllerへURLデータを渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // セグエ用にダウンキャストしたWebViewControllerのインスタンス
        let wvc = segue.destination as! WebViewController
        // 変数newsUrlの値をWebViewControllerの変数newsUrlに代入
        wvc.newsUrl = newsUrl
        wvc.newsTitle = newsTitle
    }
    
    // XML解析開始時に実行されるメソッド
    func parserDidStartDocument(_ parser: XMLParser) {
        //print("XML解析開始しました")
    }
    
    // 解析中に要素の開始タグがあったときに実行されるメソッド
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        // print("開始タグ:" + elementName)
        _elementName = elementName
        if elementName == "item" {
            // Itemオブジェクトの初期化
            _item = Item()
        }
    }
    
    // 開始タグと終了タグでくくられたデータがあったときに実行されるメソッド
    func parser(_ parser: XMLParser, foundCharacters chars: String) {
        if _item == nil { return }
        //print(chars)
        //print(_elementName)
        if _elementName == "title" {
            _item!.title = chars
        } else if _elementName == "description" {
            _item!.description = chars
        } else if _elementName == "link" {
            _item!.link = chars
        } else if _elementName == "pubDate" {
            _item!.pubDate = chars
        }
    }
    
    // 解析中に要素の終了タグがあったときに実行されるメソッド
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // print("終了タグ:" + elementName)
        if (elementName == "item" && _item != nil && _item!.title != "" && _item?.description != "") {
            _items!.append(_item!)
        }
        _elementName = ""
    }
    
    // XML解析終了時に実行されるメソッド
    func parserDidEndDocument(_ parser: XMLParser) {
        // print("XML解析終了しました")
        // for Debug
        /*
         for i in _items {
         print("#####################")
         print(i.title)
         print(i.description)
         print("#####################")
         }
         */
        
        // UIの変更はmain thread で行う
        DispatchQueue.main.async(execute: {
            self.table.reloadData()
             print("reload OK")
        })
    }
    
    func refresh() {
        loadRss()
        self.refreshControl?.endRefreshing()
    }
}

