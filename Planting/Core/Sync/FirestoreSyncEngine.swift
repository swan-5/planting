import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth

/// M3 of the accounts+sync plan (see BUILD_LOG.md §4) — mirrors the local
/// SwiftData store to Firestore under `users/{uid}/...`. Deliberately
/// simple: last-write-wins via each model's `updatedAt`, no CRDTs, no
/// conflict UI — appropriate for one person syncing their own devices, not
/// multi-writer collaboration.
///
/// Lives entirely outside `Core/Persistence`/`Core/Models` (which
/// `PlantingWidgets` compiles directly) so the widget never needs to link
/// Firestore. Push observes SwiftData's own `ModelContext.didSave`
/// notification rather than having the repositories call in — that would
/// put a Firebase import inside files the widget also compiles.
@MainActor
final class FirestoreSyncEngine {
    static let shared = FirestoreSyncEngine()

    private static let collections = ["categories", "schedules", "todos", "memos", "monthlyReflections"]

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var didSaveObserver: NSObjectProtocol?
    private var isActive = false

    /// Deletions are the one case `ModelContext.didSave` can't self-describe:
    /// by the time the notification fires, a deleted identifier's backing
    /// data is already gone — touching it crashes ("backing data could no
    /// longer be found"). This cache (filled on every push) lets a delete
    /// look up which Firestore doc to remove without ever touching the
    /// invalidated model. Only covers objects this engine has already seen
    /// this run; anything deleted before its first sync leaves an orphaned
    /// Firestore doc — an accepted gap at this app's scale.
    private var identifierCache: [PersistentIdentifier: (collection: String, docID: String)] = [:]

    private init() {}

    func startListening() {
        guard !isActive, let uid = AppSession.shared.currentUserID else { return }
        isActive = true
        let context = PersistenceController.sharedContainer.mainContext

        // Force a fresh ID token before touching Firestore — starting sync
        // synchronously inside the Auth state-change callback can otherwise
        // race Firestore's own internal token attachment, which shows up as
        // a misleading "Missing or insufficient permissions" error.
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { [weak self] _, _ in
            guard let self else { return }
            self.pushAllLocalData(context: context, uid: uid)
            self.attachListeners(uid: uid, context: context)
            self.observeLocalSaves(context: context)
        }
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        if let didSaveObserver {
            NotificationCenter.default.removeObserver(didSaveObserver)
        }
        didSaveObserver = nil
        identifierCache.removeAll()
        isActive = false
    }

    // MARK: - Push (local -> Firestore)

    private func pushAllLocalData(context: ModelContext, uid: String) {
        for category in (try? context.fetch(FetchDescriptor<Category>())) ?? [] {
            pushCategory(category, uid: uid)
        }
        for schedule in (try? context.fetch(FetchDescriptor<Schedule>())) ?? [] {
            pushSchedule(schedule, uid: uid)
        }
        for todo in (try? context.fetch(FetchDescriptor<Todo>())) ?? [] {
            pushTodo(todo, uid: uid)
        }
        for memo in (try? context.fetch(FetchDescriptor<Memo>())) ?? [] {
            pushMemo(memo, uid: uid)
        }
        for reflection in (try? context.fetch(FetchDescriptor<MonthlyReflection>())) ?? [] {
            pushReflection(reflection, uid: uid)
        }
    }

