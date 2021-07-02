//
// ViewController.swift
//taskapp
//
//created by Kakunaka Renon on 2021/06/28.
//


import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorysearch: UISearchBar!
    
    //Realmインスタンスを取得する
    let realm = try! Realm() //追加
    
    //DB内のタスクが格納されるリスト。
    //日付の近い順でソート：昇順
    //以降内容をアップデートするリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date",ascending: true) //追加
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        categorysearch.delegate = self
        
        categorysearch.showsSearchResultsButton = true
        //入力されてなくてもReturnキーを押せる
        categorysearch.enablesReturnKeyAutomatically = false
        
        categorysearch.showsCancelButton = true
    }

//categoryを検索するメソッド
    func searchBarSearchButtonClicked(_ categorysearch: UISearchBar) {
        //キーボードを閉じる
        categorysearch.endEditing(true)
        //検索結果は検索文字とcategoryの文字が一致するように
        let predicate = NSPredicate(format: "category =  %@", categorysearch.text! )
        let result = realm.objects(Task.self).filter(predicate)
        
        taskArray = result
        tableView.reloadData()
        categorysearch.showsCancelButton = true
    }
//cancelでタスク一覧へ
    func searchBarCancelButtonClicked(_ categorysearch: UISearchBar) {
        //キーボードを閉じる
        categorysearch.endEditing(true)
        
        categorysearch.text = ""
        let main = realm.objects(Task.self)
        
       taskArray = main
       tableView.reloadData()
    }
    
//データの数(＝セルの数)を返すメソッド　　　　　　　　//↓セルの数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count //taskArrayの要素数
    }
    
//各セルの内容を返すメソッド　　　　　　　　　　　　　　//↓taskArrayから該当するデータを取り出してセルに設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        //再生用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //Cellに値を設定する　以下追加
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
                        //↓””を任意の形の文字列に変換
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        //ここまで追加
        
        return cell
   }
    
//各セルを選択した時に実行されるメソッド　　　　　　　 //↓セルをタップした時に呼ばれる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //↓cellSegueのsegueが実行されて画面遷移
        performSegue(withIdentifier: "cellSegue", sender: nil)//タスク一覧画面で＋ボタンをタップした時と、セルをタップした時にタスク作成/編集画面へ遷移
 
    }
    
//セルが削除可能なことを伝えるメソッド　　　　　　　　//↓セルが削除または並び替え可能か
    func tableView(_ tableView: UITableView,editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        
        return.delete
    }
    
//Deleteボタンが押された時に呼ばれるメソッド　　　　　//↓セルが削除された時に呼ばれる
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            //削除するタスクを取得する
            let task = self.taskArray[indexPath.row]

                        // ローカル通知をキャンセルする
                        let center = UNUserNotificationCenter.current()
                        center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
                        //データベースから削除する
                            try! realm.write { //try!はエラー無視
                            self.realm.delete(self.taskArray[indexPath.row])
                                      //↓左にスワイプして削除ボタンを表示タップ
                            tableView.deleteRows(at: [indexPath], with: .fade)
        }
            // 未通知のローカル通知一覧をログ出力
                        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                            for request in requests {
                                print("/---------------")
                                print(request)
                                print("---------------/")
                            }
                        }
                    }
        }
        
//segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
   }

    
// 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        }
}
