//
//  DisplayActiveSetTableViewController.swift
//  PreferencePicker
//
//  Created by Kevin Connor on 2/29/16.
//  Copyright © 2016 Kevin Connor. All rights reserved.
//

import UIKit

class DisplayActiveSetTableViewController: UITableViewController {
    var activeSet: PreferenceSet?
    
    override func viewDidAppear(animated: Bool) {

        if self.activeSet == nil {
            
            struct HandlerTitles {
                static let CreateSet = "Create Set"
                static let LoadSet = "Load Set"
            }
            
            func alertHandler(action: UIAlertAction) -> Void {
                let loadSetNavController = storyboard!.instantiateViewControllerWithIdentifier("LoadNavigationController") as! UINavigationController
                loadSetNavController.pushViewController(storyboard!.instantiateViewControllerWithIdentifier("LoadNewExistingSet") as! SetLoaderViewController, animated: true)
                loadSetNavController.pushViewController(storyboard!.instantiateViewControllerWithIdentifier(action.title!) as! SetLoaderViewController, animated: true )

                self.presentViewController(loadSetNavController, animated: true, completion: nil)
            }
            let alert = UIAlertController(
                title: "No Active Set",
                message: "Load or Create a Preference Set",
                preferredStyle: UIAlertControllerStyle.Alert
            )
          /*  alert.addAction(UIAlertAction(
                title: "Create Set",
                style: UIAlertActionStyle.Default,
                handler: { (action: UIAlertAction) -> Void in
            })
            )*/
            alert.addAction(UIAlertAction(
                title: HandlerTitles.LoadSet,
                style: UIAlertActionStyle.Default,
                handler: alertHandler
            ))
            
            presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //let count = (activeSet ?? activeSet.items.count)
        return (activeSet != nil ? activeSet!.items.count : 0)
    }
    
    private struct Storyboard {
        static let CellReuseIdentifier = "ChooseActiveSetCell"
    }
    
    private func activeItemTitleForDisplay(indexPath: NSIndexPath) -> String {
        return activeSet!.items[indexPath.row].titleForTableDisplay()
    }
    
    private func activeItemSubtitleForTableDisplay(indexPath: NSIndexPath) -> String {
        return activeSet!.items[indexPath.row].subtitleForTableDisplay()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath)
        
        cell.textLabel?.text = self.activeItemTitleForDisplay(indexPath)
        cell.detailTextLabel?.text = self.activeItemSubtitleForTableDisplay(indexPath)
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
