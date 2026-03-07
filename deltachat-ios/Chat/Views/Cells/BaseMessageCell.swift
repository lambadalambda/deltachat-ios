import UIKit
import DcCore

public class BaseMessageCell: UITableViewCell {

    // horizontal message constraints for received messages
    private var leadingConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var trailingConstraintEditingMode: NSLayoutConstraint?
    private var leadingConstraintGroup: NSLayoutConstraint?
    private var gotoOriginalLeftConstraint: NSLayoutConstraint?

    // horizontal message constraints for sent messages
    private var leadingConstraintCurrentSender: NSLayoutConstraint?
    private var leadingConstraintCurrentSenderEditingMode: NSLayoutConstraint?
    private var trailingConstraintCurrentSender: NSLayoutConstraint?
    private var gotoOriginalRightConstraint: NSLayoutConstraint?

    private var mainContentBelowTopLabelConstraint: NSLayoutConstraint?
    private var mainContentUnderTopLabelConstraint: NSLayoutConstraint?
    private var mainContentAboveActionBtnConstraint: NSLayoutConstraint?
    private var mainContentUnderBottomLabelConstraint: NSLayoutConstraint?
    private var mainContentViewLeadingConstraint: NSLayoutConstraint?
    private var mainContentViewTrailingConstraint: NSLayoutConstraint?
    private var actionBtnZeroHeightConstraint: NSLayoutConstraint?
    private var actionBtnTrailingConstraint: NSLayoutConstraint?

    public var mainContentViewHorizontalPadding: CGFloat {
        get {
            return mainContentViewLeadingConstraint?.constant ?? 0
        }
        set {
            mainContentViewLeadingConstraint?.constant = newValue
            mainContentViewTrailingConstraint?.constant = -newValue
        }
    }

    // if set to true topLabel overlaps the main content
    public var topCompactView: Bool {
        get {
            return mainContentUnderTopLabelConstraint?.isActive ?? false
        }
        set {
            mainContentBelowTopLabelConstraint?.isActive = !newValue
            mainContentUnderTopLabelConstraint?.isActive = newValue
            topLabel.backgroundColor = newValue ?
                DcColors.systemMessageBackgroundColor :
                UIColor(alpha: 0, red: 0, green: 0, blue: 0)
        }
    }

    // if set to true bottomLabel overlaps the main content
    public var bottomCompactView: Bool {
        get {
            return mainContentUnderBottomLabelConstraint?.isActive ?? false
        }
        set {
            mainContentAboveActionBtnConstraint?.isActive = !newValue
            mainContentUnderBottomLabelConstraint?.isActive = newValue
        }
    }

    public var showBottomLabelBackground: Bool {
        didSet {
            statusView.backgroundColor = showBottomLabelBackground ?
                DcColors.systemMessageBackgroundColor :
                UIColor(alpha: 0, red: 0, green: 0, blue: 0)
        }
    }

    public var isActionButtonHidden: Bool {
        get {
            return actionButton.isHidden
        }
        set {
            mainContentAboveActionBtnConstraint?.constant = newValue ? -2 : 8
            actionBtnZeroHeightConstraint?.isActive = newValue
            actionBtnTrailingConstraint?.isActive = !newValue
            actionButton.isHidden = newValue
        }
    }

    public var isTransparent: Bool = false

    public weak var baseDelegate: BaseMessageCellDelegate?

    public lazy var quoteView: QuoteView = {
        let view = QuoteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.isHidden = true
        view.isAccessibilityElement = false
        return view
    }()

    public lazy var messageLabel: PaddingTextView = {
        let view = PaddingTextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.font = UIFont.preferredFont(for: .body, weight: .regular)
        view.delegate = self
        view.enabledDetectors = [.url, .phoneNumber, .command]
        let attributes = [
            NSAttributedString.Key.foregroundColor: view.tintColor!,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.underlineColor: view.tintColor!
        ]
        view.label.setAttributes(attributes, detector: .url)
        view.label.setAttributes(attributes, detector: .phoneNumber)
        view.label.setAttributes(attributes, detector: .command)
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = false
        return view
    }()

    let avatarSize = 34.0
    lazy var avatarView: InitialsBadge = {
        let view = InitialsBadge(size: avatarSize)
        view.setColor(UIColor.gray)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.isHidden = true
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = false
        return view
    }()

    lazy var topLabel: PaddingTextView = {
        let view = PaddingTextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(for: .caption1, weight: .bold)
        view.layer.cornerRadius = 4
        view.numberOfLines = 1
        view.label.lineBreakMode = .byTruncatingTail
        view.clipsToBounds = true
        view.paddingLeading = 4
        view.paddingTrailing = 4
        view.isAccessibilityElement = false
        return view
    }()

