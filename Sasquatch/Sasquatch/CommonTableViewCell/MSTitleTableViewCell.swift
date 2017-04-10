//
//  MSTitleTableViewCell.swift
//  Sasquatch
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit


class MSTitleTableViewCell: UITableViewCell {
  
  @IBOutlet weak var titleNameLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  class func name()->String {
    return String(describing: MSTitleTableViewCell.self)
  }
  
  class func nib()->UINib{
    return UINib(nibName: MSTitleTableViewCell.name() , bundle: nil)
  }
}
