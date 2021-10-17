//
//  FeedViewController.swift
//  Instagram
//
//  Created by Joohak Lee on 10/10/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate{

    @IBOutlet weak var tableView: UITableView!
    
    var selectedPost: PFObject!
    var posts = [PFObject]()
    
    let commentBar = MessageInputBar()
    
    var postLimit = 0
    
    let refreshControl =  UIRefreshControl()
    
    var showsCommentBar = false
    override func viewDidLoad() {
        super.viewDidLoad()
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        postLimit = 20
        tableView.delegate = self
        tableView.dataSource = self
        loadImage()
        refreshControl.addTarget(self, action: #selector(loadImage), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        //tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
    }
    //keyboard popup
    @objc func keyboardWillBeHidden(note: Notification){
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
        
        selectedPost.add(comment, forKey: "comments") //every array should have comment
        
        selectedPost.saveInBackground { success, error in
            if success{
                print("comment saved")
            }
            else{
                print("error saving comment")
            }
        }
        tableView.reloadData()
        // Clear and dismiss the input
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    @objc func loadImage(){
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author" , "comments", "comments.author"])
        query.limit = 30
        query.findObjectsInBackground { (posts, error) in
            if posts != nil{
                self.posts.removeAll()
                self.posts = posts!
                self.posts.reverse()
                while(self.posts.count != 20){
                    self.posts.removeLast()
                }
                self.tableView.reloadData()
            }
        
            self.refreshControl.endRefreshing()
        }
    }

    func loadMoreImage(){
        postLimit += 1
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = postLimit
        query.findObjectsInBackground { (posts, error) in
            if posts != nil{
                self.posts.removeAll()
                self.posts = posts!
                self.posts.reverse()
                self.tableView.reloadData()
            }
        
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == postLimit{
            loadMoreImage()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0{
        
        let user = post["author"] as! PFUser
        cell.usernameLabel.text = user.username
        cell.captionLabel.text = post["caption"] as! String
        
        let imageFile = post["iamge"] as! PFFileObject
        let urlString = imageFile.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af.setImage(withURL: url)
        
        
        //cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)

        return cell
        }
        else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1{
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
//        let comment = PFObject(className: "Comments")

//        comment["text"] = "Testing comment"
//        comment["post"] = post
//        comment["author"] = PFUser.current()!
//
//        post.add(comment, forKey: "comments") //every array should have comment
//
//        post.saveInBackground { success, error in
//            if success{
//                print("comment saved")
//            }
//            else{
//                print("error saving comment")
//            }
//        }
    }
    
    
    @IBAction func logOut(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        guard let windowSCene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowSCene.delegate as? SceneDelegate else{
            return}
        delegate.window?.rootViewController = loginViewController
    }
}
