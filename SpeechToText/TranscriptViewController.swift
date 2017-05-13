//
//  TranscriptViewController.swift
//  SpeechToText
//
//  Created by Roger Zhang on 2017-05-11.
//  Copyright © 2017 Roger Zhang. All rights reserved.
//

import UIKit

class TranscriptViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var table: UITableView?
    
    private var transcripts: [String] = []
    
    private var selectedRow: Int = -1
    
    var newRowText: String = ""
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("notes")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Notes"
        
        if let rowHeight = table?.rowHeight {
            table?.estimatedRowHeight = rowHeight
            table?.rowHeight = UITableViewAutomaticDimension
        }
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if selectedRow == -1 {
            return
        }
        transcripts[selectedRow] = newRowText
        if newRowText == "" {
            transcripts.remove(at: selectedRow)
        }
        table?.reloadData()
        
        save()
    }
    
    private func insertNote(_ newNote: String, _ indexPath: IndexPath) {
        transcripts.insert(newNote, at: 0)
        table?.insertRows(at: [indexPath], with: .automatic)
    }
    
    @objc private func addNote() {
        let newNote = ""
        let indexPath = IndexPath(row: 0, section: 0)
        
        self.insertNote(newNote, indexPath)
        
        table?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        
        self.performSegue(withIdentifier: "note", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcripts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = transcripts[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        transcripts.remove(at: indexPath.row)
        table?.deleteRows(at: [indexPath], with: .fade)
        save()
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "note", sender: nil)
    }
    
    // MARK: - Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        table?.setEditing(editing, animated: animated)
    }
    
    // MARK: - Saving
    
    private func save() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(transcripts, toFile: TranscriptViewController.ArchiveURL.path)
        if isSuccessfulSave {
            print("Transcript archives were saved")
        } else {
            print("Transcript archives were not successfully saved")
        }
    }
    
    private func load() {
        if let loadedData = NSKeyedUnarchiver.unarchiveObject(withFile: TranscriptViewController.ArchiveURL.path) as? [String] {
            transcripts = loadedData
            table?.reloadData()
        }
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationViewController = segue.destination
        if let speechTextViewController = destinationViewController as? SpeechTextViewController,
            let identifier = segue.identifier {
            speechTextViewController.navigationItem.title = identifier
            speechTextViewController.masterView = self
            if let thisRow = table?.indexPathForSelectedRow?.row {
                selectedRow = thisRow
                speechTextViewController.setText(with: transcripts[selectedRow])
            }
        }
    }
}
