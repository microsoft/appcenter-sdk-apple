//
//  MSDetailsTableViewCell.swift
//  SwiftDemo
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

class MSDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var titleNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
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

}
