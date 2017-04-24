//
//  SubjectsViewController.swift
//  DailyLabs
//
//  Created by Gleb Kulik on 2/11/17.
//  Copyright © 2017 Gleb Kulik. All rights reserved.
//

import UIKit
import RealmSwift
import SWXMLHash

class SubjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var subjectsTableView: UITableView!
    
    var subjects : Results<Subject>! {
        didSet {
            self.subjectsTableView.setEditing(false, animated: true)
            self.subjectsTableView.reloadData()
        }
    }
    
    var subjectsNames = Set<String>()
    var isEditingMode = false
    var currentCreateAction:UIAlertAction!
    var groupsToID = [String:String]()
    
    let downloadCanceledNotification = Notification.Name(rawValue: "downloadCanceled")
    
    
    override func viewDidLoad() {
        // For Tests only!
        try! dlRealm.write {
            dlRealm.deleteAll()
        }
        
        subjectsTableView.rowHeight = 65.0
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cancelDownload),
                                               name: downloadCanceledNotification,
                                               object: nil)
        startDownload()
        super.viewDidLoad()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func cancelDownload() {
        DispatchQueue.main.sync {
            try? dlRealm.write {
                for subjectName in subjectsNames {
                    let subj = Subject()
                    subj.name = subjectName
                    dlRealm.add(subj)
                }
                subjects = dlRealm.objects(Subject.self)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func startDownload() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Splash") {
            present(vc, animated: false)
            XMLFetcher.fetch(from: Const.studentGroupsURL) { xml in
                self.groupsToID = BSUIRXMLParser.parseGroupsID(xml)
                XMLFetcher.fetch(from: Const.scheduleURL.appendingPathComponent(self.groupsToID["453503"] ?? "")) { xml in
                    self.subjectsNames = BSUIRXMLParser.parseSubjects(xml)
                    NotificationCenter.default.post(Notification(name: self.downloadCanceledNotification))
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        readSubjectsAndUpdateUI()
    }
    
    func readSubjectsAndUpdateUI(){
        subjects = dlRealm.objects(Subject.self)
        self.subjectsTableView.setEditing(false, animated: true)
        self.subjectsTableView.reloadData()
    }
   
    // MARK: - User Actions -
    
    @IBAction func didClickOnAddButton(_ sender: UIBarButtonItem) {
        
        displayAlertToAddSubject(nil)
    }
    
    //Enable the create action of the alert only if textfield text is not empty
    func subjectNameFieldDidChange(_ textField:UITextField){
        self.currentCreateAction.isEnabled = (textField.text?.characters.count)! > 0
    }
    
    func displayAlertToAddSubject(_ updatedSubject:Subject!){
        
        var title = "New subject"
        var doneTitle = "Create"
        if updatedSubject != nil{
            title = "Update subject"
            doneTitle = "Update"
        }
        
        let alertController = UIAlertController(title: title, message: "Write the name and description of your subject.", preferredStyle: UIAlertControllerStyle.alert)
        let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.default) { (action) -> Void in
            
            let subjectName = alertController.textFields![0].text
            let subjectNote = alertController.textFields![1].text
            if updatedSubject != nil{
                // update mode
                try! dlRealm.write {
                    updatedSubject.name = subjectName!
                    updatedSubject.notes = subjectNote!
                    self.readSubjectsAndUpdateUI()
                }
            }
            else{
                
                let newSubject = Subject()
                newSubject.name = subjectName!
                newSubject.notes = subjectNote!
                try! dlRealm.write{
                    
                    dlRealm.add(newSubject)
                    self.readSubjectsAndUpdateUI()
                }
            }
            
            print(subjectName ?? "")
            print(subjectNote ?? "")
        }
        
        alertController.addAction(createAction)
        createAction.isEnabled = false
        self.currentCreateAction = createAction
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Subject name"
            textField.addTarget(self, action: #selector(SubjectsViewController.subjectNameFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            if updatedSubject != nil{
                textField.text = updatedSubject.name
            }
        }
        
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Subject description"
            textField.addTarget(self, action: #selector(SubjectsViewController.subjectNameFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            if updatedSubject != nil{
                textField.text = updatedSubject.notes
            }
            
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let listsTasks = subjects {
            return listsTasks.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell")
        
        let list = subjects[indexPath.row]
        
        cell?.textLabel?.text = list.name
        cell?.detailTextLabel?.text = "\(list.labs.count) Labs"
        return cell!
    }
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //Deletion will go here
            
            let listToBeDeleted = self.subjects[indexPath.row]
            try! dlRealm.write{
                
                dlRealm.delete(listToBeDeleted)
                self.readSubjectsAndUpdateUI()
            }
        }
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (editAction, indexPath) -> Void in
            self.isEditingMode = !self.isEditingMode
            self.subjectsTableView.setEditing(self.isEditingMode, animated: true)
            // Editing will go here
            let listToBeUpdated = self.subjects[indexPath.row]
            self.displayAlertToAddSubject(listToBeUpdated)
            
        }
        return [deleteAction, editAction]
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "openLabs", sender: self.subjects[indexPath.row])
    }
    
    //cell style
    func colorForIndex(index: Int) -> UIColor {
        let subjectsCount = subjects.count - 1
        if subjectsCount == 0{
            return UIColor(red:0.20, green:0.47, blue:0.90, alpha:1.0)
        }
        let val = (CGFloat(index) / CGFloat(subjectsCount)) * 0.3
        return UIColor(red:0.20, green:val, blue:0.90, alpha:1.0)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        cell.backgroundColor = colorForIndex(index: indexPath.row)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let labsViewController = segue.destination as! LabsViewController
        labsViewController.selectedSubject = sender as! Subject
    }
    
}
