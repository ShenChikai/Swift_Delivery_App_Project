//
//  ChatViewController.swift
//  Harvest
//
//  Created by Zixuan Li on 2021/3/16.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseUI

/// A base class for the example controllers
class ChatViewController: MessagesViewController, MessagesDataSource {

    let storageRef = Storage.storage().reference()

    lazy var messageList: [Message] = []
    
    let selfSender: User = Auth.auth().currentUser!
    
    private var docRef: DocumentReference?
    
    // the other sender
    //    var user2Name = String()
    //    var user2ImgRef: StorageReference?
    //    var user2ID = String()
    var user2Name = "Irene Driver" // TODO: fix
    var user2Img_url = "image/customer_avatar/Link.jpeg" // TODO: fix
    var user2ID = "owaWKBdQqqWNCpYZIf7QjVdSywp2" // TODO: fix
    var user2PhoneNum = "213232232" // TODO: fix
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadChat), for: .valueChanged)
        return control
    }()

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        configureMessageCollectionView()
        configureMessageInputBar()
        title = user2Name // TODO: fix with ?? "Chat"
        
        configureNavBarUI()
        loadChat()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
        
        messagesCollectionView.refreshControl = refreshControl
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .black
        messageInputBar.sendButton.setTitleColor(UIColor(named: "GreenTheme"), for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.black.withAlphaComponent(0.3),
            for: .highlighted
        )
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Header
    private func configureNavBarUI() {
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.isNavigationBarHidden = false
        
        setTitle(self.title!, image_url: user2Img_url)
        
        // init back button
        let buttonBack = UIButton()
        buttonBack.tintColor = UIColor(named: "GreenTheme")
        buttonBack.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        buttonBack.addTarget(self, action: #selector(buttonBackPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        // init phone button
        let buttonPhone = UIButton()
        buttonPhone.tintColor = UIColor(named: "GreenTheme")
        buttonPhone.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        buttonPhone.clipsToBounds = true
        buttonPhone.addTarget(self, action: #selector(btnCall), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonPhone)
    }
    
    @objc private func buttonBackPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setTitle(_ title: String, image_url: String) {
        if self.navigationController == nil {
            return
        }

        // Create a navView to add to the navigation bar
        let navView = UIView()

        // Create the name label
        let label = UILabel()
        label.text = title
        label.font = UIFont(name: "Roboto-Medium", size: 20)
        label.sizeToFit()
        label.center = CGPoint(x: navView.center.x, y: navView.center.y)
        label.textAlignment = .center
        
        // load avatar from cloud
        let imgRef = storageRef.child(user2Img_url)
        let imageView = UIImageView()
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
        imageView.frame = CGRect(x: label.frame.origin.x - label.frame.size.height * 1.3, y: label.frame.origin.y, width: label.frame.size.height, height: label.frame.size.height)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = label.frame.size.height / 2
        imageView.clipsToBounds = true

        // Add to the navView
        navView.addSubview(label)
        navView.addSubview(imageView)

        // Set the navigation bar's navigation item's titleView to the navView
        self.navigationItem.titleView = navView

        // Set the navView's frame to fit within the titleView
        navView.sizeToFit()
    }
    
    @objc private func btnCall() {
        print("click on phone")
        makePhoneCall(user2PhoneNum)
    }
    
    func makePhoneCall(_ phoneNum: String) {
        if let phoneURL = NSURL(string: ("tel://" + phoneNum)) {

            let alert = UIAlertController(title: ("Call " + phoneNum + "?"), message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Call", style: .default, handler: { (action) in
                UIApplication.shared.open(phoneURL as URL, options: [:], completionHandler: nil)
            }))

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - load and save chat messages
    private func createNewChat() {
        let users = [self.selfSender.uid, self.user2ID]
         let data: [String: Any] = [
             "users":users
         ]
         
         let db = Firestore.firestore().collection("chats")
         db.addDocument(data: data) { (error) in
             if let error = error {
                 print("Unable to create chat! \(error)")
                 return
             }
             else {
                 self.loadChat()
             }
         }
    }
    
    /// fetch all chat messages between current user and user2
    @objc func loadChat() {
        //Fetch all the chats which has current user in it
        let db = Firestore.firestore().collection("chats")
                .whereField("users", arrayContains: Auth.auth().currentUser?.uid ?? "Self sender not found")
        
        db.getDocuments { (doc, error) in
            
            if let error = error {
                print("Failed to retrieve messages for current sender: \(error)")
                return
            } else {
                
                // count how many documents retreived
                guard let queryCount = doc?.documents.count else {
                    return
                }
                
                // if no chat is available, create new chat instance
                if queryCount == 0 {
                    self.createNewChat()
                    return
                }
                // if chats found for currentUser
                else if queryCount >= 1 {
                    for doc in doc!.documents {
                        let chat = Chat(dictionary: doc.data())
                        
                        // filter chats to contain user2
                        if (chat?.users.contains(self.user2ID))! {
                            self.docRef = doc.reference
                             doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                            if let error = error {
                                print("Failed to retrieve chats contained user2: \(error)")
                                return
                            } else {
                                self.messageList.removeAll() // reset messages placeholder
                                
                                for message in threadQuery!.documents {
                                    let msg = Message(dictionary: message.data())
                                    self.messageList.append(msg!)
//                                    print("Retrieved message: \(msg?.content ?? "No message found")")
                                }
                                
                                self.messagesCollectionView.reloadData()
                                self.messagesCollectionView.scrollToLastItem(animated: true)
                            }})
                            
                            return
                        } //end of if
                    } //end of for
                    self.createNewChat()
                } else {
                    print("ERRORRRRR!")
                }
            }
        }
    }
    
    /// add the message to messages and reload
    func insertMessage(_ message: Message) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    /// prepare data and store in firebase
    private func save(_ message: Message) {
        
        let data: [String: Any] = [
        "content": message.content,
        "created": message.created,
        "id": message.id,
        "senderID": message.senderID,
        "senderName": message.senderName
        ]
        
        docRef?.collection("thread").addDocument(data: data, completion: { (error) in
            if let error = error {
                print("Fail to send message: \(error)")
                return
            }
            
            self.messagesCollectionView.scrollToLastItem()
        })
    }
    

    // MARK: - MessagesDataSource
    func currentSender() -> SenderType {
        return Sender(senderId: selfSender.uid, displayName: selfSender.displayName ?? "default")
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        if messageList.count == 0 {
            print("There're no messages")
            return 0
        }
        return messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        // if has been a while
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        // if is last message and sent be current sender
        if indexPath.section == messageList.count - 1 && isFromCurrentSender(message: message) {
            return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
}

// MARK: - MessageCellDelegate
extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate
extension ChatViewController: MessageLabelDelegate {
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }

    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }

    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
}

// MARK: - Bubble/Styles
extension ChatViewController: MessagesDisplayDelegate {
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(named: "GreenTheme")! : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            // resize space between messages
            layout.sectionInset = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
            // align left read/delivered status
            layout.setMessageOutgoingCellBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        }
        
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
        
        // remove space avatar occupies
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        }
    }
    
}
// MARK: - message layout

extension ChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        // if have top lable
        if indexPath.section % 3 == 0 {
            return 18
        }
        return 0
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        // if is last message
        if indexPath.section == messageList.count - 1 {
            return 17
        }
        return 0
    }
    
    // disable sender name above message
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    // disable message sent date below message
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
}

// MARK: - pressed send button
extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: selfSender.uid, senderName: "Irene Customer") // TODO: fix name
        
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async { [weak self] in
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = "Aa"
                self?.insertMessage(message)
                self?.save(message)
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }
}