    lazy var mainContentView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [quoteView])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        return view
    }()

    lazy var actionButton: DynamicFontButton = {
        let button = DynamicFontButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(onActionButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont.preferredFont(for: .body, weight: .regular)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        button.accessibilityLabel = String.localized("show_full_message")
        return button
    }()

    private let gotoOriginalWidth = CGFloat(32)
    lazy var gotoOriginalButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.constraintHeightTo(gotoOriginalWidth),
            button.constraintWidthTo(gotoOriginalWidth)
        ])
        button.addTarget(self, action: #selector(onGotoOriginal), for: .touchUpInside)
        button.backgroundColor = DcColors.gotoButtonBackgroundColor
        button.setImage(UIImage(systemName: "chevron.right")?.sd_tintedImage(with: DcColors.gotoButtonFontColor), for: .normal)
        button.layer.cornerRadius = gotoOriginalWidth / 2
        button.layer.masksToBounds = true
        button.accessibilityLabel = String.localized("show_in_chat")

        return button
    }()

    let statusView = StatusView()

    lazy var messageBackgroundContainer: BackgroundContainer = {
        let container = BackgroundContainer()
        container.image = UIImage(color: UIColor.blue)
        container.contentMode = .scaleToFill
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = true
        return container
    }()

    let reactionsView: ReactionsView

    private var showSelectionBackground: Bool
    private var timer: Timer?

    private var dcContextId: Int?
    private var dcMsgId: Int?
    var a11yDcType: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        reactionsView = ReactionsView()
        reactionsView.translatesAutoresizingMaskIntoConstraints = false

        statusView.translatesAutoresizingMaskIntoConstraints = false

        showSelectionBackground = false
        showBottomLabelBackground = false
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        reactionsView.addTarget(self, action: #selector(BaseMessageCell.reactionsViewTapped(_:)), for: .touchUpInside)
        clipsToBounds = false
        backgroundColor = .none
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func setupSubviews() {
        selectedBackgroundView = UIView()
        contentView.addSubview(messageBackgroundContainer)
        messageBackgroundContainer.addSubview(mainContentView)
        messageBackgroundContainer.addSubview(topLabel)
        messageBackgroundContainer.addSubview(actionButton)
        messageBackgroundContainer.addSubview(statusView)
        contentView.addSubview(avatarView)
        contentView.addSubview(gotoOriginalButton)

        contentView.addConstraints([
            avatarView.constraintAlignLeadingTo(contentView, paddingLeading: 2),
            avatarView.constraintAlignBottomTo(messageBackgroundContainer),
            avatarView.constraintWidthTo(avatarSize, priority: .defaultHigh),
            avatarView.constraintHeightTo(avatarSize, priority: .defaultHigh),
            topLabel.constraintAlignTopTo(messageBackgroundContainer, paddingTop: 6),
            topLabel.constraintAlignLeadingTo(messageBackgroundContainer, paddingLeading: 8),
            topLabel.constraintAlignTrailingMaxTo(messageBackgroundContainer, paddingTrailing: 8),
            messageBackgroundContainer.constraintAlignTopTo(contentView, paddingTop: 3),
            actionButton.constraintAlignLeadingTo(messageBackgroundContainer, paddingLeading: 12),
            statusView.constraintAlignLeadingMaxTo(messageBackgroundContainer, paddingLeading: 8),
            statusView.constraintAlignTrailingTo(messageBackgroundContainer, paddingTrailing: 8),
            statusView.constraintToBottomOf(actionButton, paddingTop: 8, priority: .defaultHigh),
            statusView.constraintAlignBottomTo(messageBackgroundContainer, paddingBottom: 6),
            gotoOriginalButton.constraintCenterYTo(messageBackgroundContainer),
        ])

        gotoOriginalLeftConstraint = gotoOriginalButton.constraintAlignLeadingTo(messageBackgroundContainer, paddingLeading: -(gotoOriginalWidth+8))
        gotoOriginalLeftConstraint?.isActive = false
        gotoOriginalRightConstraint = gotoOriginalButton.constraintToTrailingOf(contentView, paddingLeading: -(gotoOriginalWidth+8))
        gotoOriginalRightConstraint?.isActive = false

        leadingConstraint = messageBackgroundContainer.constraintAlignLeadingTo(contentView, paddingLeading: 6)
        bottomConstraint = messageBackgroundContainer.constraintAlignBottomTo(contentView, paddingBottom: 3)
        bottomConstraint?.isActive = true
        leadingConstraintGroup = messageBackgroundContainer.constraintToTrailingOf(avatarView, paddingLeading: 2)
        trailingConstraint = messageBackgroundContainer.constraintAlignTrailingMaxTo(contentView, paddingTrailing: 50)
        trailingConstraintEditingMode = messageBackgroundContainer.constraintAlignTrailingMaxTo(contentView, paddingTrailing: 6)
        leadingConstraintCurrentSender = messageBackgroundContainer.constraintAlignLeadingMaxTo(contentView, paddingLeading: 50)
        leadingConstraintCurrentSenderEditingMode = messageBackgroundContainer.constraintAlignLeadingMaxTo(contentView, paddingLeading: 6)
        trailingConstraintCurrentSender = messageBackgroundContainer.constraintAlignTrailingTo(contentView, paddingTrailing: 6)

        mainContentViewLeadingConstraint = mainContentView.constraintAlignLeadingTo(messageBackgroundContainer)
        mainContentViewTrailingConstraint = mainContentView.constraintAlignTrailingTo(messageBackgroundContainer)
        mainContentViewLeadingConstraint?.isActive = true
        mainContentViewTrailingConstraint?.isActive = true

        mainContentBelowTopLabelConstraint = mainContentView.constraintToBottomOf(topLabel, paddingTop: 6)
        mainContentUnderTopLabelConstraint = mainContentView.constraintAlignTopTo(messageBackgroundContainer)
        mainContentAboveActionBtnConstraint = actionButton.constraintToBottomOf(mainContentView, paddingTop: 8, priority: .defaultHigh)
        mainContentUnderBottomLabelConstraint = mainContentView.constraintAlignBottomTo(messageBackgroundContainer, paddingBottom: 0, priority: .defaultHigh)

        actionBtnZeroHeightConstraint = actionButton.constraintHeightTo(0)
        actionBtnTrailingConstraint = actionButton.constraintAlignTrailingTo(messageBackgroundContainer, paddingTrailing: 12)

        topCompactView = false
        bottomCompactView = false
        showBottomLabelBackground = false
        isActionButtonHidden = true

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onAvatarTapped))
        gestureRecognizer.numberOfTapsRequired = 1
        avatarView.addGestureRecognizer(gestureRecognizer)

        let messageLabelGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        messageLabelGestureRecognizer.numberOfTapsRequired = 1
        messageLabel.addGestureRecognizer(messageLabelGestureRecognizer)

        let quoteViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onQuoteTapped))
        quoteViewGestureRecognizer.numberOfTapsRequired = 1
        quoteView.addGestureRecognizer(quoteViewGestureRecognizer)

        let statusGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onStatusTapped))
        statusGestureRecognizer.numberOfTapsRequired = 1
        statusView.addGestureRecognizer(statusGestureRecognizer)

        contentView.addSubview(reactionsView)

        let reactionsViewConstraints = [
            messageBackgroundContainer.leadingAnchor.constraint(lessThanOrEqualTo: reactionsView.leadingAnchor, constant: -10),
            messageBackgroundContainer.trailingAnchor.constraint(equalTo: reactionsView.trailingAnchor, constant: 10),
            messageBackgroundContainer.bottomAnchor.constraint(equalTo: reactionsView.bottomAnchor, constant: -20)
        ]

        NSLayoutConstraint.activate(reactionsViewConstraints)

    }

    @objc
    open func handleTapGesture(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let touchLocation = gesture.location(in: messageLabel)
        let isHandled = messageLabel.label.handleGesture(touchLocation)
        if !isHandled, let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            self.baseDelegate?.textTapped(indexPath: indexPath)
        }
    }

    @objc func onAvatarTapped() {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.avatarTapped(indexPath: indexPath)
        }
    }

    @objc func onGotoOriginal() {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.gotoOriginal(indexPath: indexPath)
        }
    }

    @objc func onQuoteTapped() {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.quoteTapped(indexPath: indexPath)
        }
    }

    @objc func onActionButtonTapped() {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.actionButtonTapped(indexPath: indexPath)
        }
    }

    @objc func onStatusTapped() {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.statusTapped(indexPath: indexPath)
        }
    }
    public override func willTransition(to state: UITableViewCell.StateMask) {
        super.willTransition(to: state)
        // while the content view gets intended by the appearance of the edit control,
        // we're adapting the the padding of the messages on the left side of the screen
        if state == .showingEditControl {
            if trailingConstraint?.isActive ?? false {
                trailingConstraint?.isActive = false
                trailingConstraintEditingMode?.isActive = true
            }
            if leadingConstraintCurrentSender?.isActive ?? false {
                leadingConstraintCurrentSender?.isActive = false
                leadingConstraintCurrentSenderEditingMode?.isActive = true
            }
        } else {
            if trailingConstraintEditingMode?.isActive ?? false {
                trailingConstraintEditingMode?.isActive = false
                trailingConstraint?.isActive = true
            }
            if leadingConstraintCurrentSenderEditingMode?.isActive ?? false {
                leadingConstraintCurrentSenderEditingMode?.isActive = false
                leadingConstraintCurrentSender?.isActive = true
            }
        }
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
         super.setSelected(selected, animated: animated)
         if selected && showSelectionBackground {
             selectedBackgroundView?.backgroundColor = DcColors.chatBackgroundColor.withAlphaComponent(0.5)
         } else {
             selectedBackgroundView?.backgroundColor = .clear
         }
     }

    // update classes inheriting BaseMessageCell first before calling super.update(...)
    func update(dcContext: DcContext, msg: DcMsg, messageStyle: UIRectCorner, showAvatar: Bool, showName: Bool, showViewCount: Bool, searchText: String?, highlight: Bool) {
        let fromContact = dcContext.getContact(id: msg.fromContactId)
        if msg.isFromCurrentSender {
            topLabel.text = msg.isForwarded ? String.localized("forwarded_message") : nil
            let topLabelTextColor: UIColor
            if msg.isForwarded {
                if topCompactView {
                    topLabelTextColor = DcColors.coreDark05
                } else {
                    topLabelTextColor = DcColors.unknownSender
                }
            } else {
                topLabelTextColor = DcColors.defaultTextColor
            }
            topLabel.textColor = topLabelTextColor
            leadingConstraint?.isActive = false
            leadingConstraintGroup?.isActive = false
            trailingConstraint?.isActive = false
            trailingConstraintEditingMode?.isActive = false
            leadingConstraintCurrentSender?.isActive = !isEditing
            leadingConstraintCurrentSenderEditingMode?.isActive = isEditing
            trailingConstraintCurrentSender?.isActive = true
            gotoOriginalLeftConstraint?.isActive = true
            gotoOriginalRightConstraint?.isActive = false
        } else {
            topLabel.text = msg.isForwarded ? String.localized("forwarded_message") :
                showName ? msg.getSenderName(fromContact, markOverride: true) : nil
            let topLabelTextColor: UIColor
            if msg.isForwarded {
                if topCompactView {
                    topLabelTextColor = DcColors.coreDark05
                } else {
                    topLabelTextColor = DcColors.unknownSender
                }
            } else if showName {
                topLabelTextColor = fromContact.color
            } else {
                topLabelTextColor = DcColors.defaultTextColor
            }
            topLabel.textColor = topLabelTextColor
            leadingConstraintCurrentSender?.isActive = false
            leadingConstraintCurrentSenderEditingMode?.isActive = false
            trailingConstraintCurrentSender?.isActive = false
            if showName {
                leadingConstraint?.isActive = false
                leadingConstraintGroup?.isActive = true
            } else {
                leadingConstraintGroup?.isActive = false
                leadingConstraint?.isActive = true
            }
            trailingConstraint?.isActive = !isEditing
            trailingConstraintEditingMode?.isActive = isEditing
            gotoOriginalLeftConstraint?.isActive = false
            gotoOriginalRightConstraint?.isActive = true
        }

        if showAvatar {
            avatarView.isHidden = false
            avatarView.setName(msg.getSenderName(fromContact))
            avatarView.setColor(fromContact.color)
            if let profileImage = fromContact.profileImage {
                avatarView.setImage(profileImage)
            }
        } else {
            avatarView.isHidden = true
        }

        gotoOriginalButton.isHidden = msg.originalMessageId == 0

        let downloadState = msg.downloadState
        let hasHtml = msg.hasHtml
        let hasWebxdc =  msg.type == DC_MSG_WEBXDC
        
        switch downloadState {
        case DC_DOWNLOAD_AVAILABLE:
            actionButton.setTitle(String.localized("download"), for: .normal)
            isActionButtonHidden = false
        case DC_DOWNLOAD_FAILURE:
            actionButton.setTitle(String.localized("download_failed"), for: .normal)
            isActionButtonHidden = false
        case DC_DOWNLOAD_IN_PROGRESS:
            actionButton.isEnabled = false
            actionButton.setTitle(String.localized("downloading"), for: .normal)
            isActionButtonHidden = false
        default:
            if hasHtml {
                actionButton.setTitle(String.localized("show_full_message"), for: .normal)
                isActionButtonHidden = false
            } else if hasWebxdc {
                actionButton.setTitle(String.localized("start_app"), for: .normal)
                isActionButtonHidden = false
            } else {
                isActionButtonHidden = true
            }
        }

        messageBackgroundContainer.update(rectCorners: messageStyle,
                                          color: getBackgroundColor(dcContext: dcContext, message: msg))

        if !msg.isInfo {
            var tintColor: UIColor
            if showBottomLabelBackground {
                tintColor = DcColors.coreDark05
            } else if msg.isFromCurrentSender {
                tintColor = DcColors.checkmarkGreen
            } else {
                tintColor = DcColors.incomingMessageSecondaryTextColor
            }

            let viewCount = showViewCount ? dcContext.getMessageReadReceiptCount(messageId: msg.id) : nil
            statusView.update(message: msg, tintColor: tintColor, showOnlyPendingAndError: showViewCount, viewCount: viewCount)
            let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self else { return }

                self.statusView.dateLabel.text = msg.formattedSentDate()
            }

            self.timer = timer
        }

        if let quoteText = msg.quoteText {
            quoteView.isHidden = false
            quoteView.quote.text = quoteText

            if let quoteMsg = msg.quoteMessage {
                let isWebxdc = quoteMsg.type == DC_MSG_WEBXDC
                let quoteImage = isWebxdc ? quoteMsg.getWebxdcPreviewImage() : quoteMsg.image
                quoteView.setImagePreview(quoteImage)
                quoteView.setRoundedCorners(isWebxdc)
                if quoteMsg.isForwarded {
                    quoteView.senderTitle.text = String.localized("forwarded_message")
                    quoteView.senderTitle.textColor = DcColors.unknownSender
                    quoteView.citeBar.backgroundColor = DcColors.unknownSender
                } else {
                    let contact = dcContext.getContact(id: quoteMsg.fromContactId)
                    quoteView.senderTitle.text = quoteMsg.getSenderName(contact, markOverride: true)
                    quoteView.senderTitle.textColor = contact.color
                    quoteView.citeBar.backgroundColor = contact.color
                }

            }
        } else {
            quoteView.isHidden = true
        }

        messageLabel.attributedText = getFormattedText(messageText: msg.text, searchText: searchText, highlight: highlight)
        messageLabel.delegate = self

        if let reactions = dcContext.getMessageReactions(messageId: msg.id) {
            reactionsView.isHidden = false
            reactionsView.configure(with: reactions)
            bottomConstraint?.constant = -20
        } else {
            reactionsView.isHidden = true
            bottomConstraint?.constant = -3
        }

        self.dcContextId = dcContext.id
        self.dcMsgId = msg.id
    }

    private func getFormattedText(messageText: String?, searchText: String?, highlight: Bool) -> NSAttributedString? {
        guard let messageText else { return nil }

        // Guard against pathological cases; the core limit is lower, this is a failsafe.
        // If we ever hit this limit, we prefer returning plain text over doing expensive parsing.
        let upperLimitForParsedMessagesUtf16 = 20_000
        if messageText.utf16.count >= upperLimitForParsedMessagesUtf16 {
            return plainAttributedString(messageText: messageText, searchText: searchText, highlight: highlight)
        }

        let markdownElements = MessageMarkdownParser.parseMarkdown(messageText)
        let visibleText = MessageMarkdownRenderer.plainText(from: markdownElements)
        let baseFontSize = BaseMessageCell.jumbomojiAdjustedFontSize(for: visibleText)
        let baseFont = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)

        let codeBackgroundColor = UIColor.themeColor(
            light: UIColor.black.withAlphaComponent(0.06),
            dark: UIColor.white.withAlphaComponent(0.12)
        )

        let rendered = MessageMarkdownRenderer.render(
            elements: markdownElements,
            mode: .interactive,
            baseFont: baseFont,
            textColor: DcColors.defaultTextColor,
            codeBackgroundColor: codeBackgroundColor
        )

        let highlighted = applySearchHighlight(
            rendered,
            searchText: searchText,
            highlight: highlight,
            fallbackFont: baseFont
        )

        return highlighted
    }

    private static func jumbomojiAdjustedFontSize(for messageText: String) -> CGFloat {
        var fontSize = UIFont.preferredFont(for: .body, weight: .regular).pointSize
        let charCount = messageText.count
        if charCount <= 8 && messageText.containsOnlyEmoji {
            if charCount <= 2 {
                fontSize *= 3.0
            } else if charCount <= 4 {
                fontSize *= 2.5
            } else if charCount <= 6 {
                fontSize *= 1.75
            } else {
                fontSize *= 1.35
            }
        }
        return fontSize
    }

    private func plainAttributedString(messageText: String, searchText: String?, highlight: Bool) -> NSAttributedString {
        let baseFontSize = BaseMessageCell.jumbomojiAdjustedFontSize(for: messageText)
        let font = UIFont.systemFont(ofSize: baseFontSize, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: DcColors.defaultTextColor
        ]
        let rendered = NSMutableAttributedString(string: messageText, attributes: attributes)
        return applySearchHighlight(rendered, searchText: searchText, highlight: highlight, fallbackFont: font)
    }

    private func applySearchHighlight(
        _ attributedString: NSMutableAttributedString,
        searchText: String?,
        highlight: Bool,
        fallbackFont: UIFont
    ) -> NSAttributedString {
        guard let searchText, !searchText.isEmpty else {
            return attributedString
        }

        let fullString = attributedString.string
        let ranges = fullString.ranges(of: searchText, options: .caseInsensitive)
        for range in ranges {
            let nsRange = NSRange(range, in: fullString)
            MessageMarkdownRenderer.applyFontWeight(.semibold, to: attributedString, range: nsRange, fallbackFont: fallbackFont)
            if highlight {
                attributedString.addAttribute(.backgroundColor, value: DcColors.highlight, range: nsRange)
            }
        }
        return attributedString
    }

    public override func accessibilityElementDidBecomeFocused() {
        logger.info("jit-rendering accessibility string")  // jit-rendering is needed as the reactions summary require quite some database calls
        guard let dcContextId, let dcMsgId else { return }
        let dcContext = DcAccounts.shared.get(id: dcContextId)
        let msg = dcContext.getMessage(id: dcMsgId)
        let dcChat = dcContext.getChat(chatId: msg.chatId)
        let shouldShowViewCount = msg.isFromCurrentSender && dcChat.isOutBroadcast
        let viewCount = shouldShowViewCount ? dcContext.getMessageReadReceiptCount(messageId: msg.id) : nil
        let reactions = dcContext.getMessageReactions(messageId: msg.id)

        var topLabelAccessibilityString = ""
        var quoteAccessibilityString = ""
        var messageLabelAccessibilityString = ""
        var additionalAccessibilityString = ""

        if let topLabelText = topLabel.text {
            topLabelAccessibilityString = "\(topLabelText), "
        }
        let a11yMessageText = messageLabel.attributedText?.string ?? messageLabel.text
        if let a11yMessageText {
            messageLabelAccessibilityString = "\(a11yMessageText), "
        }
        if let senderTitle = quoteView.senderTitle.text, let quote = quoteView.quote.text {
            quoteAccessibilityString = "\(senderTitle), \(quote), \(String.localized("reply_noun")), "
        }
        if let a11yDcType {
            additionalAccessibilityString = "\(a11yDcType), "
        }

        var reactionsString = ""
        if let reactions {
            reactionsString = ", " + String.localized(stringID: "n_reactions", parameter: reactions.reactionsByContact.count) + ": "
            for (contactId, reactions) in reactions.reactionsByContact {
                reactionsString += dcContext.getContact(id: contactId).displayName + ": " + reactions.joined(separator: " ") + ", "
            }
        }

        accessibilityLabel = "\(topLabelAccessibilityString) " +
            "\(quoteAccessibilityString) " +
            "\(additionalAccessibilityString) " +
            "\(messageLabelAccessibilityString) " +
            "\(StatusView.getAccessibilityString(message: msg, showOnlyPendingAndError: shouldShowViewCount, viewCount: viewCount))" +
            "\(reactionsString) "
    }

    func getBackgroundColor(dcContext: DcContext, message: DcMsg) -> UIColor {
        var backgroundColor: UIColor
        if isTransparent {
            backgroundColor = UIColor.init(alpha: 0, red: 0, green: 0, blue: 0)
        } else if message.isFromCurrentSender {
            backgroundColor =  DcColors.messagePrimaryColor
        } else {
            backgroundColor = DcColors.messageSecondaryColor
        }
        return backgroundColor
    }

    func getTextOffset(of text: String?) -> CGFloat {
        guard let text = text else { return 0 }
        let offsetInLabel = messageLabel.label.offsetOfSubstring(text)
        if offsetInLabel == 0 {
            return 0
        }

        let labelTop = CGPoint(x: messageLabel.label.bounds.minX, y: messageLabel.label.bounds.minY)
        let point = messageLabel.label.convert(labelTop, to: self)
        return point.y + offsetInLabel
    }

    override public func prepareForReuse() {
        accessibilityLabel = nil
        textLabel?.text = nil
        textLabel?.attributedText = nil
        topLabel.text = nil
        topLabel.attributedText = nil
        avatarView.reset()
        messageBackgroundContainer.prepareForReuse()
        statusView.prepareForReuse()
        baseDelegate = nil
        messageLabel.text = nil
        messageLabel.attributedText = nil
        messageLabel.delegate = nil
        quoteView.prepareForReuse()
        actionButton.isEnabled = true
        showSelectionBackground = false
        reactionsView.prepareForReuse()
        timer?.invalidate()
        timer = nil
        dcContextId = nil
        dcMsgId = nil
    }

    @objc func reactionsViewTapped(_ sender: Any?) {
        guard let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) else { return }

        baseDelegate?.reactionsTapped(indexPath: indexPath)
    }
}

