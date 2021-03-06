//
//  DisplayScoresTableViewController.swift
//  PreferencePicker
//
//  Created by Kevin Connor on 3/22/16.
//  Copyright © 2016 Kevin Connor. All rights reserved.
//

import UIKit

class DisplayScoresTableViewController: UITableViewController {

    @IBOutlet weak var table: UITableView!
    
    var activeSet: PreferenceSet?
    var preferenceScores: [(MemoryId, Double)]?
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preferenceScores = activeSet!.returnSortedPreferenceScores()
        self.table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferenceScores = activeSet!.returnSortedPreferenceScores()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate struct Storyboard {
        static let CellReuseIdentifier = "PreferenceScoreCell"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preferenceScores!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellReuseIdentifier, for: indexPath)
        let scoreTuple = preferenceScores![indexPath.row]
        let item = activeSet!.getItemById(scoreTuple.0)
        cell.textLabel?.text = item!.titleForTableDisplay()
        cell.detailTextLabel?.text = String(format: "%.0f", scoreTuple.1)

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
