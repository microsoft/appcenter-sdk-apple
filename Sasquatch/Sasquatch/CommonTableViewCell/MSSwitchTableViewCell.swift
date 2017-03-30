//
//  MSSwitchTableViewCell.swift
//  Sasquatch
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

protocol MSSwitchCellDelegate : NSObjectProtocol {
  func switchValueChanged(cell:MSSwitchTableViewCell, sender:UISwitch)
}

class MSSwitchTableViewCell: UITableViewCell {
  
  @IBOutlet weak var titleNameLabel: UILabel!
  @IBOutlet weak var titleSwitch: UISwitch!
  weak var delegate: MSSwitchCellDelegate?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  class func name()->String {
    return String(describing: MSSwitchTableViewCell.self)
  }
  
  class func nib()->UINib{
    return UINib(nibName: MSSwitchTableViewCell.name() , bundle: nil)
  }
  
  @IBAction func switchValueChanged(_ sender: UISwitch) {
    self.delegate?.switchValueChanged(cell: self, sender: sender)
  }
  
}