// MARK: - MessageLabelDelegate
extension BaseMessageCell: MessageLabelDelegate {
    public func didSelectAddress(_ addressComponents: [String: String]) {}

    public func didSelectDate(_ date: Date) {}

    public func didSelectPhoneNumber(_ phoneNumber: String) {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.phoneNumberTapped(number: phoneNumber, indexPath: indexPath)
        }

    }

    public func didSelectURL(_ url: URL) {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.urlTapped(url: url, indexPath: indexPath)
        }
    }

    public func didSelectTransitInformation(_ transitInformation: [String: String]) {}

    public func didSelectMention(_ mention: String) {}

    public func didSelectHashtag(_ hashtag: String) {}

    public func didSelectCommand(_ command: String) {
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
            baseDelegate?.commandTapped(command: command, indexPath: indexPath)
        }
    }

    public func didSelectCustom(_ pattern: String, match: String?) {}
}

extension BaseMessageCell: SelectableCell {
    public func showSelectionBackground(_ show: Bool) {
        showSelectionBackground = show
    }
}

// MARK: - BaseMessageCellDelegate
// this delegate contains possible events from base cells or from derived cells
public protocol BaseMessageCellDelegate: AnyObject {
    func commandTapped(command: String, indexPath: IndexPath) // `/command`
    func phoneNumberTapped(number: String, indexPath: IndexPath)
    func urlTapped(url: URL, indexPath: IndexPath) // url is eg. `https://foo.bar`
    func imageTapped(indexPath: IndexPath, previewError: Bool)
    func avatarTapped(indexPath: IndexPath)
    func textTapped(indexPath: IndexPath)
    func quoteTapped(indexPath: IndexPath)
    func actionButtonTapped(indexPath: IndexPath)
    func statusTapped(indexPath: IndexPath)
    func gotoOriginal(indexPath: IndexPath)
    func reactionsTapped(indexPath: IndexPath)
}

