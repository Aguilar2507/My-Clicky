import Foundation

/// One JSON file per chat in `chats/`. A damaged file is set aside (`.damaged`) and never affects the others.
public final class ChatStore: @unchecked Sendable {
    public let paths: AppPaths
    private let queue = DispatchQueue(label: "MyClicky.ChatStore")
    private var pending: [UUID: DispatchWorkItem] = [:]
    private let debounce: TimeInterval

    public init(paths: AppPaths = .standard, debounce: TimeInterval = 0.3) {
        self.paths = paths
        self.debounce = debounce
    }

    public struct LoadResult {
        public var chats: [Chat]
        public var setAside: [URL]
    }

    public func loadAll() -> LoadResult {
        var result = LoadResult(chats: [], setAside: [])
        let files = (try? FileManager.default.contentsOfDirectory(at: paths.chats, includingPropertiesForKeys: nil)) ?? []
        for url in files where url.pathExtension == "json" {
            let expectedID = UUID(uuidString: url.deletingPathExtension().lastPathComponent)
            if let data = JSONFile.read(url),
               let chat = try? JSONFile.decoder.decode(Chat.self, from: data),
               chat.id == expectedID {
                result.chats.append(chat)
            } else if let moved = JSONFile.setAside(url) {
                result.setAside.append(moved)
            }
        }
        return result
    }

    public func save(_ chat: Chat) {
        queue.sync {
            pending[chat.id]?.cancel()
            let work = DispatchWorkItem { [paths] in try? JSONFile.write(chat, to: paths.chatFile(chat.id)) }
            pending[chat.id] = work
            queue.asyncAfter(deadline: .now() + debounce, execute: work)
        }
    }

    public func saveNow(_ chat: Chat) {
        queue.sync {
            pending[chat.id]?.cancel()
            pending[chat.id] = nil
            try? JSONFile.write(chat, to: paths.chatFile(chat.id))
        }
    }

    public func delete(id: UUID) {
        queue.sync {
            pending[id]?.cancel()
            pending[id] = nil
            try? FileManager.default.removeItem(at: paths.chatFile(id))
        }
    }

    public func flush() {
        queue.sync {
            for work in pending.values where !work.isCancelled {
                work.perform()
                work.cancel()
            }
            pending.removeAll()
        }
    }
}
