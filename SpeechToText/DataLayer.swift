//
//  DataLayer.swift
//  SpeechToText
//
//  Created by Roger Zhang on 2017-05-07.
//  Copyright © 2017 Roger Zhang. All rights reserved.
//

import Foundation
import CoreData

class DataLayer {
    let parentContext = CoreDataStack.sharedInstance.persistentContainer.viewContext
    
    let persistentContainer = CoreDataStack.sharedInstance.persistentContainer
    
    let sort = NSSortDescriptor(key:"entry", ascending: true)
    
    var notes = [Note]()
    
    lazy var numberOfResults: Int = {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        let count = (try? self.parentContext.count(for: fetchRequest)) ?? 0
        
        return count
    }()
    
    func saveData(with entry: String) {
        let note = Note(context: parentContext)
        note.entry = entry
        parentContext.saveContext()
    }
    
    func deleteData(with entry: String) {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        
        let predicate = NSPredicate(format: "entry = %@", entry)
        request.predicate = predicate
        request.sortDescriptors = [sort]
        
        if let matchingNotes = try? parentContext.fetch(request) {
            if matchingNotes.count > 0 {
                parentContext.delete(matchingNotes[0])
                parentContext.saveContext()
            }
        }
    }
    
    func fetchData(context: NSManagedObjectContext? = nil) -> [String] {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.sortDescriptors = [sort]
        
        let currentContext = context ?? self.parentContext
        
        var entries = [String]()
        
        if let notes = try? currentContext.fetch(fetchRequest) {
            for note in notes {
                if let entry = note.entry {
                    entries.append(entry)
                }
            }
        }
        
        return entries
    }
}
