//
//  ViewController.swift
//  taskapp
//
//  Created by 石井 美記夫 on 2019/05/28.
//  Copyright © 2019 hinoe2646. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var seaBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    var task: Task!
    
    // DB内のタスクが格納されるリスト。
    // 日付近い順|順でソート：降順     "date",(false)
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
//    var dummyTaskArray = try! Realm().objects(Result.self).sorted(byKeyPath: "date", ascending: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        seaBar.delegate = self
    }
    
    // 検索入力欄に何も入力していないときの処理
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            let resTask = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: false)
            taskArray = resTask
            tableView.reloadData()  // テーブル表示の更新
        }
    }
    
    // 検索機能を使用したときの処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        seaBar.endEditing(true)     // 検索ボタン押下でキーボードを閉じる
        
        if seaBar.text == "" {
            let resTask = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: false)
            taskArray = resTask
        } else {
            let resTask = realm.objects(Task.self).filter("category == '\(String(describing: seaBar.text!))'")                
                taskArray = resTask
        }
        tableView.reloadData()  // テーブル表示の更新
    }
    
    // MARK: UITableViewDataSourcecのプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count  // データ数
    }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 再利用可能な　cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する.
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text =
        "\(dateString) [\(task.category)]"

        return cell
    }
    
    // MARK: UITableVIewDelegateプロトコルのメソッド
    // 各セルをた選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests {(requests: [UNNotificationRequest]) in
            
                for request in requests {
                    print("/--------------")
                    print(request)
                    print("--------------/")
                }
            }
        }
    }
    
    // segue で画面遷移するに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = Date()  // 初期値
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1   // 初期値
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    
    @objc func dismissKeyboard() {
        // キーボードを閉じる
        view.endEditing(true)
    }

}