// MARK: - Message Markdown

internal enum MessageMarkdownElement: Equatable {
    case text(String)
    case inlineCode(String)
    case codeBlock(content: String, language: String)
    case markdownLink(target: String, label: [MessageMarkdownElement])
    case bold([MessageMarkdownElement])
    case italic([MessageMarkdownElement])
    case strike([MessageMarkdownElement])
}

internal struct MessageMarkdownParser {
    private static let escapableMarkdownCharacters: Set<Character> = [
        "\\",
        "[",
        "]",
        "(",
        ")",
        "*",
        "_",
        "~",
        "`"
    ]

    private static let simpleFormatCharacters: Set<Character> = ["*", "_", "~"]

    static func parseMarkdown(_ message: String) -> [MessageMarkdownElement] {
        mergeTextElements(parseBlocks(message))
    }

    private static func parseBlocks(_ message: String) -> [MessageMarkdownElement] {
        let chars = Array(message)
        var parts: [MessageMarkdownElement] = []
        var offset = 0

        while offset < chars.count {
            guard let blockStart = indexOfTripleBackticks(in: chars, from: offset) else {
                parts.append(contentsOf: parseInline(String(chars[offset..<chars.count])))
                break
            }

            if blockStart > offset {
                parts.append(contentsOf: parseInline(String(chars[offset..<blockStart])))
            }

            if let parsedCodeBlock = tryParseCodeBlock(chars, startIndex: blockStart) {
                parts.append(parsedCodeBlock.element)
                offset = parsedCodeBlock.nextIndex
            } else {
                parts.append(.text("```"))
                offset = blockStart + 3
            }
        }

        return parts
    }

