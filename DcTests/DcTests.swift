import Testing
import XCTest
import DcCore
@testable import deltachat_ios
import UIKit

class DcTests {
    lazy var context = DcTestContext.newOfflineAccount()
    deinit { DcTestContext.cleanup() }
    
    @Test @MainActor func webxdcShouldNotLeak() async throws {
        // send a webxdc message
        let selfChat = context.createChatByContactId(contactId: Int(DC_CONTACT_ID_SELF))
        let chess = Bundle.module.url(forResource: "chess", withExtension: "xdc")!
        let xdcMessage = context.newMessage(viewType: DC_MSG_WEBXDC)
        xdcMessage.setFile(filepath: chess.path)
        context.sendMessage(chatId: selfChat, message: xdcMessage)
        
        // test if webxdc vc deinits after being presented and then dismissed
        let window = UIWindow()
        let vc = UIViewController()
        window.rootViewController = vc
        window.windowLevel = .alert
        window.makeKeyAndVisible()
        vc.present(WebxdcViewController(dcContext: context, messageId: xdcMessage.id), animated: false)
        weak var webxdcVC = vc.presentedViewController as? WebxdcViewController
        #expect(webxdcVC != nil)
        await webxdcVC!.dismiss(animated: false)
        #expect(webxdcVC == nil)
    }

    @Test @MainActor func markdownRenderingShouldStripMarkersAndAddLinks() async throws {
        let input = "Hello *bold* _it_ ~st~ `code` ```swift\nprint(\"hi\")\n``` [Delta](delta.chat)"
        let elements = MessageMarkdownParser.parseMarkdown(input)

        let rendered = MessageMarkdownRenderer.render(
            elements: elements,
            mode: .interactive,
            baseFont: UIFont.systemFont(ofSize: 14),
            textColor: .label,
            codeBackgroundColor: .secondarySystemBackground
        )

        #expect(rendered.string == "Hello bold it st code swift\nprint(\"hi\")\n Delta")

        let ns = rendered.string as NSString
        let deltaRange = ns.range(of: "Delta")
        #expect(deltaRange.location != NSNotFound)

        let link = rendered.attribute(.link, at: deltaRange.location, effectiveRange: nil) as? URL
        #expect(link?.absoluteString == "https://delta.chat")
    }

    @Test @MainActor func markdownShouldSuppressAutodetectionInsideMarkdownLinkLabels() async throws {
        let label = MessageLabel()
        label.enabledDetectors = [.url]

        let text = NSMutableAttributedString(string: "https://evil.com https://outside.com")
        let ns = text.string as NSString
        let evilRange = ns.range(of: "https://evil.com")
        #expect(evilRange.location != NSNotFound)

        text.addAttribute(.link, value: URL(string: "https://good.com")!, range: evilRange)
        text.addAttribute(
            MessageLabel.detectorSuppressionAttributeKey,
            value: MessageLabel.DetectorSuppression.autoDetectOnly.rawValue,
            range: evilRange
        )

        label.attributedText = text

        let urls = label.rangesForDetectors[.url, default: []].compactMap { tuple -> String? in
            if case let .link(url) = tuple.1 {
                return url?.absoluteString
            }
            return nil
        }

        #expect(urls.contains("https://good.com"))
        #expect(urls.contains("https://outside.com"))
        #expect(!urls.contains("https://evil.com"))
    }
}


struct DcTestContext {
    static func cleanup() {
        let accounts = DcAccounts.shared.getAll().compactMap(DcAccounts.shared.get(id:))
        for context in accounts where context.getConfigBool("ui.ios.test_account") {
            assert(DcAccounts.shared.remove(id: context.id))
        }
    }
    
    static func newOfflineAccount() -> DcContext {
        cleanup()
        let newAccountId = DcAccounts.shared.add()
        let newAccount = DcAccounts.shared.get(id: newAccountId)
        newAccount.setConfig("displayname", "Unit Test Account")
        newAccount.setConfig("addr", "ios.test@delta.chat")
        newAccount.setConfig("configured_addr", "ios.test@delta.chat")
        newAccount.setConfig("configured_mail_pw", "abcd")
        newAccount.setConfigBool("bcc_self", false)
        newAccount.setConfigBool("ui.ios.test_account", true)
        newAccount.setConfigBool("configured", true)
        assert(DcAccounts.shared.select(id: newAccountId))
        return newAccount
    }
}

extension UIViewController {
    func dismiss(animated: Bool) async {
        await withCheckedContinuation { continuation in
            dismiss(animated: animated, completion: continuation.resume)
        }
    }
}

extension UIView {
    func saveSnapshot(named name: String) throws {
        let thisFile = #filePath
        let snapFile = "file://" + thisFile
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast()
            .map(String.init)
            .appending("snapshots")
            .appending(name + ".png")
            .joined(separator: "/")
        try asImage().pngData()!.write(to: URL(string: snapFile)!)
    }
    
    func asImage() -> UIImage {
        UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

extension Array {
    func appending(_ newElement: Element) -> [Element] {
        var result = self
        result.append(newElement)
        return result
    }
}

extension Task where Failure == Never, Success == Never {
    static func sleep(seconds: Double) async throws {
        let nanoseconds = (seconds * 1_000_000_000).rounded(.down)
        try await sleep(nanoseconds: UInt64(exactly: nanoseconds) ?? 0)
    }
}

extension Bundle {
    @objc private class _This: NSObject {}
    internal static var module: Bundle {
        Bundle(for: _This.self)
    }
}
