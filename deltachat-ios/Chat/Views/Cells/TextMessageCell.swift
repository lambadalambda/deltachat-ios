import Foundation
import DcCore
import UIKit

class TextMessageCell: BaseMessageCell, ReusableCell {

    static let reuseIdentifier = "TextMessageCell"

    override func setupSubviews() {
        super.setupSubviews()
        mainContentView.addArrangedSubview(messageLabel)
        messageLabel.paddingLeading = 12
        messageLabel.paddingTrailing = 12
    }

    override func update(dcContext: DcContext, msg: DcMsg, messageStyle: UIRectCorner, showAvatar: Bool, showName: Bool, showViewCount: Bool, searchText: String?, highlight: Bool) {
        if msg.type == DC_MSG_CALL {
            msg.text = "📞 " + (msg.text ?? "")
        }

        messageLabel.text = msg.text

        super.update(dcContext: dcContext,
                     msg: msg,
                     messageStyle: messageStyle,
                     showAvatar: showAvatar,
                     showName: showName,
                     showViewCount: showViewCount,
                     searchText: searchText,
                     highlight: highlight)
    }
}

class AgentProgressMessageCell: BaseMessageCell, ReusableCell {
    static let reuseIdentifier = "AgentProgressMessageCell"

    private var progressMessage: AgentProgressMessage?
    private var isExpanded = false

    private lazy var currentTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        )
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = DcColors.defaultTextColor
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var currentStateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(for: .caption1, weight: .regular)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = DcColors.defaultTextColor
        label.isHidden = true
        return label
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.isAccessibilityElement = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var currentRowView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [currentTextLabel, activityIndicator])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isAccessibilityElement = false
        return stack
    }()

    private lazy var callsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()

    override func setupSubviews() {
        super.setupSubviews()
        mainContentViewHorizontalPadding = 12
        mainContentView.spacing = 8
        mainContentView.addArrangedSubview(currentRowView)
        mainContentView.addArrangedSubview(currentStateLabel)
        mainContentView.addArrangedSubview(callsStackView)
    }

    func configureAgentProgress(_ progressMessage: AgentProgressMessage, isExpanded: Bool) {
        self.progressMessage = progressMessage
        self.isExpanded = isExpanded
    }

    override func update(
        dcContext: DcContext,
        msg: DcMsg,
        messageStyle: UIRectCorner,
        showAvatar: Bool,
        showName: Bool,
        showViewCount: Bool,
        searchText: String? = nil,
        highlight: Bool
    ) {
        super.update(
            dcContext: dcContext,
            msg: msg,
            messageStyle: messageStyle,
            showAvatar: showAvatar,
            showName: showName,
            showViewCount: showViewCount,
            searchText: searchText,
            highlight: highlight
        )

        guard let progressMessage else {
            currentTextLabel.text = effectiveMessageText(for: msg)
            currentStateLabel.isHidden = true
            activityIndicator.stopAnimating()
            clearCallRows()
            isActionButtonHidden = true
            return
        }

        currentTextLabel.text = progressMessage.collapsedText

        if progressMessage.isActive && !UIAccessibility.isReduceMotionEnabled {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }

        currentStateLabel.text = localizedState(progressMessage.state)
        currentStateLabel.isHidden = progressMessage.isActive || progressMessage.state == .done

        configureActionButton(for: progressMessage)
        configureCallRows(for: progressMessage)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressMessage = nil
        isExpanded = false
        currentTextLabel.text = nil
        currentStateLabel.text = nil
        currentStateLabel.isHidden = true
        activityIndicator.stopAnimating()
        clearCallRows()
    }

    private func configureActionButton(for progressMessage: AgentProgressMessage) {
        let canExpand = progressMessage.calls.count > 1
        guard canExpand else {
            isActionButtonHidden = true
            actionButton.accessibilityLabel = nil
            return
        }

        isActionButtonHidden = false
        let buttonTitle = isExpanded
            ? String.localized("agent_progress_hide_calls")
            : String.localized(stringID: "agent_progress_show_calls", parameter: progressMessage.calls.count)
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.accessibilityLabel = buttonTitle
    }

    private func configureCallRows(for progressMessage: AgentProgressMessage) {
        let shouldShowCalls = isExpanded && progressMessage.calls.count > 1
        callsStackView.isHidden = !shouldShowCalls
        guard shouldShowCalls else {
            clearCallRows()
            return
        }

        clearCallRows()
        for call in progressMessage.calls {
            callsStackView.addArrangedSubview(makeCallRow(for: call))
        }
    }

    private func makeCallRow(for call: AgentProgressMessage.Call) -> UIView {
        let statusLabel = UILabel()
        statusLabel.font = UIFont.preferredFont(for: .caption2, weight: .bold)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = DcColors.defaultTextColor
        statusLabel.text = localizedStatus(call.status).uppercased()
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel = UILabel()
        textLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        )
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textColor = DcColors.defaultTextColor
        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.text = call.formattedText
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [statusLabel, textLabel])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
        return row
    }

    private func clearCallRows() {
        for view in callsStackView.arrangedSubviews {
            callsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func localizedStatus(_ status: AgentProgressMessage.Call.Status) -> String {
        switch status {
        case .run:
            return String.localized("agent_progress_status_running")
        case .ok:
            return String.localized("agent_progress_status_ok")
        case .err:
            return String.localized("agent_progress_status_failed")
        case .cancel:
            return String.localized("agent_progress_status_cancelled")
        }
    }

    private func localizedState(_ state: AgentProgressMessage.State) -> String {
        switch state {
        case .thinking:
            return String.localized("agent_progress_status_thinking")
        case .running:
            return String.localized("agent_progress_status_running")
        case .done:
            return String.localized("done")
        case .failed:
            return String.localized("agent_progress_status_failed")
        case .cancelled:
            return String.localized("agent_progress_status_cancelled")
        }
    }
}