    private static func indexOfTripleBackticks(in chars: [Character], from start: Int) -> Int? {
        guard chars.count >= 3, start < chars.count else { return nil }
        var i = start
        while i + 2 < chars.count {
            if chars[i] == "`" && chars[i + 1] == "`" && chars[i + 2] == "`" {
                return i
            }
            i += 1
        }
        return nil
    }

    private static func tryParseCodeBlock(
        _ chars: [Character],
        startIndex: Int
    ) -> (element: MessageMarkdownElement, nextIndex: Int)? {
        guard startIndex + 2 < chars.count else { return nil }
        guard chars[startIndex] == "`", chars[startIndex + 1] == "`", chars[startIndex + 2] == "`" else { return nil }

        let afterFence = startIndex + 3
        guard let closingFence = indexOfTripleBackticks(in: chars, from: afterFence) else {
            return nil
        }

        // Find first line break between fences.
        let firstLineBreak = chars[afterFence..<closingFence].firstIndex(of: "\n")
        let hasLanguageHeader = firstLineBreak != nil && firstLineBreak != afterFence

        let language: String
        if hasLanguageHeader, let firstLineBreak {
            language = String(chars[afterFence..<firstLineBreak]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            language = ""
        }

        let contentStart: Int
        if let firstLineBreak, firstLineBreak < closingFence {
            contentStart = firstLineBreak + 1
        } else {
            contentStart = afterFence
        }

        let content = String(chars[contentStart..<closingFence])

        return (
            element: .codeBlock(content: content, language: language),
            nextIndex: closingFence + 3
        )
    }

    private static func parseInline(_ message: String) -> [MessageMarkdownElement] {
        let chars = Array(message)
        var elements: [MessageMarkdownElement] = []
        var plainTextBuffer = ""
        var offset = 0

        func flushPlainTextBuffer() {
            guard !plainTextBuffer.isEmpty else { return }
            elements.append(.text(plainTextBuffer))
            plainTextBuffer = ""
        }

        while offset < chars.count {
            let current = chars[offset]
            let next = (offset + 1 < chars.count) ? chars[offset + 1] : nil

            if current == "\\", let next, escapableMarkdownCharacters.contains(next) {
                plainTextBuffer.append(next)
                offset += 2
                continue
            }

            if current == "[" {
                if let parsedLink = tryParseMarkdownLink(chars, startIndex: offset) {
                    flushPlainTextBuffer()
                    elements.append(
                        .markdownLink(
                            target: parsedLink.target,
                            label: parseInline(parsedLink.label)
                        )
                    )
                    offset = parsedLink.nextIndex
                    continue
                }
            }

            if current == "`" {
                if let parsedInlineCode = tryParseInlineCode(chars, startIndex: offset) {
                    flushPlainTextBuffer()
                    elements.append(.inlineCode(parsedInlineCode.content))
                    offset = parsedInlineCode.nextIndex
                    continue
                }
            }

            if simpleFormatCharacters.contains(current) {
                if let parsedFormatted = tryParseSimpleFormatting(chars, startIndex: offset) {
                    flushPlainTextBuffer()

                    let contentElements = parseInline(parsedFormatted.content)
                    switch parsedFormatted.type {
                    case .bold:
                        elements.append(.bold(contentElements))
                    case .italic:
                        elements.append(.italic(contentElements))
                    case .strike:
                        elements.append(.strike(contentElements))
                    }

                    offset = parsedFormatted.nextIndex
                    continue
                }
            }

            plainTextBuffer.append(current)
            offset += 1
        }

        flushPlainTextBuffer()
        return mergeTextElements(elements)
    }

    private static func tryParseMarkdownLink(
        _ chars: [Character],
        startIndex: Int
    ) -> (label: String, target: String, nextIndex: Int)? {
        guard chars.get(at: startIndex) == "[" else { return nil }

        var labelDepth = 1
        var labelEnd: Int?
        var i = startIndex + 1
        while i < chars.count {
            let current = chars[i]

            if current == "\\" {
                i += 2
                continue
            }

            if current == "[" {
                labelDepth += 1
                i += 1
                continue
            }

            if current == "]" {
                labelDepth -= 1
                if labelDepth == 0 {
                    labelEnd = i
                    break
                }
            }

            i += 1
        }

        guard let labelEnd else { return nil }
        guard chars.get(at: labelEnd + 1) == "(" else { return nil }

        var targetDepth = 1
        var targetEnd: Int?
        i = labelEnd + 2
        while i < chars.count {
            let current = chars[i]

            if current == "\\" {
                i += 2
                continue
            }

            if current == "(" {
                targetDepth += 1
                i += 1
                continue
            }

            if current == ")" {
                targetDepth -= 1
                if targetDepth == 0 {
                    targetEnd = i
                    break
                }
            }

            i += 1
        }

        guard let targetEnd else { return nil }

        let label = String(chars[(startIndex + 1)..<labelEnd])
        let rawTarget = String(chars[(labelEnd + 2)..<targetEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTarget.isEmpty else { return nil }

        let target = normalizeLinkTarget(rawTarget)
        guard !target.isEmpty else { return nil }

        return (label: label, target: target, nextIndex: targetEnd + 1)
    }

    private static func normalizeLinkTarget(_ rawTarget: String) -> String {
        let trimmedTarget: String
        if rawTarget.hasPrefix("<"), rawTarget.hasSuffix(">"), rawTarget.count >= 2 {
            trimmedTarget = String(rawTarget.dropFirst().dropLast())
        } else {
            trimmedTarget = rawTarget
        }

        // Unescape: \\, \(, \), \[, \]
        let chars = Array(trimmedTarget)
        var result = ""
        var i = 0
        while i < chars.count {
            if chars[i] == "\\", let next = chars.get(at: i + 1) {
                if next == "\\" || next == "(" || next == ")" || next == "[" || next == "]" {
                    result.append(next)
                    i += 2
                    continue
                }
            }
            result.append(chars[i])
            i += 1
        }
        return result
    }

    private static func tryParseInlineCode(
        _ chars: [Character],
        startIndex: Int
    ) -> (content: String, nextIndex: Int)? {
        guard chars.get(at: startIndex) == "`" else { return nil }

        var markerLength = 1
        while chars.get(at: startIndex + markerLength) == "`" {
            markerLength += 1
        }

        let searchStart = startIndex + markerLength
        var closingIndex: Int?

        var i = searchStart
        while i + markerLength <= chars.count {
            if chars[i] == "`" && startsWith(chars, marker: "`", length: markerLength, at: i) {
                closingIndex = i
                break
            }
            i += 1
        }

        guard let closingIndex else { return nil }
        guard closingIndex != searchStart else { return nil }

        let content = String(chars[searchStart..<closingIndex])
        return (content: content, nextIndex: closingIndex + markerLength)
    }

    private enum FormattedType {
        case bold
        case italic
        case strike
    }

    private static func tryParseSimpleFormatting(
        _ chars: [Character],
        startIndex: Int
    ) -> (type: FormattedType, content: String, nextIndex: Int)? {
        guard let marker = chars.get(at: startIndex), simpleFormatCharacters.contains(marker) else {
            return nil
        }

        let markerLength = (chars.get(at: startIndex + 1) == marker) ? 2 : 1
        let previous = startIndex > 0 ? chars[startIndex - 1] : nil
        let afterOpeningMarker = chars.get(at: startIndex + markerLength)
        if afterOpeningMarker == nil || isWhitespace(afterOpeningMarker) || !isBoundaryCharacter(previous) {
            return nil
        }

        let type: FormattedType
        if marker == "*" {
            type = .bold
        } else if marker == "_" {
            type = .italic
        } else {
            type = .strike
        }

        var closingIndex = startIndex + markerLength
        while closingIndex < chars.count {
            let current = chars[closingIndex]
            if current == "\\" {
                closingIndex += 2
                continue
            }

            if !startsWith(chars, marker: marker, length: markerLength, at: closingIndex) {
                closingIndex += 1
                continue
            }

            let beforeClosingMarker = closingIndex > 0 ? chars[closingIndex - 1] : nil
            let afterClosingMarker = chars.get(at: closingIndex + markerLength)

            if beforeClosingMarker == nil || isWhitespace(beforeClosingMarker) || !isBoundaryCharacter(afterClosingMarker) {
                closingIndex += 1
                continue
            }

            let content = String(chars[(startIndex + markerLength)..<closingIndex])
            if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                closingIndex += 1
                continue
            }

            return (type: type, content: content, nextIndex: closingIndex + markerLength)
        }

        return nil
    }

    private static func startsWith(
        _ chars: [Character],
        marker: Character,
        length: Int,
        at index: Int
    ) -> Bool {
        guard index >= 0, length > 0, index + length <= chars.count else { return false }
        for j in 0..<length where chars[index + j] != marker {
            return false
        }
        return true
    }

    private static func isWhitespace(_ value: Character?) -> Bool {
        guard let value else { return false }
        return value.isWhitespace
    }

    private static func isBoundaryCharacter(_ value: Character?) -> Bool {
        guard let value else { return true }
        return !value.unicodeScalars.contains(where: { CharacterSet.alphanumerics.contains($0) })
    }

    private static func mergeTextElements(_ elements: [MessageMarkdownElement]) -> [MessageMarkdownElement] {
        var merged: [MessageMarkdownElement] = []

        for element in elements {
            if case let .text(text) = element,
               let last = merged.last,
               case let .text(lastText) = last {
                merged.removeLast()
                merged.append(.text(lastText + text))
            } else {
                merged.append(element)
            }
        }

        return merged
    }
}

internal struct MessageMarkdownRenderer {
    enum Mode {
        case interactive
        case nonInteractive
    }

    private struct Style {
        var weight: UIFont.Weight
        var italic: Bool
        var monospaced: Bool
    }

    static func plainText(from elements: [MessageMarkdownElement]) -> String {
        elements.map(plainText(from:)).joined()
    }

    private static func plainText(from element: MessageMarkdownElement) -> String {
        switch element {
        case .text(let text):
            return text
        case .inlineCode(let code):
            return code
        case .codeBlock(let content, let language):
            return language.isEmpty ? content : (language + "\n" + content)
        case .markdownLink(let target, let label):
            if label.isEmpty {
                return target
            }
            return plainText(from: label)
        case .bold(let children), .italic(let children), .strike(let children):
            return plainText(from: children)
        }
    }

    static func render(
        elements: [MessageMarkdownElement],
        mode: Mode,
        baseFont: UIFont,
        textColor: UIColor,
        codeBackgroundColor: UIColor
    ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        let baseStyle = Style(weight: .regular, italic: false, monospaced: false)
        for element in elements {
            result.append(
                render(
                    element: element,
                    mode: mode,
                    style: baseStyle,
                    baseFont: baseFont,
                    textColor: textColor,
                    codeBackgroundColor: codeBackgroundColor
                )
            )
        }
        return result
    }

    static func applyFontWeight(
        _ weight: UIFont.Weight,
        to attributedString: NSMutableAttributedString,
        range: NSRange,
        fallbackFont: UIFont
    ) {
        var updates: [(NSRange, UIFont)] = []
        attributedString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let currentFont = (value as? UIFont) ?? fallbackFont
            let updated = fontBySettingWeight(weight, on: currentFont)
            updates.append((subrange, updated))
        }
        for (subrange, font) in updates {
            attributedString.addAttribute(.font, value: font, range: subrange)
        }
    }

    private static func render(
        element: MessageMarkdownElement,
        mode: Mode,
        style: Style,
        baseFont: UIFont,
        textColor: UIColor,
        codeBackgroundColor: UIColor
    ) -> NSMutableAttributedString {
        switch element {
        case .text(let text):
            return NSMutableAttributedString(
                string: text,
                attributes: baseAttributes(
                    style: style,
                    baseFont: baseFont,
                    textColor: textColor,
                    codeBackgroundColor: nil
                )
            )

        case .bold(let children):
            var newStyle = style
            newStyle.weight = .bold
            return renderChildren(
                children,
                mode: mode,
                style: newStyle,
                baseFont: baseFont,
                textColor: textColor,
                codeBackgroundColor: codeBackgroundColor
            )

        case .italic(let children):
            var newStyle = style
            newStyle.italic = true
            return renderChildren(
                children,
                mode: mode,
                style: newStyle,
                baseFont: baseFont,
                textColor: textColor,
                codeBackgroundColor: codeBackgroundColor
            )

        case .strike(let children):
            let rendered = renderChildren(
                children,
                mode: mode,
                style: style,
                baseFont: baseFont,
                textColor: textColor,
                codeBackgroundColor: codeBackgroundColor
            )
            rendered.addAttribute(
                .strikethroughStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: NSRange(location: 0, length: rendered.length)
            )
            return rendered

        case .inlineCode(let code):
            var newStyle = style
            newStyle.monospaced = true
            let rendered = NSMutableAttributedString(
                string: code,
                attributes: baseAttributes(
                    style: newStyle,
                    baseFont: baseFont,
                    textColor: textColor,
                    codeBackgroundColor: codeBackgroundColor
                )
            )
            suppressDetectors(.all, in: rendered)
            return rendered

        case .codeBlock(let content, let language):
            var newStyle = style
            newStyle.monospaced = true
            let blockText = language.isEmpty ? content : (language + "\n" + content)
            let rendered = NSMutableAttributedString(
                string: blockText,
                attributes: baseAttributes(
                    style: newStyle,
                    baseFont: baseFont,
                    textColor: textColor,
                    codeBackgroundColor: codeBackgroundColor
                )
            )
            suppressDetectors(.all, in: rendered)

            if !language.isEmpty {
                let languageLength = (language as NSString).length
                let languageRange = NSRange(location: 0, length: languageLength)

                let headerFontSize = (baseFont.pointSize * 0.82).rounded(.down)
                let headerFont = UIFont.monospacedSystemFont(ofSize: headerFontSize, weight: .semibold)
                rendered.addAttribute(.font, value: headerFont, range: languageRange)
                rendered.addAttribute(
                    .foregroundColor,
                    value: textColor.withAlphaComponent(0.85),
                    range: languageRange
                )
            }

            return rendered

        case .markdownLink(let target, let label):
            let labelElements: [MessageMarkdownElement] = label.isEmpty ? [.text(target)] : label
            let renderedLabel = renderChildren(
                labelElements,
                mode: .nonInteractive,
                style: style,
                baseFont: baseFont,
                textColor: textColor,
                codeBackgroundColor: codeBackgroundColor
            )

            guard mode == .interactive else {
                return renderedLabel
            }

            let fullTarget = normalizedLinkTarget(target)
            guard let url = URL(string: fullTarget) else {
                return renderedLabel
            }

            renderedLabel.addAttribute(
                .link,
                value: url,
                range: NSRange(location: 0, length: renderedLabel.length)
            )
            suppressDetectors(.autoDetectOnly, in: renderedLabel)
            return renderedLabel
        }
    }

    private static func renderChildren(
        _ children: [MessageMarkdownElement],
        mode: Mode,
        style: Style,
        baseFont: UIFont,
        textColor: UIColor,
        codeBackgroundColor: UIColor
    ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        for child in children {
            result.append(
                render(
                    element: child,
                    mode: mode,
                    style: style,
                    baseFont: baseFont,
                    textColor: textColor,
                    codeBackgroundColor: codeBackgroundColor
                )
            )
        }
        return result
    }

    private static func baseAttributes(
        style: Style,
        baseFont: UIFont,
        textColor: UIColor,
        codeBackgroundColor: UIColor?
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(for: style, baseFont: baseFont),
            .foregroundColor: textColor
        ]
        if let codeBackgroundColor {
            attributes[.backgroundColor] = codeBackgroundColor
        }
        return attributes
    }