    private func observeLocalSaves(context: ModelContext) {
        didSaveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: context,
            queue: .main
        ) { [weak self] notification in
            self?.handleDidSave(notification, context: context)
        }
    }

    private func handleDidSave(_ notification: Notification, context: ModelContext) {
        guard let uid = AppSession.shared.currentUserID else { return }
        let userInfo = notification.userInfo ?? [:]

        let inserted = (userInfo[ModelContext.NotificationKey.insertedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? []
        let updated = (userInfo[ModelContext.NotificationKey.updatedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? []
        let deleted = (userInfo[ModelContext.NotificationKey.deletedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? []

        for identifier in inserted + updated {
            guard let model = context.model(for: identifier) as? any PersistentModel else { continue }
            switch model {
            case let category as Category: pushCategory(category, uid: uid)
            case let schedule as Schedule: pushSchedule(schedule, uid: uid)
            case let todo as Todo: pushTodo(todo, uid: uid)
            case let memo as Memo: pushMemo(memo, uid: uid)
            case let reflection as MonthlyReflection: pushReflection(reflection, uid: uid)
            default: break
            }
        }

        for identifier in deleted {
            guard let cached = identifierCache[identifier] else { continue }
            db.collection("users").document(uid).collection(cached.collection).document(cached.docID).delete { error in
                if let error { print("FirestoreSyncEngine delete failed (\(cached.collection)/\(cached.docID)): \(error)") }
            }
            identifierCache.removeValue(forKey: identifier)
        }
    }

    /// Every push funnels through here so a failure (most commonly: the
    /// Firestore database was never created, or the security rules reject
    /// it) shows up in the console instead of failing completely silently.
    private func writeDoc(collection: String, uid: String, docID: String, data: [String: Any]) {
        db.collection("users").document(uid).collection(collection).document(docID).setData(data) { error in
            if let error { print("FirestoreSyncEngine push failed (\(collection)/\(docID)): \(error)") }
        }
    }

    private func pushCategory(_ category: Category, uid: String) {
        let docID = category.id.uuidString
        identifierCache[category.persistentModelID] = (collection: "categories", docID: docID)
        let data: [String: Any] = [
            "id": docID,
            "name": category.name,
            "colorHex": category.colorHex,
            "order": category.order,
            "kindRawValue": category.kindRawValue,
            "updatedAt": Timestamp(date: category.updatedAt),
        ]
        writeDoc(collection: "categories", uid: uid, docID: docID, data: data)
    }

    private func pushSchedule(_ schedule: Schedule, uid: String) {
        let docID = schedule.id.uuidString
        identifierCache[schedule.persistentModelID] = (collection: "schedules", docID: docID)
        var data: [String: Any] = [
            "id": docID,
            "title": schedule.title,
            "startDate": Timestamp(date: schedule.startDate),
            "allDay": schedule.allDay,
            "recurrenceRule": Self.encodeCodable(schedule.recurrenceRule),
            "excludedDates": schedule.excludedDates.map { Timestamp(date: $0) },
            "updatedAt": Timestamp(date: schedule.updatedAt),
        ]
        data["endDate"] = schedule.endDate.map { Timestamp(date: $0) }
        data["startTime"] = schedule.startTime.map { Timestamp(date: $0) }
        data["endTime"] = schedule.endTime.map { Timestamp(date: $0) }
        data["location"] = schedule.location
        data["memo"] = schedule.memo
        data["categoryID"] = schedule.category?.id.uuidString
        writeDoc(collection: "schedules", uid: uid, docID: docID, data: data)
    }

    private func pushTodo(_ todo: Todo, uid: String) {
        let docID = todo.id.uuidString
        identifierCache[todo.persistentModelID] = (collection: "todos", docID: docID)

        var occurrenceStates: [String: [String: Any]] = [:]
        for occurrence in todo.occurrences {
            let key = Self.isoDateFormatter.string(from: occurrence.occurrenceDate)
            var state: [String: Any] = ["completed": occurrence.completed, "isSkipped": occurrence.isSkipped, "order": occurrence.order]
            state["completedAt"] = occurrence.completedAt.map { Timestamp(date: $0) }
            occurrenceStates[key] = state
        }

        var data: [String: Any] = [
            "id": docID,
            "title": todo.title,
            "startDate": Timestamp(date: todo.startDate),
            "recurrenceRule": Self.encodeCodable(todo.recurrenceRule),
            "occurrenceStates": occurrenceStates,
            "updatedAt": Timestamp(date: todo.updatedAt),
        ]
        data["dueDate"] = todo.dueDate.map { Timestamp(date: $0) }
        data["memo"] = todo.memo
        data["categoryID"] = todo.category?.id.uuidString
        writeDoc(collection: "todos", uid: uid, docID: docID, data: data)
    }

    private func pushMemo(_ memo: Memo, uid: String) {
        let docID = memo.id.uuidString
        identifierCache[memo.persistentModelID] = (collection: "memos", docID: docID)
        var data: [String: Any] = [
            "id": docID,
            "content": memo.content,
            "date": Timestamp(date: memo.date),
            "locked": memo.locked,
            "updatedAt": Timestamp(date: memo.updatedAt),
        ]
        data["title"] = memo.title
        data["categoryID"] = memo.category?.id.uuidString
        writeDoc(collection: "memos", uid: uid, docID: docID, data: data)
    }

    private func pushReflection(_ reflection: MonthlyReflection, uid: String) {
        let docID = reflection.id.uuidString
        identifierCache[reflection.persistentModelID] = (collection: "monthlyReflections", docID: docID)
        let data: [String: Any] = [
            "id": docID,
            "year": reflection.year,
            "month": reflection.month,
            "goal": reflection.goal,
            "wentWell": reflection.wentWell,
            "couldImprove": reflection.couldImprove,
            "nextMonthFocus": reflection.nextMonthFocus,
            "updatedAt": Timestamp(date: reflection.updatedAt),
        ]
        writeDoc(collection: "monthlyReflections", uid: uid, docID: docID, data: data)
    }

    // MARK: - Pull (Firestore -> local)

    private func attachListeners(uid: String, context: ModelContext) {
        for collection in Self.collections {
            let listener = db.collection("users").document(uid).collection(collection)
                .addSnapshotListener { [weak self] snapshot, _ in
                    guard let self, let snapshot else { return }
                    self.handleSnapshot(snapshot, collection: collection, uid: uid, context: context)
                }
            listeners.append(listener)
        }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot, collection: String, uid: String, context: ModelContext) {
        for change in snapshot.documentChanges {
            let docID = change.document.documentID
            switch change.type {
            case .added, .modified:
                applyRemote(collection: collection, docID: docID, data: change.document.data(), uid: uid, context: context)
            case .removed:
                deleteLocal(collection: collection, docID: docID, context: context)
            }
        }
        try? context.save()
    }

    private func applyRemote(collection: String, docID: String, data: [String: Any], uid: String, context: ModelContext) {
        guard let id = UUID(uuidString: docID) else { return }
        let remoteUpdatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? .distantPast

        switch collection {
        case "categories":
            let existing = fetchOne(Category.self, id: id, uid: uid, context: context)
            if let existing, existing.updatedAt >= remoteUpdatedAt { return }
            let category = existing ?? Category(name: "", colorHex: "6F9ED8", order: 0, ownerID: uid)
            category.name = data["name"] as? String ?? category.name
            category.colorHex = data["colorHex"] as? String ?? category.colorHex
            category.order = data["order"] as? Int ?? category.order
            category.kindRawValue = data["kindRawValue"] as? String ?? category.kindRawValue
            category.updatedAt = remoteUpdatedAt
            if existing == nil {
                category.id = id
                context.insert(category)
                identifierCache[category.persistentModelID] = (collection: "categories", docID: docID)
            }

        case "schedules":
            let existing = fetchOne(Schedule.self, id: id, uid: uid, context: context)
            if let existing, existing.updatedAt >= remoteUpdatedAt { return }
            let schedule = existing ?? Schedule(title: "", startDate: .now, ownerID: uid)
            schedule.title = data["title"] as? String ?? schedule.title
            schedule.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? schedule.startDate
            schedule.endDate = (data["endDate"] as? Timestamp)?.dateValue()
            schedule.startTime = (data["startTime"] as? Timestamp)?.dateValue()
            schedule.endTime = (data["endTime"] as? Timestamp)?.dateValue()
            schedule.allDay = data["allDay"] as? Bool ?? schedule.allDay
            schedule.location = data["location"] as? String
            schedule.memo = data["memo"] as? String
            if let ruleDict = data["recurrenceRule"] as? [String: Any] {
                schedule.recurrenceRule = Self.decodeCodable(ruleDict) ?? .none
            }
            schedule.excludedDates = (data["excludedDates"] as? [Timestamp])?.map { $0.dateValue() } ?? []
            schedule.category = (data["categoryID"] as? String).flatMap { UUID(uuidString: $0) }
                .flatMap { fetchOne(Category.self, id: $0, uid: uid, context: context) }
            schedule.updatedAt = remoteUpdatedAt
            if existing == nil {
                schedule.id = id
                context.insert(schedule)
                identifierCache[schedule.persistentModelID] = (collection: "schedules", docID: docID)
            }

        case "todos":
            let existing = fetchOne(Todo.self, id: id, uid: uid, context: context)
            if let existing, existing.updatedAt >= remoteUpdatedAt { return }
            let todo = existing ?? Todo(title: "", startDate: .now, ownerID: uid)
            todo.title = data["title"] as? String ?? todo.title
            todo.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? todo.startDate
            todo.dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
            todo.memo = data["memo"] as? String
            if let ruleDict = data["recurrenceRule"] as? [String: Any] {
                todo.recurrenceRule = Self.decodeCodable(ruleDict) ?? .none
            }
            todo.category = (data["categoryID"] as? String).flatMap { UUID(uuidString: $0) }
                .flatMap { fetchOne(Category.self, id: $0, uid: uid, context: context) }
            todo.updatedAt = remoteUpdatedAt
            if existing == nil {
                todo.id = id
                context.insert(todo)
            }
            identifierCache[todo.persistentModelID] = (collection: "todos", docID: docID)

            // Overlay completion state onto already-materialized local
            // occurrences only — anything not yet materialized on this
            // device picks up its rule-derived date next time the app
            // materializes it, without this remote state (an accepted gap).
            if let occurrenceStates = data["occurrenceStates"] as? [String: [String: Any]] {
                for occurrence in todo.occurrences {
                    let key = Self.isoDateFormatter.string(from: occurrence.occurrenceDate)
                    guard let state = occurrenceStates[key] else { continue }
                    occurrence.completed = state["completed"] as? Bool ?? occurrence.completed
                    occurrence.isSkipped = state["isSkipped"] as? Bool ?? occurrence.isSkipped
                    occurrence.order = state["order"] as? Int ?? occurrence.order
                    occurrence.completedAt = (state["completedAt"] as? Timestamp)?.dateValue()
                }
            }

        case "memos":
            let existing = fetchOne(Memo.self, id: id, uid: uid, context: context)
            if let existing, existing.updatedAt >= remoteUpdatedAt { return }
            let memo = existing ?? Memo(content: "", date: .now, ownerID: uid)
            memo.title = data["title"] as? String
            memo.content = data["content"] as? String ?? memo.content
            memo.date = (data["date"] as? Timestamp)?.dateValue() ?? memo.date
            memo.locked = data["locked"] as? Bool ?? memo.locked
            memo.category = (data["categoryID"] as? String).flatMap { UUID(uuidString: $0) }
                .flatMap { fetchOne(Category.self, id: $0, uid: uid, context: context) }
            memo.updatedAt = remoteUpdatedAt
            if existing == nil {
                memo.id = id
                context.insert(memo)
                identifierCache[memo.persistentModelID] = (collection: "memos", docID: docID)
            }

        case "monthlyReflections":
            let existing = fetchOne(MonthlyReflection.self, id: id, uid: uid, context: context)
            if let existing, existing.updatedAt >= remoteUpdatedAt { return }
            let reflection = existing ?? MonthlyReflection(year: data["year"] as? Int ?? 0, month: data["month"] as? Int ?? 0, ownerID: uid)
            reflection.goal = data["goal"] as? String ?? reflection.goal
            reflection.wentWell = data["wentWell"] as? String ?? reflection.wentWell
            reflection.couldImprove = data["couldImprove"] as? String ?? reflection.couldImprove
            reflection.nextMonthFocus = data["nextMonthFocus"] as? String ?? reflection.nextMonthFocus
            reflection.updatedAt = remoteUpdatedAt
            if existing == nil {
                reflection.id = id
                context.insert(reflection)
                identifierCache[reflection.persistentModelID] = (collection: "monthlyReflections", docID: docID)
            }

        default:
            break
        }
    }

    private func deleteLocal(collection: String, docID: String, context: ModelContext) {
        guard let id = UUID(uuidString: docID) else { return }
        let uid = AppSession.shared.currentUserID ?? ""
        switch collection {
        case "categories":
            if let model = fetchOne(Category.self, id: id, uid: uid, context: context) { context.delete(model) }
        case "schedules":
            if let model = fetchOne(Schedule.self, id: id, uid: uid, context: context) { context.delete(model) }
        case "todos":
            if let model = fetchOne(Todo.self, id: id, uid: uid, context: context) { context.delete(model) }
        case "memos":
            if let model = fetchOne(Memo.self, id: id, uid: uid, context: context) { context.delete(model) }
        case "monthlyReflections":
            if let model = fetchOne(MonthlyReflection.self, id: id, uid: uid, context: context) { context.delete(model) }
        default:
            break
        }
    }

    // MARK: - Helpers

    private func fetchOne<T: PersistentModel>(_ type: T.Type, id: UUID, uid: String, context: ModelContext) -> T? {
        if type == Category.self {
            let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id && $0.ownerID == uid })
            return (try? context.fetch(descriptor))?.first as? T
        } else if type == Schedule.self {
            let descriptor = FetchDescriptor<Schedule>(predicate: #Predicate { $0.id == id && $0.ownerID == uid })
            return (try? context.fetch(descriptor))?.first as? T
        } else if type == Todo.self {
            let descriptor = FetchDescriptor<Todo>(predicate: #Predicate { $0.id == id && $0.ownerID == uid })
            return (try? context.fetch(descriptor))?.first as? T
        } else if type == Memo.self {
            let descriptor = FetchDescriptor<Memo>(predicate: #Predicate { $0.id == id && $0.ownerID == uid })
            return (try? context.fetch(descriptor))?.first as? T
        } else if type == MonthlyReflection.self {
            let descriptor = FetchDescriptor<MonthlyReflection>(predicate: #Predicate { $0.id == id && $0.ownerID == uid })
            return (try? context.fetch(descriptor))?.first as? T
        }
        return nil
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = MonthGridBuilder.calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func encodeCodable<T: Encodable>(_ value: T) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(value),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return json
    }

    private static func decodeCodable<T: Decodable>(_ dict: [String: Any]) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
