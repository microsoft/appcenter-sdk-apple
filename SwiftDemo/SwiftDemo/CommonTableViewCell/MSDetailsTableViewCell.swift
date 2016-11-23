//
//  MSDetailsTableViewCell.swift
//  SwiftDemo
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

protocol MSDetailsCellDelegate : NSObjectProtocol {
    func actionButtonTapped(cell:MSDetailsTableViewCell, sender:UIButton)
}

class MSDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    weak var delegate : MSDetailsCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    class func name()->String {
        return String(describing: MSDetailsTableViewCell.self)
    }
    
    class func nib()->UINib{
        return UINib(nibName: MSDetailsTableViewCell.name() , bundle: nil)
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        self.delegate?.actionButtonTapped(cell: self, sender: sender)
    }
}
