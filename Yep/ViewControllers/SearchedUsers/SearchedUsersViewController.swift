//
//  SearchedUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUsersViewController: BaseViewController {

    var searchText = "NIX"

    @IBOutlet weak var searchedUsersTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var searchedUsers = [DiscoveredUser]() {
        didSet {
            if searchedUsers.count > 0 {
                updateSearchedUsersTableView()

            } else {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: searchedUsersTableView.bounds.width, height: 240))

                label.textAlignment = .Center
                label.text = NSLocalizedString("No search results.", comment: "")
                label.textColor = UIColor.lightGrayColor()

                searchedUsersTableView.tableFooterView = label
            }
        }
    }

    let cellIdentifier = "ContactsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "") + " \"\(searchText)\""

        searchedUsersTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        searchedUsersTableView.rowHeight = 80


        activityIndicator.startAnimating()

        searchUsersByQ(searchText, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason, errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] users in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
                self?.searchedUsers = users
            }
        })
    }

    // MARK: Actions

    func updateSearchedUsersTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.searchedUsersTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = searchedUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController

                if discoveredUser.id != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                }

                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension SearchedUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = searchedUsers[indexPath.row]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak cell] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell?.avatarImageView.image = roundImage
            }
        }

        cell.joinedDateLabel.text = discoveredUser.introduction
        let distance = discoveredUser.distance.format(".1")
        cell.lastTimeSeenLabel.text = "\(distance)km | \(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"

        cell.nameLabel.text = discoveredUser.nickname

        if let badgeName = discoveredUser.badge, badge = BadgeView.Badge(rawValue: badgeName) {
            cell.badgeImageView.image = badge.image
            cell.badgeImageView.tintColor = badge.color
        } else {
            cell.badgeImageView.image = nil
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}