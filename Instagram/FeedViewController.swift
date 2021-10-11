//
//  FeedViewController.swift
//  Instagram
//
//  Created by Joohak Lee on 10/10/21.
//

import UIKit
import Parse
import AlamofireImage
class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()
    
    var postLimit = 0
    
    let refreshControl =  UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postLimit = 20
        tableView.delegate = self
        tableView.dataSource = self
        loadImage()
        refreshControl.addTarget(self, action: #selector(loadImage), for: .valueChanged)
        tableView.refreshControl = refreshControl
        //tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
    }
    
    
    @objc func loadImage(){
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
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
        query.includeKey("author")
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
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        let post = posts[indexPath.row]
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
    
    
    
    @IBAction func logOut(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
