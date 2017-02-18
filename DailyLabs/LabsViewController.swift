//
//  LabsViewController.swift
//  DailyLabs
//
//  Created by Gleb Kulik on 2/07/17.
//  Copyright © 2017 Gleb Kulik. All rights reserved.
//

import UIKit
import RealmSwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}



class LabsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var selectedSubject : Subject!
    var todoLabs : Results<Lab>!
    var completedLabs : Results<Lab>!
    var currentCreateAction:UIAlertAction!
    
    var isEditingMode = false

    @IBOutlet weak var labsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        labsTableView.rowHeight = 65.0
        self.title = selectedSubject.name
        readLabsAndUpateUI()
    }
    
    // MARK: - User Actions -
    
    @IBAction func didClickOnEditLabs(_ sender: UIBarButtonItem) {
        isEditingMode = !isEditingMode
        self.labsTableView.setEditing(isEditingMode, animated: true)
    }
    
    @IBAction func didClickOnAddLab(_ sender: UIBarButtonItem) {
        self.displayAlertToAddLab(nil)
    }
    
    func readLabsAndUpateUI(){
        
        completedLabs = self.selectedSubject.labs.filter("isCompleted = true")
        todoLabs = self.selectedSubject.labs.filter("isCompleted = false")
        
        self.labsTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource -
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if section == 0{
            return todoLabs.count
        }
        return completedLabs.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0{
            return "TODO LABS"
        }
        return "COMPLETED LABS"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        var task: Lab!
        if indexPath.section == 0{
            cell?.backgroundColor = colorForIndexUndone(index: indexPath.row)
            task = todoLabs[indexPath.row]
        }
        else{
            task = completedLabs[indexPath.row]
            cell?.backgroundColor = colorForIndexDone(index: indexPath.row)
        }
        
        cell?.textLabel?.text = task.name
        return cell!
    }
    
    
    func displayAlertToAddLab(_ updatedLab:Lab!){
        
        var title = "New Lab"
        var doneTitle = "Create"
        if updatedLab != nil{
            title = "Update Lab"
            doneTitle = "Update"
        }
        
        let alertController = UIAlertController(title: title, message: "Write the name of your lab.", preferredStyle: UIAlertControllerStyle.alert)
        let createAction = UIAlertAction(title: doneTitle, style: UIAlertActionStyle.default) { (action) -> Void in
            
            let labName = alertController.textFields?.first?.text
            
            if updatedLab != nil{
                // update mode
                try! dlRealm.write{
                    updatedLab.name = labName!
                    self.readLabsAndUpateUI()
                }
            }
            else{
                
                let newLab = Lab()
                newLab.name = labName!
                
                try! dlRealm.write{
                    
                    self.selectedSubject.labs.append(newLab)
                    self.readLabsAndUpateUI()
                }
            }
            
            print(labName ?? "")
        }
        
        alertController.addAction(createAction)
        createAction.isEnabled = false
        self.currentCreateAction = createAction
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Lab Name"
            textField.addTarget(self, action: #selector(LabsViewController.labNameFieldDidChange(_:)) , for: UIControlEvents.editingChanged)
            if updatedLab != nil{
                textField.text = updatedLab.name
            }
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //Enable the create action of the alert only if textfield text is not empty
    func labNameFieldDidChange(_ textField:UITextField){
        self.currentCreateAction.isEnabled = textField.text?.characters.count > 0
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (deleteAction, indexPath) -> Void in
            
            //Deletion will go here
            
            var labToBeDeleted: Lab!
            if indexPath.section == 0{
                labToBeDeleted = self.todoLabs[indexPath.row]
            }
            else{
                labToBeDeleted = self.completedLabs[indexPath.row]
            }
            
            try! dlRealm.write{
                dlRealm.delete(labToBeDeleted)
                self.readLabsAndUpateUI()
            }
        }
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (editAction, indexPath) -> Void in
            
            // Editing will go here
            var labToBeUpdated: Lab!
            if indexPath.section == 0{
                labToBeUpdated = self.todoLabs[indexPath.row]
            }
            else{
                labToBeUpdated = self.completedLabs[indexPath.row]
            }
            
            self.displayAlertToAddLab(labToBeUpdated)
            
        }
        
        let doneAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Done") { (doneAction, indexPath) -> Void in
            
            // Editing will go here
            var labToBeUpdated: Lab!
            if indexPath.section == 0{
                labToBeUpdated = self.todoLabs[indexPath.row]
            }
            else{
                labToBeUpdated = self.completedLabs[indexPath.row]
            }
            try! dlRealm.write{
                labToBeUpdated.isCompleted = true
                self.readLabsAndUpateUI()
            }
            
        }
        return [deleteAction, editAction, doneAction]
    }
    
    // MARK: - Table view delegate
    
    func colorForIndexUndone(index: Int) -> UIColor {
        let todoLabsCount = todoLabs.count - 1
        if todoLabsCount == 0{
            return UIColor(red:0.86, green:0.04, blue:0.04, alpha:1.0)
        }
        let val = (CGFloat(index) / CGFloat(todoLabsCount)) * 0.2
        return UIColor(red:0.86, green:val, blue:0.04, alpha:1.0)
    }
    
    func colorForIndexDone(index: Int) -> UIColor {
        let completedLabsCount = completedLabs.count - 1
        if completedLabsCount == 0{
            return UIColor(red: 0.11, green: 0.62, blue: 0.11, alpha: 1.0)
        }
        let val = (CGFloat(index) / CGFloat(completedLabsCount)) * 0.3
        return UIColor(red: val, green: 0.62, blue: 0.11, alpha: 1.0)
    }
    
}