    private static func font(for style: Style, baseFont: UIFont) -> UIFont {
        let size = baseFont.pointSize
        let base: UIFont
        if style.monospaced {
            base = UIFont.monospacedSystemFont(ofSize: size, weight: style.weight)
        } else {
            base = UIFont.systemFont(ofSize: size, weight: style.weight)
        }

        guard style.italic else {
            return base
        }

        if let descriptor = base.fontDescriptor.withSymbolicTraits(base.fontDescriptor.symbolicTraits.union(.traitItalic)) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    private static func normalizedLinkTarget(_ target: String) -> String {
        let hasScheme = linkTargetHasScheme(target)
        return hasScheme ? target : ("https://" + target)
    }

    private static func linkTargetHasScheme(_ target: String) -> Bool {
        guard let first = target.first, first.isLetter else { return false }

        var index = target.index(after: target.startIndex)
        while index < target.endIndex {
            let ch = target[index]
            if ch == ":" {
                return true
            }
            if ch.isLetter || ch.isNumber || ch == "+" || ch == "-" || ch == "." {
                index = target.index(after: index)
                continue
            }
            return false
        }
        return false
    }

    private static func fontBySettingWeight(_ weight: UIFont.Weight, on font: UIFont) -> UIFont {
        var traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
        traits[.weight] = weight
        let descriptor = font.fontDescriptor.addingAttributes([.traits: traits])
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private enum DetectorSuppression {
        case autoDetectOnly
        case all
    }

    private static func suppressDetectors(_ suppression: DetectorSuppression, in attributedString: NSMutableAttributedString) {
        let value: Int
        switch suppression {
        case .autoDetectOnly:
            value = MessageLabel.DetectorSuppression.autoDetectOnly.rawValue
        case .all:
            value = MessageLabel.DetectorSuppression.all.rawValue
        }
        attributedString.addAttribute(
            MessageLabel.detectorSuppressionAttributeKey,
            value: value,
            range: NSRange(location: 0, length: attributedString.length)
        )
    }
}
